# Handoff — enchantment books outside siege (Linear KNG-5)

**Status:** Done and **merged to trunk** 2026-09-26 together with KNG-6 (see the
[KNG-6 handoff](2026-09-26-grade-enchant-cap-kng-6.md)). The steps below are kept for history.
**Last updated:** 2026-09-26

Design, decisions and the manual test checklist are in
[`docs/specs/enchantment-books/ENCHANTMENT_BOOK_APPLICATION.md`](../../specs/enchantment-books/ENCHANTMENT_BOOK_APPLICATION.md).

## What to do next (at your PC)

1. In knk-plugin, check out `claude/linear-backlog-access-4cr50w` and run `./gradlew build`.
   - The knk-paper part has never been compiled: the cloud blocks `repo.papermc.io`.
   - Expected fix-ups, if any, are small API mismatches in `paper/enchantbook/*` or `EnchantBookListener`.
2. Run the API from knk-web-api `claude/linear-backlog-access-4cr50w`. `EnchantBookSeed` adds 46 book
   blueprints on startup; no migration is needed.
3. Walk through the spec's §5 checklist on the dev server.
4. Merge both branches into trunk (they are trunk plus one commit each), then close KNG-5.

## Things worth knowing

- **Not a cherry-pick.** The siege book files depend on most of the siege module, so the siege-agnostic parts
  were ported as new classes instead (spec §2). `claude/siege-minigame` is untouched. When siege merges,
  `SiegeEnchantBooks.evaluate` can delegate to `EnchantBookRules`.
- **New rule: custom enchantments go on gear only** (items with durability). It's one line in
  `EnchantBookRules.customCompatible`; change it there if you want something else.
- **KNG-6 still needs implementing.** The earlier session's grade patches (`DropChance`,
  `EnchantLevelCapDivisor`) were never committed. The cap slots into `EnchantBookRules.evaluate` (spec §3.4).
- **The web-app designated branch was not changed.** No web-app work was needed.
