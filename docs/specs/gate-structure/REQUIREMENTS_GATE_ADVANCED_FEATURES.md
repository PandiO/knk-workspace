# REQUIREMENTS: Gate Advanced Features (Pass-Through, Guards, Siege, Health Display)

**Status**: Draft - Extends base gate animation requirements  
**Created**: January 31, 2026  
**Parent Document**: REQUIREMENTS_GATE_ANIMATION.md

This document specifies advanced features discovered during legacy code analysis that extend the base gate animation system.

---

## Overview

These features were identified in the legacy Gate.java implementation and confirmed as required functionality for the v2 system:

1. **Pass-Through System**: Auto-open/close for authorized players
2. **Guard Spawn System**: NPC defenders (future feature placeholder)
3. **Health Display System**: Configurable visual health indicators
4. **Siege Integration**: Gates as objectives/obstacles in siege minigame
5. **Continuous Damage System**: Fire-based damage over time

All features integrate with the base animation system defined in REQUIREMENTS_GATE_ANIMATION.md.

---

## Feature 1: Pass-Through System

### Business Requirements

**Goal**: Allow authorized players to walk through gates without manual interaction, improving gameplay flow for friendly/VIP players.

**User Stories:**
- As a **clan member**, I want to pass through my clan's gates automatically so I don't have to manually open/close them
- As a **VIP player**, I want to bypass gates in certain areas based on my donator rank
- As an **admin**, I want to configure complex access conditions (XP, ethics, permissions) per gate

### Entity Fields (GateStructure)

```csharp
public bool AllowPassThrough { get; set; } = false;
// Master toggle - enable/disable pass-through feature

public int PassThroughDurationSeconds { get; set; } = 4;
// How long gate stays open after player passes (default 4 seconds)

public string PassThroughConditionsJson { get; set; } = string.Empty;
// JSON object defining eligibility conditions (see schema below)
```

### Pass-Through Conditions Schema

```json
{
  "minExperience": 1000,
  "requiredClanId": 5,
  "minEthicsLevel": 3,
  "requiredDonatorRank": 1,
  "requiredPermissions": ["knk.gate.vip", "knk.gate.passthrough.<gateId>"],
  "allowedUserIds": [1, 2, 3],
  "deniedUserIds": [99, 100]
}
```

**Field Descriptions:**
- `minExperience` (int, optional): Minimum XP required
- `requiredClanId` (int, optional): Must belong to specific clan
- `minEthicsLevel` (int, optional): Minimum ethics/karma level (0-5 scale)
- `requiredDonatorRank` (int, optional): Minimum donator tier (0=none, 1=bronze, 2=silver, 3=gold, 4=platinum)
- `requiredPermissions` (string[], optional): All listed permissions required
- `allowedUserIds` (int[], optional): Whitelist specific users (bypass other conditions)
- `deniedUserIds` (int[], optional): Blacklist specific users (overrides all conditions)

**Condition Evaluation Logic:**
```
IF AllowPassThrough = false THEN deny
IF IsActive = false OR IsDestroyed = true THEN deny
IF deniedUserIds contains player.Id THEN deny
IF allowedUserIds contains player.Id THEN allow

# All conditions must pass (AND logic)
IF minExperience defined AND player.Experience < minExperience THEN deny
IF requiredClanId defined AND player.ClanId != requiredClanId THEN deny
IF minEthicsLevel defined AND player.EthicsLevel < minEthicsLevel THEN deny
IF requiredDonatorRank defined AND player.DonatorRank < requiredDonatorRank THEN deny
IF requiredPermissions defined AND NOT player.hasAllPermissions(requiredPermissions) THEN deny

ELSE allow
```

### Workflow

**Player Proximity Detection:**
1. Plugin runs proximity check every 5 ticks (0.25 seconds)
2. For each player within 3 blocks of gate anchor:
   - Check if gate `AllowPassThrough = true`
   - Evaluate pass-through conditions
   - If authorized: trigger pass-through sequence

