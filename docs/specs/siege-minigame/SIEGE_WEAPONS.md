# Siege Minigame — Siege Weapons

**Status:** Design complete for V1 gameplay (2026-11-15). Placement, operation, aiming, ammunition, damage, limits,
economy, operator rules and the main engineering choices are decided by the developer. Remaining items are balance
values and the open questions in §12. No implementation plan, no code.
**Last updated:** 2026-11-15 (aiming, firing, ammunition, limits, unlocks, siege points, operator rules, defenders,
siege fire, tactical/targeting map, entities and forms, siege shop, schematic storage, crash safety, token and lease;
"siege coins" renamed "siege points"); 2026-11-12 (first version)
**Issue:** [PandiO/knk-workspace#354](https://github.com/PandiO/knk-workspace/issues/354). Sub-issues: #355 aiming,
firing and damage design (recorded here), #356 siege points, #357 spot picker on the web map, #613 tactical map and
targeting page, #616 turning ballista research. Related issues from the same sessions: #611 siege shop, #612 notable
events, #614 schematic and snapshot pipeline, #615 siege fire.
**Related:**
- [DESIGN.md](DESIGN.md): the Siege minigame this extends (`SiegeScenario` §3.3, `SiegeTeam` §3.4, gates §8, rewards §7.6, menus §10)
- [../in-game-maps/DESIGN.md](../in-game-maps/DESIGN.md) and #224: battle map tables, a later in-game addition to the browser targeting page
- [../siege-survival/DESIGN.md](../siege-survival/DESIGN.md) and #41: Siege Survival's match currency (S12, S33), the model for siege points (§7)
- [../gate-structure-animation/](../gate-structure-animation/): gate health, `GateCrackVisuals` and destroy/respawn, the model for weapon damage feedback (§6)
- [../world-tasks/](../world-tasks/): the world tasks feature used to author weapon spots (§4)
- [../realtime-signalr/](../realtime-signalr/): the SignalR channel for the operator lease heartbeat and web app notifications (§8)

**Authority:** the developer's design conversations of 2026-11-12 (text) and the voice design sessions recorded on
2026-11-15. Items marked *proposal* are suggestions the developer has not explicitly confirmed; treat them as defaults
for the implementation plan, not as decisions.

## 1. Goal

Players can field **siege weapons** during a Siege match: trebuchets, catapults and ballistas. Each scenario reserves
**spots** for them, owned by a team, attackers and defenders alike. A player who has unlocked a weapon type buys one in
the siege shop with siege points and picks a free spot of their team. The system pastes the weapon in from a
schematic, and it builds up over a configurable time, during which it can be attacked. Once built, **anyone on the
team** can operate it.

Trebuchets and catapults are **indirect, map-targeted artillery**: the operator picks a target on a BlueMap web page
and the shot lands randomly inside a targeting circle. The ballista is **direct fire**: the operator mounts it and
shoots where they look, and it is the best weapon against gates.

Scope: the Siege minigame (PvP). Siege Survival may get siege weapons later; nothing here changes that mode.

## 2. Decisions (developer)

### 2.1 Placement, build and destruction (2026-11-12)

| ID | Decision |
|---|---|
| W1 | **Roster:** ballista, catapult, trebuchet. **Battering rams are out for now** (they look odd in vanilla blocks and are too large for the current town dimensions). The cannon is out too (W25). |
| W2 | **Weapons are schematics.** A library of Minecraft schematics, one per weapon template, pasted in by the system on request. |
| W3 | **Three spot size classes** (small, medium, large). A larger spot can hold a smaller weapon. Sizes in §3 are placeholders until real designs are chosen. |
| W4 | **Spots are authored with the existing world tasks feature**, one world task per spot, from a WorldEdit selection or a WorldGuard region. |
| W5 | **Facing** is filled in by the world task from the admin's look direction; the admin can override it. |
| W6 | **Weapons have health points, like gates,** and can be damaged. |
| W7 | **Build time** is configurable per weapon template. During it, HP rises evenly from 0 to full, a deliberate window for the opponents to attack. |
| W8 | **Wreck schematic in V1:** a destroyed weapon is replaced by a destroyed variant, defined per template. |
| W9 | **Damage and destruction feedback follows gate doors:** broken block states (cracks) as HP drops, sounds, and particle effects. |
| W10 | **After destruction only that spot is locked** for a cooldown, not the weapon type for the team. |
| W11 | **Cooldown length is set on the weapon template,** with an optional override on the scenario. |
| W12 | **Spot selection V1: in-game menu** listing the team's free spots, with a command fallback (UI-first principle). Later, a spot picker mode on the web map (#357). |
| W13 | **Economy:** a weapon type is first **unlocked** permanently with **personal coins**; **placing** one in a match costs **siege points** (W33), a per-match balance earned in play and reset every match, like Call of Duty scorestreaks. |
| W14 | **Pricing in "minutes of good play":** prices are anchored to a good player's earn rate; every value is configurable and tuned during the alpha. |

### 2.2 Operation, aiming and ammunition (recorded 2026-11-15)

| ID | Decision |
|---|---|
| W15 | **One operator at a time** per weapon in V1. |
| W16 | **Trebuchet and catapult: map targeting, no in-game aiming.** The operator walks up and right-clicks the weapon (or an NPC at it, §12), gets a link to the BlueMap targeting page (§8), picks a target inside the weapon's range, and fires. V1 fires **one projectile per shot**; the impact point is **random inside the targeting circle**. The weapon's schematic never turns. |
| W17 | **Shots damage players, gates and siege weapons**, with an explosion effect. They never break blocks, except through siege fire in burnable regions (W37). |
| W18 | **Blast radius is configurable per ammo type,** with defaults. |
| W19 | **Ammo types per weapon template.** Each template lists its allowed ammo types; each ammo type has its own damage, blast radius, effect and price. **Trebuchet:** heavy boulder (small radius, high damage), heavy bomb (larger radius, lower damage spread out), heavy fire bomb (napalm-like fire over an area of configurable range) and heavy rotten carcass (poison in the radius). **Catapult:** lighter versions of the same four. The trebuchet's defining traits are a higher arc, larger projectiles, more damage and a larger area of effect. **Ballista:** bolts, kinetic, explosive and incendiary. |
| W20 | **Ammo is chosen on the targeting page** (ballista: §5.3) and costs **siege points per shot**, paid by **whoever fires**. |
| W21 | **Reload time per weapon template** (not per ammo type), shown as a countdown on the targeting page and on an **in-game info display** near the weapon with its state and reload time, **visible only to the owning team** (per-player displays, as the gate view does). |
| W22 | **Range:** a maximum range per template and an **optional minimum range**, both shown as rings on the targeting map. |
| W23 | **Friendly fire is off by default,** with a switch on the scenario. Allies follow the existing `AllianceGroup` rule. |
| W24 | **Ballista: direct fire, in V1.** The operator mounts it and it fires where they look, but only inside a **cone around the spot's facing** (*proposal:* ±60°); the schematic never turns. The developer wants it tested early; a research task looks at making it turn (#616). |
| W25 | **No cannon for now.** The ballista is the **gate-breaker**: each template has a **gate damage multiplier** (*proposal:* ×3 for the ballista); catapults and trebuchets damage gates too, less effectively. |

### 2.3 Limits, unlocks, siege points and operator rules (recorded 2026-11-15)

| ID | Decision |
|---|---|
| W30 | **Spots are the main limit.** On the scenario, the admin sets **per team how many of its spots are active**. |
| W31 | **No per-player limit:** a player who can afford it may fill every active spot of their team. A built weapon belongs to the **whole team**; the purchase is one player's, the use is everyone's. |
| W32 | **Unlocks are per weapon type** (trebuchet, catapult, ballista) and are only needed to **buy** a weapon, not to operate one, so a new player can fire a teammate's trebuchet. |
| W33 | **"Siege coins" are renamed "siege points"**, so they aren't confused with the coins on the player's account. |
| W34 | **Siege points come from personal play:** kills, assists, a **small amount per death** (catch-up), a **kill-streak multiplier** that is **capped** and **resets on death**, gate damage, a small trickle over time, and **notable events** (#612). Capture progress was on the first list; see §12 Q4. Amounts are configured and tuned in the alpha (#356). |
| W35 | **Operator rules:** if the operator dies, they are dismounted or their targeting session ends and the weapon is free. **Enemies can only damage a weapon, never fire it** (its facing and range assume the owning side). |
| W36 | **Operator lease:** opening the targeting page (or mounting the ballista) takes the weapon's lease. The page sends a heartbeat over SignalR about every 10 s; after about 30 s without one the lease expires (forgotten tab, phone locked, lost Wi-Fi). It is released at once when the operator dies, leaves the match or walks too far from the weapon. The fire command is **atomic on the server**: at most one shot per reload, even in a race. |

### 2.4 Defenders, fire, maps and engineering (recorded 2026-11-15)

| ID | Decision |
|---|---|
| W26 | **BlueMap** is the renderer for the targeting and tactical map (settles the earlier BlueMap vs Dynmap question; matches [in-game-maps](../in-game-maps/DESIGN.md) M2). **V1 uses a web page in the player's browser.** The in-game battle map tables (#224) are a later, switchable addition with the browser page as fallback; they are not in V1. |
| W27 | **Map content:** the **pre-game snapshot** tiles (no live re-render), **live markers of the player's own team only** (spectators, non-members and enemies hidden), and gate and objective markers. The view is locked to the scenario area. |
| W28 | **One page, two modes** (#613): a **tactical map** for every participant, linked at match start and meant to stay open on a second screen or phone, which switches to **targeting mode** when opened from a weapon. Nice to have: a SignalR notification in the web app for a logged-in player when their match starts. |
| W29 | **Opening from the game:** a clickable chat link with a one-time token. The token says which player, match and weapon it is for and **logs nobody in**. If a web session already exists it must belong to the same player, or the page refuses; if it does, the page uses that player's settings. |
| W37 | **Siege fire** (#615): during a match, fire **spreads and burns** in gate structure regions, which are snapshotted before and restored after the match (gate door blocks only go when the door is destroyed); elsewhere in the scenario town fire **spreads without destroying blocks** and goes out the vanilla way. |
| W38 | **Configuration through the form wizard:** the new entities get API metadata, which makes them editable in the web app's form wizard; default form configurations are seeded. No hand-built forms (§9). |
| W39 | **Siege shop** (#611): weapons are bought in **one general in-match shop** with categories (siege weapons, consumables such as ender pearls and healing potions, later magic), not a weapon-only menu. |
| W40 | **Schematic storage: a general schematic and snapshot pipeline** (#614): uploads through the web app into **S3-compatible object storage**, metadata in the database, short-lived links from the API, and the plugin caching files by hash. Siege weapons are its first user. |
| W41 | **Crash and outage safety:** before each paste the plugin snapshots the spot area and records it with the match, **also in a local file**, so after a crash or restart it restores every recorded spot even while the API is down, then syncs once the API is back. No blocks or states are left behind. |
| W42 | **Targeting token:** single-use, expires after about 5 minutes, bound to player, weapon and match. The server re-checks range, reload, siege points and the operator lease on every shot. The token stops working when the weapon is destroyed or the match ends. |
| W43 | **Pasting near players:** just before a paste, players inside the spot are pushed to its edge (as gate animations do). Placement is refused if the area holds anything other than air or the spot's recorded original blocks. |
| W44 | **Defenders use the same weapons and spots.** Spots belong to any team; whether defenders get spots (for example a catapult on a wall tower) is up to the scenario designer. |

## 3. Weapon templates, ammo types and size classes

A **weapon template** defines one weapon type:

| Field | Notes |
|---|---|
| Name, description | Shown in menus and on the targeting page. |
| Kind | Indirect (map-targeted: trebuchet, catapult) or direct (mounted: ballista). |
| Size class | small / medium / large (W3). |
| Schematic, wreck schematic | The working weapon and its destroyed variant (W2, W8), from the schematic pipeline (W40). |
| Max health | HP at the end of the build (W6). |
| Build time | Seconds from paste to full HP (W7). |
| Reload time | Seconds between shots (W21). |
| Max range, min range | Blocks from the spot; min range optional (W22). |
| Cone half-angle | Direct-fire weapons only (W24). |
| Gate damage multiplier | Damage factor against gates (W25). |
| Spot cooldown | Seconds the spot stays locked after destruction (W11). |
| Match price | Siege points to place it (W13). |
| Unlock price | Personal coins to unlock this type (W32). |
| Allowed ammo types | Many-to-many with ammo types (W19). |

An **ammo type** is its own entity, so heavy and light variants are simply different rows:

| Field | Notes |
|---|---|
| Name, description | For example "Heavy boulder", "Incendiary bolt". |
| Effect | Impact, explosion, fire or poison. |
| Damage | Player damage at the centre; *proposal:* falls off towards the edge, with impact-type ammo concentrated near the centre. |
| Blast radius | Blocks, with a default (W18). |
| Effect radius and duration | Fire area for fire bombs, poison level and duration for carcasses. |
| Price per shot | Siege points (W20). |

**Size classes (placeholders, W3).** The developer will pick real designs from online references; the final numbers
come from those.

| Class | Footprint W × L × H (blocks) | Fits |
|---|---|---|
| Small | ~5 × 5 × 5 | Ballista |
| Medium | ~7 × 9 × 8 | Catapult |
| Large | ~11 × 15 × 16 | Trebuchet |

A spot accepts any weapon whose class is the same size or smaller. *Proposal:* schematics are authored facing one
fixed direction (for example north) so they can be rotated in 90° steps to the spot's facing.

## 4. Weapon spots (scenario authoring)

- Each scenario has reserved **weapon spots**, and each spot belongs to one team, attacker or defender (W44).
- An admin creates a spot through a **world task** (W4): they make a WorldEdit selection or pick a WorldGuard region,
  and the task stores its bounds.
- The **size class is derived from the selection's dimensions.** A selection smaller than the small class is
  rejected. *Proposal:* the class is the largest one whose footprint fits.
- **Facing** is pre-filled from the admin's look direction when they confirm the task, and the admin can change it
  (W5). *Proposal:* rounded to the nearest of north, east, south, west, matching the 90° schematic rotation.
- **Team** is a field on the spot. **Active spots per team** is a field on the team or scenario (W30).
- A spot on a wall or tower must hold the paste exactly: the world task should warn when the selection's floor isn't
  solid or the volume isn't clear (*proposal*, W44).
- *Proposal:* spots join the scenario readiness check (DESIGN §3.9) as a warning, not a blocker, so a scenario
  without spots stays playable.

## 5. Player flow

### 5.1 Buying and placing

1. The player has unlocked the weapon type (W32).
2. During the match, they open the **siege shop** (#611) and choose a weapon in the siege weapons category. A command
   does the same as a fallback.
3. They pick one of their team's **free, active spots** that fits the weapon's size class (V1: a menu list;
   *proposal:* each entry shows a rough location, and hovering briefly highlights the spot with particles).
4. The match charges the siege-point price. Players inside the spot are pushed to its edge, the spot area is
   snapshotted (W41, W43), and the schematic is pasted, rotated to the spot's facing.
5. The **build phase** runs (§6). At its end the weapon is ready, for the whole team (W31).

### 5.2 Firing a trebuchet or catapult

1. A team member right-clicks the weapon. If no one holds its lease, they get it (W36) and a clickable chat link with
   a one-time token (W29, W42).
2. The link opens the **targeting page** (§8): the scenario map with range rings, the targeting circle and the
   allowed ammo types with their prices.
3. They pick an ammo type and a target inside range and press fire. The server checks the token, lease, range, reload
   and the shooter's siege points, charges the shot, and starts the reload (W21).
4. The plugin launches one projectile on an arc to a random point inside the targeting circle (W16). On impact it
   applies the ammo type's damage and effect (W17–W19) and plays the explosion effect.
5. The page shows the reload countdown; the operator can fire again when it ends, or close the page (the lease then
   expires, W36).

### 5.3 Firing a ballista

1. A team member mounts the ballista and gets its lease (W36). An in-game menu or the hotbar picks the bolt type
   (*proposal*).
2. They aim by looking, inside the cone around the spot's facing (W24), and fire. The server checks reload and siege
   points and charges the shot.
3. The bolt flies straight and applies its ammo type's damage and effect, with the gate damage multiplier against
   gates (W25).
4. Dismounting, dying or leaving the match releases the lease.

## 6. Health, build phase and destruction

- **Health (W6):** every weapon has HP. Damage sources: enemy players, enemy siege weapon shots, fire and explosions;
  allies only when friendly fire is on (W23).
- **Build phase (W7):** HP starts at 0 and rises evenly to the template's max over its build time. The weapon can be
  attacked while it builds and can't fire until it's built.
- **Damage feedback (W9):** reuse the gate approach: health-based cracks per viewer (`GateCrackVisuals`, Paper
  `Player#sendBlockDamage`) and sounds, plus particle effects (for gates too, if they don't have them yet; to check in
  knk-plugin).
- **Destruction (W8):** at 0 HP the system plays the destruction sound and particles, ends any operator lease, and
  **swaps the schematic for the template's wreck schematic**.
- **Spot cooldown (W10, W11):** only that spot is locked, for the template's cooldown or the scenario override. The
  wreck stays while the spot is locked and is cleared when the spot frees up.
- **Team info display (W21):** a per-player display near the weapon shows its state (building with HP, ready,
  reloading with countdown, in use) to the owning team only.
- **Match end:** every weapon and wreck is removed and every spot restored from its snapshot (W41).

## 7. Economy

- **Unlock (W32):** permanent, per weapon type, on the player's account, paid with personal coins (`User.Coins`).
  Needed to buy, not to operate.
- **Siege points (W33, W34):** a per-match balance that starts at 0 and is reset every match. Earned from personal
  play (W34). Spent on weapon placements and shots (W13, W20), and on other shop items (#611). Never converts to
  personal coins. This is the same concept as Siege Survival's match currency (S12, S33); #356 builds it once for both
  modes where possible.
- **Pricing (W14):** price each weapon and shot in minutes of good play. *Example only:* if a good player earns about
  100 siege points a minute, a ballista costs about 2 minutes' worth (200) and a trebuchet about 8 (800). Earn rates
  and prices are configuration, tuned during the alpha.

## 8. Tactical and targeting map (#613)

One BlueMap-based web page in the player's browser, in two modes (W28):

- **Tactical map:** for every participant. At match start the player gets a clickable chat link; logged-in players
  can also get a web app notification over SignalR (nice to have). Shows the scenario area on the pre-game snapshot
  tiles, live markers of the player's own team, and gate and objective markers (W27).
- **Targeting mode:** opened from a trebuchet or catapult (§5.2). Adds the weapon's range rings, the targeting circle
  under the cursor, ammo choice with prices, the player's siege points, the reload countdown and the fire button.
- **Later:** a spot picker mode (#357) and the in-game battle map tables (#224).

Rules:

- **Area lock:** the view is limited to the scenario's bounds and zoom levels, and the tile server refuses tiles
  outside them, so the page can't be used to scout the rest of the world.
- **Team-only markers:** BlueMap's public live-player layer is switched off; the page fetches markers for the
  player's team with its token.
- **No login by link** (W29). A token proves player, match and weapon; an existing web session must match that
  player.
- **Token and lease** as in W36 and W42.

## 9. Configuration: entities, forms and menus

CRUD in the web app runs through the **form wizard**: every API entity with metadata can get form configurations, so
the work is defining the entities and seeding default forms (W38).

*Proposal*, following the siege domain conventions in DESIGN §3:

- `SiegeWeaponTemplate`: the fields in §3, with schematic references into the schematic pipeline (#614).
- `SiegeAmmoType`: the fields in §3; many-to-many with `SiegeWeaponTemplate`.
- `SiegeWeaponSpot`, owned by `SiegeScenario`: `SiegeTeamId`, bounds (min/max corner or WorldGuard region id),
  derived `SizeClass`, `Facing`, `Name`, `SortOrder`; created through a world task.
- `SiegeTeam.ActiveWeaponSpots` (W30).
- `SiegeScenario.WeaponSpotCooldownOverrideSeconds` (nullable, W11) and `SiegeScenario.FriendlyFire` (W23).
- `UserSiegeWeaponUnlock`: user, weapon template, unlocked at (W32).
- Siege points earn rates and the kill-streak cap: scenario or global siege settings (#356).
- Runtime only (plugin, match state with local checkpoint): placed weapons with HP, build progress, reload timers,
  operator leases, spot snapshots and lock timers, and each player's siege-point balance.
- **Default form seeds** for templates, ammo types and the scenario's spot list.

In-game menus: the **siege shop** with its siege weapons category and spot picker (#611), siege points shown in the
shop and on the scoreboard, and the ballista's bolt choice. Menus are UI-first with a command fallback.

**Schematic storage decision (W40).** Options weighed in the session:

| Option | Admin management | Plugin load speed | Backups and sync | Effort |
|---|---|---|---|---|
| A: files in the plugin folder | Poor, needs server file access | Fast | Manual | Lowest |
| B: web app upload, stored in the database | Good | Slower, large blobs | Comes with database backups | Medium |
| C: web app upload, files in object storage, plugin caches by hash | Good | Fast after the first load | Bucket plus metadata | Medium |

**Chosen: C on S3-compatible object storage** (self-hosted in Docker on the NAS for the alpha, for example Garage,
MinIO or SeaweedFS; Cloudflare R2 or S3 on a VPS later by config change). It is a general pipeline: later users are
destroyed gate variants, region snapshots for siege fire restores and resettable ore mines (#614).

## 10. Engineering safeguards

- **Crash and outage safety (W41):** spot snapshots are recorded with the match and in a local file before each paste;
  on startup and at match end the plugin restores every recorded spot, without needing the API, and syncs later. The
  same applies to siege fire restores (#615).
- **Concurrency (W36):** one lease per weapon, heartbeat expiry, atomic fire, server-side re-validation on every shot.
- **Paste safety (W43):** push players out, refuse a paste over unexpected blocks.

## 11. Effects outside this feature

- **Siege fire** (#615) changes fire rules for the whole match area; it is a Siege minigame feature that incendiary
  ammo uses.
- **Notable events** (#612) are a Siege and Siege Survival feature; they pay siege points (W34) and mission score.
- **Siege shop** (#611) is shared by weapons and future consumables and magic.
- **Schematic pipeline** (#614) is shared infrastructure.

## 12. Open questions

| # | Question |
|---|---|
| Q1 | How a player starts operating a trebuchet or catapult: right-click the schematic, or an NPC standing at it. |
| Q2 | Final footprint per size class, once real designs are chosen. |
| Q3 | Objectives: Siege objectives are capture points without health. Should shots affect them (for example pausing capture progress), or only players, gates and weapons? |
| Q4 | (#356) Siege-point amounts per action, and whether capture progress still pays points, given the wish to earn from personal play rather than siege progress. |
| Q5 | Damage fall-off curve per ammo effect and the default numbers per ammo type (balance tests). |
| Q6 | Ballista cone angle and how the bolt type is chosen while mounted. |
| Q7 | Which object store to run on the NAS (#614). |
