# Items — Grade scale, DropChance and the enchant-book level cap (Linear KNG-6)

**Status:** Implemented on `claude/adoring-dirac-p4pn54` (knk-web-api `3c0d7aa` + `70554f4`, knk-plugin
`8eaf977` + `d86b87b`), on top of KNG-5. knk-paper not compiled (the cloud blocks `repo.papermc.io`); in-game test open.
Decisions in §6 were made without a synchronous review and are flagged for the developer.
**Last updated:** 2026-09-26 (capped applies now ask for confirmation, knk-plugin `64f91ae`)

This note recreates the design note an earlier KNG-6 session wrote but never committed, and records what
this session built. The design itself (10 grades, v1's cap for 1-5, uncapped 6-10, a divisor per grade)
was decided on the Linear issue on 2026-09-26.

## 1. Summary

- Grades go from 5 to **10**. Each grade gets two new fields: `DropChance` (percent) and
  `EnchantLevelCapDivisor` (`int?`, configurable per grade in the web app, null = uncapped).
- A permanent enchantment book (KNG-5) can raise an item's enchantment only up to
  **`definitionMaxLevel / EnchantLevelCapDivisor`** (integer division, exactly as v1). Grades 1-5 use
  v1's divisors (5, 4, 3, 2, 1); grades 6-10 are fully uncapped: no formula at all.
- A book still has v1's **bonus level**: a configurable chance (default 20%) of one extra level, never
  above the cap.
- Items carry their grade as a PDC tag holding the grade's **stars**. The divisor is looked up live at
  click time, so retuning a grade in the web app also applies to items that already exist.

## 2. Grade table

| Stars | Name | DropChance | EnchantLevelCapDivisor |
|---|---|---|---|
| 1 | Common | 70% | 5 |
| 2 | Uncommon | 60% | 4 |
| 3 | Rare | 40% | 3 |
| 4 | Epic | 25% | 2 |
| 5 | Legendary | 15% | 1 |
| 6 | Mythic* | 8% | null (uncapped) |
| 7 | Ascended* | 5% | null |
| 8 | Relic* | 1% | null |
| 9 | Exalted* | 0.5% | null |
| 10 | Divine* | 0.05% | null |

\* Placeholder names, kept as decided. **Renaming is pending** (the developer's call; rename in the web app,
nothing in code depends on the names).

**Where the DropChance values come from.** v1's `Product.gradeChance()` (`knk-v1-archive`
`src/Products/Product.java` ~line 1801) used 70 / 60 / 40 / **5** / **1** for grades 1-5. Grades 1-3 match
v1 exactly. Grades 4 and 5 were deliberately re-spread to 25 / 15 when the scale grew to 10 (the old 5% and
1% now sit at grades 7 and 8). v1 also rolled `getRandom(0, 100) <= chance`, one percent more generous than
the number says.

**DropChance is carried, not used yet.** It is stored, exposed through the API and mapped into the plugin's
`KnkGrade.dropChance()`, but nothing rolls it yet. It is for the future loot/drop work.

## 3. The level cap

### 3.1 v1 source, verified

`knk-v1-archive` `src/Products/EnchantbookClick.java`, `canEnchant()` (lines 148-177) and `onInvClick()`
(lines 99-134):

```java
Integer maxEnchantLevel = Math.round((enchant.getEnchantmentMaxLevel(enchantmentID)/(6-product.getGrade(productID, false).intValue())));
...
if (currentEnchantLevel < maxEnchantLevel)
    for (int i = 1; i < maxEnchantLevel+1; i++)
        if (currentEnchantLevel+i <= maxEnchantLevel) enchantLevels = i;   // = maxEnchantLevel - current
...
} else { enchantLevels = 2; }                                           // not a vanilla enchantment
...
if (random.nextInt(100) <= 20 && enchantLevels >= 2) enchantLevel = 2;   // bonus
if (enchantLevels >= 1) { /* add enchantLevel to the current level */ }
else "This item reached the max. enchantmentlevel for this enchantment"
```

What that confirms:

1. **The formula** is `maxLevel / (6 - grade)` with two `int`s, so the division truncates *before*
   `Math.round` sees it. `Math.round` is a no-op. Unbreaking (max 3) on a 1-star item is `3 / 5 = 0`.
