# Enchantment books outside siege — design and implementation plan

**Status:** Implemented on `claude/linear-backlog-access-4cr50w` (knk-plugin `ba74efe`, knk-web-api `638b50e`);
knk-paper code not compiled in the cloud container (see §6), in-game test open. Tracks Linear **KNG-5**; the level cap is **KNG-6**.
**Last updated:** 2026-09-26 (initial version, written alongside the implementation. The earlier
local-only draft this path was reserved for was never committed; this replaces it.)

## 1. Goal

v1 and v2 both let a player use a special enchanted book to put its enchantment on an item in their own
inventory; the book is consumed. v3 has this only on the unmerged `claude/siege-minigame` branch, and there
it is siege-scoped: match-locked, non-persistent, vanilla-only, and reverted after the match.

KNG-5 asks for a **permanent** variant that works anywhere, including for custom (Knk) enchantments. The
decisions below were recorded on the Linear issue on 2026-09-26:

| Decision | Choice |
|---|---|
| Where books come from | `ItemBlueprint`s: a book is an item blueprint like any other |
| Restrictions | Same as the siege version: compatible, not conflicting, must be an improvement. The v1 grade cap is deferred to KNG-6 |
| Custom enchantments | In scope (Poison, Chaos, ...) |
| Vanilla ↔ custom bridging | Reuse `EnchantmentDefinitionBukkitMapper` (as `EnchantmentDefinitionsDebugCommand` does) |

## 2. Deviation from the issue: port the pattern, don't cherry-pick the files

KNG-5 asked to cherry-pick `SiegeEnchantBooks`, `SiegeEnchantBookListener`, `SiegeEnchantMarkers` and
`EnchantDropPlanner` onto trunk. These files **can't be cherry-picked on their own**:

- `SiegeEnchantBooks` is a `SiegeMatchObserver` that depends on `SiegeService`, `SiegeMatch`,
  `SiegeLobbyRuntime`, `KnkSiegeConfiguration`, `KnkSiegeObjective`, `SiegeObjectiveBoard`, `ObjectiveState`
  and `SiegeBukkit`.
- `SiegeEnchantBookListener` and `SiegeEnchantMenu` depend on `SiegeMessages`.
- `EnchantDropPlanner` and `SiegeEnchantMarkers` only matter for siege (drops, reverting).

Taking "whatever they depend on" would bring most of the siege module onto trunk. It would also create
add/add merge conflicts with the siege overnight chain, which is still editing those files on
`claude/siege-minigame`.

So instead, the **siege-agnostic parts** (the apply check, the cursor-click apply, the right-click item
chooser) are ported as new, generic classes. The siege files stay untouched on their own branch. When siege
merges to trunk, `SiegeEnchantBooks.evaluate` can delegate its compatible/conflict/improvement checks to
`EnchantBookRules` (a follow-up, not required).

## 3. Design

### 3.1 What makes an item a permanent enchantment book

An `ItemBlueprint` whose material is `minecraft:enchanted_book` and which has at least one
`DefaultEnchantment`. The **first** default enchantment is the one the book teaches; any others are ignored
and logged. No new DB columns, tags or categories are needed: an admin makes a book in the web app the same
way as any other item.

`ItemBlueprintBukkitMapper.fromBlueprint` is the single place every surface builds items from blueprints:
kit grants (`KitGrantPlacer`), the `items.catalog` menu (`CatalogItemRow`) and `/knk itemblueprints give`.
It now turns such a blueprint into a book:

- a PDC tag `knightsandkings:knk_enchant_book` holding the encoded `EnchantBookPayload`
  (`vanilla;minecraft:sharpness;3` or `custom;poison;2`). This tag is the only source of truth;
- a lore line `Teaches: Sharpness III` and two how-to-use lines;
- a forced enchantment glint.

The book deliberately has **no** vanilla stored enchantment (`EnchantmentStorageMeta`). That keeps it out
of the vanilla anvil, so it can't bypass the KNG-6 cap later or reach levels above the vanilla maximum.

The `Teaches:` prefix is also deliberate. `LocalEnchantmentRepositoryImpl` treats any lore line shaped
`<Custom Name> <Roman>` as a live custom enchantment. A book whose lore read `Poison II` would therefore
poison people when used as a weapon.

`/knk itemblueprints give` normally applies the blueprint's default enchantments to the item itself. It now
skips that step for books; otherwise the book would carry the enchantment itself.

Resolving the enchantment uses `EnchantmentDefinitionBukkitMapper`:

- `toBukkit` for vanilla;
- `toCustom` for custom (`isCustom = true`).

The mapper resolves from a definition built out of the blueprint's denormalized default-enchantment fields
(`fromDefaultEnchantment`). This was extracted from `ItemBlueprintsDebugCommand.mapFallbackDefinition`, which
now calls it. Building a book therefore needs no extra API round trip and stays synchronous.

### 3.2 Applying a book

There are two ways, both ported from siege:

1. **Cursor onto an item:** hold the book on the cursor and left- or right-click an item in your own
   inventory.
2. **Right-click chooser:** right-click with the book in hand. A chest-style chooser lists every item in your
   inventory the book can go on; click one to apply the book.

The check is `EnchantBookRules.evaluate` (knk-core, pure, unit-tested), fed with facts the Paper side reads
from the item. It returns the first result that applies:

| Result | When |
|---|---|
| `INVALID_BOOK` | Not a permanent book; payload missing, malformed, or the enchantment isn't known on this server |
| `NOT_ENCHANTABLE` | Target is air, a book, or an enchanted book; or vanilla `canEnchantItem` is false; or, for a custom enchantment, the target is not gear (no durability) |
| `CONFLICT` | Vanilla only: the book's enchantment conflicts with one the target already has |
| `NO_IMPROVEMENT` | New level `max(existing, book)` is not above the existing level |
| `APPLIED` | Otherwise |

