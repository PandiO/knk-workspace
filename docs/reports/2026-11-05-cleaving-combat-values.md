# Cleaving's gate numbers as combat values (#259) — 2026-11-05

**Status:** in review (branches pushed, not merged, not deployed, not live-tested)
**Last updated:** 2026-11-05
**Issue:** [PandiO/knk-workspace#259](https://github.com/PandiO/knk-workspace/issues/259); developer decisions of
2026-11-05 in its comments (level I + a step per level; config.yml `gates.cleaving` removed)
**Base:** knk-plugin `main` `33122cf` (core 2476 / api-client 321 / paper 2504), knk-web-api `master` `2e3dfeb` (3659
passed), knk-web-app `main` `a7b231d` (2013/2013)

## 1. What was built

Branch `claude/cleaving-combat-values-259`: knk-plugin `93c807e`, knk-web-api `e255362`, knk-web-app `bc4ae42`,
knk-workspace `cdad08e`.

- **API:** four nullable `EnchantmentDefinition` columns, migration `20261105200617_AddCleavingCombatValues` (made with
  `dotnet ef migrations add`; `has-pending-model-changes` clean): `GateDamageBonusPerLevel` 0–10, `StrikeMultiplier`
  0–100, `StrikeMultiplierPerLevel` −100 to 100, `CooldownPerLevelSeconds` −86400 to 86400. Range checks on the DTOs,
  written on update only when sent. Cleaving now has combat defaults (the old config values: 0.25, 5, +1, cooldown
  60 s, −10 s), written into empty columns at startup. Form seed `EnchantmentDefinition - Default (seed v5)`. The
  #221 info page builds Cleaving's rows from the live values.
- **Plugin:** `EnchantmentTuning` gains a `GateStrike`; Cleaving has a built-in entry with the old defaults.
  `GateCleaving` reads it per hit (`/ce reload` and the 5-minute refresh apply a change); the strike's level-I
  cooldown is Cleaving's own cooldown (off = no strike cooldown). `config.yml` `gates.cleaving` is removed. Cleaving
  has no on-hit effect, so its new tuning entry starts no cooldown on normal hits (the executor skips it). `/ce info`
  shows `gate hits +25%, charged strike 5x, strike cooldown 60s`.
- **Web app:** DTO types only; the form comes from the seed and the Guides page needed no change.

## 2. Tests

| | Base | Branch |
|---|---|---|
| Plugin core / api-client / paper | 2476 / 321 / 2504 | 2479 / 321 (parse test extended) / 2507, 0 failures |
| API | 3659 passed | 3672 passed (+13), 0 failed |
| Web app | 2013 | 2013 (types only), `tsc` clean |

A trial merge of the plugin branch with `claude/chat-tokens-233` (also touches `KnKPlugin.java` / `config.yml`) has no
conflicts.

## 3. Flags

- Behaviour change beyond level IV (only if an admin raises Cleaving's max level): the steps continue (strike 9×,
  cooldown 0 at level V with the defaults) instead of repeating the level-IV values as the config lists did.
- A server whose `config.yml` had changed `gates.cleaving` numbers falls back to the defaults after the update until an
  admin enters them in the web app.

## 4. After deploy

1. knk-web-api: apply migration `AddCleavingCombatValues`; at startup the API fills in Cleaving's defaults.
2. Web app: import form seed v5 and make it the default.
3. Deploy the plugin build (its `config.yml` `gates.cleaving` block can be deleted from the server's copy).
