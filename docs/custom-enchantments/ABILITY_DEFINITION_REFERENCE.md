# Ability Definition Reference (Admins + Players)

This is the canonical reference for custom ability metadata that is hardcoded in:
- `Repository/knk-web-api-v2/Models/Item/AbilityDefinition.cs` (`AbilityDefinition.CanonicalCatalog`)

On API startup, these entries are idempotently seeded and wired to matching custom `EnchantmentDefinition` records.

## How wiring works

- Only custom enchantments (`EnchantmentDefinition.IsCustom = true`) are considered.
- Matching is key-based using aliases (e.g., `flash_chaos`, `flashchaos`, `knk:flash_chaos`).
- For each matched custom enchantment, one `AbilityDefinition` row is created/updated.
- Existing ability rows are updated to canonical `AbilityKey`, `RuntimeConfigJson`, and assignment contract.

## Canonical abilities

| Ability Key | Effect Summary | Admin Usage | Player Usage |
|---|---|---|---|
| `armor_repair` | Repairs all equipped armor to full durability. Cooldown: 120s. | Assign to custom enchantment definitions where players should have emergency armor restore. | Right-click with the enchanted item to instantly repair all worn armor. |
| `blindness` | Applies Blindness I for level × 60 ticks on every hit. | Use for guaranteed vision disruption on hit-based builds. | Attack with the enchanted weapon to blind targets. |
| `chaos` | AoE burst: up to 40 damage in radius 3 and knockback in radius 5. Cooldown: 90s. | Assign for aggressive area control activations. | Right-click to trigger an area blast around you. |
| `confusion` | 15% chance per level to apply Nausea III for level × 60 ticks. | Use when you want probabilistic crowd disruption in melee combat. | Attack to proc confusion on enemies. |
| `flash_chaos` | AoE burst: up to 60 damage (radius 3) + Slowness I and Nausea II to players in radius 5. Cooldown: 90s. | Assign as a high-impact active ability with PvP-oriented debuffs. | Right-click to unleash a stronger chaos burst with player debuffs. |
| `freeze` | 15% chance per level to freeze player targets for level × 60 ticks. | Use for control-focused weapon identities. | Attack players to occasionally immobilize them. |
| `health_boost` | Heals in 6 pulses (every 5 ticks), scaling by level. Cooldown: 120s. | Assign to survivability-focused enchantments. | Right-click for a short burst of self-healing ticks. |
| `invisibility` | Applies Invisibility for 200 ticks. Cooldown: 90s. | Use for stealth or repositioning archetypes. | Right-click to become invisible temporarily. |
| `poison` | 15% chance per level to apply Poison II for level × 60 ticks. | Assign for sustained damage-over-time pressure. | Attack to proc poison on hit. |
| `resistance` | Applies Resistance for (level × 100 + 100) ticks. Cooldown: 120s. | Use for temporary defensive windows in combat builds. | Right-click to gain temporary resistance. |
| `strength` | 15% chance per level to apply Strength to attacker for 300 ticks. Cooldown: 120s. | Assign when on-hit self-buff loops are desired. | Attack to potentially trigger your own strength buff. |
| `wither` | 15% chance per level to apply Wither II for level × 40 ticks. | Assign for high-pressure offensive builds. | Attack to proc wither on enemies. |

## Operational notes

- This setup is intended to reduce dependence on `/ce` command usage for baseline ability attachment.
- Admins can still modify relationships by managing `EnchantmentDefinition` entries in API/WebApp.
- Runtime plugin behavior remains authoritative for in-game execution and cooldown enforcement.