On `APPLIED`:

- **vanilla:** `addEnchant(enchantment, level, ignoreLevelRestriction = true)`, the same unsafe policy as the
  v1 seed data and `/knk itemblueprints give`;
- **custom:** `EnchantmentRepository.applyEnchantment` on the lore (replaces an existing line or appends one);
- one book is consumed.

Nothing is written into the siege PDC keys (`siege_book`, `siege_enchants`). The siege stripping sweep only
matches those keys, so permanent results are exempt by construction.

**Custom-enchantment target rule** (new; neither v1 nor the debug commands had one): the target must be gear,
i.e. `Material.getMaxDurability() > 0` (weapons, tools, armor, bows, shields ...). Custom effects fire from
combat and interaction on held or worn items, so a Poison stick of bread makes no sense. The rule is one line
in `EnchantBookRules`; loosen it there if needed.

### 3.3 Seed data (knk-web-api)

`EnchantBookSeed` follows the same create-only, natural-key convention as `ItemBlueprintV1Seed`. It runs after
the V1 seed (it reuses the vanilla `EnchantmentDefinition`s that seed creates) and creates:

- a `Enchantment Books` category, with an `minecraft:enchanted_book` material ref;
- one blueprint per (enchantment, level): every custom enchantment at every level up to its max, plus a small
  vanilla set (Sharpness, Protection, Efficiency, Unbreaking, Power) up to the vanilla max.

Blueprints are named `Enchanted Book (Poison II)`.

An enchantment definition that doesn't exist yet is logged and skipped, never invented. For example, a
vanilla one the V1 seed didn't create on a DB where it ran before this seed existed.

### 3.4 Out of scope

- **KNG-6 grade cap.** Its formula is decided (v1's `maxLevel / (6 - grade)` for grades 1–5, uncapped for
  6–10, divisor configurable per grade). But the `Grade.EnchantLevelCapDivisor`/`DropChance` patches from
  that session were never committed. When KNG-6 is implemented, the cap belongs in `EnchantBookRules.evaluate`
  as one more check before `NO_IMPROVEMENT`, fed from the target item's grade.
- Siege book behavior: unchanged, it lives on `claude/siege-minigame` only.
- Web app: no change needed. Blueprints with default enchantments are already editable there.

## 4. Implementation plan

| # | Repo | Change | State |
|---|---|---|---|
| 1 | knk-plugin / knk-core | `core/enchantbook/EnchantBookPayload` (encode/decode) and `EnchantBookRules` (apply decision) + unit tests | done |
| 2 | knk-plugin / knk-paper | `EnchantmentDefinitionBukkitMapper.fromDefaultEnchantment`; debug command reuses it | done |
| 3 | knk-plugin / knk-paper | `paper/enchantbook/EnchantBookItems`: static tag, build from blueprint, read payload | done |
| 4 | knk-plugin / knk-paper | `ItemBlueprintBukkitMapper.fromBlueprint` builds books; `/knk itemblueprints give` skips default enchantments on books | done |
| 5 | knk-plugin / knk-paper | `paper/enchantbook/EnchantBooks` (evaluate/apply), `EnchantBookMenu` (chooser), `listeners/EnchantBookListener`; wired in `KnKPlugin` after the enchantment runtime | done |
| 6 | knk-web-api | `Models/Item/EnchantBookSeed.cs` + `Program.cs` call + seed tests | done |
| 7 | — | In-game test on the dev server (see §5) | **open, needs the developer's PC** |

## 5. Manual test checklist (dev server)

1. Start the API on a fresh DB, or on an existing one (the seed is additive). The log should read
   `EnchantBookSeed complete. Created: ...`.
2. `/knk itemblueprints search name Enchanted Book` lists the books.
3. `/knk itemblueprints give <id>` for `Enchanted Book (Sharpness III)`. The book glints and shows
   `Teaches: Sharpness III`.
4. Right-click it. The chooser lists only swords and axes. Click one: the sword gets Sharpness III and the
   book is gone.
5. Put a book on the cursor and click it onto a pickaxe. You should see "That enchantment can't go on this
   item." and the book stays.
6. `Enchanted Book (Poison II)` onto a diamond sword: the sword lore shows `Poison II` and hits apply poison.
   Onto bread: refused.
7. Hit a mob holding the Poison book itself: no poison effect.
8. Put the book in an anvil with a sword: no result (no stored enchantment).
9. Apply a lower-level book onto a higher-level item: "already has that enchantment at this level or higher".

## 6. Verification state

- knk-core `enchantbook` classes and their tests: compiled and run in a scratch build, using Maven Central only
  and JUnit 5; the same method the siege chain used.
- knk-paper changes: **not compiled**. The cloud network policy denies `repo.papermc.io` (paper-api) and
  `maven.enginehub.org`, so Gradle can't resolve dependencies. Run `./gradlew build` locally before merging.
- knk-paper, partial check: the new and changed files that don't need the whole plugin (`enchantbook/*`,
  `EnchantBookListener`, both mappers) were type-checked against hand-written Bukkit stubs plus the real
  Adventure jars. This catches typos and type errors, not Paper API drift. The only Paper call not already used
  elsewhere in the codebase is `ItemMeta#setEnchantmentGlintOverride` (Paper 1.20.5+).
- knk-web-api: `dotnet build` passes. `dotnet test`: 506/511, with 5 new `EnchantBookSeedTests` all green. The
  5 failures are the known pre-existing ones (ClientActivityStore, 2× PathResolution `Town.*`, FieldValidation
  ConditionalRequired, FormSubmissionProgressRepository). Baseline before this change was 501/506.
- No EF migration is needed; the seed only adds rows.
