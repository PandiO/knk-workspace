# Handoff — enchantment books + grade level cap: closed out (Linear KNG-5, KNG-6)

**Status:** Done. Implemented, tested in-game by the developer, and merged to trunk. Both Linear issues are Done.
The feature branches are cleared for deletion; the developer deletes them, because the cloud session isn't
allowed to delete branches (see below).
**Last updated:** 2026-09-26

This is the final note for the feature. The detailed handoffs are
[`2026-09-26-enchantment-books-kng-5.md`](2026-09-26-enchantment-books-kng-5.md) and
[`2026-09-26-grade-enchant-cap-kng-6.md`](2026-09-26-grade-enchant-cap-kng-6.md), which has the full test lists.

## What shipped

Permanent enchantment books, outside siege. An `ItemBlueprint` with material `enchanted_book` and a default
enchantment is a book. It works with vanilla and custom (Poison, Chaos, …) enchantments.

- **Applying:** right-click the book in hand to open a chooser. This is the **only** way; applying from the
  cursor was removed as too accident-prone.
- **The chooser lists every item the enchantment could go on by type**, usable ones first. Each item shows its
  status: "Click to apply", "Grade limit / Click to review", or "✘ Can't apply" with the reason (grade cap,
  conflict, already as high).
- **Grade level cap (v1's formula):** an item may take an enchantment up to `definitionMaxLevel / divisor`
  (integer division). The divisors are 5, 4, 3, 2, 1 for grades 1-5, and grades 6-10 are uncapped. The divisors
  are per-grade DB fields that can be edited in the web app, and changes also apply to existing items. When the
  cap lowers what a book gives, a **confirmation screen** explains it first.
- **Grades:** 10 tiers, each with `DropChance` and `EnchantLevelCapDivisor`. The divisors are seeded, and a
  migration backfills grades 1-5.
- **Custom enchantment lore:** one shared pipeline (`CustomEnchantmentLore`). Custom lines sit directly under
  the vanilla enchantments, with Grade/Origin at the bottom.

## Where it is

| Repo | Trunk commits |
|---|---|
| knk-plugin `main` | `ba74efe` (KNG-5), `b721384`, `a7bbcef`, `6dd638e`, `bc97d2e`, `8a8d5e2` |
| knk-web-api `master` | `638b50e` (KNG-5), `45449a3`, `435a974`. Migration `20260926104605_AddGradeDropChanceAndEnchantCap` |
| knk-workspace `main` | [design note](../../specs/items/GRADE_DROPCHANCE.md), [enchant-book spec](../../specs/enchantment-books/ENCHANTMENT_BOOK_APPLICATION.md) (incl. manual test results §6.1/§6.2), the handoffs above, `ACTIVE_SESSIONS.md` |
| knk-web-app | no changes |

## Feature branches: safe to delete (developer action)

On 2026-09-26 I checked that everything on these branches is already on trunk (or, for the siege commits, on
`claude/siege-minigame`). The developer approved deleting them. The cloud session's git proxy refuses branch
deletions (HTTP 403, org policy), so they **still exist and need deleting by hand**. Use the "Branches" page of
each repo on GitHub (`https://github.com/PandiO/<repo>/branches`), or run this locally:

```sh
# in knk-plugin, knk-web-api and knk-workspace each:
git push origin --delete claude/linear-backlog-access-4cr50w claude/adoring-dirac-p4pn54
```

The last commit of each, in case one ever needs restoring:

| Branch | knk-plugin | knk-web-api | knk-workspace |
|---|---|---|---|
| `claude/linear-backlog-access-4cr50w` (KNG-5) | `ba74efe` | `638b50e` | `5e5f74f` |
| `claude/adoring-dirac-p4pn54` (KNG-6 work branch) | `bc654e3` | `70554f4` | `2c455dc`\* |

\* After this note, the session pushed one more docs commit straight to workspace `main`, not to the branch.

`claude/adoring-dirac-p4pn54` in knk-web-app was already gone. **`claude/siege-minigame` was not touched and
must stay.** It holds the unfinished siege work and none of this feature.

## Still open (developer)

0. **Delete the feature branches** (see above).
1. **`./gradlew build` on knk-plugin `main`.** knk-paper was never compiled in the cloud: `repo.papermc.io` is
   blocked there. The changed Paper files were only type-checked against hand-written stubs.
2. **Rename grades 6-10.** Mythic, Ascended, Relic, Exalted and Divine are placeholders; rename them in the web
   app, since no code depends on the names.
3. **Grade form in the web app:** if a Grade form configuration exists, add `DropChance` and
   `EnchantLevelCapDivisor` to it in the form builder. Until then, edits keep their values (the API only writes
   fields the request contains).
4. Optional: the "Further tests" list in the KNG-6 handoff (off-hand, conflicts, siege sweep, kit/catalog books,
   API-down fallback, uncapped grade).

## When siege merges into trunk

- **knk-web-api:** siege's `KnKDbContextModelSnapshot.cs` doesn't have the two new grade columns. Expect a merge
  conflict there and keep both sides. Siege has no copy of the grade migration. The only other copy (`20260926080330`)
  is on the work branch `claude/adoring-dirac-p4pn54`, which should be deleted and never merged.
- **knk-plugin:** siege books (`SiegeEnchantBooks`) stay uncapped by decision (their enchantments are
  temporary). Optionally, `SiegeEnchantBooks.evaluate` can delegate its compatible/conflict/improvement checks
  to `EnchantBookRules`. The siege listener still applies books from the cursor; that is separate from the
  permanent books and is the siege work's call.

## Decisions made along the way

These are kept in the design note §6 and the spec:

- Ungraded items count as grade 1.
- Custom enchantments are uncapped, as in v1 (`apply-to-custom`).
- The bonus level chance is 20% (v1 was 21%).
- A capped apply needs a confirmation.
- The chooser shows blocked items with their reason.
