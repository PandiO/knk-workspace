# Items — v1 Seed Data (recovered from v1 playerdata)

**Status:** Implemented — `ItemBlueprintV1Seed` (knk-web-api, branch `claude/v1-item-port`), run
against the dev DB 2026-09-25. Decisions in §4 are defaults picked without a synchronous review —
flagged for the developer.
**Last updated:** 2026-09-25

**Source:** `MinecraftServer/Servers/Archive/K&K_OpenBeta_Archive_17-08-22/Server/Old_KnK/playerdata/`
— 143 v1 player files (inventory + ender chest). They carry no `DataVersion` tag, i.e. they were
written by a pre-1.9 server and never upgraded: untouched v1 data. (The `K&K_OpenBeta_Backup_21-11-22`
copy of `Old_KnK` is identical; the 1.16 `world/` folders and `mc104550.sql` are v2.)

**Why playerdata and not a DB:** v1's item definitions lived in its `Products` table
(`docs/specs/legacy/items.md`), and no dump of it survives. v1 never persisted an `ItemStack` —
every product was rebuilt from that table as:

- name `§f<grade colour><DisplayName>`
- lore: one `§7<enchant> <roman>` line per custom enchantment, two spacer lines,
  `§l§bGrade: ★ ★ ★`, and optionally `Soulbound` / `Ghosted`
- vanilla enchantments added unsafely (numeric pre-1.13 ids, levels above vanilla caps allowed)

so the items players still hold are a faithful, if partial, copy of that table.

**Tooling:** `scripts/v1-item-port/v1_items.py` (stdlib Python, own NBT reader):
`player <dir> <name>` dumps one player's named items, `report <dir>` prints the per-item consensus
below, `generate <dir>` prints the C# rows for `ItemBlueprintV1Seed.Blueprints`. Regenerate the seed
table with it rather than hand-editing it. Curation rules (§4) live in the script.

## 1. Field mapping

