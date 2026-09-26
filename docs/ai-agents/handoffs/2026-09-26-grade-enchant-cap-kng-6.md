# Handoff — grade level cap for enchantment books + DropChance (Linear KNG-6)

**Status:** Code complete on `claude/adoring-dirac-p4pn54` in knk-web-api (`3c0d7aa`, `70554f4`) and
knk-plugin (`8eaf977`, `d86b87b`). Needs a local plugin build, the migration on the dev DB, and an in-game
test.
**Last updated:** 2026-09-26 (added `8508f41`, fixes from the KNG-5 manual test; see the enchant-book spec §6.1)

Design, v1 verification, worked examples and edge cases:
[`docs/specs/items/GRADE_DROPCHANCE.md`](../../specs/items/GRADE_DROPCHANCE.md). Enchant-book spec §3.4 has
the summary.

## ⚠ Branch base: read this before merging

The designated branch `claude/adoring-dirac-p4pn54` was created from **`claude/siege-minigame`** in
knk-plugin, knk-web-api and knk-web-app, not from trunk. Resetting it onto trunk would have needed a force
push, which this session wasn't allowed to do. So, as instructed, KNG-5
(`origin/claude/linear-backlog-access-4cr50w`) was **merged into** it. The branch therefore carries the
siege work (22 commits in knk-plugin, 16 in knk-web-api) plus KNG-5 plus KNG-6.

- **Don't merge this branch to trunk as-is** unless siege is going in too.
- To land KNG-6 on its own, cherry-pick just the KNG-6 commits onto `claude/linear-backlog-access-4cr50w`
  (KNG-5 = trunk + one commit):
  - knk-plugin: `8eaf977`, `d86b87b`, plus `8508f41` (KNG-5 manual-test fixes: creative cursor-apply and
    custom-enchantment lore order; it belongs to KNG-5 and cherry-picks onto that branch on its own). These touch
    no siege files; the `KnKPlugin.java` hunk should apply
    cleanly because it's next to the grades data-access setup, not the siege block.
  - knk-web-api: `3c0d7aa`, `70554f4`. The migration's `.Designer.cs` and the `KnKDbContextModelSnapshot.cs`
    hunk were generated on top of the siege schema, so a cherry-pick onto KNG-5 will conflict in the
    snapshot (and the Designer would describe siege tables). Cleanest: cherry-pick, drop the two migration
    files and the snapshot hunk, then re-run `dotnet ef migrations add AddGradeDropChanceAndEnchantCap`.
    After that, paste the backfill loop from this branch's migration (`Backfill` array + the `foreach` in
    `Up`) into the regenerated file. The `AddGradeDropChanceAndEnchantCapTests` test pins the class name
    and the SQL.
- knk-web-app and `claude/siege-minigame` itself were **not changed**.

## What to do next (at your PC)

1. **knk-plugin:** `./gradlew build`. knk-paper has never been compiled with these changes (the cloud
   blocks `repo.papermc.io`). Likely fix-ups, if any, are small API mismatches in `paper/enchantbook/*`,
   `mapper/ItemGradeTag` or `KnKPlugin.refreshGradeCatalog`.
2. **knk-web-api:** run it (or `dotnet ef database update`). Migration `AddGradeDropChanceAndEnchantCap`
   adds `grades.DropChance` / `grades.EnchantLevelCapDivisor` and backfills grades 1-5 by stars. On startup
   the seeds add grades 6-10 (Mythic … Divine). Check:
   `SELECT Stars, Name, DropChance, EnchantLevelCapDivisor FROM grades ORDER BY Stars;` → 10 rows, divisors
   5,4,3,2,1 then NULL×5.
3. **Web app:** if a Grade **form configuration** already exists, add the two new fields (`DropChance`,
   `EnchantLevelCapDivisor`) in the form builder to edit them. Until then, editing a grade through the old
   form keeps their values: the API only writes fields the request contains.
4. Walk through the in-game checklist below.
5. Decide the open items below, then close KNG-6.

## In-game test checklist (dev server)

