# Item render pipeline — one path from blueprint to item

**Status:** Implemented and merged to knk-plugin `main` 2026-10-05 (`74607a9`); developer smoke test passed (see the lootboxes plan, "Smoke test results — 2026-10-05"). The pipeline itself existed since lootboxes Phase 0; the single `assemble` entry point and the decoy/colour changes are new in that merge
**Last updated:** 2026-11-04 (shield banner patterns and armour trims on blueprints and instances, [#232](https://github.com/PandiO/knk-workspace/issues/232): merged and smoke-tested, § 2c); 2026-11-03 (lore line wrap, [#212](https://github.com/PandiO/knk-workspace/issues/212), and scan `descriptionLore`, [#40](https://github.com/PandiO/knk-workspace/issues/40): merged 2026-11-02 to knk-plugin `main` `27798ab` and knk-web-app `main` `b770597`; developer smoke test accepted 2026-11-03); 2026-10-18 (KNG-175 merged to knk-plugin `main` `147806d8`); 2026-10-15 (items catalogue goes through `assembleDefaults`, [KNG-175](https://linear.app/kngpandi/issue/KNG-175))
**Linear:** [KNG-54](https://linear.app/kngpandi/issue/KNG-54) (Done)
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

1. **`ItemBlueprintBukkitMapper.fromBlueprint`** (the assembler's item factory): material, display name, **description lore** (each line wrapped, § 2a), grade star line, origin line (wrapped), `ItemLoreLayout.compose` spacing, `knk_grade` tag, **shield banner and armour trim** (§ 2c), permanent enchantment-book decoration (`EnchantBookItems.decorate`).
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

### 2a. Lore line wrap ([#212](https://github.com/PandiO/knk-workspace/issues/212))

One helper, **`LoreWrap`** (`knk-core/.../core/util/`), keeps every lore line within a maximum width. Choices made (developer defaults, 2026-11-02):

| Question | Choice |
|---|---|
| How to measure | **Visible characters** (code points); legacy colour/format codes (`§x`/`&x`, hex `§x§r§r§g§g§b§b`) don't count. `&` only counts as a code before a valid code character (`Salt & Pepper` is text). Pixel width (Minecraft's font is proportional) is not used: it would need the client's font table, and 40 characters stays inside the normal tooltip for ordinary text. |
| Maximum width | **40**, configurable as `lore.max-width` in the plugin's `config.yml` (read at startup, minimum 10). The kits menu keeps its own narrower 32 for the kit description and #172's 40 for "Other contents". |
| Colours | A continuation line starts with the **colour and formats active where the line broke** (`&c…` stays red, `§7§l…` stays gray bold, hex colours too; after a `§r` nothing is carried). |
| Long words | Lines break **only at spaces**; a single word **longer than the width** (long names, URLs) is **hard-broken** into pieces of exactly the width. A word that fits is never split. |
| Lines that fit | Returned **unchanged** (same string), so wrapping twice is a no-op and blank spacer lines stay. |

Where it runs:

| Lore | Code |
|---|---|
| Blueprint item description lines and the origin line (every route in § 3) | `ItemBlueprintBukkitMapper.buildLore` / `fromBlueprint` |
| Every menu item's lore (all menu-engine content: kits, items catalogue, teleport, profile, leaderboards, …) | `MenuItemBukkitMapper.applyLore`, after the `&` → `§` translation |
| Kits menu row: description (32), rank-rule / requirement and other status lines, #172's "Other contents" (`truncate` + `packItems`, items never split, capped with "… and N more") | `KitMenuRow` |

Custom-enchantment lines and the grade line are not wrapped (they are short, and enchantment detection matches a whole line). Hard-coded lore outside the menu engine (§ 5) is not wrapped. The items catalogue preview and kit grants go through `fromBlueprint`, so they get the wrap (and the tag) too.

**The wrap is never scanned back.** When the wrap changes a blueprint item's description, `fromBlueprint` stamps the authored lines (before the wrap) in the PDC tag **`knightsandkings:knk_description`** (`ItemDescriptionTag`). Items whose description fits get no tag, so they still stack with copies built earlier. A scan returns the tag's lines when the item's description lines still show the same text (whitespace and codes ignored, so a later `lore.max-width` change doesn't matter). If the text was edited by hand since, it falls back to `LoreWrap.unwrap`, the inverse of the wrap by width: two neighbouring lines are joined when the second can only be a continuation. That means the first fits the width, the second starts in the formatting the first ended in, and either the second's first word would not have fit after the first (joined with a space) or the first is a hard-broken piece (exactly the width, no space; joined without one). That fallback can also join two authored lines that happen to meet these rules. Wrapping the joined line again at the same width gives the same two lines, so the item looks the same, but the stored line break is lost. Avoiding that is why the tag exists.

### 2b. Scanning an item back into a blueprint ([#40](https://github.com/PandiO/knk-workspace/issues/40))

`ScannedItemJsonBuilder` (ItemScan and KitScan) sends the raw `lore` and, next to it, **`descriptionLore`**: `ItemLoreLayout.descriptionLines` (drops blank spacers, lines the custom-enchantment repository recognises, and everything from the first `Grade:` or `Origin:` line on). When the item carries the `knk_description` tag (§ 2a), the tag's authored lines are sent instead; without a tag the lines go as they are (the plugin didn't wrap them). The web app's FormWizard (`applyItemScanResult`, and KitScan's blueprint creation) fills Display description from `descriptionLore` when present, else from the raw lore (`src/utils/scannedItemDescription.ts`). Scan → save → build gives the same lore again (test `ItemScanDescriptionLoreTest`).

