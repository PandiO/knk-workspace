# #259 Cleaving combat values merged — 2026-11-10

**Status:** merged into the trunks, not deployed
**Last updated:** 2026-11-10
**Issue:** [PandiO/knk-workspace#259](https://github.com/PandiO/knk-workspace/issues/259)
**Previous report:** [2026-11-05](2026-11-05-cleaving-combat-values.md)

## 1. Developer smoke test

All steps passed (developer, 2026-11-10): the defaults unchanged (`/ce info`, 10 per hit and 50 / 128 per strike,
60 s / 30 s strike cooldown bars, no effect on players), admin values live after `/ce reload` (strike multiplier,
cooldown change per level down to "off", gate bonus, cooldown switched off, out-of-range refusal), the Guides page with
the live numbers, and the reset to the defaults.

## 2. Merges

All three trunks had #233 (chat tokens, with two API migrations) merged since the branch, so the merged results were
tested before pushing.

| Repo | Trunk head | Merged | Tests on the merged trunk |
|---|---|---|---|
| knk-plugin | `main` `200cbbd` | `claude/cleaving-combat-values-259` `93c807e` into `b8ab3a0` | core 2500 / api-client 324 / paper 2526, 0 failures; shaded jar builds |
| knk-web-api | `master` `f477797` | `e255362` into `6f3edd1` | 3678 passed, 0 failed; `has-pending-model-changes` clean; migration order `AddChatTokenSettings`, `SeedChatTokenNodes`, `AddCleavingCombatValues` |
| knk-web-app | `main` `b240a02` | `bc4ae42` into `4d6e2ac` | `tsc` clean, 2016/2016, `CI=true` build clean |
| knk-workspace | `main` | `claude/cleaving-combat-values-259` (admin guide, gate design, quick reference, CHANGELOG) | — |

## 3. After deploy

1. knk-web-api: apply migration `AddCleavingCombatValues` (with #233's two, if not yet applied).
2. Web app: import form seed EnchantmentDefinition v5 and make it the default (if not done in the smoke test).
3. Plugin: the server's `config.yml` `gates.cleaving` block can be deleted.