**Pass-Through Sequence:**
```
Player enters proximity (3 blocks from gate)
  ↓
Evaluate conditions
  ↓
IF authorized:
  ↓
  Check current state:
    - CLOSED → Begin OPENING animation
    - OPENING → Continue (already opening)
    - OPEN → Extend timer (reset to PassThroughDurationSeconds)
    - CLOSING → Reverse to OPENING
  ↓
  Gate reaches OPEN state
  ↓
  Monitor player position:
    - Player exits proximity (5 blocks) → Start close timer
    - Timer expires (PassThroughDurationSeconds) → Begin CLOSING
  ↓
  Gate returns to CLOSED state
```

**Edge Cases:**
- **Multiple players**: Timer extends while ANY authorized player is within proximity
- **Mid-animation interruption**: If player moves away while gate is opening, complete opening animation, then auto-close after timer
- **Manual open/close**: Admin can override pass-through (gate stays in set state)
- **Siege active**: Pass-through disabled during siege (security measure)

### API Endpoints

**Update Pass-Through Settings:**
```
PUT /api/gates/{id}/passthrough
{
  "allowPassThrough": true,
  "passThroughDurationSeconds": 6,
  "passThroughConditionsJson": "{...}"
}
```

**Test Conditions (Admin Tool):**
```
POST /api/gates/{id}/passthrough/test
{
  "userId": 123
}

Response:
{
  "authorized": true,
  "failedConditions": [],
  "evaluationDetails": {
    "minExperience": { "required": 1000, "actual": 2500, "passed": true },
    "requiredClanId": { "required": 5, "actual": 5, "passed": true },
    ...
  }
}
```

### Web App UI

**Configuration Panel:**
- Toggle: "Enable Pass-Through"
- Slider: "Auto-Close Delay" (1-30 seconds)
- Conditions Editor:
  - Number input: "Minimum Experience"
  - Dropdown: "Required Clan" (clan list from API)
  - Slider: "Minimum Ethics Level" (0-5)
  - Dropdown: "Required Donator Rank"
  - Multi-select: "Required Permissions"
  - Text area: "Allowed User IDs" (comma-separated)
  - Text area: "Denied User IDs" (comma-separated)
- Button: "Test Conditions" → Opens modal with user search

**Test Conditions Modal:**
- Search bar: "Enter username or user ID"
- Results table:
  - User | Authorized? | Failed Conditions | Details
  - john_doe | ✅ Yes | - | All conditions passed
  - jane_smith | ❌ No | minExperience, requiredClanId | XP: 500/1000, Clan: 3/5

---

## Feature 2: Guard Spawn System (Future)

### Business Requirements

**Goal**: Spawn NPC guards to defend gates when attacked, enhancing PvE combat and siege mechanics.

**User Stories:**
- As an **attacker**, I want to face NPC defenders when breaching gates to make sieges more challenging
- As a **defender**, I want my gates to spawn guards automatically so I don't have to manually defend 24/7
- As an **admin**, I want to configure guard types, spawn points, and behavior per gate

**Implementation Priority**: Phase 2 (post-animation system)

### Entity Fields (GateStructure)

```csharp
public string GuardSpawnLocationsJson { get; set; } = string.Empty;
// JSON array of spawn points with position and rotation

public int GuardCount { get; set; } = 0;
// Number of guards to spawn (0 = disabled)

public int? GuardNpcTemplateId { get; set; }
// Foreign Key → NpcTemplate (defines guard stats, equipment, AI)

public MinecraftMaterialRef? GuardNpcTemplate { get; set; } = null;
// Navigation property (future NPC system)
```

### Guard Spawn Locations Schema

```json
[
  { "x": 100, "y": 64, "z": 100, "yaw": 180.0, "pitch": 0.0 },
  { "x": 105, "y": 64, "z": 100, "yaw": 0.0, "pitch": 0.0 },
  { "x": 102, "y": 65, "z": 102, "yaw": 90.0, "pitch": 0.0 }
]
```