2. **Which max level:** v1's own `Enchantments.MaxLevel` column (`Enchantment.getEnchantmentMaxLevel`), i.e.
   the enchantment *definition's* max, not vanilla's. In v3 that is `EnchantmentDefinition.MaxLevel`.
3. **How the cap limits the result:** v1 books were *additive*. A book added +1 level (or +2 on the bonus
   roll) to the item's current level. `canEnchant` returns the headroom, `max(0, cap - current)`: a book
   is refused only when there is no headroom, and it never raises the item above the cap.
4. **The bonus:** `nextInt(100) <= 20` is 21 of 100 outcomes, so really **21%**, not 20%. It only fires
   when there are at least 2 levels of headroom, i.e. it too stays within the cap.
5. **Custom enchantments were never capped.** `getEnchantmentfromString` returns null for them, and that
   branch returns `enchantLevels = 2` unconditionally. They were only held at their own max level by
   `Product.addCustomEnchantment`.

### 3.2 v3 formula

v3 books (KNG-5) are *level-setting*, not additive: a book teaches e.g. "Sharpness III" and gives
`max(existing, book)`. The cap is translated to keep v1's two guarantees: never above the cap, and a book
is refused only when there is no headroom left.

```
cap      = definitionMaxLevel / divisor(grade)      // int division; null divisor → uncapped
if cap != null and existing >= cap  → LEVEL_CAPPED  (book kept)
result   = min(max(existing, bookLevel), cap)
if result <= existing               → NO_IMPROVEMENT (book kept)
else APPLIED at result; on a bonus roll: result + 1 if that is still <= (cap ?? definitionMaxLevel)
```

- `KnkGrade.capEnchantLevel(int)` (knk-core) is the formula; `EnchantBookRules.evaluate` (knk-core) runs
  the check as one more step before `NO_IMPROVEMENT`. The order is: `INVALID_BOOK`, `NOT_ENCHANTABLE`,
  `CONFLICT`, **`LEVEL_CAPPED`**, `NO_IMPROVEMENT`, `APPLIED`.
- **A book above the cap is applied at the cap, after a confirmation.** A Sharpness III book on a 1-star sword
  gives Sharpness I and is used up, matching v1, where a book could always add whatever headroom was left. It
  never happens by accident: the chooser marks such items "Grade limit: only up to I / Click to review", and
  clicking one opens a confirmation screen. That screen explains the item's grade, the highest level the grade
  allows, and what the book will actually give, with Apply / Cancel buttons (the developer's call after the
  2026-09-26 manual test; `EnchantBookMenu.ConfirmHolder`). Refusing such books outright would be one line in
  `EnchantBookRules.appliedLevel(Target, int)` and `evaluate`.
- **The bonus** is v1's +1 extra level, capped the same way. When uncapped (grades 6-10, custom
  enchantments) it stops at the definition max level: v1's highest cap (grade 5) was exactly the max level,
  so v1 never produced a level above the max either.

### 3.3 Worked examples

Cap per grade for each definition max level (grades 6-10: uncapped):

| Max level | Example enchantments | 1★ /5 | 2★ /4 | 3★ /3 | 4★ /2 | 5★ /1 |
|---|---|---|---|---|---|---|
| 1 | Mending, Silk Touch, Flame | 0 | 0 | 0 | 0 | 1 |
| 2 | Fire Aspect, Knockback | 0 | 0 | 0 | 1 | 2 |
| 3 | Unbreaking, Looting, Fortune | 0 | 0 | 1 | 1 | 3 |
| 4 | Protection, Feather Falling | 0 | 1 | 1 | 2 | 4 |
| 5 | Sharpness, Efficiency, Power | 1 | 1 | 1 | 2 | 5 |

A cap of 0 means the enchantment can't go on items of that grade at all. For example, Mending is
Legendary-only.

Scenarios (Sharpness, max 5):

| Item | Book | Result |
|---|---|---|
| 1★ sword, no Sharpness | III | Confirmation screen, then applied at **I** (capped), book consumed |
| 1★ sword, Sharpness I | any | `LEVEL_CAPPED`, book kept |
| 4★ sword, Sharpness I | V | Confirmation, then applied at **II** (capped) |
| 4★ sword, no Sharpness | I | Applied at I; bonus roll → II |
| 5★ sword, Sharpness III | IV | Applied at IV; bonus roll → V |
| 5★ sword, Sharpness III | II | `NO_IMPROVEMENT` (under the cap, just not better) |
| 7★ sword, Sharpness IV | V | Applied at V; bonus can't go past the max (V) |
| vanilla-crafted sword (ungraded → 1★) | V | Confirmation ("no grade, counts as Common"), then I |
| 1★ sword, Poison (custom, max 3) | II | Applied at II: custom enchantments aren't capped by default |