Enchantment detection ignores colours (it matches the plain display name + level), so the description colour can't make a description line look like an enchantment or vice versa (test: `CustomEnchantmentLoreTest.aDarkGrayDescription…`).

### 2c. Shield banner patterns and armour trims ([#232](https://github.com/PandiO/knk-workspace/issues/232))

**Status:** merged 2026-11-04 (knk-web-api `master` `93f9380`, knk-plugin `main` `497e0fe`, knk-web-app `main` `4dd11d0`); developer smoke test the same day, shield pattern checks passed, armour trim accepted ([guide](../guides/shield-banner-trim-smoke-test.md)).

A shield's banner and an armour piece's trim are stored data, not lore, and round-trip scan → save → build like the description:

| Where | Shield banner | Armour trim |
|---|---|---|
| **knk-web-api** `ItemBlueprint` | `ShieldBannerBaseColor` (`BannerDyeColor?`, the shield's own colour) + child table `item_blueprint_banner_layers` (`ItemBlueprintBannerLayer`: `SortOrder`, `PatternKey`, `Color`; bottom to top, same shape as the clan `BannerLayer`) | `ArmorTrimPattern` + `ArmorTrimMaterial` (registry keys, both or neither) |
| **knk-web-api** `ItemInstance` | the same two, copied from the blueprint at mint and **frozen** like `GradeId` (`item_instance_banner_layers`); `/knk item more` clones copy the source's | same |
| **API DTOs** | `shieldBannerBaseColor` + `shieldBannerLayers: [{patternKey, color}]` on the blueprint read/create/update DTOs, the instance DTO and the lootbox claim result (the instance's copy, else the blueprint's) | `armorTrimPattern` + `armorTrimMaterial` on the same DTOs |
| **Validation** (`Services/ItemAppearanceRules.cs`) | any casing; bare or namespaced keys (`BannerPatternKeys.Normalize`); layers without a base colour get `WHITE` (Minecraft's shield default); an unknown colour or pattern is a **400**, never dropped | `ArmorTrimKeys` mirrors the `trim_pattern`/`trim_material` registries (paper-api 26.3); a trim needs both keys |
| **knk-plugin** build | `ItemAppearanceBukkitMapper.applyShieldBanner` in `fromBlueprint`: `ShieldMeta.setBaseColor` + `setPatterns` through `BannerPatternSpec` and `BannerDesignBukkitMapper.toLayers` (the clan/menu banner path, so every banner renders one way); a banner **item** gets the layers only (its colour is the material); other metas are left alone | `applyArmorTrim`: `ArmorMeta.setTrim(new ArmorTrim(material, pattern))` on armour metas |
| **knk-plugin** lootbox drop | `LootboxDelivery.withClaimLook`: the claim's look (the instance's frozen one) replaces the cached blueprint's before the build, like `withClaimGrade`; a claim from an API without the fields changes nothing | same |
| **knk-plugin** scan (`ScannedItemJsonBuilder`) | `shieldBanner: {baseColor, layers}` only when the item has one (`ItemAppearanceBukkitMapper.readShieldBanner`) | `armorTrim: {pattern, material}` only when trimmed |
| **knk-web-app** form (`ItemBlueprint.json` seed, "Item in game" step) | `ShieldBannerBaseColor` (Enum) + `ShieldBannerLayers` (new field type **`BannerLayers`**: ordered rows of pattern and colour, bottom first, `BannerLayersField`; pattern list from `GET /api/BannerDesigns/pattern-keys`, bundled fallback) | `ArmorTrimPattern` + `ArmorTrimMaterial` (String) |
| **knk-web-app** scan | `applyItemScanResult` fills the four fields from `shieldBanner`/`armorTrim` (`src/utils/scannedItemLook.ts`), clears them for a plain item, and asks first when the form already holds a look; KitScan's blueprint creation sends them too | |
| **knk-web-app** instance detail | `ItemInstanceDetail` shows "Shield banner" and "Armour trim" rows when the instance has them | |

A pattern or trim key the running server doesn't know (authored for a newer version) is skipped with a warning and the rest of the item is built, as `BannerDesignBukkitMapper` does for clan banners. The developer's armour trim check (#232): no trim support existed in any repo before this change; it was added here.

## 3. Who spawns blueprint items (all go through §1)

| Route | Code | Entry point |
|---|---|---|
| Lootbox hand-over (world-box pickup + token open, `/knk lootbox give`, redelivery on join) | `LootboxDelivery.build` | `assemble` (claim defaults + rolled, vanilla rules, instance stamp, claim quantity) |
| Lootbox opening reel — the passing items | `LootboxDelivery.decoy` | `assemble` (blueprint defaults + freshly rolled enchantments, vanilla rules, no stamp) — see lootboxes design §3.9 |
| Kit grants | `KitGrantPlacer.buildResolvedItem` | `assembleDefaults` (slot quantity for content slots); on an unexpected exception it falls back to the plain built item |
| `/knk itemblueprints give <id> <player>` | `ItemBlueprintsDebugCommand.executeGive` | `assembleDefaults` (fetched definitions from the payload) |
| Items catalogue menu (`items.catalog`), display only | `CatalogItemRow.menuItemStack` | `assembleDefaults` (the full blueprint's own default-enchantment rows, no extra fetch; no quantity), so the preview is the item a player gets ([KNG-175](https://linear.app/kngpandi/issue/KNG-175); until 2026-10-15 it used `fromBlueprint` only and showed no enchantments) |

**Menu icons** built from blueprints elsewhere use the menu engine's own lore rendering (`ItemBlueprintMenuMapper` → bindings), which is not an item a player can obtain.

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
- A long lore line? Don't wrap by hand: menu lore and blueprint descriptions already go through `LoreWrap` (§ 2a); for other lore call `LoreWrap.wrap`/`wrapAll` (configured width) rather than a local wrap.
- A shield's pattern or an armour trim? It is data on the blueprint/instance (§ 2c), applied by `ItemAppearanceBukkitMapper` inside `fromBlueprint`; never set `BannerMeta`/`ArmorMeta` by hand on a blueprint item.
- Tests: `BlueprintItemAssemblerTest` (the assembler), `ItemBlueprintLoreColorTest`, `CustomEnchantmentLoreTest`, `LootboxDeliveryTest` (drops and decoys, the claim's look), `LoreWrapTest` (wrap/unwrap), `ItemScanDescriptionLoreTest` (scan of a built item), `ItemAppearanceBukkitMapperTest` + `KnkShieldBannerTest` + `ItemAppearanceMapperTest` (§ 2c; applying a real pattern/trim needs the server registries and is the in-game smoke test).

## 7. History

- 2026-11-04 ([#232](https://github.com/PandiO/knk-workspace/issues/232); merged, smoke test accepted the same day): shield banner patterns (base colour + layers) and armour trims stored on blueprints and instances, applied in `fromBlueprint`, scanned back, edited in the web app (§ 2c).

- KNG-5 (2026-09-26): `CustomEnchantmentLore` introduced (books skipped the "enchantments first" reorder).
- KNG-29 (2026-10-04): stable lore section spacing (`ItemLoreLayout`); Flaming Samurai's inline `&7` removed — which, as found 2026-10-05, made its description vanilla purple, since the plugin applied no colour.
- 2026-10-05: description default `&8`; reel decoys built through the assembler; single `assemble` entry point adopted by kits, `give` and lootboxes; `CustomEnchantmentLore.remove`; `/ce add` and the debug command use `CustomEnchantmentLore.apply`.
- 2026-11-02 ([#212](https://github.com/PandiO/knk-workspace/issues/212), [#40](https://github.com/PandiO/knk-workspace/issues/40); merged, smoke test accepted 2026-11-03): shared `LoreWrap` (§ 2a) for blueprint descriptions/origin, every menu's lore and the kits menu (#172's "Other contents" moved onto it); scans send a cleaned `descriptionLore` without generated lines and with the wrap joined back (§ 2b).