### Spawn Triggers

1. **Gate Damage**: Spawn guards when `HealthCurrent` decreases
   - Threshold: Every 10% health lost spawns 1 guard (configurable)
   - Example: 500hp → 450hp (-50hp = 10%) → Spawn 1 guard

2. **Siege Start**: Spawn all guards when gate enters siege mode
   - `CurrentSiegeId` changes from null → siegeId

3. **Manual Command**: Admin spawns guards via `/gate admin guards spawn <name>`

### NPC Template (Future Entity)

```csharp
public class NpcTemplate
{
    public int Id { get; set; }
    public string Name { get; set; }  // "Castle Guard", "Elite Archer", etc.
    public string NpcType { get; set; }  // MELEE, RANGED, MAGE
    
    // Combat Stats
    public double HealthMax { get; set; } = 20.0;
    public double Damage { get; set; } = 5.0;
    public double MoveSpeed { get; set; } = 0.25;
    
    // Equipment
    public string EquipmentJson { get; set; }  // JSON: {helmet, chestplate, ...}
    
    // AI Behavior
    public string BehaviorType { get; set; }  // PATROL, DEFENSIVE, AGGRESSIVE
    public int AggroRange { get; set; } = 16;  // Blocks
    public int PatrolRadius { get; set; } = 10;  // Blocks from spawn
    
    // Loot
    public string LootTableJson { get; set; }  // JSON: [{item, chance, quantity}]
}
```

### Placeholder Implementation (v1)

Since NPC system is future work, v1 implementation:
- Store fields in GateStructure entity
- Web app allows configuration
- API endpoints save/retrieve data
- Plugin **does not spawn guards** (feature disabled until NPC system ready)
- Admin UI shows "Feature coming soon" message

---

## Feature 3: Health Display System

### Business Requirements

**Goal**: Provide visual feedback on gate health and status to players, especially during combat and sieges.

**User Stories:**
- As a **player**, I want to see gate health so I know how much damage I've dealt
- As a **defender**, I want to see gate status (open/closed) from a distance
- As an **admin**, I want to configure when health displays are visible (always, damaged only, siege only)

### Entity Fields (GateStructure)

```csharp
public bool ShowHealthDisplay { get; set; } = true;
// Master toggle - show/hide health display

public string HealthDisplayMode { get; set; } = "ALWAYS";
// Enum: ALWAYS, DAMAGED_ONLY, NEVER, SIEGE_ONLY

public int HealthDisplayYOffset { get; set; } = 2;
// Blocks above gate anchor to place display entity
```

### Display Modes

| Mode | Visibility Condition |
|------|---------------------|
| ALWAYS | Display always visible when `ShowHealthDisplay = true` && `IsActive = true` |
| DAMAGED_ONLY | Display visible only when `HealthCurrent < HealthMax` |
| NEVER | No display (health only visible via `/gate info` command) |
| SIEGE_ONLY | Display visible only when `CurrentSiegeId != null` (during siege) |

### Display Implementation (Plugin)

**Entity Type**: ArmorStand
- Invisible base (no visible armor stand model)
- Custom name visible (always)
- Name tag always visible (even through walls, within render distance)
- No gravity, invulnerable, persistent

**Display Text Format:**
```
[Gate Name] - [Health]/[MaxHealth]hp - [Status]
```

**Color Coding (Health):**
- `HealthCurrent >= 75% HealthMax`: §a (Green)
- `50% ≤ HealthCurrent < 75%`: §e (Yellow)
- `25% ≤ HealthCurrent < 50%`: §6 (Gold/Orange)
- `HealthCurrent < 25%`: §c (Red)
- `IsDestroyed = true`: §4 (Dark Red)

**Status Indicators:**
- 🟢 OPEN (`IsOpened = true`)
- 🔴 CLOSED (`IsOpened = false`)
- ⚙️ OPENING (state = OPENING)
- ⚙️ CLOSING (state = CLOSING)
- 💀 DESTROYED (`IsDestroyed = true`)
- 🛡️ INVINCIBLE (`IsInvincible = true`)

