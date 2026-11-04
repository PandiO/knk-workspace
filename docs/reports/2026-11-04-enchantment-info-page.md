# Public enchantment info page under "Guides" (#221) — 2026-11-04

**Status:** in review (branches pushed, not merged, not deployed, not live-tested)
**Last updated:** 2026-11-04
**Issue:** [PandiO/knk-workspace#221](https://github.com/PandiO/knk-workspace/issues/221); developer decisions of
2026-11-03 in its comments (public, custom enchantments only, after #223, under a new "Guides" section)
**Base:** knk-web-api `master` `71b814c` (3445 passed, 0 failed), knk-web-app `main` `865fe53` (1785/1785). No plugin
change.

## 1. What was built

Branch `claude/enchantment-info-221`: knk-web-api `bcf0332`, knk-web-app `a346cea`, knk-workspace `63ce1b8` (admin guide
§ 8, ability reference).

- **API:** `GET /api/EnchantmentDefinitions/public/info`, `[AllowAnonymous]` like the #174 match pages and pinned in
  `EndpointAccessRulesTests`. One sheet per custom definition, by name: trigger, whom it affects, summary, damage and
  knockback radius, notes, and per level the chance, cooldown, effects (potion level, duration, who), area and gate
  damage, healing and Cleaving's gate text. Numbers are the live combat values (empty = default), worked out per level
  like the plugin's `EnchantmentTuning`. The fixed facts are in `Services/EnchantmentInfo/EnchantmentInfoCatalog.cs`,
  taken from knk-plugin `main` `bd4eff6` (`effects/impl/*Effect.java`).
- **Web app:** `/guides` (guide list) and `/guides/enchantments` (the page), public; "Guides" in the navigation bar
  (signed in) and a line on the landing page (signed out, since the bar only shows signed in). Theme tokens only.
  Checked in Chromium on a production build with the API's real output: desktop 1280 and phone 390, no sideways
  scrolling.
- **Tests:** API 3454 passed (+9), 0 failed. Web app 1789/1789 (+4), `tsc` clean, `CI=true` build clean, no new raw
  colour classes. A trial merge with `claude/page-background-image-231` (also touches `App.tsx` and `Navigation.tsx`)
  has no conflicts.

## 2. Flags

- **Cleaving** shows its `config.yml` **defaults** as text (+25 % per level, strike 5/6/7/8x, 60/50/40/30 s): its
  numbers are server settings, not combat values, so a changed config isn't reflected. Moving them into the combat
  values would need its own issue.
- The fixed facts in `EnchantmentInfoCatalog` must follow plugin changes to an effect (potion or amplifier).
- Signed out there is no navigation bar (existing app behaviour); the landing page now links the guides.
- Knockback strength and armour-penetration values aren't shown (not configurable; armour simply lowers Chaos / Flash
  Chaos damage).

## 3. After deploy

Nothing beyond deploying both builds (no migration, no form seed). Smoke steps: issue #221.
