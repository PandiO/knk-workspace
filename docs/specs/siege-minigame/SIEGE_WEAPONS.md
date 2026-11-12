# Siege Minigame — Siege Weapons

**Status:** Design in progress (2026-11-12). Placement, spawning, build phase, health, destruction and economy are
decided by the developer; **aiming, firing, ammunition and damage are not designed yet** (§10). No implementation
plan, no code.
**Last updated:** 2026-11-12 (first version, from the developer's design conversation)
**Issue:** [PandiO/knk-workspace#354](https://github.com/PandiO/knk-workspace/issues/354) (sub-issues: #355 aiming/firing/damage design, #356 siege coins, #357 web map spot picker)
**Related:**
- [DESIGN.md](DESIGN.md): the Siege minigame this extends (`SiegeScenario` §3.3, `SiegeTeam` §3.4, gates §8, rewards §7.6, menus §10)
- [../in-game-maps/DESIGN.md](../in-game-maps/DESIGN.md) and #224: battle map tables, the web map targeting page for siege engines
- [../siege-survival/DESIGN.md](../siege-survival/DESIGN.md) and #41: Siege Survival's match currency (S12, S33), the model for siege coins (§7); siege weapons may come to Siege Survival later
- [../gate-structure-animation/](../gate-structure-animation/): gate health, `GateCrackVisuals` and destroy/respawn, the model for weapon damage feedback (§6)
- [../world-tasks/](../world-tasks/): the world tasks feature used to author weapon spots (§4)

**Authority:** the developer's design conversation of 2026-11-12. Items marked *proposal* are suggestions from that
conversation or from this write-up that the developer has not confirmed; treat them as defaults for the
implementation plan, not as decisions.

## 1. Goal

Players can field **siege weapons** during a Siege match: trebuchets, catapults and ballistas, and possibly cannons.
Each scenario reserves **spots** for them, owned by a team. A player who has unlocked siege weapons buys one during the
match with siege coins, picks a free spot of their team, and the system pastes the weapon in from a schematic. It then
builds up over a configurable time, during which it is vulnerable, and is ready for use.

Scope: the Siege minigame (PvP). Siege Survival may get siege weapons later; nothing here changes that mode.

## 2. Decisions (developer, 2026-11-12)

| ID | Decision |
|---|---|
| W1 | **Roster:** ballista, catapult, trebuchet; cannon is a maybe. **Battering rams are out for now:** they look odd in vanilla blocks and are too large for the current town dimensions. |
| W2 | **Weapons are schematics.** A library of Minecraft schematics, one per weapon template, pasted in by the system on request. |
| W3 | **Three spot size classes** (small, medium, large) instead of one standard size. A larger spot can hold a smaller weapon. Sizes in §3 are placeholders until real designs are chosen. |
| W4 | **Spots are authored with the existing world tasks feature**, one world task per spot, from a WorldEdit selection or a WorldGuard region. |
| W5 | **Facing** is filled in by the world task from the admin's look direction; the admin can override it. |
| W6 | **Weapons have health points, like gates,** and can be damaged. |
| W7 | **Build time** is configurable per weapon template. During it, HP rises evenly from 0 to full, a deliberate window for the opponents to attack. |
| W8 | **Wreck schematic in V1** (changed during the conversation from "plain removal in V1, wreck in V2"): a destroyed weapon is replaced by a destroyed variant, defined per template. |
| W9 | **Damage and destruction feedback follows gate doors:** broken block states (cracks) as HP drops, sounds, and particle effects. |
| W10 | **After destruction only that spot is locked** for a cooldown, not the weapon type for the team. |
| W11 | **Cooldown length is set on the weapon template,** with an optional override on the scenario. |
| W12 | **Spot selection V1: in-game menu** listing the team's free spots, with a command fallback (UI-first principle). **Later, the preferred route is the web map:** a siege-specific view where free spots are highlighted and clickable. |
| W13 | **Economy:** a player first **unlocks** siege weapons permanently, paid with **personal coins**; **placing** a weapon in a match costs **siege coins**, a per-match balance earned in play (objectives, kills, etc.) and reset every match, like Call of Duty scorestreaks. |
| W14 | **Pricing in "minutes of good play":** prices are anchored to a good player's earn rate; every value is configurable and tuned during the alpha. |

## 3. Weapon templates and size classes

A **weapon template** defines one weapon type:

| Field | Notes |
|---|---|
| Name, description | Shown in menus. |
| Size class | small / medium / large (W3). |
| Schematic | The working weapon (W2). |
| Wreck schematic | The destroyed variant (W8). |
| Max health | HP at the end of the build (W6). |
| Build time | Seconds from paste to full HP (W7). |
| Spot cooldown | Seconds the spot stays locked after destruction (W11). |
| Match price | Siege coins to place it (W13). |
| Unlock price | Personal coins to unlock it (W13). Whether unlocks are per weapon or one unlock for siege weapons in general is open (§10). |

**Size classes (placeholders, W3).** The developer will pick real designs from online references; the final numbers
come from those.

| Class | Footprint W × L × H (blocks) | Fits |
|---|---|---|
| Small | ~5 × 5 × 5 | Ballista |
| Medium | ~7 × 9 × 8 | Catapult, cannon |
| Large | ~11 × 15 × 16 | Trebuchet |

A spot accepts any weapon whose class is the same size or smaller. *Proposal:* schematics are authored facing one
fixed direction (for example north) so they can be rotated in 90° steps to the spot's facing.

## 4. Weapon spots (scenario authoring)

- Each scenario has reserved **weapon spots**, and each spot belongs to one team.
- An admin creates a spot through a **world task** (W4): they make a WorldEdit selection or pick a WorldGuard region,
  and the task stores its bounds.
- The **size class is derived from the selection's dimensions.** A selection smaller than the small class is
  rejected. *Proposal:* the class is the largest one whose footprint fits.
- **Facing** is pre-filled from the admin's look direction when they confirm the task, and the admin can change it
  (W5). *Proposal:* rounded to the nearest of north, east, south, west, so it matches the 90° schematic rotation.
- **Team** is a field on the spot.
- *Proposal:* spots join the scenario readiness check (DESIGN §3.9) as a warning, not a blocker, so a scenario
  without spots stays playable.

## 5. Player flow

1. The player has unlocked siege weapons (§7).
2. During the match, they open the siege menu and choose a weapon. The menu may extend the siege spawn point menu
   (DESIGN §6.6, §10). A command does the same as a fallback (W12).
3. They pick a **free spot of their team** that fits the weapon's size class. V1: a menu list of spots;
   *proposal:* each entry shows a rough location, and hovering briefly highlights the spot with particles. Later:
   the web map view (§8).
4. The match charges the siege-coin price and the system pastes the schematic, rotated to the spot's facing.
5. The **build phase** runs (§6). At its end the weapon is ready for use.

## 6. Health, build phase and destruction

- **Health (W6):** every weapon has HP and can be damaged, as gate doors can. Which damage sources count (players,
  other weapons' projectiles, fire, explosions) belongs to the damage model (§10).
- **Build phase (W7):** HP starts at 0 and rises evenly to the template's max over its build time. The weapon can be
  attacked while it builds; destroying it then counts as a normal destruction.
- **Damage feedback (W9):** reuse the gate approach. Gates show health-based cracks per viewer
  (`GateCrackVisuals`, Paper `Player#sendBlockDamage`) and play sounds; weapons do the same. Particle effects are
  wanted for weapons too, and for gates if they don't have them yet (to check in knk-plugin).
- **Destruction (W8, W9):** at 0 HP the system plays the destruction sound and particles and **swaps the schematic for
  the template's wreck schematic**.
- **Spot cooldown (W10, W11):** only that spot is locked, for the template's cooldown or the scenario override. The
  wreck stays while the spot is locked and is cleared when the spot frees up.
- **Match end:** *proposal:* every weapon and wreck is removed and the spot areas are restored, through the same
  crash-safe restore approach as gates (DESIGN §8.4).

## 7. Economy

- **Unlock (W13):** permanent, on the player's account, paid with personal coins (`User.Coins`).
- **Placement (W13):** costs **siege coins**, a per-match balance that starts at 0 and is reset every match. Earned
  from play: objectives, kills, and similar actions. This is the same concept as Siege Survival's match currency
  (S12, S33), which isn't implemented yet; the PvP Siege mode needs its own earn rules. It never converts to personal
  coins.
- **Pricing (W14):** price each weapon in minutes of good play. *Example only:* if a good player earns about 100
  siege coins a minute, a ballista costs about 2 minutes' worth (200) and a trebuchet about 8 (800). Earn rates and
  prices are configuration, tuned during the alpha.

## 8. Web map spot picker (later)

The preferred spot picker, once the web map exists, is a siege-specific view in the web app: the player is sent to it,
their team's free spots that fit the chosen weapon are highlighted and clickable, and the plugin takes that choice.
This builds on the battle map work in [in-game-maps](../in-game-maps/DESIGN.md) (#224).

> **Renderer to confirm.** In this conversation the developer said he is still deciding between BlueMap and Dynmap for
> these map operations. [in-game-maps](../in-game-maps/DESIGN.md) M2 records BlueMap as confirmed on 2026-11-12. Both
> would work for this picker; confirm which record holds.

## 9. Proposed data model (for the implementation plan)

*Proposal only*, following the siege domain conventions in DESIGN §3 (FormWizard-configurable entities, owned
children):

- `SiegeWeaponTemplate`: the fields in §3, schematic references by name or path (storage is open, §10).
- `SiegeWeaponSpot`, owned by `SiegeScenario`: `SiegeTeamId`, bounds (min/max corner or WorldGuard region id),
  derived `SizeClass`, `Facing`, `Name`, `SortOrder`.
- `SiegeScenario.WeaponSpotCooldownOverrideSeconds` (nullable, W11).
- `UserSiegeWeaponUnlock` (or one unlock flag, depending on §10).
- Runtime only (plugin, match state): placed weapons with current HP, build progress, spot lock timers, and each
  player's siege-coin balance.

## 10. Open questions

| # | Question |
|---|---|
| Q1 | (#355) **Aiming, firing, ammunition and damage model**: projectile, reload, range, who operates the weapon, damage to gates, objectives, players and other weapons. Next design session. Targeting may use the battle map tables (#224). |
| Q2 | Final footprint per size class, once real designs are chosen. |
| Q3 | Unlock per weapon type, or one unlock for siege weapons in general? |
| Q4 | (#356) Siege-coin earn rules for PvP Siege (which actions pay, how much) and starting prices. |
| Q5 | Where schematics are stored and how they are uploaded (plugin data folder, API, web app upload). |
| Q6 | Limits: maximum weapons per team or per player at once; whether a player can place on any of their team's spots. |
| Q7 | Exact menu integration: a new siege weapon menu, or an extension of the spawn point menu. |
| Q8 | Cannon in or out of V1. |