**Examples:**
```
§a[Castle Gate] - 480/500hp - §2🟢 OPEN
§e[Main Portcullis] - 320/500hp - §c🔴 CLOSED
§6[Side Gate] - 150/500hp - §6⚙️ OPENING
§c[Weak Gate] - 80/500hp - §c🔴 CLOSED
§4[Broken Gate] - 0/500hp - §4💀 DESTROYED
§b[Admin Gate] - 500/500hp - §b🛡️ INVINCIBLE
```

**Position Calculation:**
```java
// Get gate anchor point
Vector anchor = gate.getAnchorPoint();

// Calculate gate center (horizontal)
Vector center = anchor.add(
    gate.GeometryWidth / 2.0,
    0,
    gate.GeometryDepth / 2.0
);

// Apply vertical offset
Vector displayPos = center.add(0, gate.HealthDisplayYOffset, 0);

// Spawn ArmorStand
ArmorStand display = world.spawn(displayPos.toLocation(world), ArmorStand.class);
display.setCustomName(getDisplayText(gate));
display.setCustomNameVisible(true);
display.setInvisible(true);
display.setInvulnerable(true);
display.setGravity(false);
display.setPersistent(true);
```

**Update Triggers (recalculate display text):**
- Health change: `setCurrentHealth()`, `removeHealth()`, `addHealth()`
- State change: `setOpened()`, `setDestroyed()`, `setInvincible()`
- Siege change: `setCurrentSiegeId()`
- Periodic update: Every 20 ticks (1 second) when players are nearby

**Cleanup:**
- Remove ArmorStand when gate is deleted
- Remove when `ShowHealthDisplay = false`
- Remove when display mode conditions not met

### API Endpoints

**Update Display Settings:**
```
PUT /api/gates/{id}/display
{
  "showHealthDisplay": true,
  "healthDisplayMode": "DAMAGED_ONLY",
  "healthDisplayYOffset": 3
}
```

### Web App UI

**Health Display Panel:**
- Toggle: "Show Health Display"
- Dropdown: "Display Mode" (ALWAYS, DAMAGED_ONLY, NEVER, SIEGE_ONLY)
- Number input: "Vertical Offset" (0-10 blocks)
- Preview: Live rendering of display text (mock)

---

## Feature 4: Siege Integration System

### Business Requirements

**Goal**: Integrate gates into siege minigame as objectives and obstacles, enabling strategic gameplay.

**User Stories:**
- As an **attacker**, I want to breach gates to access inner defenses during sieges
- As a **defender**, I want to keep gates closed to delay attackers
- As a **siege admin**, I want to configure which gates are objectives vs obstacles

**Priority**: Current sprint (siege minigame implementation)

### Entity Fields (GateStructure)

```csharp
public bool IsOverridable { get; set; } = true;
// Allow manual override during siege (admin emergency control)

public bool AnimateDuringSiege { get; set; } = true;
// Animate gate open/close during siege (vs instant state change)

public int? CurrentSiegeId { get; set; }
// Foreign Key → Siege (null if no active siege)

public Siege? CurrentSiege { get; set; } = null;
// Navigation property

public bool IsSiegeObjective { get; set; } = false;
// Gate is a capturable objective (vs destructible obstacle)
```

### Siege States & Gate Behavior

| Siege State | Gate Behavior |
|-------------|---------------|
| **No Siege** (`CurrentSiegeId = null`) | Normal operation - players can open/close with permissions |
| **Siege Preparing** | Gates auto-close, lock (players cannot open), `CurrentSiegeId` set |
| **Siege Active** | Gates function per configuration (see below) |
| **Siege Victory** | Winning team gains gate control (permissions granted) |
| **Siege Cleanup** | `CurrentSiegeId = null`, gates unlock, return to normal |