| v1 (item stack) | v3 |
|---|---|
| `id` + `Damage` (pre-flattening, e.g. `log:0`, `fish:0`) | `IconMaterial` → `minecraft:oak_log`, `minecraft:cod` (renamed ids mapped in the script; none left unmapped) |
| `display.Name` `§f§aGolemheart Sword` | `Name` = `Golemheart Sword` (colour-stripped), `DefaultDisplayName` = `&aGolemheart Sword` (leading `§f` dropped; `&` codes, which the plugin's `DisplayTextFormatter` translates — KitSeed stores `§`, both render) |
| lore `§l§bGrade: ★ ★ ★ ★ ★` | `Grade` by star count (the plugin re-renders the star line from `Grade`) |
| lore `§7blindness III`, `§7Health Boost I` | `ItemBlueprintDefaultEnchantment` → custom `EnchantmentDefinition` (`blindness`, `health_boost`, …) |
| `ench` `[{id:16,lvl:5}]` | `ItemBlueprintDefaultEnchantment` → vanilla `EnchantmentDefinition` `minecraft:sharpness` |
| other lore lines | `DefaultDisplayDescription` — empty for every seeded item (only enchant books and the menu compass had any) |
| `Soulbound` / `Ghosted` | dropped — instance state, not item type (`vision.md` §9.1 `ItemInstance`) |
| `Count` | not used; `DefaultQuantity` = 1, `MaxStackSize` = vanilla stack size |

## 2. Custom enchantments (lore → knk-plugin)

v1 wrote custom enchantments as lore (`docs/specs/custom-enchantments/SPEC_CUSTOM_ENCHANTMENTS.md`
§4.1 format, case varying: `§7blindness III`, `§7Freeze I`). Every such lore line across all 143
players matched one of knk-plugin's 12 `EnchantmentRegistry` ids — no unknown phrasing. They map to
the `IsCustom = true` `EnchantmentDefinition` rows that `AbilityDefinition.SeedCanonicalAsync`
already owns (keys `poison`, `wither`, `freeze`, `blindness`, `confusion`, `strength`, `chaos`,
`flash_chaos`, `health_boost`, `armor_repair`, `resistance`, `invisibility`); the v1 seed never
creates custom definitions itself and skips (with a warning) any it can't find.

Levels seen in v1 above v3's caps — `chaos II`, `flash_chaos II`, `invisibility II` (v3 max 1) — were
all on per-copy rolled items and fall out under the consensus rule (§4.2); every custom level that
*is* seeded is within its cap, so the plugin (`ItemBlueprintsDebugCommand`/`EnchantmentDefinitionBukkitMapper`,
which skips over-cap custom levels) applies all of them.

This covers the blueprint-level part of the spec's §12.2 TODO "migration/backfill strategy from
legacy plugin-only enchantment lore". Per-item (instance) backfill waits for `ItemInstance`.

## 3. Seeded rows

Create-only, natural-key lookup, same convention as `KitSeed` (`Name`; `Stars` for grades; `Key` for
enchantment definitions, custom keys matched the way the plugin's mapper normalizes them). Join rows
only under blueprints the seed itself created. Runs after `KitSeed` in `Program.cs`.

- **Tag** `Legacy v1` on every seeded blueprint — filter/cleanup handle.
- **Categories** Weapons, Armor, Food (reused from KitSeed), Tools, Resources, Trinkets.
- **Grades** by stars: Common 1 / Uncommon 2 (KitSeed's), **Rare 3, Epic 4, Legendary 5 (new names)**.
- **Vanilla enchantment definitions** created on demand, `MaxLevel`/`DisplayName` from
  `Data/minecraft_enchantment_catalog.json`, with a `MinecraftEnchantmentRef` base ref.

Dev-DB run (2026-09-25): created 77 blueprints, 28 default enchantments, 6 vanilla enchantment
definitions + refs, 3 grades, 2 categories, 44 material refs, 1 tag. Reused (left untouched):
`Iron Sword`, `Arrow` (KitSeed's) and a hand-authored `Diamond Sword\n` (id 21 — name has a trailing
newline, display `§5Diamond`) — so the v1 `Diamond Sword` (grade 4, `&bDiamond Sword`) is **not** in
the dev DB. Pre-run backup: `Documents/Werk/db-backups/knightsandkings_dev_v2_items_pre_v1_seed_20260925_235454.sql`.

80 rows; *Copies / players* = how many named stacks / distinct players the row was derived from.

| Name | Material | DefaultDisplayName | Category | Grade (★) | MaxStack | Default enchantments | Copies / players |
|---|---|---|---|---|---|---|---|
| Arrow | `minecraft:arrow` | `&fArrow` | Weapons | 1 | 64 | — | 3 / 3 |
| Bladed Steel Sword | `minecraft:iron_sword` | `&bBladed Steel Sword` | Weapons | 4 | 1 | — | 5 / 5 |
| Diamond Sword | `minecraft:diamond_sword` | `&bDiamond Sword` | Weapons | 4 | 1 | — | 14 / 13 |
| Firestone Sword | `minecraft:stone_sword` | `&9Firestone Sword` | Weapons | 2 | 1 | — | 1 / 1 |
| Golemheart Sword | `minecraft:diamond_sword` | `&aGolemheart Sword` | Weapons | 5 | 1 | — | 14 / 7 |
| Iron Sword | `minecraft:iron_sword` | `&fIron Sword` | Weapons | — | 1 | — | 10 / 10 |
| Lavonian Bow | `minecraft:bow` | `&aLavonian Bow` | Weapons | 5 | 1 | infinity 1, power 6, unbreaking 6 | 3 / 3 |
| Longbow | `minecraft:bow` | `&6Longbow` | Weapons | 2 | 1 | — | 5 / 5 |
| Practice Bow | `minecraft:bow` | `&fPractice Bow` | Weapons | 1 | 1 | — | 1 / 1 |
| Practice Sword | `minecraft:wooden_sword` | `&fPractice Sword` | Weapons | 1 | 1 | — | 1 / 1 |
| Skull splitter | `minecraft:iron_sword` | `&9Skull splitter` | Weapons | 5 | 1 | sharpness 4, health_boost 1 *(custom)* | 1 / 1 |
| Standard Bow | `minecraft:bow` | `&9Standard Bow` | Weapons | 3 | 1 | — | 1 / 1 |
| Steel Axe | `minecraft:iron_axe` | `&9Steel Axe` | Weapons | 3 | 1 | — | 61 / 35 |
| Steel Sword | `minecraft:iron_sword` | `&9Steel Sword` | Weapons | 3 | 1 | — | 89 / 83 |
| Alloy Boots | `minecraft:golden_boots` | `&fAlloy Boots` | Armor | 1 | 1 | — | 27 / 19 |
| Alloy Chestplate | `minecraft:golden_chestplate` | `&fAlloy Chestplate` | Armor | 1 | 1 | — | 28 / 23 |
| Alloy Helmet | `minecraft:golden_helmet` | `&fAlloy Helmet` | Armor | 1 | 1 | — | 36 / 23 |
| Alloy Leggings | `minecraft:golden_leggings` | `&fAlloy Leggings` | Armor | 1 | 1 | — | 28 / 19 |
| Bladed Steel Boots | `minecraft:iron_boots` | `&bBladed Steel Boots` | Armor | 4 | 1 | — | 2 / 2 |
| Bladed Steel Chestplate | `minecraft:iron_chestplate` | `&bBladed Steel Chestplate` | Armor | 4 | 1 | — | 1 / 1 |
| Bladed Steel Helmet | `minecraft:iron_helmet` | `&bBladed Steel Helmet` | Armor | 4 | 1 | — | 3 / 3 |
| Bladed Steel Leggings | `minecraft:iron_leggings` | `&bBladed Steel Leggings` | Armor | 4 | 1 | — | 2 / 2 |
| Chainmail Helmet | `minecraft:chainmail_helmet` | `&bChainmail Helmet` | Armor | 4 | 1 | — | 1 / 1 |
| Chainmail Leggings | `minecraft:chainmail_leggings` | `&bChainmail Leggings` | Armor | 4 | 1 | — | 1 / 1 |
| Diamond Boots | `minecraft:diamond_boots` | `&bDiamond Boots` | Armor | 4 | 1 | protection 1 | 2 / 2 |
| Diamond Chestplate | `minecraft:diamond_chestplate` | `&bDiamond Chestplate` | Armor | 4 | 1 | protection 1 | 1 / 1 |
| Diamond Helmet | `minecraft:diamond_helmet` | `&bDiamond Helmet` | Armor | 4 | 1 | protection 1 | 2 / 2 |
| Diamond Leggings | `minecraft:diamond_leggings` | `&bDiamond Leggings` | Armor | 4 | 1 | protection 1 | 3 / 3 |
| Golemheart Boots | `minecraft:diamond_boots` | `&aGolemheart Boots` | Armor | 5 | 1 | protection 6 | 2 / 2 |
| Golemheart Chestplate | `minecraft:diamond_chestplate` | `&aGolemheart Chestplate` | Armor | 5 | 1 | — | 3 / 3 |
| Golemheart Helmet | `minecraft:diamond_helmet` | `&aGolemheart Helmet` | Armor | 5 | 1 | aqua_affinity 1, protection 6, respiration 3, unbreaking 6, health_boost 1 *(custom)* | 1 / 1 |
| Golemheart Leggings | `minecraft:diamond_leggings` | `&aGolemheart Leggings` | Armor | 5 | 1 | — | 2 / 2 |
| Halloween Armor Boots | `minecraft:iron_boots` | `&5Halloween armor` | Armor | — | 1 | protection 3 | 1 / 1 |
| Halloween Armor Leggings | `minecraft:iron_leggings` | `&5Halloween armor` | Armor | — | 1 | protection 3 | 1 / 1 |
| Leather Boots | `minecraft:leather_boots` | `&fLeather Boots` | Armor | 1 | 1 | — | 36 / 36 |
| Leather Chestplate | `minecraft:leather_chestplate` | `&fLeather Chestplate` | Armor | 1 | 1 | — | 38 / 38 |
| Leather Helmet | `minecraft:leather_helmet` | `&fLeather Helmet` | Armor | 1 | 1 | — | 36 / 36 |
| Leather Leggings | `minecraft:leather_leggings` | `&fLeather Leggings` | Armor | 1 | 1 | — | 37 / 36 |
| Leather Pants | `minecraft:leather_leggings` | `&fLeather Pants` | Armor | 1 | 1 | — | 2 / 2 |
| Steel Boots | `minecraft:iron_boots` | `&9Steel Boots` | Armor | 3 | 1 | — | 5 / 5 |
| Steel Chestplate | `minecraft:iron_chestplate` | `&9Steel Chestplate` | Armor | 3 | 1 | — | 7 / 6 |
| Steel Helmet | `minecraft:iron_helmet` | `&9Steel Helmet` | Armor | 3 | 1 | — | 5 / 5 |
| Steel Leggings | `minecraft:iron_leggings` | `&9Steel Leggings` | Armor | 3 | 1 | — | 5 / 5 |
| Blindness Pickaxe | `minecraft:diamond_pickaxe` | `&8Blindness Pickaxe` | Tools | — | 1 | sharpness 5, blindness 2 *(custom)* | 1 / 1 |
| Diamond Pickaxe | `minecraft:diamond_pickaxe` | `&bDiamond Pickaxe` | Tools | 4 | 1 | — | 3 / 3 |
| Donator pickaxe | `minecraft:diamond_pickaxe` | `&2Donator pickaxe` | Tools | — | 1 | efficiency 2, unbreaking 2 | 1 / 1 |
| Pickaxe of Good Health | `minecraft:diamond_pickaxe` | `&aPickaxe of Good Health` | Tools | — | 1 | sharpness 5, armor_repair 1 *(custom)*, health_boost 1 *(custom)* | 1 / 1 |
| Poison Pickaxe | `minecraft:diamond_pickaxe` | `&5Poison Pickaxe` | Tools | — | 1 | sharpness 5, poison 2 *(custom)* | 1 / 1 |
| Wither Pickaxe | `minecraft:diamond_pickaxe` | `&0Wither Pickaxe` | Tools | — | 1 | sharpness 5, wither 2 *(custom)* | 1 / 1 |
| Apple | `minecraft:apple` | `&9Apple` | Food | 3 | 64 | — | 6 / 6 |
| Baked Potato | `minecraft:baked_potato` | `&9Baked Potato` | Food | 3 | 64 | — | 2 / 2 |
| Bread | `minecraft:bread` | `&9Bread` | Food | 3 | 64 | — | 25 / 22 |
| Carrot | `minecraft:carrot` | `&bCarrot` | Food | 4 | 64 | — | 13 / 13 |
| Cooked Chicken | `minecraft:cooked_chicken` | `&bCooked Chicken` | Food | 4 | 64 | — | 4 / 4 |
| Cooked Mutton | `minecraft:cooked_mutton` | `&9Cooked Mutton` | Food | 3 | 64 | — | 10 / 10 |
| Cooked Porkchop | `minecraft:cooked_porkchop` | `&fCooked Porkchop` | Food | 2 | 64 | — | 34 / 34 |
| Cooked Rabbit | `minecraft:cooked_rabbit` | `&9Cooked Rabbit` | Food | 3 | 64 | — | 2 / 1 |
| Cooked Salmon | `minecraft:cooked_cod` | `&bCooked Salmon` | Food | 4 | 64 | — | 7 / 7 |
| Cooked ribeye | `minecraft:cooked_rabbit` | `&6Cooked ribeye` | Food | — | 64 | — | 9 / 9 |
| Cookie | `minecraft:cookie` | `&fCookie` | Food | 1 | 64 | — | 12 / 10 |
| Enchanted Cake | `minecraft:cake` | `&5Enchanted Cake` | Food | 5 | 1 | — | 1 / 1 |
| Magical Apple | `minecraft:golden_apple` | `&dMagical Apple` | Food | 5 | 64 | — | 20 / 18 |
| Melon | `minecraft:melon_slice` | `&9Melon` | Food | 3 | 64 | — | 3 / 3 |
| Mushroom stew | `minecraft:mushroom_stew` | `&dMushroom stew` | Food | 5 | 1 | — | 16 / 3 |
| Potato | `minecraft:potato` | `&fPotato` | Food | 1 | 64 | — | 4 / 4 |
| Pumpkin Pie | `minecraft:pumpkin_pie` | `&fPumpkin Pie` | Food | 2 | 64 | — | 7 / 6 |
| Rabbit Stew | `minecraft:rabbit_stew` | `&fRabbit Stew` | Food | 2 | 1 | — | 3 / 2 |
| Raw Beef | `minecraft:beef` | `&fRaw Beef` | Food | 1 | 64 | — | 5 / 5 |
| Raw Chicken | `minecraft:chicken` | `&fRaw Chicken` | Food | 1 | 64 | — | 6 / 5 |
| Raw Fish | `minecraft:cod` | `&fRaw Fish` | Food | 2 | 64 | — | 6 / 6 |
| Raw Porkchop | `minecraft:porkchop` | `&fRaw Porkchop` | Food | 1 | 64 | — | 3 / 2 |
| Raw Rabbit | `minecraft:rabbit` | `&fRaw Rabbit` | Food | 1 | 64 | — | 9 / 9 |
| Steak | `minecraft:cooked_beef` | `&9Steak` | Food | 3 | 64 | — | 7 / 7 |
| Coal | `minecraft:coal` | `&fCoal` | Resources | 1 | 64 | — | 9 / 7 |
| Cobblestone | `minecraft:cobblestone` | `&fCobblestone` | Resources | 1 | 64 | — | 10 / 9 |
| Diamond | `minecraft:diamond` | `&bDiamond` | Resources | 4 | 64 | — | 4 / 4 |
| Oak Wood | `minecraft:oak_log` | `&fOak Wood` | Resources | 1 | 64 | — | 12 / 8 |
| Spruce Wood | `minecraft:spruce_log` | `&fSpruce Wood` | Resources | 1 | 64 | — | 7 / 7 |
| Wheat | `minecraft:wheat` | `&fWheat` | Resources | 1 | 64 | — | 20 / 14 |
| Life amulet | `minecraft:diamond` | `&5Life amulet` | Trinkets | 4 | 64 | — | 13 / 9 |

## 4. Decisions (defaults — review)

1. **Scope: all 143 players**, not one — no single player holds the whole catalog (the most any
   player holds is 36 named stacks).
2. **Default enchantments = the consensus of every copy, at the lowest level seen.** v1 rolled
   enchantments per copy (loot boxes, enchant books): the 14 `Golemheart Sword`s carry 13 different
   sets and two have none, so its default is none. Single-copy items (the named pickaxes, `Skull splitter`,
   `Golemheart Helmet`, `Halloween armor`) keep that one copy's enchantments — right for the
   hand-designed specials, possibly a rolled set for `Golemheart Helmet`.
3. **Skipped:** enchanted books (v1's enchant-book mechanic — 18 distinct books, not item types),
   `Personal menu` (v1 UI compass), unnamed stacks (e.g. gem diamonds `Gems: 2`, an admin
   Sharpness-1000 test sword).
4. **Renamed for uniqueness:** the two `Halloween armor` items (iron boots/leggings) → `Halloween
   Armor Boots` / `Halloween Armor Leggings`; display name kept `&5Halloween armor`.
5. **Majority wins** where copies disagree: `Steel Sword` (`&9`, grade 3 on 87 of 89), `Apple`
   (`&9` 4 vs `&f` 2), `Longbow` (`&6`/grade 2 on 3 of 5, `&b`/grade 4 on 2).
6. **Categories are inferred from material** (v1's `ProductCategory` isn't in the item data):
   swords/axes/bows/arrows → Weapons, armor pieces → Armor, pickaxes → Tools, edibles → Food,
   the rest → Resources; `Life amulet` → Trinkets by hand.
7. **Grade names 3–5** (Rare/Epic/Legendary) are new — v1 had only star counts.
8. **v1 quirks carried over as-is:** `Cooked Salmon` is `cooked_cod` (v1 used `cooked_fish:0`);
   vanilla levels above vanilla caps (Power 6, Protection 6, Unbreaking 6, Sharpness 5 on pickaxes)
   — the plugin applies vanilla enchantments unsafely.
9. **Not recovered:** prices, descriptions, origins, v1 soulbound/ghosted semantics.
