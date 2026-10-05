# Item render pipeline — one path from blueprint to item

**Status:** Implemented and merged to knk-plugin `main` 2026-10-05 (`74607a9`); developer smoke test passed (see the lootboxes plan, "Smoke test results — 2026-10-05"). The pipeline itself existed since lootboxes Phase 0; the single `assemble` entry point and the decoy/colour changes are new in that merge
**Last updated:** 2026-10-05
**Why this exists:** developer request 2026-10-05 — all lore colouring, custom-enchantment rendering and grade/origin rendering should be applied in one spot, so a route that spawns an item can't render it differently from the others.
**See also:** [lootboxes design §3.4/§3.9](../specs/lootboxes/DESIGN.md), [enchantment books](../specs/enchantment-books/ENCHANTMENT_BOOK_APPLICATION.md), [items plan](../specs/items/IMPLEMENTATION_PLAN.md), [kits](../specs/kits/DESIGN.md)

## 1. The rule

An item that a player can hold and that comes from an `ItemBlueprint` is made by **`BlueprintItemAssembler`** (`knk-paper/.../item/`), nowhere else. Callers never call `ItemBlueprintBukkitMapper.fromBlueprint` + `enchant` by hand; they call one of:

| Entry point | For | Does |
|---|---|---|
| `assemble(blueprint, materialKey, defaults, rolled, rolledOptions, quantity)` | anything with rolled enchantments or an instance stamp (lootbox drops, reel decoys) | build → `defaults` as authored → `rolled` with `rolledOptions` (second pass skipped when nothing to roll or stamp) → quantity |
| `assembleDefaults(blueprint, materialKey, fetchedDefinitions, quantity)` | kits, `/knk itemblueprints give` | `assemble` with the blueprint's own default enchantments (`defaultEnchantments`) and nothing rolled |

(`assemble(blueprint, key, enchantments, options)` and `assembleWithDefaults(…, options)` — the older single-pass forms — remain, used by tests.) Helpers: `maxStackSize`, `applyQuantity`, `defaultEnchantments`.

## 2. What happens, in order

1. **`ItemBlueprintBukkitMapper.fromBlueprint`** (the assembler's item factory): material, display name, **description lore**, grade star line, origin line, `ItemLoreLayout.compose` spacing, `knk_grade` tag, permanent enchantment-book decoration (`EnchantBookItems.decorate`).
2. **`BlueprintItemAssembler.enchant`**, once for the defaults (as authored, no vanilla rules) and once for rolled enchantments (vanilla `canEnchantItem`/`conflictsWith` rules on): vanilla enchantments via `addUnsafeEnchantment`; custom enchantments as lore lines through `EnchantmentRepository.applyEnchantment`, then `CustomEnchantmentLore.enchantmentsFirst` (custom lines on top, then description, then Grade/Origin; blank-line spacing from `ItemLoreLayout`). Books never get enchantments (they teach one).
3. Optional **meta stamp** (lootbox `knk_item_instance` tag; stackables get none).
4. **Quantity** (`applyQuantity`: at least 1, at most the blueprint's own max stack, else the material's).

Skipped enchantments are reported in `Result.skipped()`, never thrown.

### Colours (one place each)

| Line | Colour | Where |
|---|---|---|
| Description | **dark gray `&8` by default**; a colour the description sets itself wins (`&7…` stays gray) | `ItemBlueprintBukkitMapper.DESCRIPTION_COLOR` (2026-10-05; before, uncoloured lines were vanilla's purple lore) |
| Custom enchantment lines | `§7` + display name + roman level | `LocalEnchantmentRepositoryImpl.formatLore` |
| Grade | `§l§b` "Grade: ★…" | `buildGradeLoreLine` |
| Origin | `§7` "Origin: name (type)" | `buildOriginLoreLine` |

Enchantment detection ignores colours (it matches the plain display name + level), so the description colour can't make a description line look like an enchantment or vice versa (test: `CustomEnchantmentLoreTest.aDarkGrayDescription…`).

## 3. Who spawns blueprint items (all go through §1)

| Route | Code | Entry point |
|---|---|---|
| Lootbox hand-over (world-box pickup + token open, `/knk lootbox give`, redelivery on join) | `LootboxDelivery.build` | `assemble` (claim defaults + rolled, vanilla rules, instance stamp, claim quantity) |
| Lootbox opening reel — the passing items | `LootboxDelivery.decoy` | `assemble` (blueprint defaults + freshly rolled enchantments, vanilla rules, no stamp) — see lootboxes design §3.9 |
| Kit grants | `KitGrantPlacer.buildResolvedItem` | `assembleDefaults` (slot quantity for content slots); on an unexpected exception it falls back to the plain built item |
| `/knk itemblueprints give <id> <player>` | `ItemBlueprintsDebugCommand.executeGive` | `assembleDefaults` (fetched definitions from the payload) |

Display-only, step 1 only: the **items catalogue** menu (`CatalogItemRow` → `fromBlueprint` directly; icons, no enchantments). **Menu icons** built from blueprints elsewhere use the menu engine's own lore rendering (`ItemBlueprintMenuMapper` → bindings), which is not an item a player can obtain.

## 4. Editing an existing item's lore (same custom-enchantment pipeline)

`CustomEnchantmentLore` is the one way to put a custom enchantment on, or take one off, an existing item:

| Route | Call |
|---|---|
| Enchantment books (`EnchantBooks.apply`) | `CustomEnchantmentLore.apply` |
| `/ce add`; the enchantment-definitions debug command's `apply` (custom definitions) | `CustomEnchantmentLore.apply` (2026-10-05: these were the last two inline copies) |
| `/ce remove` | `CustomEnchantmentLore.remove` (2026-10-05: previously left a stray blank line when the last enchantment went) |

`/knk item lore …` is a deliberate raw admin edit (no re-compose).

## 5. Not blueprint items (own, hard-coded lore on purpose)

Lootbox **token** items (`LootboxTokenDelivery.build`), **siege enchant books** (`SiegeEnchantBooks`, Adventure components), clan **banners**, the lootbox **world box** display entity, and every **menu** item (`MenuItemBukkitMapper`/`MenuRenderer`). They never take the description default or enchantment lines.

## 6. Rules for new code

- Making an item from a blueprint? Call `assemble` / `assembleDefaults`. Don't call `fromBlueprint` + `enchant` yourself, and don't set lore on the result.
- Adding or removing a custom enchantment on an existing item? `CustomEnchantmentLore.apply` / `remove`, never `repository.applyEnchantment`/`removeEnchantment` directly.
- A new lore section (like Grade/Origin)? Add it in `ItemBlueprintBukkitMapper` and let `ItemLoreLayout.compose` place it.
- Tests: `BlueprintItemAssemblerTest` (the assembler), `ItemBlueprintLoreColorTest`, `CustomEnchantmentLoreTest`, `LootboxDeliveryTest` (drops and decoys).

## 7. History

- KNG-5 (2026-09-26): `CustomEnchantmentLore` introduced (books skipped the "enchantments first" reorder).
- KNG-29 (2026-10-04): stable lore section spacing (`ItemLoreLayout`); Flaming Samurai's inline `&7` removed — which, as found 2026-10-05, made its description vanilla purple, since the plugin applied no colour.
- 2026-10-05: description default `&8`; reel decoys built through the assembler; single `assemble` entry point adopted by kits, `give` and lootboxes; `CustomEnchantmentLore.remove`; `/ce add` and the debug command use `CustomEnchantmentLore.apply`.