### Gate Configurations During Siege

#### Configuration A: Gate as Objective (`IsSiegeObjective = true`)

**Behavior:**
- Gate is capturable (like capture point)
- Attackers gain points for opening gate
- Defenders try to keep gate closed
- Health damage affects captureability

**Animation:**
- `AnimateDuringSiege = true`: Normal animation (60 ticks, realistic)
- `AnimateDuringSiege = false`: Instant state change (arcade-style)

**Capture Mechanics:**
1. Attackers must stand near gate for X seconds
2. Capture progress bar displayed
3. On capture complete → gate opens
4. Award points to attacking team
5. Defenders can recapture by standing near gate

#### Configuration B: Gate as Obstacle (`IsSiegeObjective = false`)

**Behavior:**
- Gate must be destroyed or bypassed
- `IsInvincible` automatically set to false during siege
- Attackers damage gate to 0 HP → gate destroyed → blocks removed
- `CanRespawn` ignored during siege (gate stays destroyed)

**Destruction Rewards:**
- Award points to attacking team
- Broadcast event to all participants
- Spawn guard NPCs (if configured)

### Damage Rules During Siege

**Invincibility Override:**
```java
boolean canDamage(Player player, Gate gate) {
    if (gate.CurrentSiegeId != null) {
        // During siege, ignore IsInvincible setting
        return player.hasPermission("knk.siege.attack.gate");
    }
    return !gate.IsInvincible && player.hasPermission("knk.gate.damage");
}
```

**Damage Multipliers (Team-Based):**
```java
double damageMultiplier = 1.0;

if (gate.CurrentSiegeId != null) {
    SiegeTeam playerTeam = siege.getPlayerTeam(player);
    SiegeTeam gateOwnerTeam = siege.getDefendingTeam();
    
    if (playerTeam == SiegeTeam.ATTACKER) {
        damageMultiplier = 1.0;  // Normal damage
    } else if (playerTeam == SiegeTeam.DEFENDER) {
        damageMultiplier = 0.5;  // Friendly fire penalty
    } else {
        damageMultiplier = 0.0;  // Spectators cannot damage
    }
}

gate.removeHealth(baseDamage * damageMultiplier);
```

### Override System

**Purpose**: Admin emergency control (stuck gate, event scripting, bug recovery)

**Fields:**
- `IsOverridable`: Master toggle (default true)
- Runtime state: `overridden` (boolean, transient - not persisted)

**Override Commands:**
```
/gate admin override <name> <on|off>     - Toggle override state
/siege gate override <name> <open|close> - Force gate state during siege
```

**Override Behavior:**
```java
if (gate.overridden) {
    // Bypass all normal checks
    // Animation still plays (unless AnimateDuringSiege = false)
    // Permissions ignored
    // Pass-through disabled
    // State change forced by admin command only
}
```

**Auto-Clear Conditions:**
- Siege ends → clear override
- Admin executes `/gate admin override <name> off`
- Gate destroyed → clear override (no effect when destroyed)

### Pass-Through Disabled During Siege

**Reason**: Security - prevent friendly players from accidentally opening gates during siege

**Implementation:**
```java
boolean canPassThrough(Player player, Gate gate) {
    if (gate.CurrentSiegeId != null) {
        return false;  // Disabled during siege
    }
    return gate.AllowPassThrough && evaluateConditions(player, gate);
}
```

### API Endpoints

**Link Gate to Siege:**
```
PUT /api/gates/{id}/siege
{
  "currentSiegeId": 42,
  "isSiegeObjective": true,
  "animateDuringSiege": true
}
```

**Unlink Gate from Siege:**
```
DELETE /api/gates/{id}/siege
```

**Get Gates by Siege:**
```
GET /api/sieges/{siegeId}/gates

Response:
[
  {
    "id": 1,
    "name": "Main Gate",
    "isSiegeObjective": true,
    "healthCurrent": 320,
    "healthMax": 500,
    "isOpened": false,
    "isDestroyed": false
  },
  ...
]
```

