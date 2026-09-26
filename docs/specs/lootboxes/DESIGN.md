# Lootboxes — Design

**Status:** Partly decided — awaiting answers on spawn-area definition, daily cap and ItemInstance (see §5 resolved block)
**Last updated:** 2026-09-26
**Linear:** [KNG-19](https://linear.app/kngpandi/issue/KNG-19/lootboxes-per-category-world-lootboxes-with-grade-weighted-rolls-v1)
**Sources:** `knk-v1-archive` (single commit `4117e7e`): `src/Products/{Product,SpecialItemEvents,Enchantment}.java`,
`src/Treasure/*`, `src/Main/Main.java`, `src/KillsDeaths/KillDeathStat.java`, `src/Minigames/{BanditAmbushes,OcelotSpawn}.java`,
`src/Votes/VoteEvent.java`, `src/Users/{Users,offlineUser}.java`, `src/Handlers/ColorOptions.java`; `knk-v2-archive` (`main` + all
branches, `git grep`); knk-web-api / knk-plugin / knk-web-app at `claude/intelligent-newton-73pcsl` (trunk + siege merged);
docs `specs/legacy/{items,events-v1,commands-v1}.md`, `specs/items/{GRADE_DROPCHANCE,V1_SEED_DATA}.md`, `specs/kits/DESIGN.md`,
`vision/vision.md` §9.1, `vision/source-notes-iphone.md`; Linear KNG-15.

---

## 0. Scope

**In:**
- Lootboxes that spawn in the world inside admin-defined areas. There is **one lootbox type per ItemBlueprint `Category` row**. Each box
  has a **box grade** (its rarity), and it produces an item whose **item grade** is drawn with weights from `Grade.DropChance`.
- A server-authoritative roll (API side): the item, its grade and its rolled enchantments are decided once and logged. A box can be
  claimed once, the claim is idempotent, and delivery survives a crash.
- A "special" jackpot tier for hand-designed items. The candidates are the recovered v1 one-offs, already seeded as ItemBlueprints
  (§1.4, §3.5).
- Admin configuration in the web app: per-category box config, box-grade weights, the item pool, enchant rolls, spawn areas, an
  odds preview and the drop log. It also covers in-game admin commands, rare-drop announcements, anti-exploit rules and observability.

**Out (explicitly):**
- Soulbound / Ghosted flags on rolled items. v1's boxes set them, but v3 has no instance state for them yet (`vision.md` §9.1
  `ItemInstance`). They are recorded in §1 so they can be ported later.
- `ItemInstance` persistence. Delivered items carry a PDC claim id (§3.4) until `ItemInstance` exists.
- Coin/gem/XP rewards from boxes. v1's treasure chests gave gold and diamond *items*, not currency. If currency rewards are added
  later, they go through `UserService.AdjustBalancesAsync` (`knk-web-api:Services/UserService.cs:618`) with `reason="Lootbox"` and
  `metadata={claimId}`, and they adopt the `docs/specs/currency-payments/` ledger/idempotency design once that lands.
- Placed "treasure chests" (v1 `/treasure`) as a separate feature. §1.1 records them because they are the v1 precedent for
  world-placed loot and box grades. A fixed-location spawn area (§3.3) covers the use case.
