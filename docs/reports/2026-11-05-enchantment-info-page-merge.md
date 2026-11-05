# #221 enchantment info page merged — 2026-11-05

**Status:** merged into the trunks, not deployed
**Last updated:** 2026-11-05
**Issue:** [PandiO/knk-workspace#221](https://github.com/PandiO/knk-workspace/issues/221)
**Previous report:** [2026-11-04](2026-11-04-enchantment-info-page.md)

## 1. Developer smoke test

All steps passed (developer, 2026-11-05): signed-out access through the landing page and `/guides`, the groups and
default values of every card, live values after admin changes (Flash Chaos cooldown, Chaos damage and radius, Poison
chance capped at 100 %), the Guides link when signed in, phone layout and the anonymous API read.

## 2. Merges

Both trunks had moved since the branch (API: realtime SignalR, #232, world tasks; web app: #231 merged, SignalR), so
the merged results were tested before pushing.

| Repo | Trunk head | Merged | Tests on the merged trunk |
|---|---|---|---|
| knk-web-api | `master` `2e3dfeb` | `claude/enchantment-info-221` `bcf0332` into `453729e` | 3659 passed, 0 failed |
| knk-web-app | `main` `a7b231d` | `claude/enchantment-info-221` `a346cea` into `4d0c6ed` | `tsc` clean, 2013/2013, `CI=true` build clean, no new raw colour classes |
| knk-workspace | `main` | `claude/enchantment-info-221` (admin guide § 8, ability reference) | — |

## 3. After deploy

Deploy the API and web-app builds; no migration, no form seed. Open flag (from #221): Cleaving's gate numbers on the
page are the plugin's `config.yml` defaults, not live values.
