# Siege Minigame — Siege Weapons

**Status:** Design complete for V1 gameplay (2026-11-16). Placement, operation, aiming, ammunition, damage, knockback,
armour, limits, economy, operator rules, spawn protection and the main engineering choices are decided by the
developer. Remaining items are balance values and the open questions in §12. No implementation plan, no code.
**Last updated:** 2026-11-16 (operating by right-click, objectives, knockback, damage fall-off, vanilla damage types and armour, scroll-wheel bolt choice, cone per template, whistle sound, animated projectiles, armed/fired/wreck schematics, spawn safe zones, balancing statistics); 2026-11-15 (size classes from reference designs, with links; aiming, firing, ammunition, limits, unlocks, siege points, operator rules, defenders,
siege fire, tactical/targeting map, entities and forms, siege shop, schematic storage, crash safety, token and lease;
"siege coins" renamed "siege points"); 2026-11-12 (first version)
**Issue:** [PandiO/knk-workspace#354](https://github.com/PandiO/knk-workspace/issues/354). Sub-issues: #355 aiming,
firing and damage design (recorded here), #356 siege points, #357 spot picker on the web map, #613 tactical map and
targeting page, #616 turning ballista research. Related issues from the same sessions: #611 siege shop, #612 notable
events, #614 schematic and snapshot pipeline, #615 siege fire, #651 balancing statistics, #652 test-run recording,
#653 usability testing.
**Related:**
- [DESIGN.md](DESIGN.md): the Siege minigame this extends (`SiegeScenario` §3.3, `SiegeTeam` §3.4, gates §8, rewards §7.6, menus §10)
- [../in-game-maps/DESIGN.md](../in-game-maps/DESIGN.md) and #224: battle map tables, a later in-game addition to the browser targeting page
- [../siege-survival/DESIGN.md](../siege-survival/DESIGN.md) and #41: Siege Survival's match currency (S12, S33), the model for siege points (§7)
- [../gate-structure-animation/](../gate-structure-animation/): gate health, `GateCrackVisuals` and destroy/respawn, the model for weapon damage feedback (§6)
- [../world-tasks/](../world-tasks/): the world tasks feature used to author weapon spots (§4)
- [../realtime-signalr/](../realtime-signalr/): the SignalR channel for the operator lease heartbeat and web app notifications (§8)

**Authority:** the developer's design conversations of 2026-11-12 (text) and the voice design sessions recorded on
2026-11-15 and 2026-11-16. Items marked *proposal* are suggestions the developer has not explicitly confirmed; treat them as defaults
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

### 2.5 Operating, impact, armour, visuals and spawn protection (voice session 2026-11-16)

| ID | Decision |
|---|---|
| W45 | **Operating a trebuchet or catapult starts with a right-click on any block of the weapon.** The spot bounds tell the plugin where to look: a right-click inside an occupied spot means that spot's weapon. An NPC "siege engineer" may come later as flavour. (Resolves Q1.) |
| W46 | **Capture points get no special effect** from shots. Players standing on one are hurt like anywhere else. Most objectives are indoors today, so shots rarely reach them. (Resolves Q3.) |
| W47 | **Knockback, configurable per ammo type.** A **blast** pushes players away from the impact point, weaker towards the edge (same curve as the damage, W48). A **direct hit** (ballista bolt, boulder) pushes along the projectile's flight direction, taken from the projectile entity's velocity, so a bolt flying north pushes north, angled slightly up or down. Solid projectiles push modestly; explosions push hard. |
| W48 | **Damage fall-off by effect:** **impact** (boulder, kinetic bolt): full damage in a small inner core, then a steep drop; **explosion** (bomb, explosive bolt): even fall-off from centre to edge; **fire**: no fall-off, players in the area are set alight, plus ground fire for the fire bomb; **poison**: the same poison effect for everyone in the radius. Numbers come from balance tests. (Resolves the curve part of Q5.) |
| W49 | **Vanilla damage types, so armour, enchantments and shields work by themselves.** Bolts and boulders deal projectile damage (Projectile Protection helps; boulders from trebuchets and catapults count too), bombs deal explosion damage (Blast Protection), fire bombs and incendiary bolts fire damage (Fire Protection), poison is a potion effect (armour doesn't help). Plain Protection reduces all of them a little. Shields block bolts from the front and soften blasts the vanilla way. Each ammo type gets an **optional armour-piercing factor**, because a full set of high-protection armour can cut damage by up to 80% (the vanilla enchantment cap). |
| W50 | **Capture progress earns siege points**, alongside personal play (W34). (Resolves the open part of Q4; amounts stay with #356.) |
| W51 | **Ballista bolt choice by scroll wheel, without touching the inventory.** While mounted, the plugin cancels the hotbar slot change and cycles the bolt type instead; the current bolt and its price show on the action bar. No items are swapped, so a crash or API outage can't lose any. An inventory menu stays as a fallback. (Resolves the second part of Q6.) |
| W52 | **The ballista's cone is set per template**, default 60° either side of the spot's facing. (Resolves Q6.) |
| W53 | **Impact warning: sound only, no visual marker.** An incoming shot whistles like modern artillery, then explodes. V1 uses pitch-shifted vanilla sounds (no server resource pack yet). |
| W54 | **Projectiles are visible in flight.** Trebuchet and catapult shots are **block display entities** (for example stone for a boulder, TNT for a bomb) moved along the arc every tick with a particle trail (smoke for bombs, flames for fire bombs); the client smooths the movement. The ballista bolt is a real arrow entity. A player watching the weapon sees the launch and can follow the path. |
| W55 | **Three schematics per template: armed, fired and wreck**, all on the same footprint. On firing the weapon swaps to **fired**, and back to **armed** when the reload ends, so its state shows from a distance. More in-between frames can come later, using the frame-swap approach of the gate animations. |
| W56 | **Spawn safe zones are fully protected.** A player inside their own team's spawn safe zone takes **no damage, poison, fire or knockback** from siege weapons. Firing at a spawn zone is **allowed**; protection is checked **per player at impact**, which is correct in 3D: a shot landing on a tower's upper floor hurts the players there, even with a spawn room directly below. The targeting map **shades spawn zones** and, when the target circle overlaps one, shows "Be advised: projectiles don't harm players inside their spawn zone." |
| W57 | **Balancing statistics:** siege weapon stats per match (shots, hits, damage and kills per weapon and ammo type) are logged, as part of general Siege balancing statistics for player kills, deaths and more (#651), recorded per alpha test run (#652). |

### 2.6 Review gaps closed (design run 2026-11-19)

A design run (`knk-design` skill) closed the gaps a review of this spec found on 2026-11-19. From here the log has
date and author columns; agent decisions list their alternatives in § 2.7 and are open to review until the design is
Decided.

| ID | Date | Who | Decision |
|---|---|---|---|
| W58 | 2026-11-19 | developer | **Spread by ranging in.** Each indirect template has a **start spread radius** and a **minimum spread radius**. Every consecutive shot by the same operator at about the same target (aim point within the current radius of the previous one) shrinks the radius by a template **ranging step** down to the minimum. It resets to the start radius when the aim point moves further, the operator changes or the lease ends. The impact point stays random inside the current circle (W16). |
| W59 | 2026-11-19 | developer | **Impact height and cover by line of sight.** An indirect shot lands on the **highest solid (motion-blocking) block** at the chosen x/z. A player inside the radius is affected (damage, knockback, fire, poison) only when a ray from just above the impact point to their body is not blocked by solid blocks; roofs and walls give cover. Structures (gates, weapons) use the same check against their nearest block. Ground fire from fire bombs is placed only where it has the same line of sight. |
| W60 | 2026-11-19 | developer | **Weapon kills pay full siege points,** streak and multiplier included, like any kill (W34). The snowball risk is accepted and watched in the alpha balance runs (#651, W57), using the per-match weapon kill statistics. |
| W61 | 2026-11-19 | developer | **No buyer privileges and no refunds.** W31 stands: the weapon is the team's from the moment it is placed; the buyer gets no lease priority, and a weapon destroyed during its build (or later) refunds nothing. Losing it in the build window is the risk W7 intends. (A placement the paste check refuses is never charged: W67.) |
| W62 | 2026-11-19 | developer | **In-game aiming fallback for indirect weapons in V1,** next to the browser page (W26 stays the main way). Right-clicking a trebuchet or catapult gives the operator two clickable choices in chat: the page link (W29) and **"aim in game"**. In game, they look at a block (a ray up to the template's max range) and fire with a click; ammo is chosen with the scroll wheel as for the ballista (W51). The same lease, server checks, spread (W58), costs and min/max range apply. There is no map, so blind shots over walls stay a browser advantage. |
| W63 | 2026-11-19 | developer | **The plugin owns weapon match state; the API relays page commands.** HP, build progress, reload timers, operator leases, spread (W58) and siege-point balances live in the plugin's match state (with its local checkpoint, W41). The page talks only to knk-web-api, which checks the page credential (W64) and forwards lease, heartbeat and fire commands to the plugin over the existing SignalR hub as request/response messages with a correlation id and a timeout; the plugin decides on the main thread and the API passes results and state changes back to the page. In-game actions (ballista, W62) never leave the plugin. Decision matrix: [DECISION-weapon-state.md](DECISION-weapon-state.md) (option 1, 92 of 100). |

## 3. Weapon templates, ammo types and size classes

A **weapon template** defines one weapon type:

| Field | Notes |
|---|---|
| Name, description | Shown in menus and on the targeting page. |
| Kind | Indirect (map-targeted: trebuchet, catapult) or direct (mounted: ballista). |
| Size class | small / medium / large (W3). |
| Armed, fired and wreck schematics | Ready to fire, just fired (shown during the reload) and destroyed, all on one footprint (W2, W8, W55), from the schematic pipeline (W40). |
| Max health | HP at the end of the build (W6). |
| Build time | Seconds from paste to full HP (W7). |
| Reload time | Seconds between shots (W21). |
| Max range, min range | Blocks from the spot; min range optional (W22). |
| Cone half-angle | Direct-fire weapons only; default 60° (W24, W52). |
| Gate damage multiplier | Damage factor against gates (W25). |
| Spot cooldown | Seconds the spot stays locked after destruction (W11). |
| Match price | Siege points to place it (W13). |
| Unlock price | Personal coins to unlock this type (W32). |
| Allowed ammo types | Many-to-many with ammo types (W19). |

An **ammo type** is its own entity, so heavy and light variants are simply different rows:

| Field | Notes |
|---|---|
| Name, description | For example "Heavy boulder", "Incendiary bolt". |
| Effect | Impact, explosion, fire or poison; sets the vanilla damage type (W49) and the fall-off curve (W48). |
| Damage | Player damage at the centre, with the effect's fall-off (W48). |
| Blast radius | Blocks, with a default (W18). |
| Knockback | Strength, with the same fall-off as the damage; direction away from impact for blasts, along the flight path for direct hits (W47). |
| Armour piercing | Optional factor that reduces how much armour and enchantments cut the damage (W49). |
| Projectile look | Block for the display entity and particle trail (W54). |
| Effect radius and duration | Fire area for fire bombs, poison level and duration for carcasses. |
| Price per shot | Siege points (W20). |

**Size classes (W3, updated 2026-11-15 from reference designs).** The developer chose the reference builds below; the
numbers are estimated by counting blocks in their screenshots (the pages themselves could not be opened from the
session) and get confirmed when our own schematics are built.

| Class | Footprint W × L × H (blocks) | Fits |
|---|---|---|
| Small | 7 × 9 × 5 | Ballista (compact designs) |
| Medium | 7 × 9 × 8 | Catapult; a large ballista whose bow spans more than 7 |
| Large | 9 × 15 × 16 | Trebuchet |

Changes from the first placeholders (5 × 5 × 5, 7 × 9 × 8, 11 × 15 × 16): **small** became long and flat, because a
ballista is a long rail with a wide bow; **large** became narrower, because a trebuchet is long and tall rather than
wide, which saves room along walls. Height above the footprint matters for the catapult's raised arm and the
trebuchet's throwing arm.

**Reference designs** (inspiration only):

| Design | Estimated size W × L × H | Fits class |
|---|---|---|
| [A simple ballista design](https://www.reddit.com/r/Minecraftbuilds/comments/o1dsrb/a_simple_ballista_design/) (r/Minecraftbuilds; the BrokenPixelSK build) | ~13 × 12 × 4 | Medium or larger: the bow is too wide for small |
| [Pinterest pin](https://nl.pinterest.com/pin/211174973434805/) | not measured | — |
| [Medieval siege weapons](https://www.reddit.com/r/DetailCraft/comments/1ssza13/medieval_siege_weapons/) (r/DetailCraft) | see the pack below | — |
| [Medieval Siege Weapons Pack](https://www.planetminecraft.com/project/medieval-siege-weapons-pack/) (Planet Minecraft): compact ballista | ~5 × 9 × 3 | Small |
| same pack: catapults and mangonels | ~5–7 × 7–9 × 4–6 | Medium |
| same pack: counterweight trebuchet | ~7 × 13 × 14 | Large |

The pack also has siege towers and a covered battering ram, which are out of scope (W1).

**Using the designs:** these builds belong to their authors. Before any of them is pasted on the server as-is, check
its licence or get the author's permission; the default plan is to build our own versions inspired by them and fitted
to these size classes. Each weapon also needs a **wreck** at the same footprint (W8); simple, low designs make more
convincing wrecks.

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

1. A team member right-clicks any block of the weapon (W45). If no one holds its lease, they get it (W36) and a clickable chat link with
   a one-time token (W29, W42).
2. The link opens the **targeting page** (§8): the scenario map with range rings, the targeting circle and the
   allowed ammo types with their prices.
3. They pick an ammo type and a target inside range and press fire. The server checks the token, lease, range, reload
   and the shooter's siege points, charges the shot, and starts the reload (W21).
4. The weapon swaps to its **fired** schematic (W55) and the plugin launches one visible projectile on an arc to a
   random point inside the targeting circle (W16, W54). Players near the impact hear the incoming whistle (W53). On
   impact it applies the ammo type's damage, effect and knockback (W17–W19, W47–W49), skipping players inside their
   own spawn safe zone (W56), and plays the explosion effect.
5. The page shows the reload countdown; when it ends the weapon swaps back to **armed**. The operator can fire again, or close the page (the lease then
   expires, W36).

### 5.3 Firing a ballista

1. A team member mounts the ballista and gets its lease (W36). The scroll wheel cycles the bolt type, shown with its
   price on the action bar, without changing the inventory (W51); a menu is the fallback.
2. They aim by looking, inside the cone around the spot's facing (W24), and fire. The server checks reload and siege
   points and charges the shot.
3. The ballista swaps to **fired** until the reload ends (W55). The bolt, a real arrow entity, flies straight and
   applies its ammo type's damage, effect and knockback along its flight direction (W47, W49), with the gate damage
   multiplier against gates (W25) and no effect on players in their own spawn safe zone (W56).
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
- **Spawn protection (W56):** players inside their own team's spawn safe zone take nothing from siege weapons: no
  damage, poison, fire or knockback. Checked per player at impact.
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
  Spawn safe zones are shaded; a target circle that overlaps one shows "Be advised: projectiles don't harm players
  inside their spawn zone." The shot is still allowed (W56).
- **Usability:** the page ships with usability logging and a few scripted tasks for test runs, such as "pick a target
  and fire a trebuchet" (#653).
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
- **Balancing statistics** (#651), **test-run recording** (#652) and **usability testing** (#653) cover the whole
  Siege minigame and the web app; siege weapons add their own events to them (W57). Plan balance runs with the
  [alpha balance test plan template](../../guides/alpha-balance-test-plan-template.md).

## 12. Open questions

| # | Question |
|---|---|
| Q1 | ~~How a player starts operating a trebuchet or catapult.~~ Decided 2026-11-16: right-click (W45). |
| Q2 | Confirm the size classes in §3 once our own schematics are built (current numbers are estimates from reference screenshots). |
| Q3 | ~~Effect of shots on objectives.~~ Decided 2026-11-16: none beyond hurting players (W46). |
| Q4 | (#356) Siege-point amounts per action. Capture progress pays too (W50). |
| Q5 | Default numbers per ammo type: damage, radius, knockback, armour piercing (balance tests, #651). Curves decided (W48). |
| Q6 | ~~Ballista cone and bolt choice.~~ Decided 2026-11-16: per template, default 60° (W52); scroll wheel (W51). |
| Q7 | Which object store to run on the NAS (#614). |