Setup: `/knk itemblueprints search name Enchanted Book` lists the KNG-5 books. Use a Common (1★) blueprint
item (e.g. `Iron Sword` from KitSeed), an Epic (4★) and a Legendary (5★) one from the v1 seed (e.g.
`Diamond Sword` 4★, `Golemheart Sword` 5★; check the grade in the web app if the DB already had them). The server log should show `Grade table loaded (10 grades) for the enchant-book level cap`.

1. `/knk itemblueprints give` a **Common** Iron Sword. Check its PDC: `/data get entity @s SelectedItem
   components` shows `PublicBukkitValues` with `"knightsandkings:knk_grade": 1` under `minecraft:custom_data`.
2. Right-click `Enchanted Book (Sharpness III)`. The chooser lists the sword with "Grade limit: only up to
   I". Click it: the sword gets **Sharpness I**, the book is consumed, and the action bar says "applied at
   I, the most this item's grade allows".
3. Click a second Sharpness book onto that sword: "This item's grade doesn't allow that enchantment any
   higher." The book stays.
4. `Enchanted Book (Unbreaking I)` onto the Common sword: refused (`3 / 5 = 0`); the chooser doesn't list it.
5. **Epic** (4★) sword + `Sharpness V` book → Sharpness **II**.
6. **Legendary** (5★) sword + `Sharpness III` book → III. Repeat with a few fresh swords: about 1 in 5 get
   **IV** with "lucky, a bonus level". (Temporarily set `bonus-level-chance: 1.0` to see it every time.)
7. A **vanilla-crafted** iron sword (ungraded) + `Sharpness III` → Sharpness I (treated as grade 1).
8. `Enchanted Book (Poison II)` onto the Common sword → Poison II: custom enchantments aren't capped by
   default.
9. **Retune live:** in the web app, set Common's divisor to 1 (or empty). Within `grade-refresh-minutes`
   (default 10; restart to skip the wait), the *existing* Common sword accepts Sharpness III.
10. An item built **before** this change (no `knk_grade` tag, but a `Grade: ★★` lore line) is capped as
    2★ (lore fallback).
11. Set `enchant-books.grade-cap.enabled: false`, restart: books behave as in KNG-5 (no cap, no bonus).
12. Regression: KNG-5 spec §5 checklist steps 3-9 still behave the same on a 5★ or higher item.

## Open items / decisions to confirm (made without you; all reversible)

- **Rename grades 6-10.** Mythic / Ascended / Relic / Exalted / Divine are placeholders. Rename in the web
  app; nothing in code keys on names.
- **Ungraded items = grade 1** (most capped), so vanilla gear isn't a loophole. `ungraded-stars` in
  `config.yml` (0 = uncapped).
- **Siege books stay uncapped** (temporary enchantments). Nothing was changed on `claude/siege-minigame`.
- **Custom enchantments uncapped** by default, as in v1 (v1's `canEnchant` returned 2 for them).
  `apply-to-custom: true` caps them.
- **Book above the cap is applied at the cap** (and consumed), as in v1's "use whatever headroom is left".
  The alternative is to refuse and keep the book; see GRADE_DROPCHANCE.md §3.2.
- **Bonus chance 20%**. v1's `nextInt(100) <= 20` was actually 21%; set `0.21` if you want exact v1 odds.
- **DropChance 4 = 25%, 5 = 15%** as decided. For reference, v1's `gradeChance()` used 5% / 1% for grades
  4 / 5. DropChance is stored and mapped but nothing rolls it yet.

## Things worth knowing

- The grade tag holds **stars**, and the divisor is looked up live (`GradeCatalog`, refreshed async from
  `/api/Grades/search`). Retuning applies to existing items. If the API is down, the seeded defaults are
  used.
- `KitSeed` used to create only Common/Uncommon by name. It now creates all 10, and also skips a grade
  whose stars already exist, so the two seeds can't create duplicate-star grades.
- Verified: knk-core tests 74/74 and api-client `GradeMapperTest` 3/3 (scratch `javac` + JUnit). knk-paper
  was stub-type-checked only. knk-web-api `dotnet test` 733/738, against a baseline of 715/720 with the
  same 5 known failures. The migration was run on a local MySQL 8: apply, pending-changes check, roll back
  to 0, re-apply, and the backfill on pre-existing rows.
