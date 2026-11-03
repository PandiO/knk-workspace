# Chaos / Flash Chaos area damage as combat values (#223) and death messages (#222) — 2026-11-03

**Status:** both in review (branches pushed, not merged, not deployed, not live-tested)
**Last updated:** 2026-11-03
**Issues:** [PandiO/knk-workspace#223](https://github.com/PandiO/knk-workspace/issues/223),
[#222](https://github.com/PandiO/knk-workspace/issues/222); developer decisions of 2026-11-03 in the issue comments
**Base:** knk-plugin `main` `8f11bed5` (core 2440 / api-client 288 / paper 2404, run at `4f29e9c3`; `8f11bed5` only
adds a 2-line `InvisibilityEffect` change), knk-web-api `master` `c4c7772` (3412 passed + the 4 known reds, #99),
knk-web-app `main` `c02b365` (1773/1773; the 1383 of the brief predates the #95 merges)

## 1. #223 — area damage, gate damage and radii

Branch `claude/area-damage-223`: knk-plugin `9c1a7e9d`, knk-web-api `5b3afc3`, knk-web-app `53d715b`, knk-workspace
`5bab6f3` (admin guide § 1–3, ability reference).

- **API:** four nullable `EnchantmentDefinition` columns, migration `20261103202219_AddEnchantmentAreaDamage`
  (generated with `dotnet ef migrations add`; `has-pending-model-changes` clean): `AreaDamage` 0–1000, `GateDamage`
  0–10000, `DamageRadiusBlocks` and `EffectRadiusBlocks` 0–32. On the read/create/update DTOs with range checks
  (400 out of range); an update writes them only when sent. Startup writes the old hard-coded values into empty
  columns: Chaos 40 / 40, Flash Chaos 60 / 60, radius 3, reach 5 (gate damage = player damage, decision on #223).
  Form seed `EnchantmentDefinition - Default (seed v4)` adds the four fields to "Combat values".
- **Plugin:** `EnchantmentTuning` gains an `AreaBlast`, read per activation (startup, the 5-minute refresh,
  `/ce reload`); out-of-range values are clamped. Damage and gate damage = value × (1 + `LevelMultiplier` × (n − 1))
  (decision on #223; both abilities are max level I today). Gate doors get the separate gate damage; their reach stays
  `gates.area-enchantment-radius-blocks`. A knockback radius below the damage radius counts as the damage radius;
  0 damage = knockback only. `/ce info` shows `area damage 40 within 3 blocks, gates 40, knockback within 5 blocks`.
- **Web app:** the four fields on the enchantment definition DTO types (`tsc` clean); the form comes from the seed.
- **Tests:** plugin core 2446 (+6) / api-client 288 (parse test extended) / paper 2410 (+6), 0 failures, shaded jar
  builds. API 3425 passed (+13) + the same 4 known reds. Web app 1773/1773 (= base).

## 2. #222 — death messages

Branch `claude/death-messages-222`: knk-plugin `13c0a205`, knk-workspace `2c24e4c` (admin guide § 7). No API or
web-app change (decision on #222).

- Chaos and Flash Chaos damage through `SupportEnchantmentEffect.damageAsAbility`, which records the hit in
  `AreaKillAttribution` while `target.damage` runs; the death event fires inside that call. `AbilityDeathMessageListener`
  (priority HIGH) then sets `<victim> was killed with <Enchantment> by <player>`. Pattern in `config.yml`
  `custom-enchantments.death-messages` (`enabled`, `default`, optional `overrides.<id>`; `&` colours; read per death).
- Scope per the decision: only deaths inside the ability's own hit. Poison/Wither over time and later deaths keep
  the vanilla message. A siege match still clears the message at HIGHEST; `getKiller()` and the statistics (#164)
  are unchanged, because the damage still has the user as its source.
- **Tests:** plugin core 2445 (+5) / api-client 288 / paper 2410 (+6), 0 failures.

## 3. The two branches together

Both change `ChaosEffect` / `FlashChaosEffect`. #222 changes only the one `target.damage(...)` line in each
`callDamageEventAndApply` (no new imports there), and #223 doesn't touch those lines. `config.yml` changes are in
different blocks. Checked: `claude/area-damage-223` + `claude/death-messages-222` merge without conflicts in
knk-plugin (merged result: core 2451 / api-client 288 / paper 2416, 0 failures) and in knk-workspace. Either order
works.

## 4. After deploy

1. Deploy knk-web-api `claude/area-damage-223` and apply migration `AddEnchantmentAreaDamage` (four nullable
   columns, no data change). On start, the API fills in the defaults for Chaos and Flash Chaos.
2. Web app → form configurations → Import / seeds → `EnchantmentDefinition` → import **seed v4** and make it the
   default.
3. Deploy the web app and plugin builds. #222 needs only the plugin; its config keys have defaults, so an existing
   `config.yml` without the block works.

## 5. Flags

- Not done (optional in #223): **knockback strength** stays hard-coded (1.2 horizontal, 0.4 up).
- The knockback reach is still a box of ± radius around the user, not a sphere (as before). The damage radius is a
  real distance.
- Flash Chaos shares one `LevelMultiplier` between its debuff durations and its damage; to scale only one of them, a
  separate field would be needed.
- Death messages use plain player names (no rank prefix or display name).
- Not run here: anything against a real MySQL (migration applied), a Paper server or the live alpha.
