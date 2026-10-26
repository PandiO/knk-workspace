# Ability Definition Reference (Admins + Players)

This is the canonical reference for custom ability metadata that is hardcoded in:
- `Repository/knk-web-api/Models/Item/AbilityDefinition.cs` (`AbilityDefinition.CanonicalCatalog`)

On API startup, these entries are idempotently seeded and wired to matching custom `EnchantmentDefinition` records.

## How wiring works

- Only custom enchantments (`EnchantmentDefinition.IsCustom = true`) are considered.
- Matching is key-based using aliases (e.g., `flash_chaos`, `flashchaos`, `knk:flash_chaos`).
- For each matched custom enchantment, one `AbilityDefinition` row is created/updated.
- Existing ability rows are updated to canonical `AbilityKey`, `RuntimeConfigJson`, and assignment contract.

## Combat values (PandiO/knk-workspace#151, #156)

Since #151 the chance, cooldown, duration and level multiplier of each custom enchantment are columns on
`EnchantmentDefinition`, edited in the web app (form seed v2, step "Combat values") and read by the plugin
(`EnchantmentTuningTable`, refreshed every few minutes and on `/ce reload`). `CanonicalCatalog` entries carry the
defaults (`CombatDefaults`, #156); the startup seed writes them into empty columns only. `RuntimeConfigJson` and the
effect summaries below describe those defaults; the plugin doesn't read `RuntimeConfigJson`. Admin guide:
[custom enchantment combat values](../../guides/admin/custom-enchantment-combat-values-admin-guide.md). On the package
branches `claude/alpha-run-1-enchantments`, not merged yet (2026-10-26).

## Canonical abilities

| Ability Key | Effect Summary | Admin Usage | Player Usage |
|---|---|---|---|
| `armor_repair` | Repairs all equipped armor to full durability. Cooldown: 120s. | Assign to custom enchantment definitions where players should have emergency armor restore. | Right-click with the enchanted item to instantly repair all worn armor. |
| `blindness` | Default: 20% chance at level I, +10 per level, to apply Blindness I for 2/3/4 s (levels I-III); 10 s cooldown per attacker. | Attach to custom EnchantmentDefinition entries to blind the target on a share of hits. | Hit enemies with the enchanted weapon for a chance to blind them. |
| `chaos` | AoE burst: up to 40 damage in radius 3 and knockback in radius 5. Cooldown: 90s. | Assign for aggressive area control activations. | Right-click to trigger an area blast around you. |
| `confusion` | Default: 10% chance at level I, +5 per level, to apply Nausea III for 3/4.5/6 s (levels I-III); 8 s cooldown per attacker. | Use when you want probabilistic crowd disruption in melee combat. | Attack to proc confusion on enemies. |
| `flash_chaos` | AoE burst: up to 60 damage (radius 3) + Slowness I and Nausea II to players in radius 5. Cooldown: 90s. | Assign as a high-impact active ability with PvP-oriented debuffs. | Right-click to unleash a stronger chaos burst with player debuffs. |
| `freeze` | Default: 10% chance at level I, +5 per level, to freeze the target for 1.5/2.25/3 s (levels I-III); then 20 s cooldown per attacker. | Use for control-focused weapon identities. | Attack players to occasionally immobilize them. |
| `health_boost` | Heals in 6 pulses (every 5 ticks), scaling by level. Cooldown: 120s. | Assign to survivability-focused enchantments. | Right-click for a short burst of self-healing ticks. |
| `invisibility` | Applies Invisibility for 200 ticks. Cooldown: 90s. | Use for stealth or repositioning archetypes. | Right-click to become invisible temporarily. |
| `poison` | Default: 10% chance at level I, +5 per level, to apply Poison II for 3/4.5/6 s (levels I-III); 8 s cooldown per attacker. | Assign for sustained damage-over-time pressure. | Attack to proc poison on hit. |
| `resistance` | Applies Resistance for (level × 100 + 100) ticks. Cooldown: 120s. | Use for temporary defensive windows in combat builds. | Right-click to gain temporary resistance. |
| `strength` | 15% chance per level to apply Strength to attacker for 300 ticks. Cooldown: 120s. | Assign when on-hit self-buff loops are desired. | Attack to potentially trigger your own strength buff. |
| `wither` | Default: 10% chance at level I, +5 per level, to apply Wither II for 2/3/4 s (levels I-III); 8 s cooldown per attacker. | Assign for high-pressure offensive builds. | Attack to proc wither on enemies. |

## Operational notes

- This setup is intended to reduce dependence on `/ce` command usage for baseline ability attachment.
- Admins can still modify relationships by managing `EnchantmentDefinition` entries in API/WebApp.
- Runtime plugin behavior remains authoritative for in-game execution and cooldown enforcement.