### Web App UI (Siege Configuration)

**Siege Editor - Gate Assignment:**
- Table: Available gates in domain
  - Columns: Gate Name | Type | Health | Objective? | Animate?
  - Checkbox: "Siege Objective" (vs obstacle)
  - Checkbox: "Animate During Siege"
  - Button: "Add to Siege"
- Drag-and-drop to reorder gates (strategic sequence)

**Live Siege Monitor:**
- Gate status cards:
  - Gate name
  - Health bar (color-coded)
  - Status: OPEN/CLOSED/DESTROYED
  - Capture progress (if objective)
  - Last damage timestamp
- Button: "Override Gate" → modal with force open/close/repair

---

## Feature 5: Continuous Damage System

### Business Requirements

**Goal**: Apply damage over time from fire-based weapons, balancing instant vs sustained attacks.

**User Stories:**
- As an **attacker**, I want to use fire-based weapons to damage gates over time
- As a **defender**, I want time to respond to fire attacks (extinguish, repair, defend)
- As a **game designer**, I want different damage mechanics for different weapon types

### Entity Fields (GateStructure)

```csharp
public bool AllowContinuousDamage { get; set; } = true;
// Enable/disable continuous damage feature

public double ContinuousDamageMultiplier { get; set; } = 1.0;
// Scaling factor for continuous damage sources

public int ContinuousDamageDurationSeconds { get; set; } = 5;
// How long continuous damage persists per application
```

### Damage Sources

| Source | Base Damage | Duration | Visual Effect |
|--------|-------------|----------|---------------|
| Flint & Steel | 0.5 HP/sec | 5 sec | Blocks ignite |
| Fire Aspect I | 1.0 HP/sec | 5 sec | Blocks ignite |
| Fire Aspect II | 1.5 HP/sec | 5 sec | Blocks ignite + smoke |
| Lava Bucket | 2.0 HP/sec | 10 sec | Lava pools on blocks |
| Fire Charge | 1.0 HP/sec | 5 sec | Fireball impact particles |

### Mechanics

**Damage Calculation:**
```java
double damagePerSecond = baseDamage * gate.ContinuousDamageMultiplier;
int duration = gate.ContinuousDamageDurationSeconds;
double totalDamage = damagePerSecond * duration;

// Example: Fire Aspect II (base 1.5 HP/sec) * 1.0 multiplier * 5 seconds = 7.5 HP total
```

**Stacking Rules:**
- Multiple applications **extend duration** (do not stack damage rate)
- Example:
  - Player hits gate with Fire Aspect sword → 5 second timer starts
  - 2 seconds later, player hits again → timer resets to 5 seconds (not 7)
  - Total duration: 5 seconds (not cumulative)
  - Total damage: 1.0 HP/sec * 5 sec = 5.0 HP

**Visual Effects:**
1. **Ignite Blocks**: Set random gate blocks on fire (cosmetic)
   - 3-5 blocks per application
   - Fire spreads to adjacent gate blocks (does not damage nearby structures)
   - Fire extinguishes when continuous damage expires

2. **Particles**: Smoke particles every tick
   - `ParticleEffect.SMOKE_LARGE` at ignited block positions
   - Visible to players within 32 blocks

3. **Sound**: Crackling fire sound every 2 seconds
   - `Sound.BLOCK_FIRE_AMBIENT` at gate center

### Implementation (Plugin - ContinuousGateDamage Class)