- Lootbox **items** (v1's "Sword Box" consumables): optional Phase 5, and see Q5.

---

## 1. Legacy design

### 1.1 v1: what actually existed (verified in source)

The "sword boxes" were **inventory items, not world objects**. Nothing in v1 spawns a box in the world. v1 has three world-spawned
loot mechanics, and the developer's memory most likely merges them with the sword boxes:

| Mechanic | What it was | Source |
|---|---|---|
| **Sword boxes** | Two consumable items, products `legendaryswordbox` / `rareswordbox`. Right-click to consume and receive a randomly enchanted sword. | `Products/SpecialItemEvents.java:24-70`, `Product.java:1966-2175` |
| **Treasure chests** | Admin-placed chests with a grade of 1-5. Each player can open each chest once and gets a random-loot inventory. | `Treasure/*.java` |
| **Loot ocelots** | Every 10 min, with ≥3 players online, an ocelot spawns at every spawnpoint whose name contains `ocelot`. A kill pays coins/XP and drops a random product. | `Main.java:1342-1370`, `KillDeathStat.java:237-285` |
| **Random product drops** | `getRandomProduct()` picks from *every* active product category. Sword boxes were products, so they could drop from treasure, ocelots, bandits and votes if their category was active (the `Products` table is lost, so this can't be confirmed). | `Product.java:1832-1941`, `VoteEvent.java:145-155` |

**How sword boxes reached players (the explicit paths):** donator rank grants in `Users.setDonator`. Noble → 2× `rareswordbox`,
Royal → 1× `legendaryswordbox`, Dragonblood → 2× `legendaryswordbox` (`Users/Users.java:167-180`, duplicated at
`Users/offlineUser.java:3300-3312`). Delivery used `Product.giveProduct` (`Product.java:2177-2224`: inventory → ender chest (buggy:
it calls `getInventory().addItem`) → scheduled give). The vision notes also want boxes as PvP-kill loot and as a referral reward
(`vision/source-notes-iphone.md:47,94`; "lucky chests" at :43, "30/40 treasure chests in de map" at :83).

#### Sword box click handler (`SpecialItemEvents.onInteract`, `:24-70`)
- `RIGHT_CLICK_AIR|RIGHT_CLICK_BLOCK` with a held item whose **colour-stripped display name** equals (ignoring case)
  `"legendary sword box"` / `"rare sword box"`. The event is cancelled.
- `player.getInventory().addItem(product.getLegendarySwordBox())` runs **before** the box is removed from the hand. The hand stack is
  then decremented.
- Messages: `ChatColor.LIGHT_PURPLE + "You received a Legendary Random Sword!"` / `ChatColor.BLUE + "You received a Random Sword!"`.
  There is no broadcast, no log and no permission check.

#### Legendary Sword Box roll (`Product.getLegendarySwordBox`, `:1966-2073`)
Every roll is independent. `random.nextInt(100) <= X` is really **(X+1)%**, and `main.getRandom(0,100) <= X` is **(X+1)/101**
(`Main.java:958-973`, inclusive bounds). Vanilla levels are added with `addUnsafeEnchantment`, and the Bukkit 1.8 max for
`DAMAGE_ALL` is 5.

| Step | Effective chance | Result |
|---|---|---|
| Base item | 69.3% / **30.7%** (`getRandom(0,100) <= 30`) | `diamondsword` / **`golemheartsword`** |
| Sharpness | 91% | level `1 + (int)(rand*6)` = **1-6** |
| | else 9% | **4** |
| Knockback | 66% | `1 + (int)(rand*7)` = **1-7** (copy-paste: uses `DAMAGE_ALL.getMaxLevel()+1+1`) |
| Fire Aspect | 51% | **1-7** (same bug) |
| Unbreaking | 46% | **1-7** (same bug) |
| Custom block A | 29% | poison 41%→I else II, then 46% +III · blindness 46%→I else II, then 51% +III · confusion 51%→I else II, then 56% +III |
| Custom block B | 21% | poison: 31% I, else-if 46% II, else-if 41% III |
| Custom block C | 26% | blindness: 41% +I; 56% +II; 51% +III (independent) |
| Custom block D | 31% | confusion: 46% +I; 61% +II; 56% +III (independent) |
| Chaos | 6% | `chaos` I |
| **Ghosted** | 46% | `GhostItem` (lore `§8Ghosted`) |
| Floor | if Sharpness ≤ 2 | re-set to `1 + (int)(rand*6 + 1.0)` = **2-7** |

#### Rare Sword Box roll (`Product.getRareSwordBox`, `:2075-2175`)

| Step | Effective chance | Result |
|---|---|---|
| Base item | `r = getRandom(0,100)`: r≤5 **5.9%** / r≤30 24.8% / else 69.3% | **`golemheartsword`** / `diamondsword` / `bladedsteelsword` |
| Sharpness | 91% | `1 + (int)(rand*5)` = **1-5** |
| | else 9% | **3** |
| Knockback / Fire Aspect / Unbreaking | 66% / 51% / 46% | **1-6** each |
| Custom block A | 19% | poison 51%→I else II, 41% +III · blindness 56%→I else II, 46% +III · confusion 61%→I else II, 51% +III |
| Custom block B | 11% | poison: 41% I, else-if 40% II, else-if 39% III |
| Custom block C | 19% | blindness: 51% I, else-if 52% II, else-if 50% III |
| Custom block D | 23% | confusion: 56% I, else-if 55% II, else-if 54% III |
| Armor repair | 6% | `armorrepair` I |
| **Soulbound** | 46% | `SoulboundItem` (lore `§cSoulbound`) |
| Floor | if Sharpness ≤ 2 | re-roll `1 + (int)(rand*5)` = 1-5 (can stay ≤ 2) |

**Custom enchant stacking** (`Product.addCustomEnchantment`, `:1646-1731`): custom enchants are lore lines `§7<key> <roman>`. Adding
an enchant that is already on the item concatenates roman strings. `"I"+"I"="II"` becomes 2 (or 1 if the max is 1). `"III"` or longer
becomes the enchant's **max level**. So "I then +III" gives the max (3), not 4. Every custom level above 3 is therefore clamped.
v3's `EnchantmentRegistry` maxima (`knk-core:.../domain/enchantment/EnchantmentRegistry.java:18-29`) are poison/blindness/confusion 3,
chaos 1 and armor_repair 1.

**Sword items used** (recovered in `specs/items/V1_SEED_DATA.md` §3, seeded by `ItemBlueprintV1Seed`):
`Golemheart Sword` (diamond_sword, `&aGolemheart Sword`, ★5), `Diamond Sword` (`&bDiamond Sword`, ★4, *not in the dev DB*, which has
the hand-made id 21 `Diamond Sword\n` instead), `Bladed Steel Sword` (iron_sword, `&bBladed Steel Sword`, ★4). The 14 Golemheart Swords
found in playerdata carry 13 different enchant sets, which fits these rolls.

#### Treasure chests (`Treasure/*`), the v1 box-grade precedent
- `/treasure create <1-5>` (perm `k&k.treasure`), then right-click a CHEST. This stores a `Treasure(Grade, SpawnpointID)` row and a
  spawnpoint named `treasure_<id>` (`Treasures.java:27-66`). The `remove`, `info` and `list` subcommands are stubs
  (`TreasureCommands.java:101-117`).
- **Box grade names/colours** (`Treasures.getTreasureName`, `:305-324`): 1-2 `§9Default Treasure`, 3-4 `§bRare Treasure`,
  5 `§dLegendary Treasure`, each followed by `★`×grade (`ColorOptions.stars`, `:162-172`).
- **Items per open** (`getRewardAmount`, `:284-303`): 1 + `getRandom` of 1-2 / 1-3 / 2-5 / 4-7 / 6-12 for grades 1-5. Items go into
  random slots of a 27-slot virtual inventory titled with the chest name. A slot that is already taken is silently skipped, so
  **fewer items than rolled**.
- Per slot: 61/101 `getRandomProduct(null,null)`, else one of gold nugget 16-48, gold ingot 8-32, gold block 8-28, diamond 8-18
  or diamond block 8-12 (`Treasure.java:267-299`).
- Once per player, via the `TreasureDiscovered(UserID, TreasureID)` table. The list is saved only every **300 s** and on shutdown, by
  delete-all then insert (`Main.java:1258-1263`, `Treasure.java:167-202`). **Exploit:** a crash inside that window lets a player
  loot again.
- Ambience (`Main.java:1264-1275`, every 4 s): gold-block `BLOCK_CRACK` particles (8 particles, radius 1) and `LEVEL_UP` at volume
  0.1 with random pitch. Both are sent only to players within 15 blocks who haven't opened it yet (`Treasure.java:49-53, 232-265`).
- A right-click on a chest that isn't a treasure falls through silently (`TreasureEvents.java:89-92`).

#### `getRandomProduct` (the world-loot roll, `Product.java:1832-1941`)
It picks a random non-empty category (or the given one), shuffles its products, and takes the **first** product that passes
`getRandom(0,100) <= getdropChance(grade)`, with a uniform fallback. **This path uses `drop1..drop5 = 80/70/60/10/1`**
(`Product.java:41-45, 1943-1964`), not `gradeChance()`'s 70/60/40/5/1 (`:1801-1830`). `gradeChance()` is used only by vote rewards
(`VoteEvent.java:145-155`) and a test command (`me/Pandi/Commands.java:650-661`). The first-success-in-shuffled-order algorithm makes
the real odds depend on how many products each grade has. For non-food, non-resource categories the stack amount is 1, with a 6/10001
chance of 2.

#### Loot ocelots
- `startOcelotTask` (`Main.java:1342-1370`, period 600 s): if ≥3 players are online, it broadcasts `"Loot-ocelots have spawned in all
  towns!"`, spawns one ocelot per `*ocelot*` spawnpoint, plays `CAT_MEOW` to everyone, then broadcasts `"A total of <n> have spawned.
  Kill them to earn money, exp and other bonusses!"`.
- **No cap and no despawn**: ocelots pile up every 10 min. `OcelotSpawn` force-uncancels ocelot spawns (`Minigames/OcelotSpawn.java:19-26`).
- A kill (`KillDeathStat.java:237-285`) gives XP `getExpPart(12)`, 1000-12000 coins, a `getRandomProduct` drop, then 2/101 a skill
  point, else 6/101 gems 20-200 ×multiplier, else 16/101 gems 2-50 ×multiplier.

#### Other v1 golemheart sources
Bandit ambush drops: `random.nextInt(10000) <= 5` (6/10000) `golemheartsword` (`BanditAmbushes.java:157-160`).

### 1.2 Known v1 bugs and exploits (don't port)
1. **Rename exploit.** A box is identified only by its colour-stripped display name (`SpecialItemEvents.java:37-38`). Renaming any item
   to "Rare Sword Box" in an anvil makes it a box that yields a free sword.
2. **Full inventory loses the sword.** `addItem` runs while the box still occupies its slot, and the leftovers `addItem` returns are
   ignored. The box is consumed anyway (`:41-50`).
3. Knockback, Fire Aspect and Unbreaking levels come from `DAMAGE_ALL.getMaxLevel()`, which is a copy-paste bug, giving 1-7
   (legendary) and 1-6 (rare). Custom-enchant levels accumulate through roman-string concatenation (see above).
4. Treasure: re-loot after a crash (300 s save window). Items are lost to slot collisions. Items the player doesn't take are lost
   when the inventory closes. `/treasure remove` does nothing. `removeTreasure` calls `setInt(3, …)` on a one-parameter statement
   (`Treasures.java:105-106`).
5. Ocelots accumulate without a cap. Every reward is chat-only, with no log.

### 1.3 v2
There is nothing similar. `git grep -iE 'lootbox|crate|treasure|swordbox|lucky|mystery'` finds no match on `main` or
`claude/intelligent-newton-73pcsl`. No commit message mentions loot, crates or boxes, and there is no drop-chance concept at all
(`specs/legacy/items.md:142` agrees). The only "rewards" are minigame win payouts (`MGScenario.java:66-68,129-136`).

### 1.4 "Ultra-rare special hardcoded items": not found in v1 source
I searched v1 for hardcoded named items (display names, lore literals, `addUnsafeEnchantment`/`addCustomEnchantment` call sites, and
`legendary|mythic|unique|ultra|relic|artifact|excalibur`). The only hardcoded item references are product *keys*
(`golemheartsword`, `diamondsword`, `bladedsteelsword`, `rareswordbox`, `legendaryswordbox`, `beginnersword`, …). The item
definitions lived in the lost `Products` table. `bin/` holds no class files.

The hand-designed one-offs survive only in v1 **playerdata**, recovered verbatim in `V1_SEED_DATA.md` §3 and already seeded as
ItemBlueprints tagged `Legacy v1`. They are the proposed special pool (§3.5):

| Name | Material | DefaultDisplayName | Cat. | ★ | Enchantments (seeded) | Copies |
|---|---|---|---|---|---|---|
| Skull splitter | iron_sword | `&9Skull splitter` | Weapons | 5 | sharpness 4, health_boost 1 *(custom)* | 1 |
| Lavonian Bow | bow | `&aLavonian Bow` | Weapons | 5 | infinity 1, power 6, unbreaking 6 | 3 |
| Golemheart Helmet | diamond_helmet | `&aGolemheart Helmet` | Armor | 5 | aqua_affinity 1, protection 6, respiration 3, unbreaking 6, health_boost 1 *(custom)* | 1 |
| Halloween Armor Boots | iron_boots | `&5Halloween armor` | Armor | — | protection 3 | 1 |
| Halloween Armor Leggings | iron_leggings | `&5Halloween armor` | Armor | — | protection 3 | 1 |
| Pickaxe of Good Health | diamond_pickaxe | `&aPickaxe of Good Health` | Tools | — | sharpness 5, armor_repair 1, health_boost 1 *(custom)* | 1 |
| Poison Pickaxe | diamond_pickaxe | `&5Poison Pickaxe` | Tools | — | sharpness 5, poison 2 *(custom)* | 1 |
| Wither Pickaxe | diamond_pickaxe | `&0Wither Pickaxe` | Tools | — | sharpness 5, wither 2 *(custom)* | 1 |
| Blindness Pickaxe | diamond_pickaxe | `&8Blindness Pickaxe` | Tools | — | sharpness 5, blindness 2 *(custom)* | 1 |
| Donator pickaxe | diamond_pickaxe | `&2Donator pickaxe` | Tools | — | efficiency 2, unbreaking 2 | 1 |

None of these has lore text (`DefaultDisplayDescription` is empty for every seeded item) or code-defined abilities beyond its custom
enchantments. **The developer should confirm or name any others (Q1).**

### 1.5 v3 today
There is **no lootbox code in any v3 repo** (`grep -ri lootbox`). These parts are reusable:

| Area | What exists | Path |
|---|---|---|
| Item catalog | `ItemBlueprint` (single `CategoryId`, `GradeId`, `DefaultEnchantments`, `Tags`, `Origins`) | `knk-web-api:Models/Item/ItemBlueprint.cs` |
| Categories | **A table, not an enum**: `Category(Id, Name, IconMaterialRefId, ParentCategoryId, ChildCategories, Tags)`, hierarchical. Seeded rows: **Weapons, Armor, Food** (`KitSeed.cs:40-45`), **Tools, Resources, Trinkets** (`ItemBlueprintV1Seed.cs:38-46`), **Enchantment Books** (`EnchantBookSeed.cs:24`). The 18 `ItemBlueprintExampleCatalogSeed` "trade goods" have no category. The dev DB may hold more categories authored in the web app. | `Models/Category.cs` |
| Grades | 10 rows, `DropChance` (decimal(7,4) %) and `EnchantLevelCapDivisor`: ★1 70 /5, ★2 60 /4, ★3 40 /3, ★4 25 /2, ★5 15 /1, ★6 8, ★7 5, ★8 1, ★9 0.5, ★10 0.05 (6-10 uncapped). **DropChance is stored but nothing rolls it yet.** | `Models/Item/Grade.cs`, `GradeDefaults.cs`, `specs/items/GRADE_DROPCHANCE.md` |
| Enchantments | `EnchantmentDefinition(Key, IsCustom, MaxLevel, BaseEnchantmentRef)` with 12 custom definitions seeded by `AbilityDefinition.SeedCanonicalAsync`. The vanilla catalog JSON has a `category` (Weapon/Armor/…). | `Models/Item/EnchantmentDefinition.cs`, `Data/minecraft_enchantment_catalog.json` |
| Blueprint → ItemStack | `ItemBlueprintBukkitMapper.fromBlueprint` sets name, lore, grade star line, origin and PDC `knightsandkings:knk_grade`, but **no enchantments**. Enchantment application exists only inside `ItemBlueprintsDebugCommand.give` (`:233-293`: vanilla via `addUnsafeEnchantment`, custom via `EnchantmentRepository.applyEnchantment` lore, then lore reorder). Kits and the menu catalog therefore hand out unenchanted items (`KitGrantPlacer.java:48-52`, ACTIVE_SESSIONS CP row). | `knk-paper:mapper/ItemBlueprintBukkitMapper.java`, `commands/ItemBlueprintsDebugCommand.java` |
| Grade cap | `KnkGrade.capEnchantLevel`, `GradeCatalog` (a live grade table refreshed every 10 min) | `knk-core:domain/item/` |
| Grant placement | `KitGrantPlacer`: equipment slots → free slot → `dropItemNaturally`. The developer chose "drop rather than lose". | `knk-paper:kit/KitGrantPlacer.java`, `specs/kits/DESIGN.md` §6 |
| Kits give (KNG-15) | `POST /api/Kits/{id}/give` is the **only** `[Authorize]` game endpoint (`KitsController.cs:160`). The plugin sends no `Authorization` header because `config.yml` has `api.auth.type: none` → 401. `ApiKeyAuthProvider` exists in the client, but the API has no API-key scheme (`Program.cs:65-83` is JWT only). **So the plugin has no service identity today, and every other endpoint is anonymous.** | KNG-15; `knk-api-client:api/auth/*`; `KnKPlugin.java:1190-1205` |
| Timed world drops | `EnchantDropPlanner` (Bukkit-free chance/cap/uniform-disc planner). `SiegeEnchantBooks` (items with a PDC token and `setPersistent(false)`, cleared at match end). `SiegeWorldPresenter` (`TextDisplay` labels with a PDC token, plus a crash-recovery block log). **Only on `claude/siege-minigame`**, not on plugin `main`. | `knk-core:siege/EnchantDropPlanner.java`, `knk-paper:siege/*` |
| Regions | `WorldGuardRegionLookup.at(Location)`, `WorldGuardIntegration.regionExists`, the `WgRegionIdTaskHandler` world task (define a region from the web app), `Domain.WgRegionId` (Town/District) | `knk-paper:regions/`, `integration/`, `tasks/` |
| API → plugin messages | `PlayerNotificationPoller` (2 s poll, queue held for offline players) | `knk-paper:tasks/PlayerNotificationPoller.java` |
| Singleton config pattern | `SiegeConfiguration`, `SalaryConfiguration` + `/admin/siege-configuration` page | web-api `Models/Siege`, web-app `pages/admin/SiegeConfigurationPage.tsx` |
| Audit | `AuditLogEntry` + `AuditAction` (0-11, `KitGranted = 11`) | `Models/AuditLogEntry.cs`, `Enums/AuditAction.cs` |
| Permissions | `KnkPermissible` resolves `knk.<feature>.<action>` against the REST model and fails closed. Player-facing commands follow the `/kit` and `/siege` pattern (`plugin.yml:74-91`). | `knk-paper:permissions/KnkPermissible.java` |

---

## 2. Gap analysis

| Capability | v1/v2 behaviour | v3 today | Reusable v3 component (path) | Work |
|---|---|---|---|---|
| Box definition per category | 2 hardcoded box items (swords only) | none | `Category`, `ItemBlueprint` | M (new entities) |
| Box rarity (box grade) | Rare/Legendary box items; treasure grade 1-5 with names/colours | none | `Grade` (10 rows, `DropChance`) | S |
| Item-grade roll | per-grade drop tables 80/70/60/10/1 (world loot) and 70/60/40/5/1 (votes), with a count-biased algorithm | `DropChance` stored, unused | `Grade.DropChance`, `GradeCatalog` | M (roll engine) |
| Enchant roll | hardcoded chains (§1.1) | none | `EnchantmentDefinition`, `KnkGrade.capEnchantLevel` formula | M |
| Special items | none hardcoded; one-offs exist in playerdata | seeded as `Legacy v1` blueprints | `ItemBlueprintV1Seed` rows, `Tag` | S |
| World spawning | treasure (manual), ocelots (10 min, ≥3 online, no cap) | none | `EnchantDropPlanner` pattern, WG lookup (siege branch) | L |
| Physical box + tracking | chest block / held item, matched by display name | none | display entities with a PDC token (`SiegeWorldPresenter`) | M |
| Claim once / idempotent | per-player list saved every 5 min; box consumed before the grant is checked | none | `KitClaim` append-only pattern | M |
| Delivery + full inventory | lost (box) / scheduled give (products) | Kits drop on the ground | `KitGrantPlacer`, `ItemBlueprintsDebugCommand` enchant logic | M (extract assembler) |
| Drop log / admin view | none | none | `AuditLog`, paged search pattern | M |
| Admin config UI | `/treasure create` only | none | FormWizard + `SiegeConfigurationPage` pattern | M |
| Announcements | ocelot broadcast; none for boxes | none | Adventure in plugin, `GameSettings` template style | S |
| Plugin → API auth | n/a | none (KNG-15) | `ApiKeyAuthProvider` (client), no server scheme | M (shared prerequisite) |
| Soulbound/Ghosted on roll | 46% each | none | — | deferred to `ItemInstance` |

**Reuse as-is:** `Grade`/`DropChance`/`GradeCatalog`, `Category`, `ItemBlueprint` + the v1 seed, `EnchantmentDefinition`,
`KnkPermissible`, the FormWizard pipeline, `WorldGuardRegionLookup`, `ItemGradeTag`. **Extend:** extract the enchantment
application from `ItemBlueprintsDebugCommand` into a shared `BlueprintItemAssembler`, which also fixes kits and the catalog, and
port the `EnchantDropPlanner`/`SiegeWorldPresenter` patterns (not the code, because it lives on the siege branch) into
`core/lootbox`. **New:** the lootbox entities, roll engine, spawn/claim API, plugin presenter/scheduler/listeners, admin page and
plugin service auth (unless currency-payments/KNG-15 ships it first).

---

## 3. v3 design

### 3.1 Core model and rolls

**Where the roll happens: API side (`LootboxRollEngine`).** Why:
1. The inputs (pools, grades, enchant rolls, specials, per-player limits) are all DB rows, so the API reads them without a cache.
2. Claim, roll and drop log commit in **one transaction** with a uniqueness guarantee. The result exists before any item does, so a
   relog, crash, retry or double click can never re-roll.
3. The same code computes the admin odds preview and the real roll, so the preview can't drift. It is unit-testable in xUnit with an
   injected `ILootRandom`, which wraps `RandomNumberGenerator`.
4. Cost: a click needs the API (about 10 ms locally). If the API is down, the box stays and the player sees "Try again in a moment."

The plugin decides *where* a box can physically go (terrain, loaded chunks, regions). The API decides *whether* a box may spawn
(caps) and *what* it is (type, box grade).

**Spawn-time roll (API, `POST /api/LootboxSpawns`):**
1. **Type:** weighted by `LootboxType.SpawnWeight` among the enabled types allowed in the area.
2. **Box grade:** the grades with stars in `[MinBoxStars, MaxBoxStars]` (default 1-5), weighted by `LootboxTypeGradeWeight.Weight`
   if the admin set one, else `Grade.DropChance`. Defaults for 1-5 (sum 210): ★1 33.3%, ★2 28.6%, ★3 19.0%, ★4 11.9%, ★5 7.1%.
   With 1-10 (sum 224.55): ★6 3.6%, ★7 2.2%, ★8 0.45%, ★9 0.22%, ★10 0.02%.

**Claim-time roll (API, `POST /api/LootboxSpawns/{id}/claim`)**, box grade B stars:
1. **Special check.** Run through enabled `LootboxSpecialEntry` rows for this type (or type-less ones) with `MinBoxStars ≤ B`, in
   `SortOrder`. Each has an independent `ChancePerMillion` roll and the first hit wins. The item is the blueprint as-is, with its
   default enchantments and no rolled ones.
2. **Item grade (two-stage).** The grade window is `[max(1, B − ItemStarSpread), B]` (default spread 2: a ★5 box gives ★3-★5). Keep
   only grades that have at least one eligible pool item, and weight each by `Grade.DropChance`. If the window is empty, widen it
   downward, then upward, and log a warning. *Two-stage, not per-item weights,* so adding more ★3 items to a category doesn't dilute
   the ★5 odds. This also replaces v1's count-biased first-success algorithm.
3. **Item.** Uniform among eligible pool items of that grade, times `LootboxPoolEntry.WeightOverride` (default 1).
   - **The pool** is every blueprint whose `CategoryId` is the type's category (plus descendants if `IncludeSubcategories`), that has
     a `GradeId`, and that isn't tagged `Lootbox Special`.
   - Admin `LootboxPoolEntry` rows add items (`Mode=Include`, any category or an ungraded item with an explicit `GradeId` override)
     or remove them (`Mode=Exclude`).
4. **Enchantments.** For each `LootboxEnchantRoll` of the type with `MinBoxStars ≤ B`, in `SortOrder`:
   - Roll `ChancePercent`. On a hit, take a level uniform in `[MinLevel, MaxLevel]`.
   - **Clamp vanilla** to `EnchantmentDefinition.MaxLevel / Grade.EnchantLevelCapDivisor` of the *item's* grade (null divisor =
     definition max), the same formula as KNG-6 `KnkGrade.capEnchantLevel`. Drop the enchant if the result is below 1.
   - **Custom** enchants are clamped to the definition max only (KNG-6 D3: custom is uncapped by grade).
   - Merge with the blueprint's default enchantments as `max(default, rolled)`.
   - Enchantment Books blueprints never get rolled enchantments (same rule as `ItemBlueprintsDebugCommand:236-240`).
5. **Quantity** = the blueprint's `DefaultQuantity` (Food/Resources stacks); `ItemsPerBox` repeats steps 1-4 (default 1).

**Worked example.** Weapons box ★5, dev-DB weapons: ★3 Standard Bow / Steel Axe / Steel Sword, ★4 Bladed Steel Sword, ★5 Golemheart
Sword / Lavonian Bow, with Skull splitter special. The grade roll is 40:25:15 → 50% / 31.25% / 18.75%, so **Golemheart Sword = 9.4%**
(v1 legendary box: 30.7%). The admin can raise it with a pool `WeightOverride` or grade weights; the odds preview shows the result.

### 3.2 Data model (knk-web-api, `Models/Lootbox/`, one migration `AddLootboxes`)

| Entity | Fields (beyond `Id`) | Notes |
|---|---|---|
| `LootboxType` `[FormConfigurableEntity]` | `Name`, `CategoryId` (**unique**), `IncludeSubcategories`=true, `Enabled`=false, `SpawnWeight`=10, `MinBoxStars`=1, `MaxBoxStars`=5, `ItemStarSpread`=2, `ItemsPerBox`=1, `DisplayMaterialRefId?` (model shown; default category icon, then `minecraft:chest`), `MaxClaimsPerPlayerPerDay?` (null = global), `AnnounceMinItemStars?` (null = global) | One per category, enforced by a unique index. Seed: one disabled row per existing category. |
| `LootboxTypeGradeWeight` | `LootboxTypeId`, `GradeId`, `Weight` decimal | Optional override of `Grade.DropChance` for the box-grade roll |
| `LootboxPoolEntry` | `LootboxTypeId`, `ItemBlueprintId`, `Mode` (Include/Exclude), `WeightOverride?`, `GradeIdOverride?` | Composite PK (type, blueprint). No cascade to `ItemBlueprint` (vision §9.2 rule): `DeleteBehavior.Restrict`, and the service refuses a blueprint delete while it is referenced. |
| `LootboxEnchantRoll` | `LootboxTypeId`, `EnchantmentDefinitionId`, `ChancePercent` decimal(7,4), `MinLevel`, `MaxLevel`, `MinBoxStars`=1, `SortOrder` | |
| `LootboxSpecialEntry` `[FormConfigurableEntity]` | `LootboxTypeId?` (null = any box), `ItemBlueprintId`, `ChancePerMillion`, `MinBoxStars`=5, `Enabled`, `SortOrder` | Its blueprint also gets the `Lootbox Special` tag (excluded from normal pools) |
| `LootboxSpawnArea` `[FormConfigurableEntity]` | `Name`, `World`, `WgRegionId` (or picked from a `Domain`), `Enabled`, `MaxActive`=3, `SpawnIntervalSeconds`=600, `SpawnChancePercent`=100, `MinOnlinePlayers`=3, `MinDistanceFromPlayers`=24, `LifetimeMinutes`=30, `ExcludedRegionIds` (CSV) | Defaults echo v1 ocelots (600 s, ≥3 online). A fixed-point area (a tiny region) reproduces v1 treasure spots. |
| `LootboxSpawnAreaType` | `LootboxSpawnAreaId`, `LootboxTypeId` | Empty = all enabled types |
| `LootboxConfiguration` (singleton, like `SiegeConfiguration`) | `Enabled`, `GlobalMaxActive`=15, `MaxClaimsPerPlayerPerDay`=10, `AnnounceMinItemStars`=5, `AnnounceSpawnMinBoxStars`=6, `DropAnnouncementTemplate`=`"&6{player} &efound {item} &ein a {box}!"`, `SpawnAnnouncementTemplate`=`"&eA {box} &eappeared in &6{area}&e!"` | |
| `LootboxSpawn` | `Token` Guid (unique), `LootboxTypeId`, `BoxGradeId`, `SpawnAreaId?`, `World`, `X`,`Y`,`Z` (int), `Status` (Active/Claimed/Expired/Removed) **`[ConcurrencyCheck]`**, `SpawnedAt`, `ExpiresAt`, `ClaimedAt?`, `ClaimedByUserId?`, `ServerId`, `CreatedByUserId?` (admin spawn) | Indexes `(Status, ExpiresAt)`, `(SpawnAreaId, Status)`. Not form-configurable. |
| `LootboxClaim` | `LootboxSpawnId` (**unique**, nullable for future token items), `UserId`, `LootboxTypeId`, `BoxGradeId`, `ItemBlueprintId`, `ItemGradeId?`, `Quantity`, `IsSpecial`, `IdempotencyKey` (unique), `ClaimedAt`, `DeliveredAt?`, `DeliveryMethod?` (Inventory/DroppedOwned/Redelivered), `DeliveryNote?` | Append-only drop log, like `KitClaim`. Index `(UserId, ClaimedAt)`. |
| `LootboxClaimEnchantment` | `LootboxClaimId`, `EnchantmentDefinitionId`, `Level` | Normalized per vision §9.1, so it can be copied onto a future `ItemInstance` |

`AuditAction` gains `LootboxSpawnedByAdmin = 12` and `LootboxGranted = 13` (admin give). Player claims are logged in `LootboxClaim`,
not in the audit log.

### 3.3 API (controllers under `api/[controller]`, PascalCase like `Kits`)

| Endpoint | Purpose | Auth |
|---|---|---|
| CRUD + `search` on `LootboxTypes`, `LootboxSpecialEntries`, `LootboxSpawnAreas` (join rows edited through the type form, like `KitContent`); `GET/PUT LootboxConfiguration` | Admin config | Same as other FormWizard entities today (anonymous; `RequireAdmin` once the web app sends tokens, which is not specific to lootboxes) |
| `GET LootboxTypes/{id}/odds?boxStars=` | Preview: per-grade %, per-item %, specials, per-enchant hit % and effective level range after the cap, plus box-grade distribution | Admin |
| `GET LootboxSpawns/runtime-config` | Enabled types (id, name, category, display material, per-star name) and areas, plus the global config. Plugin caches it (`runtime-refresh-seconds`). | **PluginService** |
| `GET LootboxSpawns/active` | Active spawns: id, token, type, box stars, world/x/y/z, expiresAt | PluginService |
| `POST LootboxSpawns` `{areaId, world, x, y, z, serverId}` | Checks caps (area `MaxActive`, `GlobalMaxActive`, `Enabled`), rolls type and box grade, inserts the row. 201 `LootboxSpawnDto`; 409 `{code: AreaFull\|GlobalFull\|NoEnabledType\|Disabled}` | PluginService |
| `POST LootboxSpawns/admin` `{typeId, boxStars?, world, x, y, z, actorUserId}` | Manual spawn (ignores caps), audited | PluginService |
| `POST LootboxSpawns/{id}/despawn` `{actorUserId?}` | Status → Removed | PluginService |
| `POST LootboxSpawns/{id}/claim` `{token, userId, idempotencyKey}` | §3.1 roll. 200 `LootboxClaimResultDto {claimId, replay, itemBlueprintId, quantity, itemGradeStars, isSpecial, enchantments[{definitionId, key, isCustom, level}], announce, boxLabel}`; 409 `AlreadyClaimed\|Expired\|TokenMismatch`; 429 `DailyLimit` | PluginService |
| `POST LootboxClaims/{id}/delivered` `{method, note?}` | Sets `DeliveredAt` (idempotent) | PluginService |
| `GET LootboxClaims/pending?userId=` | Undelivered claims older than 30 s | PluginService |
| `POST LootboxClaims/search` | Paged drop log (filters: user, type, grade, special, date) | Admin |

**Claim transaction** (explicit `BeginTransactionAsync`, as `SiegeMatchRepository.cs:107` does):
1. Load the spawn. If `IdempotencyKey` already exists for this user, **return the stored claim with `replay=true`** (no roll).
2. If Status ≠ Active or `ExpiresAt` has passed, return 409. If the token doesn't match, return 409.
3. If the user has ≥ the limit of claims in the last 24 h, return 429.
4. Roll, set Status=Claimed (the `[ConcurrencyCheck]` makes a concurrent winner raise `DbUpdateConcurrencyException`, which maps
   to 409 `AlreadyClaimed`), insert the claim and its enchant rows, commit.
5. The unique index on `LootboxClaim.LootboxSpawnId` is the last line of defence on MySQL.

**Expiry:** a lazy sweep (`UPDATE … SET Status=Expired WHERE Status=Active AND ExpiresAt<now`) runs at the start of `active`, `spawn`
and `claim`. No hosted service is needed.

**PluginService policy (prerequisite, shared with KNG-15 / currency-payments):** an `ApiKey` authentication scheme reading `X-API-Key`
against `Security:PluginApiKeys` in appsettings, plus an `[Authorize(Policy="PluginService")]` policy. The plugin switches to
`api.auth.type: apikey`, and `ApiKeyAuthProvider` already exists. If currency-payments lands a different service-auth design first,
lootboxes adopt it instead (§4 D2). Without this, a browser could `POST …/claim` for any `userId`.

**Observability:**
- `Meter("Knk.Lootboxes")` counters `lootbox_spawns_total{type,box_stars}`, `lootbox_claims_total{type,box_stars,item_stars,special}`,
  `lootbox_claim_conflicts_total{reason}` and histogram `lootbox_claim_duration_ms`. They are exported through the existing OTLP
  pipeline. Note: **there is no Prometheus `/metrics` endpoint yet** (`Program.cs:186` TODO), despite `knk-web-api/CLAUDE.md`.
- Structured logs on every spawn, claim, 409 and replay.

### 3.4 Plugin (knk-plugin)

**Physical box: display entities, not a block.** Each box is an `ItemDisplay` (model = `DisplayMaterial`, slowly rotating), an
`Interaction` hitbox (0.9×0.9) and an optional `TextDisplay` label (`<colour>Legendary Weapons Lootbox ★★★★★`). All three are
**`setPersistent(false)`** and carry PDC `knightsandkings:knk_lootbox = <token>`.
- Why not a block: it can't overwrite player builds, can't be pushed by pistons, broken or blown up, and needs no block log.
- Non-persistent entities disappear on chunk unload and crash, so stale copies never exist. The plugin re-renders boxes from its
  active-spawn cache.
- The pattern is `SiegeWorldPresenter`'s.
- Particles and sound echo v1 treasure: gold-block particles every 4 s to players within 15 blocks.

Components (new unless noted):

| Module | Class | Role |
|---|---|---|
| knk-core | `core/lootbox/LootboxSpawnPlanner` | Pure decision per area per tick: interval elapsed, online ≥ min, local active < max, chance → candidate x/z uniform in the region's bounding box (like `EnchantDropPlanner`) |
| knk-core | `core/lootbox/ActiveLootboxCache` | Spawns keyed by id, token and chunk key; refreshed from `GET active` plus local claim/despawn events |
| knk-core | `core/lootbox/ClaimGuard` | In-flight map `spawnId → uuid`: a second click while a claim is in flight is ignored |
| knk-core | ports `LootboxesQueryApi`, `LootboxesCommandApi`; records `KnkLootboxSpawn`, `KnkLootboxType`, `KnkLootboxClaimResult` | |
| knk-api-client | `LootboxDtos`, `LootboxMapper`, `Lootboxes{Query,Command}ApiImpl` | |
| knk-paper | `lootbox/LootboxSpawnScheduler` | Runs every `scheduler-tick-seconds`. Picks a surface via `getChunkAtAsync(x, z, false)`, which **never generates terrain** (missing chunks are skipped). Rejects liquids, leaves, non-solid ground and places without 2 air blocks above. Requires the point to be inside the area's WG region and outside `ExcludedRegionIds`, and ≥ `MinDistanceFromPlayers` from every player. Then POSTs the spawn and renders it if the chunk is loaded. |
| knk-paper | `lootbox/LootboxPresenter` | Spawns and removes the entities |
| knk-paper | `listeners/LootboxChunkListener` | `ChunkLoadEvent` renders cached spawns in that chunk; `EntitiesLoadEvent` removes any entity carrying `knk_lootbox` whose token isn't active (belt and braces) |
| knk-paper | `listeners/LootboxInteractListener` | `PlayerInteractEntityEvent` on the `Interaction`. Checks `knk.lootbox.open`, not in staff/owner/vanish mode (unless configured), distance ≤ `claim-max-distance`, a free slot (else "Your inventory is full — make room to open this lootbox", **no API call**), and `ClaimGuard`. Then claims async and delivers on the main thread. |
| knk-paper | `item/BlueprintItemAssembler` (**extracted** from `ItemBlueprintsDebugCommand:233-320`) | Blueprint plus an enchant list → ItemStack. Skips enchantments that fail `canEnchantItem` or `conflictsWith` and reports them in `delivered.note`. Also used by `/knk itemblueprints give`, and kits can adopt it. |
| knk-paper | `lootbox/LootboxDelivery` | Stamps PDC `knightsandkings:knk_lootbox_claim = claimId` on the item, adds it to the inventory, and if leftovers remain drops them with `Item#setOwner(uuid)` + `setCanMobPickup(false)`, then ACKs `delivered`. |
| knk-paper | `listeners/LootboxJoinListener` | On join, `GET pending` and deliver. Before re-giving, it scans the inventory and ender chest for the same claim id, so a crash between give and ACK doesn't dupe. |
| knk-paper | `commands/LootboxCommand` (`/lootbox`, alias `/lb`) | Player: `/lootbox` (help), `/lootbox odds <category>` (read-only preview). Admin: `spawn <category> [stars]`, `despawn [id\|nearest]`, `list [area]`, `tp <id>`, `give <player> <category> [stars]` (roll + deliver without a world box, audited), `reload` |

`config.yml`:
```yaml
lootboxes:
  enabled: true
  runtime-refresh-seconds: 60      # runtime-config + active spawns re-read
  scheduler-tick-seconds: 20
  claim-max-distance: 5
  full-inventory: refuse           # refuse (pre-check) | drop-owned
  staff-mode-can-claim: false
  surface:
    max-attempts-per-tick: 4
    forbidden-ground: [WATER, LAVA, MAGMA_BLOCK, CACTUS, POWDER_SNOW]
  display:
    label: true
    rotate: true
    particles-radius: 15
    grade-colors: { "1": "&9", "2": "&9", "3": "&b", "4": "&b", "5": "&d", "6": "&6", "7": "&6", "8": "&c", "9": "&c", "10": "&4" }
```
Grades 1-5 use v1 treasure's colours (§1.1). Grades 6-10 are new.

**Permissions** (in-house model through `KnkPermissible`, declared in `plugin.yml` for documentation): `knk.lootbox.open` (players),
`knk.lootbox.odds` (players), `knk.lootbox.admin.spawn`, `.despawn`, `.list`, `.tp`, `.give`, `.reload`. A seed grants
`knk.lootbox.open` and `knk.lootbox.odds` to the Default `PermissionGroup` (§4 D8).

**Messages / UX:**
- Hover label: `<colour><GradeName> <Category> Lootbox <stars>`.
- Opening: a chest-open sound, then `&aYou opened a {box} and found {item}!`, where the item name is hoverable (Adventure `showItem`).
- Already claimed: `&cSomeone else got there first.` Expired: `&cThis lootbox has crumbled away.` Daily limit: `&cYou've opened
  {n} lootboxes today — come back tomorrow.` API down: `&cThe lootbox is stuck — try again in a moment.`
- Rare drop (`isSpecial` or item ★ ≥ `AnnounceMinItemStars`): a server broadcast from `DropAnnouncementTemplate` with a hoverable
  item, plus a `UI_TOAST_CHALLENGE_COMPLETE` sound for the finder.
- Spawns with box ★ ≥ `AnnounceSpawnMinBoxStars` broadcast `SpawnAnnouncementTemplate` (v1 ocelot precedent).
- The API marks a claim `announce=true`, so the decision is made in one place. At most one broadcast per claim.

### 3.5 Special tier and seeds
- **Seed** (create-only, natural keys, after `ItemBlueprintV1Seed`, as `KitSeed` does):
  - one `LootboxType` per existing `Category` with `Enabled=false`;
  - tag `Lootbox Special`;
  - `LootboxSpecialEntry` rows for the §1.4 one-offs, each `ChancePerMillion=2000` (0.2%) and `MinBoxStars=5`, limited to their own
    category's box. **Donator pickaxe is excluded pending Q1.**
  - Specials that are ungraded in the seed get `ItemGradeId` = ★5 on the claim for cap and announcement purposes.
- **Weapons enchant rolls**, derived from v1's Legendary box and bounded by v3's grade cap:

  | Enchant | Chance | Levels | Min box ★ | v1 origin |
  |---|---|---|---|---|
  | minecraft:sharpness | 100 | 1-5 | 1 | 91% 1-6 / 9% 4, then a floor re-roll, so it's always present |
  | minecraft:knockback | 66 | 1-2 | 1 | 66% (1-7 bug) |
  | minecraft:fire_aspect | 51 | 1-2 | 1 | 51% |
  | minecraft:unbreaking | 46 | 1-3 | 1 | 46% |
  | poison | 30 | 1-3 | 3 | blocks A+B ≈ 29%/21% |
  | blindness | 26 | 1-3 | 3 | blocks A+C |
  | confusion | 31 | 1-3 | 3 | blocks A+D |
  | armor_repair | 6 | 1 | 4 | rare box 6% |
  | chaos | 6 | 1 | 5 | legendary box 6% |

  Armor and Tools get a small suggested profile (protection/efficiency 50% 1-4, unbreaking 40% 1-3). Other categories get none.
  **With the v3 cap, a ★1-3 sword can't get Knockback or Fire Aspect** (cap 0) and ★1-3 gets Sharpness I. That is intended by
  KNG-6 and differs from v1.

### 3.6 Web-app admin UI (knk-web-app)
- Clients `lootboxTypeClient.ts`, `lootboxSpecialEntryClient.ts`, `lootboxSpawnAreaClient.ts`, `lootboxConfigurationClient.ts` and
  `lootboxClaimClient.ts`, registered in `entityApiMapping`/`objectConfigs` (as siege Phase 3 did). FormConfigurations for
  `LootboxType` (steps: basics → box grades → pool → enchant rolls), `LootboxSpecialEntry` and `LootboxSpawnArea`. The area form has
  a WgRegionId picker (existing Domain regions) and a "define new region" world task (`WgRegionIdTaskHandler`).
- New page `pages/admin/LootboxesPage.tsx` (`/admin/lootboxes`), styled like `SiegeConfigurationPage`, with tabs:
  - **Settings** (singleton form);
  - **Types** (table: category, enabled, spawn weight, pool size per grade, with a warning when a grade in the window has 0 items);
  - **Odds** (type + box-star selector → the odds endpoint, rendered as a table);
  - **Active boxes** (list + despawn);
  - **Drop log** (paged claims with filters, special rows highlighted, undelivered claims flagged).

### 3.7 Anti-exploit and concurrency

| Threat | Mitigation |
|---|---|
| Chunk-reload farming | Spawns are time-scheduled and capped by the API. A chunk load only **re-renders** existing spawns. Entities are non-persistent. No roll happens at spawn or render time. |
| Relog or crash to re-roll | The roll is persisted before delivery. Pending claims are delivered on join, deduped by the claim-id PDC. |
| Double click / retry / timeout | `ClaimGuard` in-flight lock. The idempotency key `"{token}:{userId}"` replays the stored result and never re-rolls. |
| Two players clicking at once | Conditional status change (`[ConcurrencyCheck]`) inside a transaction, plus the unique `LootboxClaim.LootboxSpawnId`. Exactly one 200; the others get 409. |
| Item dupes | A box is not an item. Delivered items carry the claim id, so the admin log can spot two stacks with the same id. `ItemInstance` later. |
| Full inventory | Pre-check before the API call. If a race still leaves leftovers, they drop owner-locked and are logged as `DroppedOwned`. |
| Spawn camping / AFK | `MinDistanceFromPlayers`, per-player daily cap (API), lifetime expiry, no claims in staff/owner/vanish mode. |
| Alt accounts | Per-user daily cap only (no IP tracking). Noted. |
| Direct API calls from a browser | Runtime endpoints require PluginService auth. |
| v1 rename exploit | Box identity is a server token. No display-name matching anywhere. |
| Spawning in private or protected areas | Area region plus `ExcludedRegionIds`. Admins exclude plots and structure regions. |
| Grief/PvP around boxes | Out of scope. KNG-12 (no WG flags on town/district regions) affects safezone PvP around boxes. |

---

## 4. Decisions taken by default (review)

| # | Decision | Why / how to change |
|---|---|---|
| D1 | The roll runs **API-side**; the plugin only picks positions and delivers | §3.1. The plugin-side alternative can't make claim + roll + log atomic. |
| D2 | Runtime endpoints need a **PluginService API key** | Closes the anonymous-claim hole. Adopt currency-payments/KNG-15 service auth if it lands first. |
| D3 | Box = **display entities** (`ItemDisplay` + `Interaction` + `TextDisplay`), non-persistent | No terrain edits and no orphans. Swap in a block by replacing `LootboxPresenter`. |
| D4 | **Two-stage** item roll (grade by `DropChance`, then uniform item) with a grade window of box ★ − 2 … box ★ | Pool size doesn't dilute rare grades. Spread is per type. |
| D5 | **Box grade = the existing `Grade` table**, weighted by `DropChance` (range 1-5 by default) | No second rarity table. Per-type overrides are available. |
| D6 | Rolled vanilla levels are **clamped by the item-grade cap**, custom enchants only by definition max | Consistent with KNG-6. v1's Sharpness 6-7 and Knockback 7 are not reproduced. |
| D7 | Full inventory → **refuse before claiming**; any leftover race drops owner-locked | The Kits "drop, don't lose" rule, plus a pre-check so boxes aren't wasted |
| D8 | `knk.lootbox.open`/`odds` are granted to the Default group by seed | `KnkPermissible` fails closed (the siege `knk.siege.play` precedent) |
| D9 | One box type per **top-level or leaf** category row, `IncludeSubcategories=true`, all seeded **disabled** | The admin enables what they want. No surprise spawns after migrating. |
| D10 | Claim is **first-come, one claimer per box** (not v1 treasure's once-per-player) | The brief asks for claim-once. A per-player mode would need a claim-per-(spawn, user) key. |
| D11 | Soulbound/Ghosted rolls are dropped until `ItemInstance` | No v3 state to hold them. The v1 odds are recorded in §1.1. |
| D12 | Expiry by lazy SQL sweep, not a hosted service | Fewer moving parts. A single API instance. |
| D13 | Special entries at 0.2% for boxes ★5+ | Placeholder rarity, tunable in the web app |
| D14 | The v1 world-loot odds (80/70/60/10/1) are **not** used. `Grade.DropChance` (70/60/40/25/15/…) is the single source. | The brief says to use DropChance. `vision.md:284` asks for a richer formula (enchantments, soulbound); it stays deferred, and the roll engine is where it would go. |

## 5. Open questions for the developer

### Resolved 2026-09-26 (developer) — and still open

- **Q1 special items:** yes, the recovered one-offs minus the Donator pickaxe. The developer's "flaming samurai" sword was
  searched for in all v1/v2 source and git history: **not found** (the only "Samurai" in v1 is a Royal bodyguard name,
  `v1:Menu/Menu.java:2206`). It will be added as a new special blueprint once its display name/material/enchants are given.
- **Q2 spawn areas:** admin-defined areas — agreed. *Follow-up asked:* how they are defined/stored (answer: `LootboxSpawnArea`
  rows in MySQL via the API, each referencing a WorldGuard region; proposal to add in-game creation from a WorldEdit
  selection). Awaiting confirmation.
- **Q3 box grades ★1-5 only** — agreed.
- **Q4 daily cap:** *follow-up asked* what "10 per day" means. Awaiting a number (or none).
- **Q5 box token items as Phase 5** — agreed. *Follow-up asked:* ItemBlueprint vs ItemBlueprint instancing — awaiting a
  choice between deferring `ItemInstance` (claim id in PDC) and building a minimal `ItemInstance` now.
- **Q6 grade-capped odds** — default taken.

Original questions below, kept for the record.

1. **Which special items?** v1 source has no hardcoded ultra-rare items (§1.4). Options: (a) the 9 recovered one-offs in §1.4 minus
   Donator pickaxe; (b) (a) plus items you name from memory (give name, material, lore, enchants, abilities); (c) new v3 specials
   authored as blueprints later. **Recommended default: (a) now, (b) as you recall them. They're just blueprints plus a special entry,
   so adding more is a web-app task.**
2. **Where do boxes spawn by default?** (a) Only in admin-created `LootboxSpawnArea`s, so nothing spawns until one exists; (b) the
   wilderness of the main world minus all town regions; (c) inside towns, as v1 ocelots did ("in all towns"). **Recommended: (a)**,
   with a seeded disabled example area per town.
3. **Box grade range.** Should ★6-10 boxes exist (grades 6-10 are placeholders)? (a) Boxes ★1-5 only; (b) all 10. **Recommended:
   (a)** until grades 6-10 are named and have items.
4. **Per-player daily cap default:** (a) 10 per day globally; (b) none; (c) per-type caps only. **Recommended: (a).**
5. **Lootbox items (the v1 "Sword Box" consumable) as well as world boxes?** These would be server-token items given by
   premium/donator ranks, kits, PvP kills or referrals (all in the vision notes), opened with the same claim API. (a) Yes, Phase 5;
   (b) no. **Recommended: (a), after world boxes ship.**
6. **Faithful v1 sword-box odds?** (a) Keep the v3-capped Weapons profile (§3.5); (b) add a "v1 classic" Weapons profile that ignores
   the grade cap and reproduces §1.1 (Sharpness up to 7). **Recommended: (a).**

