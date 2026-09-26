# Handoff — grade level cap for enchantment books + DropChance (Linear KNG-6)

**Status:** Done. The developer tested it in-game and signed off; **merged to trunk** 2026-09-26: knk-web-api `master` (`638b50e` KNG-5; `45449a3`, `435a974`),
knk-plugin `main` (`ba74efe` KNG-5; `b721384`, `a7bbcef`, `6dd638e`, `bc97d2e`, `8a8d5e2`). knk-paper was never compiled in the cloud, so run `./gradlew build` on `main`.
**Last updated:** 2026-09-26 (added `8508f41` and `64f91ae`, fixes from the manual tests; see the enchant-book spec §6.1/§6.2)

Design, v1 verification, worked examples and edge cases:
[`docs/specs/items/GRADE_DROPCHANCE.md`](../../specs/items/GRADE_DROPCHANCE.md). Enchant-book spec §3.4 has
the summary.

## How it landed on trunk (2026-09-26)

The work branch `claude/adoring-dirac-p4pn54` was based on `claude/siege-minigame`, so it was **not** merged
as a whole: trunk would have received the unfinished siege work too. Instead, on top of current trunk (after
the `menu-content` merge):

- **knk-plugin `main`:** merged `claude/linear-backlog-access-4cr50w` (KNG-5, `ba74efe`), then cherry-picked
  the KNG-6 and manual-test commits (`b721384`, `a7bbcef`, `6dd638e`, `bc97d2e`, `8a8d5e2`). The only conflict
  was siege context in `KnKPlugin.java`, resolved to trunk's side; no siege code came along. knk-core/api-client
  tests 92/92, Paper files stub-type-checked.
- **knk-web-api `master`:** merged KNG-5 (`638b50e`), then cherry-picked KNG-6 (`45449a3`, `435a974`). The
  migration was **regenerated** on `master`'s schema as `20260926104605_AddGradeDropChanceAndEnchantCap`, with
  the same backfill. Checked on MySQL 8: apply all, no pending model changes, roll back to 0, re-apply, and the
  backfill on existing rows. `dotnet test` 524/529 (the 5 known failures).
- **knk-web-app:** nothing to merge (no changes).
- `claude/siege-minigame` and `claude/adoring-dirac-p4pn54` are unchanged. When siege merges later, it will
  meet these commits on trunk. Expect a snapshot conflict in knk-web-api `KnKDbContextModelSnapshot.cs` (keep
  both sides' properties). The branch's own copy of this migration (`20260926080330`) must be dropped, or the
  columns get added twice.

## What to do next (at your PC)

1. **knk-plugin:** `./gradlew build` on `main`. knk-paper has never been compiled with these changes (the cloud
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
2. Right-click `Enchanted Book (Sharpness III)`. The chooser lists the sword with "Grade limit: only up to I /
   Click to review". Click it: a confirmation screen explains the grade (Common, ★), that it allows Sharpness
   up to I, and that the book will only give Sharpness I. **Cancel** returns to the chooser and keeps the book.
   **Apply** gives Sharpness I, uses the book, and the action bar says "applied at I, the most this item's
   grade allows".
3. Right-click a second Sharpness book: the sword is still listed as "✘ Can't apply Sharpness III / Its
   grade is Common ★. / It allows Sharpness up to I, which it already has.". Clicking it only repeats that in
   the action bar.
4. Right-click `Enchanted Book (Unbreaking I)`: the Common sword is listed as "✘ Can't apply … Unbreaking
   can't go on items of this grade." (`3 / 5 = 0`).
5. **Epic** (4★) sword + `Sharpness V` book → confirmation, then Sharpness **II**.
6. **Legendary** (5★) sword + `Sharpness III` book → III. Repeat with a few fresh swords: about 1 in 5 get
   **IV** with "lucky, a bonus level". (Temporarily set `bonus-level-chance: 1.0` to see it every time.)
7. A **vanilla-crafted** iron sword (ungraded) + `Sharpness III` → confirmation says "no grade, so it counts as Common", then Sharpness I.
8. `Enchanted Book (Poison II)` onto the Common sword → Poison II: custom enchantments aren't capped by
   default.
9. **Retune live:** in the web app, set Common's divisor to 1 (or empty). Within `grade-refresh-minutes`
   (default 10; restart to skip the wait), the *existing* Common sword accepts Sharpness III.
10. An item built **before** this change (no `knk_grade` tag, but a `Grade: ★★` lore line) is capped as
    2★ (lore fallback).
11. Set `enchant-books.grade-cap.enabled: false`, restart: books behave as in KNG-5 (no cap, no bonus).
12. Regression: KNG-5 spec §5 checklist steps 3-9 still behave the same on a 5★ or higher item.

## Further tests (not covered by the rounds so far)

Enchant books:
- **Confirmation screen:** Cancel keeps the book and returns to the chooser. Clicks, shift-clicks, number
  keys and drags in both screens never move an item. While the confirmation is open, change the sword from
  the console (e.g. `/enchant <you> sharpness 1`): Apply then says "Something changed - nothing was applied".
- **Off-hand:** right-click with the book in the off-hand; the book is used from the off-hand.
- **Conflicts:** a Sharpness book with a Smite sword in the inventory: listed as "✘ Can't apply …
  Conflicts with Smite."
- **Custom at or above the book's level:** a Poison I book with a Poison II sword: listed as "Already has
  Poison II; this book is I."
- **Chooser order and size:** applicable items first, blocked ones after. A pickaxe never shows for a
  Sharpness book, and bread never shows for Poison.
- **Persistence:** relog and restart; book-applied vanilla and custom enchantments stay.
- **Siege sweep** (this branch contains siege): after a siege match, or on rejoin, permanent-book
  enchantments are *not* stripped. Only `siege_enchants`-marked ones are.
- **Other item sources:** a book from a kit grant and from the items catalog menu works like one from
  `/knk itemblueprints give`. Graded items from those sources carry `knightsandkings:knk_grade`.
- **Refactored commands** (they now share the lore helper): `/ce add poison 2`, `/knk enchantments apply
  poison 1` and `/knk itemblueprints give` of a blueprint with a custom default enchantment. All still put
  the custom line at the top.

Grades (KNG-6):
- The remaining checklist steps above: bonus roll (6), ungraded vanilla sword (7), custom uncapped (8), live
  retune (9), lore fallback on an old item (10), `enabled: false` (11).
- **An uncapped grade:** create a blueprint with grade Mythic (6★) in the web app. Sharpness V goes on
  without a confirmation, and the bonus never goes past V.
- **API down at startup:** the plugin logs "Grade table refresh failed", and caps still apply from the seeded
  defaults.
- **Web app / API:** after the migration, `grades` has 10 rows with the §2 values. Editing a grade through a
  form *without* the new fields keeps its divisor. After adding the fields to the Grade form, you can edit
  and clear them. A divisor of 0 is rejected.

## Open items / decisions to confirm (made without you; all reversible)

- **Rename grades 6-10.** Mythic / Ascended / Relic / Exalted / Divine are placeholders. Rename in the web
  app; nothing in code keys on names.
- **Ungraded items = grade 1** (most capped), so vanilla gear isn't a loophole. `ungraded-stars` in
  `config.yml` (0 = uncapped).
- **Siege books stay uncapped** (temporary enchantments). Nothing was changed on `claude/siege-minigame`.
- **Custom enchantments uncapped** by default, as in v1 (v1's `canEnchant` returned 2 for them).
  `apply-to-custom: true` caps them.
- **Book above the cap:** now asks first. A confirmation screen explains the cap before applying (your call
  after the manual test).
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