```java
public class ContinuousGateDamage {
    private Gate gate;
    private Block hitBlock;           // Block that was hit (for visual effects)
    private double damagePerSecond;
    private int durationSeconds;
    private long expiryTime;
    private List<Block> ignitedBlocks = new ArrayList<>();
    
    public ContinuousGateDamage(Gate gate, Block hitBlock, double baseDamage, int duration) {
        this.gate = gate;
        this.hitBlock = hitBlock;
        this.damagePerSecond = baseDamage * gate.getContinuousDamageMultiplier();
        this.durationSeconds = duration;
        this.expiryTime = System.currentTimeMillis() + (duration * 1000);
        
        igniteBlocks();
    }
    
    public void tick() {
        long now = System.currentTimeMillis();
        
        if (now > expiryTime) {
            extinguish();
            gate.removeContinuousGateDamage(this);
            return;
        }
        
        // Apply damage every 20 ticks (1 second)
        if (tickCounter % 20 == 0) {
            gate.removeHealth(damagePerSecond);
            spawnParticles();
        }
        
        // Play sound every 40 ticks (2 seconds)
        if (tickCounter % 40 == 0) {
            playFireSound();
        }
    }
    
    public void extend() {
        // Called when gate is hit again - reset timer
        expiryTime = System.currentTimeMillis() + (durationSeconds * 1000);
    }
    
    private void igniteBlocks() {
        // Find 3-5 random gate blocks and set on fire
        List<Block> gateBlocks = getGateBlocks();
        Collections.shuffle(gateBlocks);
        
        for (int i = 0; i < Math.min(5, gateBlocks.size()); i++) {
            Block block = gateBlocks.get(i);
            block.setType(Material.FIRE);  // Cosmetic fire on top
            ignitedBlocks.add(block);
        }
    }
    
    private void extinguish() {
        for (Block block : ignitedBlocks) {
            if (block.getType() == Material.FIRE) {
                block.setType(Material.AIR);
            }
        }
    }
    
    private void spawnParticles() {
        for (Block block : ignitedBlocks) {
            block.getWorld().spawnParticle(
                Particle.SMOKE_LARGE,
                block.getLocation().add(0.5, 0.5, 0.5),
                3, 0.2, 0.2, 0.2, 0.01
            );
        }
    }
    
    private void playFireSound() {
        gate.getLocation().getWorld().playSound(
            gate.getGateCenter(),
            Sound.BLOCK_FIRE_AMBIENT,
            1.0f, 1.0f
        );
    }
}
```

### Gate Entity Changes

**Add to Gate class:**
```java
private List<ContinuousGateDamage> continuousDamageList = new ArrayList<>();

public void addContinuousGateDamage(ContinuousGateDamage damage) {
    // Check if damage already exists for this block
    ContinuousGateDamage existing = getContinuousDamage(damage.getHitBlock());
    
    if (existing != null) {
        existing.extend();  // Extend duration instead of adding new
    } else {
        continuousDamageList.add(damage);
    }
}

public ContinuousGateDamage getContinuousDamage(Block block) {
    return continuousDamageList.stream()
        .filter(d -> d.getHitBlock().equals(block))
        .findFirst()
        .orElse(null);
}

public void removeContinuousGateDamage(ContinuousGateDamage damage) {
    continuousDamageList.remove(damage);
}
```

### Event Handlers

**On Player Damage Gate:**
```java
@EventHandler
public void onGateDamage(EntityDamageByEntityEvent event) {
    if (!(event.getDamager() instanceof Player)) return;
    
    Player player = (Player) event.getDamager();
    Gate gate = getGateAtLocation(event.getEntity().getLocation());
    if (gate == null) return;
    
    ItemStack weapon = player.getInventory().getItemInMainHand();
    
    // Check for fire-based damage
    if (weapon.getType() == Material.FLINT_AND_STEEL) {
        applyContinuousDamage(gate, player, 0.5, 5);
    } else if (weapon.containsEnchantment(Enchantment.FIRE_ASPECT)) {
        int level = weapon.getEnchantmentLevel(Enchantment.FIRE_ASPECT);
        double baseDamage = 0.5 + (0.5 * level);  // 1.0 for FA I, 1.5 for FA II
        applyContinuousDamage(gate, player, baseDamage, 5);
    }
}

private void applyContinuousDamage(Gate gate, Player player, double baseDamage, int duration) {
    if (!gate.getAllowContinuousDamage()) return;
    
    Block hitBlock = player.getTargetBlock(null, 5);
    ContinuousGateDamage damage = new ContinuousGateDamage(
        gate, hitBlock, baseDamage, duration
    );
    
    gate.addContinuousGateDamage(damage);
}
```