## 4. Where the target item's grade comes from

Before KNG-6, items built from blueprints only got a star lore line (`§l§bGrade: ★★★`) and no
machine-readable grade.

**Decision: a PDC tag holding the grade's stars, with the divisor looked up live.**

- `ItemBlueprintBukkitMapper.fromBlueprint` stamps `knightsandkings:knk_grade` (INTEGER = stars) through
  `ItemGradeTag.stamp`. It uses the blueprint's grade stars; when the blueprint came from the list endpoint
  (grade id + name only), it looks the stars up by id in the grade table. Every item surface goes through
  `fromBlueprint`: kit grants, the item catalog menu and `/knk itemblueprints give`.
- `GradeCatalog` (knk-core) is an in-memory grade table read synchronously in the click handler.
  `KnKPlugin` loads it from the API (`GradesDataAccess.listAsync`) at startup and every
  `grade-refresh-minutes` (default 10) on an async task. Until the first load succeeds, and for any star
  count the API doesn't have, it answers with the seeded defaults (`GradeCatalog.DEFAULTS`, the §2 table).
  So the cap never waits on the network and never silently turns off.
- Why stars and not the divisor: retuning a grade's divisor in the web app then applies to existing items
  within `grade-refresh-minutes`, with no need to reissue items. Freezing the divisor on the item would have
  been simpler but locks every existing item to the values at creation time. The live lookup stays
  synchronous, so the trade-off wasn't needed.
- Reading it back (`ItemGradeTag.stars`): the tag, else the stars on the `Grade:` lore line (`GradeLore`,
  for blueprint items built before this tag existed), else **ungraded**.

**The max level being divided** is the enchantment definition's (`EnchantmentDefinition.MaxLevel`, as v1).
The book carries it: `EnchantBookItems.decorate` stamps `knightsandkings:knk_enchant_book_max` from the
blueprint's default enchantment (`enchantmentMaxLevel`). Books built before KNG-6 fall back to the vanilla
`Enchantment#getMaxLevel` (vanilla) or the `EnchantmentRegistry` max (custom). Custom levels never go past
the registry max, because `EnchantmentRepository.applyEnchantment` silently ignores a higher one.

## 5. Configuration (knk-plugin `config.yml`)

```yaml
enchant-books:
  grade-cap:
    enabled: true              # false = no cap at all
    apply-to-custom: false     # v1 never capped custom enchantments
    ungraded-stars: 1          # grade assumed for items without one; 0 = uncapped
    bonus-level-chance: 0.20   # v1 was really 0.21 (nextInt(100) <= 20); 0 disables
    grade-refresh-minutes: 10  # how often the grade table is re-read from the API
```

The divisors themselves are *not* in config: they are per-grade DB fields (`Grade.EnchantLevelCapDivisor`),
editable in the web app. The API validates them to be at least 1, or empty for uncapped.

## 6. Decisions and edge cases (flagged for the developer)

| # | Case | Decision | Why / how to change |
|---|---|---|---|
| D1 | **Ungraded items** (vanilla-crafted, non-blueprint) | Treated as **grade 1** (most capped) | Otherwise vanilla gear is a loophole around the cap. `ungraded-stars` in config (0 = uncapped) |
| D2 | **Siege books** (`claude/siege-minigame`) | **Uncapped**, untouched | Their enchantments are temporary and reverted after the match. `SiegeEnchantBooks` has its own checks; this change never touches that branch |
| D3 | **Custom enchantments** | **Uncapped** by default (v1) | `apply-to-custom: true` caps them like vanilla ones |
| D4 | **Book level above the cap** | Applied at the cap after a **confirmation screen** explaining the cap; book consumed | Decided by the developer 2026-09-26 (was: applied silently). See §3.2 |
| D5 | **Bonus chance** | Configurable, default **20%** | v1 was 21% by an off-by-one; set `0.21` for exact v1 odds |
| D6 | **Grades 4-5 DropChance** | 25% / 15% as decided, not v1's 5% / 1% | Recorded in §2; retune in the web app |
| D7 | **Placeholder names 6-10** | Kept (Mythic, Ascended, Relic, Exalted, Divine) | Rename pending |

