# Kits — Seed Data (from legacy v2 dev DB backup)

**Source:** `knightsandkings_dev_backup_19_10_21.json` (phpMyAdmin export, v2 dev database,
2021-10-19), tables `category`, `category_tags`, `grade`, `item`, `itemtype`, `kit`,
`kit_contents`, `tag`. `item_description` and `item_origin` were both empty in this backup.

**Framing — this is dev/example content, not final live-game balance.** The tags present
(`Open Beta`, `Test`) and one item name (`Maggoty Bread`, clearly a placeholder/joke item) confirm
this was v2's development seed data, not tuned production content. Treat it as a way to get a
working, verifiable Kit catalog end-to-end (Phase 6 of `IMPLEMENTATION_PLAN.md`) — not as the
final Open Beta kit roster, which is a separate balancing pass.

Legacy numeric ids below (e.g. `101000074`) are the v2 auto-increment primary keys, kept here only
to show provenance/relationships — v3's `ItemBlueprint`/`Kit`/etc. use their own fresh
auto-increment ids; nothing about the legacy id values themselves is preserved.

## 1. `Category` (seed 3 rows, if not already present)

| Name | IconMaterialRef (namespace key) |
|---|---|
| Weapons | `minecraft:iron_sword` |
| Armor | `minecraft:iron_chestplate` |
| Food | `minecraft:bread` |

(Legacy `category.itemtype_id` was each category's icon material — mapped above via the
`itemtype` table's `block_data`/`name`, since v3's `MinecraftMaterialRef` is keyed by namespace,
not v2's separate `Material`+`data` int pair.)

## 2. `Tag` (seed 4 rows, if not already present)

`Open Beta`, `Test`, `Melee`, `Protection`.

## 3. `CategoryTag` (join)

| Category | Tags |
|---|---|
| Weapons | Open Beta, Melee |
| Armor | Open Beta, Protection |
| Food | Open Beta |

## 4. `Grade` (seed 2 rows, if not already present)

| Name | Stars |
|---|---|
| Common | 1 |
| Uncommon | 2 |

## 5. `ItemBlueprint` (seed 9 rows)

All from the `item` table, cross-referenced against `itemtype` for material and `category`/`grade`
for the FK links. `display_name`'s `Â§7` prefix is a legacy encoding artifact of Minecraft's
`§7` (gray) color code — re-encode as a plain `§7` (or the modern component equivalent) in
`DefaultDisplayName`, not copied byte-for-byte.

| Name | DefaultDisplayName | IconMaterialRef | Category | Grade |
|---|---|---|---|---|
| Iron Sword | `§7Iron Sword` | `minecraft:iron_sword` | Weapons | Common |
| Iron Helmet | `§7Iron Helmet` | `minecraft:iron_helmet` | Armor | Common |
| Iron Chestplate | `§7Iron Chestplate` | `minecraft:iron_chestplate` | Armor | Common |
| Iron Leggings | `§7Iron Leggings` | `minecraft:iron_leggings` | Armor | Common |
| Iron Boots | `§7Iron Boots` | `minecraft:iron_boots` | Armor | Common |
| Maggoty Bread | `§7Maggoty Bread` | `minecraft:bread` | Food | Common |
| Wooden Bow | `§7Wooden Bow` | `minecraft:bow` | Weapons | Common |
| Arrow | `§7Arrow` | `minecraft:arrow` | Weapons | Common |
| Iron Axe | `§7Iron Axe` | `minecraft:iron_axe` | Weapons | Uncommon |

`DefaultQuantity`: set `Arrow` to `64` and every other row to `1` — informational only for these
seed rows (it's `ItemBlueprint`'s own "typical amount" field, used elsewhere in the catalog); it
has no bearing on `KitContent.Quantity` below, which is now a required, independently-set value
per slot (`DESIGN.md` §0a/§2.2), not a fallback derived from the template. No `BasePriceMin`/
`BasePriceMax`, `Tags`, or `Origins` in the source backup for these rows — leave unset; they're
independent, optional fields an admin can fill in later and aren't required for Kit to function.

**"Wooden Bow"/"Wooden Bow" material note:** the display name says "Wooden," but Minecraft has
only one `Bow` material (not a wood-type variant) — `itemtype` row 1000050 is plain `BOW` with no
`block_data`, confirming "Wooden" here is flavor text only, not a distinct material. No action
needed beyond using the plain `minecraft:bow` material — noted so it isn't mistaken for a missing
material mapping.

## 6. `Kit` (seed 2 rows)

### "Default"

| Field | Value |
|---|---|
| Helmet / Chestplate / Leggings / Boots | Iron Helmet / Chestplate / Leggings / Boots |
| Shield | *(none — legacy `shield_id` was null)* |
| Hand | Iron Sword |
| Contents | Maggoty Bread, Arrow, Wooden Bow, Iron Axe |
| GrantOnFirstJoin | `true` — recommended for the seed, standing in for v1's automatic starter kit (`DESIGN.md` §4.4); not present in the legacy `kit` table itself (v2 had no such flag), this is new for v3 |
| CooldownSeconds / CostAmount / gating fields | unset — freely claimable, no restrictions, matching legacy's actual (if accidental) behavior |

### "Archer"

| Field | Value |
|---|---|
| Helmet / Chestplate / Leggings / Boots | Iron Helmet / Chestplate / Leggings / Boots |
| Shield | *(none)* |
| Hand | **Maggoty Bread** |
| Contents | Wooden Bow, Arrow |
| Other fields | unset, same as Default |

**The Archer kit's hand slot is seeded verbatim, bread and all — confirmed with the developer.**
In the source backup, `kit.hand_id` for "Archer" (id `138000353`) points at Maggoty Bread
(`101000445`), not the Wooden Bow that's sitting right there in its own `contents` list — almost
certainly leftover test data from whoever was building this kit in the v2 dev environment (put
the bow in contents, forgot to also point `hand_id` at it, and the wizard's mandatory-hand-field
requirement forced *something* to be picked). Kept as-is per explicit instruction rather than
"corrected" to the bow, since this is seed/example data, not a real design intent to preserve —
if this kit is ever meant to be live-game content rather than a working example, fixing
`HandId` to the Wooden Bow at that point is the obvious change.

## 7. `KitContent` (6 rows, from `kit_contents`)

**Slot indices are not in the source backup — v2's `kit_contents` had no positional/slot concept
at all** (it was an unordered `@ManyToMany`, `DESIGN.md` §2.2's "why this changed" note). v3's
`KitContent` is keyed by `(KitId, SlotIndex)` (per `DESIGN.md` §0a), so seeding these rows means
*assigning* arbitrary slot numbers rather than recovering real ones — the values below are simply
sequential (9, 10, 11, ...), picked to land in the general storage grid rather than the hotbar
(0-8) so they don't collide with wherever a player's own hotbar items already are on grant. If
this seed content is ever promoted from example data to real live-game kits, revisiting these
slot placements deliberately (e.g. arrows in a hotbar slot next to the bow) is a reasonable
follow-up — nothing about the arbitrary seed values here is meaningful to preserve.

| Kit | SlotIndex | ItemBlueprint | Quantity |
|---|---|---|---|
| Default | 9 | Maggoty Bread | 1 |
| Default | 10 | Arrow | 64 |
| Default | 11 | Wooden Bow | 1 |
| Default | 12 | Iron Axe | 1 |
| Archer | 9 | Wooden Bow | 1 |
| Archer | 10 | Arrow | 64 |