### Balance Considerations

**Why Separate System?**
- Different behavior from instant damage (duration, stacking, visuals)
- Clean separation of concerns (instant vs damage-over-time)
- Allows separate configuration (multiplier, duration)
- Future extensions: Fire resistance materials, extinguish mechanics

**Balancing Factors:**
- Total damage lower than instant damage weapons
- Defenders have time to respond (repair, extinguish, defend)
- Visual feedback alerts defenders to attack
- Stacking duration (not damage) prevents abuse

**Counter-Mechanics (Future):**
- Water bucket to extinguish fires (halves remaining damage)
- Fire-resistant materials (stone, obsidian) reduce continuous damage by 50%
- Defender repair kits restore health faster than continuous damage

### API Endpoints

**Update Continuous Damage Settings:**
```
PUT /api/gates/{id}/continuous-damage
{
  "allowContinuousDamage": true,
  "continuousDamageMultiplier": 1.5,
  "continuousDamageDurationSeconds": 8
}
```

### Web App UI

**Continuous Damage Panel:**
- Toggle: "Allow Continuous Damage"
- Slider: "Damage Multiplier" (0.5 - 2.0)
- Number input: "Duration (seconds)" (1-30)
- Info text: "Base damage varies by weapon. Multiplier scales all sources."
- Table: Weapon damage preview
  - Weapon | Base Damage | Modified Damage | Total Damage
  - Flint & Steel | 0.5 HP/sec | 0.75 HP/sec | 6.0 HP
  - Fire Aspect I | 1.0 HP/sec | 1.5 HP/sec | 12.0 HP
  - Fire Aspect II | 1.5 HP/sec | 2.25 HP/sec | 18.0 HP

---

## Implementation Priority

| Feature | Priority | Phase | Dependencies |
|---------|----------|-------|--------------|
| Health Display | HIGH | Phase 1 (current) | Base animation system |
| Siege Integration | HIGH | Phase 1 (current) | Siege minigame system |
| Continuous Damage | HIGH | Phase 1 (current) | Base health system |
| Pass-Through | MEDIUM | Phase 2 | Permissions system, player stats |
| Guard Spawn | LOW | Phase 3 | NPC system (future) |

**Phase 1 (Current Sprint)**:
- Health Display System
- Siege Integration
- Continuous Damage System

**Phase 2 (Next Sprint)**:
- Pass-Through System (requires player stats/ethics/clan systems)
- Advanced permissions conditions

**Phase 3 (Future)**:
- Guard Spawn System (requires full NPC framework)

---

## Testing Scenarios

### Pass-Through Testing
- Player with correct permissions approaches gate → auto-opens
- Player without permissions approaches gate → no action
- Player passes through → gate auto-closes after timer
- Multiple players trigger pass-through → timer extends correctly
- Siege starts → pass-through disabled

### Health Display Testing
- Mode ALWAYS → display always visible
- Mode DAMAGED_ONLY → display appears when damaged, disappears when repaired
- Mode SIEGE_ONLY → display appears during siege, hidden otherwise
- Mode NEVER → no display visible, health only via command
- Display updates correctly on health change

### Siege Integration Testing
- Siege starts → gates lock, auto-close
- Gate as objective → capture mechanics work
- Gate as obstacle → destruction mechanics work
- Override command → admin can force open/close
- Siege ends → gates unlock, return to normal

### Continuous Damage Testing
- Fire Aspect weapon hits gate → continuous damage applied
- Damage continues for configured duration
- Multiple hits extend duration (don't stack damage)
- Visual effects (fire, smoke, sound) display correctly
- Continuous damage respects multiplier setting

---

**End of Advanced Features Requirements Document**
