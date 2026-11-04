# #223 and #222 merged, death messages say "using <item>" — 2026-11-04

**Status:** merged into the trunks, not deployed
**Last updated:** 2026-11-04
**Issues:** [PandiO/knk-workspace#223](https://github.com/PandiO/knk-workspace/issues/223),
[#222](https://github.com/PandiO/knk-workspace/issues/222)
**Previous report:** [2026-11-03](2026-11-03-chaos-area-damage-and-death-messages.md)

## 1. Developer smoke test

All smoke steps passed (developer, 2026-11-04): #223's values, reload, radii, gate damage, out-of-range refusal and
reset to defaults; #222's Chaos / Flash Chaos messages, vanilla messages for other deaths, siege, override.

## 2. Follow-up: "using <item>" (#222)

Developer request after the test: the default ability death message also names the item, like vanilla's
`<victim> was slain by <player> using [Item]`. knk-plugin `claude/death-messages-222` `e67408b`:

- Default pattern `%victim% was killed with %enchantment% by %player% using %item%`.
- `SupportEnchantmentEffect` keeps the activation's item while the effect runs and passes it with the hit
  (`AreaKillAttribution.Hit.item`); the listener puts in `ItemStack.displayName()` (brackets, hover shows the item).
- Without a known item, ` using %item%` is left out. `%item%` also works in overrides.
- Unlike vanilla (only items with a custom name), the item is always named.
- Tests on the branch: core 2446 / api-client 288 / paper 2413, 0 failures.

## 3. Merges

| Repo | Trunk head | Merged | Tests on the merged trunk |
|---|---|---|---|
| knk-plugin | `main` `bd4eff6` | `claude/area-damage-223` + `claude/death-messages-222` into `8f11bed` | core 2452 / api-client 288 / paper 2419, 0 failures; shaded jar builds |
| knk-web-api | `master` `369fd1c` | `claude/area-damage-223` into `c4c7772` | tree = the tested branch: 3425 passed + the 4 known reds (#99) |
| knk-web-app | `main` `8613916` | `claude/area-damage-223` into `8458d9a` | tsc clean, 1784/1784 |
| knk-workspace | `main` | both doc branches | — |

## 4. After deploy

1. knk-web-api: apply migration `AddEnchantmentAreaDamage`; at startup the API fills in the Chaos / Flash Chaos defaults.
2. Web app: import form seed `EnchantmentDefinition - Default (seed v4)` and make it the default (if not done during
   the smoke test).
3. Plugin: if the server's `config.yml` already has a `custom-enchantments.death-messages.default` line from the smoke
   test, add ` using %item%` to it (the shipped default has it).
4. Live look: a Chaos / Flash Chaos kill shows `… using [<item>]`, and hovering over the item shows it.