Other edge cases, handled:

- **Item already above its cap** (e.g. from the vanilla anvil or an older unsafe grant): `LEVEL_CAPPED` for
  any book of that enchantment. Nothing is taken away.
- **Cap 0** (low max level on a low grade): `LEVEL_CAPPED`, so the enchantment can't go on at all. The
  chooser doesn't list the item.
- **Grade table not loaded / API down:** seeded defaults are used and a warning is logged per failed refresh.
- **Grade retuned or deleted in the web app:** the new divisor applies on the next refresh. A star count
  that no longer exists live falls back to the seeded default for that star count. A star count outside
  1-10 with no live row is uncapped.
- **Two grades with the same stars:** the lowest id wins (plugin and `ItemBlueprintV1Seed` alike).
  `KitSeed` now also refuses to create a grade whose stars are already taken, so the seeds can't create the
  duplicate.
- **Web-app edits from an older Grade form:** the generic form only submits the fields on the form
  configuration. `GradeUpdateDto` records which fields the request actually contained, and `GradeService`
  only writes those. A rename through a pre-KNG-6 form therefore keeps the divisor, instead of making the
  grade silently uncapped. An explicit empty value still clears it.
- **The book item itself** has no grade effect: books are never targets (`NOT_ENCHANTABLE`).

## 7. Implementation

| Repo | Change |
|---|---|
| knk-web-api | `Models/Item/Grade.cs`: `DropChance` (`decimal(7,4)`, percent) and `EnchantLevelCapDivisor` (`int?`). `Dtos/GradeDtos.cs` (all five DTOs) and `Services/GradeService.cs` (create/update, validation, partial update). `Models/Item/GradeDefaults.cs`: the §2 table, used by both `KitSeed` and `ItemBlueprintV1Seed` (create-only; all 10 grades). Migration `20260926080330_AddGradeDropChanceAndEnchantCap`: both columns, with a backfill of grades 1-5 by stars in `Up` |
| knk-plugin / knk-core | `KnkGrade` (+2 fields, `capEnchantLevel`), `GradeCatalog`, `GradeLore`, `EnchantBookRules` (`LEVEL_CAPPED`, capped `appliedLevel`, `withBonus`), `EnchantBookCapSettings` |
| knk-plugin / knk-api-client | `GradeDto`, `GradeMapper`, `ItemBlueprintMapper` |
| knk-plugin / knk-paper | `mapper/ItemGradeTag` (new), `ItemBlueprintBukkitMapper` (stamps the tag), `EnchantBookItems` (stamps the definition max), `EnchantBooks` (cap + bonus), `EnchantBookMenu`/`EnchantBookListener` (capped-level hint and messages), `EnchantmentConfigManager` + `EnchantmentBootstrap` (settings), `KnKPlugin` (grade table refresh), `config.yml` |
| knk-web-app | No change needed: the Grade form is FormConfiguration-driven and the API metadata exposes the two new properties automatically (`decimal?` → Decimal, `int?` → Integer). An **existing** Grade form configuration must have the two fields added in the form builder before admins can edit them |

## 8. Verification

- knk-core: `KnkGradeTest`, `GradeCatalogTest`, `GradeLoreTest`, `EnchantBookCapSettingsTest` and the
  extended `EnchantBookRulesTest`: every grade 1-10 for both `capEnchantLevel` and the rules check. 74/74
  green in a scratch build (`javac` + JUnit console, Maven Central only). knk-api-client `GradeMapperTest`:
  3/3.
- knk-paper: **not compiled** (papermc/enginehub blocked). The touched enchantbook/grade/listener/config
  files were type-checked against hand-written Bukkit stubs plus the real Adventure jars. That catches typos
  and type errors, not Paper API drift. `EnchantmentBootstrap` and `KnKPlugin` edits were reviewed only.
- knk-web-api: `dotnet test` 733/738; the branch baseline before this change was 715/720, with the same 5
  known failures (ClientActivityStore, 2× PathResolution `Town.*`, FieldValidation ConditionalRequired,
  FormSubmissionProgressRepository). The migration was generated against, and run on, a local MySQL 8
  following the repo's "Migrations (fresh DB)" workflow: apply all, `has-pending-model-changes` (none), roll
  back to 0, re-apply. The backfill was checked on pre-existing grade rows 1-5 (and a 7-star row, left null).
