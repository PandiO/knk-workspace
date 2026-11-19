# Siege Minigame — Siege Weapons

**Status:** **Decided 2026-11-19** (developer), with one change on approval (W75). Open questions answered (§ 15);
agent decisions W64–W73 accepted with the approval. Earlier: V1 gameplay decided 2026-11-12 to 2026-11-16 (W1–W57),
review gaps closed 2026-11-19 (W58–W74). Phases and sub-issues in § 14.2. Phase 1 (#782: entities, API, form seeds,
unlocks) merged into `next`. Phase 2 (#783: weapon spots, size class from bounds and facing in the plugin and on API
saves) merged into `next`; link L2b (#799, developer decision 2026-11-19) makes the spot task the web form's
`SiegeWeaponSpot` world task with a fan-out onto the spot's fields and removes L2's `/knk weaponspot`, built on branches
`claude/siege-weapons-l2b` (PRs into `next`), behind `siege.weapons.enabled` (default off).
**Last updated:** 2026-11-19 (spot task through the web form's world task, link L2b, #799); 2026-11-19 (phase 2 built on branches, link L2 of the chain); 2026-11-19 (phase 1 built on branches, link L1 of the chain); 2026-11-19 (Decided: W75 aiming preview arc, open questions answered, phases split to 9 with
sub-issues, smoke-test guide); 2026-11-19 (design run, `knk-design` skill: spread by ranging in, impact height and cover, weapon
kill points, no buyer privileges, in-game aiming fallback, plugin-owned state with the API as relay
([DECISION-weapon-state.md](DECISION-weapon-state.md)), page credential, structure damage, flight time, check before
charging, player damage to weapons, kill credit, size class relative to facing, idle lease, bolt damage, map snapshot
and tiles, Engineer profession later; new sections: current state, platform-specific parts, risks, acceptance
checklist, phases); 2026-11-16 (operating by right-click, objectives, knockback, damage fall-off, vanilla damage types and armour, scroll-wheel bolt choice, cone per template, whistle sound, animated projectiles, armed/fired/wreck schematics, spawn safe zones, balancing statistics); 2026-11-15 (size classes from reference designs, with links; aiming, firing, ammunition, limits, unlocks, siege points, operator rules, defenders,
siege fire, tactical/targeting map, entities and forms, siege shop, schematic storage, crash safety, token and lease;
"siege coins" renamed "siege points"); 2026-11-12 (first version)
**Issue:** [PandiO/knk-workspace#354](https://github.com/PandiO/knk-workspace/issues/354). Sub-issues: #355 aiming,
firing and damage design (recorded here), #356 siege points, #357 spot picker on the web map, #613 tactical map and
targeting page, #616 turning ballista research. Related issues from the same sessions: #611 siege shop, #612 notable
events, #614 schematic and snapshot pipeline, #615 siege fire, #651 balancing statistics, #652 test-run recording,
#653 usability testing. Phases are sub-issues (§ 14.2).
**Dependencies:** siege points (#356), siege shop (#611), schematic and snapshot pipeline (#614), tactical and
targeting map (#613), realtime channel (SignalR hub, built); siege fire (#615) only for incendiary ammo.
**Related:**
1. [DESIGN.md](DESIGN.md): the Siege minigame this extends (`SiegeScenario` §3.3, `SiegeTeam` §3.4, gates §8, rewards §7.6, menus §10)
2. [../in-game-maps/DESIGN.md](../in-game-maps/DESIGN.md) and #224: battle map tables, a later in-game addition to the browser targeting page
3. [../siege-survival/DESIGN.md](../siege-survival/DESIGN.md) and #41: Siege Survival's match currency (S12, S33), the model for siege points (§7)
4. [../gate-structure-animation/](../gate-structure-animation/): gate health, `GateCrackVisuals` and destroy/respawn, the model for weapon damage feedback (§6)
5. [../world-tasks/](../world-tasks/): the world tasks feature used to author weapon spots (§4)
6. [../realtime-signalr/](../realtime-signalr/): the SignalR channel for the operator lease heartbeat, the page relay (W63) and web app notifications (§8)
7. [DECISION-weapon-state.md](DECISION-weapon-state.md): decision matrix for W63

**Authority:** the developer's design conversations of 2026-11-12 (text) and the voice design sessions recorded on
2026-11-15 and 2026-11-16, and the design run of 2026-11-19 (questions answered by the developer in the session; agent
decisions marked "agent" in § 2.6, accepted with the approval of 2026-11-19). Items marked *proposal* are suggestions the developer has not explicitly confirmed; treat them as defaults
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

## 2. Decisions

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
| W16 | **Trebuchet and catapult: map targeting, no in-game aiming.** The operator walks up and right-clicks the weapon (or an NPC at it, § 15 After v1), gets a link to the BlueMap targeting page (§8), picks a target inside the weapon's range, and fires. V1 fires **one projectile per shot**; the impact point is **random inside the targeting circle**. The weapon's schematic never turns. *2026-11-19: an in-game aiming fallback is added next to the page (W62); "no in-game aiming" no longer holds.* |
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
| W34 | **Siege points come from personal play:** kills, assists, a **small amount per death** (catch-up), a **kill-streak multiplier** that is **capped** and **resets on death**, gate damage, a small trickle over time, and **notable events** (#612). Capture progress was on the first list; see § 15 question 2. Amounts are configured and tuned in the alpha (#356). |
| W35 | **Operator rules:** if the operator dies, they are dismounted or their targeting session ends and the weapon is free. **Enemies can only damage a weapon, never fire it** (its facing and range assume the owning side). |
| W36 | **Operator lease:** opening the targeting page (or mounting the ballista) takes the weapon's lease. The page sends a heartbeat over SignalR about every 10 s; after about 30 s without one the lease expires (forgotten tab, phone locked, lost Wi-Fi). It is released at once when the operator dies, leaves the match or walks too far from the weapon. The fire command is **atomic on the server**: at most one shot per reload, even in a race. *Extended 2026-11-19: idle timeout (W71); the plugin is the server that decides (W63).* |

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
| W42 | **Targeting token:** single-use, expires after about 5 minutes, bound to player, weapon and match. The server re-checks range, reload, siege points and the operator lease on every shot. The token stops working when the weapon is destroyed or the match ends. *Clarified 2026-11-19: the token is redeemed once for a page credential (W64).* |
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
date and author columns; agent decisions list their alternatives in § 2.7 and were accepted when the developer approved the
design on 2026-11-19.

| ID | Date | Who | Decision |
|---|---|---|---|
| W58 | 2026-11-19 | developer | **Spread by ranging in.** Each indirect template has a **start spread radius** and a **minimum spread radius**. Every consecutive shot by the same operator at about the same target (aim point within the current radius of the previous one) shrinks the radius by a template **ranging step** down to the minimum. It resets to the start radius when the aim point moves further, the operator changes or the lease ends. The impact point stays random inside the current circle (W16). |
| W59 | 2026-11-19 | developer | **Impact height and cover by line of sight.** An indirect shot lands on the **highest solid (motion-blocking) block** at the chosen x/z. A player inside the radius is affected (damage, knockback, fire, poison) only when a ray from just above the impact point to their body is not blocked by solid blocks; roofs and walls give cover. Structures (gates, weapons) use the same check against their nearest block. Ground fire from fire bombs is placed only where it has the same line of sight. |
| W60 | 2026-11-19 | developer | **Weapon kills pay full siege points,** streak and multiplier included, like any kill (W34). The snowball risk is accepted and watched in the alpha balance runs (#651, W57), using the per-match weapon kill statistics. |
| W61 | 2026-11-19 | developer | **No buyer privileges and no refunds.** W31 stands: the weapon is the team's from the moment it is placed; the buyer gets no lease priority, and a weapon destroyed during its build (or later) refunds nothing. Losing it in the build window is the risk W7 intends. (A placement the paste check refuses is never charged: W67.) |
| W62 | 2026-11-19 | developer | **In-game aiming fallback for indirect weapons in V1,** next to the browser page (W26 stays the main way). Right-clicking a trebuchet or catapult gives the operator two clickable choices in chat: the page link (W29) and **"aim in game"**. In game, they look at a block (a ray up to the template's max range) and fire with a click; ammo is chosen with the scroll wheel as for the ballista (W51). The same lease, server checks, spread (W58), costs and min/max range apply. There is no map, so blind shots over walls stay a browser advantage. |
| W63 | 2026-11-19 | developer | **The plugin owns weapon match state; the API relays page commands.** HP, build progress, reload timers, operator leases, spread (W58) and siege-point balances live in the plugin's match state (with its local checkpoint, W41). The page talks only to knk-web-api, which checks the page credential (W64) and forwards lease, heartbeat and fire commands to the plugin over the existing SignalR hub as request/response messages with a correlation id and a timeout; the plugin decides on the main thread and the API passes results and state changes back to the page. In-game actions (ballista, W62) never leave the plugin. Decision matrix: [DECISION-weapon-state.md](DECISION-weapon-state.md) (option 1, 92 of 100). |
| W64 | 2026-11-19 | agent | **Link token → page credential.** The chat link's token (W29, W42) is single-use: the page redeems it once with the API for a **page credential** scoped to that player, match and weapon (targeting mode) or player and match (tactical mode). Heartbeats, fire commands and team markers use the credential. It ends with the lease (targeting) or the match (tactical), when the weapon is destroyed, or when the player leaves the match; the unredeemed link token still expires after about 5 minutes. Server-side checks on every shot (W42) are unchanged. (Alternatives in § 2.7.) |
| W65 | 2026-11-19 | agent | **Structure damage is its own value.** Each ammo type gets **structure damage** in gate HP units (gates default to 500 HP in knk-plugin), used against gates and siege weapons with the same fall-off and line of sight as player damage (W48, W59). The template's gate damage multiplier (W25) stays, and a **weapon damage multiplier** (default ×1) is added next to it for hits on enemy siege weapons. (Alternatives in § 2.7.) |
| W66 | 2026-11-19 | agent | **Flight time per template.** Indirect templates get a **flight time at max range** (*proposal:* trebuchet 4 s, catapult 3 s) and an **arc height**; a shorter shot scales the time with distance, never below 1.5 s. The whistle (W53) starts on its way down, about 1.5 s before impact, for players near the impact point. (Alternatives in § 2.7.) |
| W67 | 2026-11-19 | agent | **Check before charging.** Placement checks every condition (unlock, free active spot that fits, paste area clear, W43, enough siege points) before taking siege points. A refused placement charges nothing and says why. The same order holds for shots: checks, then charge, then fire. (Alternatives in § 2.7.) |
| W68 | 2026-11-19 | agent | **Players damage weapons the way they damage gates.** The weapon's blocks take hits through the same causes the gate door hit model knows (`GateDoorHitService`: melee left-click, projectiles, fire), with per-cause damage taken from the existing gate settings, plus siege shots (W65) and explosions. Only enemies of the owning team (and allies when friendly fire is on, W23) do damage. (Alternatives in § 2.7.) |
| W69 | 2026-11-19 | agent | **Kill credit goes to the shooter.** A kill or assist by a siege shot, its fire or its poison is credited to the player who fired it (siege points W60, statistics W57), for as long as the effect they caused lasts. Ground fire and burning remember the shooter's team, so friendly fire off (W23) also covers fire and poison. The buyer gets no share unless they fired (W61). (Alternatives in § 2.7.) |
| W70 | 2026-11-19 | agent | **Size class measured relative to facing.** A spot's footprint is read as **width across the facing × length along it**, and its class is worked out again whenever the admin changes the facing (W5). Schematics are authored facing north (§ 3 proposal), so a north-facing 7 × 9 weapon needs a spot 7 wide and 9 deep in its facing direction. (Alternatives in § 2.7.) |
| W71 | 2026-11-19 | agent | **Idle lease timeout.** A lease also ends when its operator has not fired for a configurable time (*proposal:* 60 s after the weapon is ready), even while the heartbeat is alive. Any teammate can then take it. The page and the in-game display say "lease ended: idle". (Alternatives in § 2.7.) |
| W72 | 2026-11-19 | agent | **Bolts do only ammo damage.** The ballista bolt is a real arrow entity (W54), but its vanilla damage is cancelled; on hit the plugin applies the ammo type's damage, effect, knockback and structure damage instead. The arrow can't be picked up and is removed on impact. (Alternatives in § 2.7.) |
| W73 | 2026-11-19 | agent | **Map snapshot and tile access.** Each scenario's snapshot tiles are rendered offline by the BlueMap container (in-game-maps § 7) when an admin asks for it (*proposal:* a "render map snapshot" action on the scenario), not at match start. Tiles are served through a small reverse proxy that only serves the scenario's area and needs a valid page credential (W64); BlueMap's public live-player layer stays off (§ 8). Details are #613's. (Alternatives in § 2.7.) |
| W74 | 2026-11-19 | developer | **Coin unlocks now, Engineer profession later.** V1 keeps W32's coin unlocks. When professions are designed (vision § 4.2, open), the Engineer profession may become an extra or alternative unlock path (for example cheaper unlocks or a faster build). Nothing changes now; listed under "After v1" in § 15. |
| W75 | 2026-11-19 | developer | **Aiming preview arc for the in-game fallback** (approval change, extends W62). While a trebuchet or catapult operator aims in game, the plugin draws a **particle trail arc** from the weapon to the looked-at point and the **targeting circle** at its current spread (W58) on the highest solid block there (W59), refreshed a few times a second (*proposal:* every 5 ticks) and visible **only to the operator**. The arc follows the projectile's path for that distance (W66). Out of range, under the minimum range or with no solid block, the arc and circle switch to a warning colour and firing is refused. The page (W26) stays the main way; this is its preferred in-game backup, together with look-to-target aiming. |

### 2.7 Agent decisions: alternatives

1. **W64 token and page credential.** Chosen: redeem the single-use link token for a scoped page credential, because
   the page needs to authenticate for many minutes (heartbeats, shots) while a chat link must stay worthless once
   used or leaked.
    1. (a) Reuse the link token for every request until it expires: a leaked link (screenshot, stream) can fire for
       five minutes, and "single-use" in W42 would be untrue.
    2. (b) Require a web app login: W29 says the link logs nobody in, and most players won't have a web account.
2. **W65 structure damage.** Chosen: a separate structure damage per ammo type, because player HP (20) and gate HP
   (500 by default) differ by a factor of 25 and ammo types need different ratios (a boulder is good against walls,
   poison is useless).
    1. (a) One global conversion factor from player damage: poison and fire would hurt gates as much as boulders.
    2. (b) Only the template's gate multiplier: same problem, and no way to tune weapon-vs-weapon fights.
3. **W66 flight time.** Chosen: per-template flight time at max range, scaled by distance, because it gives a
   predictable warning and lets the trebuchet feel slower and heavier than the catapult.
    1. (a) Real ballistic physics from launch speed and gravity: harder to tune and flight times would vary a lot
       with height differences.
    2. (b) One global flight time: short shots would hang in the air as long as long shots.
4. **W67 check before charging.** Chosen: validate everything, then charge, because a refusal after payment needs a
   refund path that can fail.
    1. (a) Charge, then refund on refusal: two writes, a refund that can be lost in a crash.
5. **W68 player damage to weapons.** Chosen: reuse the gate hit model, because players already know how to damage a
   gate and the plugin already resolves hits by cause.
    1. (a) Only siege shots and explosions hurt weapons: a weapon in the build window could not be stopped by players
       on foot, which W7 wants.
    2. (b) A special tool or item to damage weapons: new item and teaching cost for little gain.
6. **W69 kill credit.** Chosen: the shooter, because they chose the target and paid for the shot (W20).
    1. (a) Split with the buyer: contradicts W61 (no buyer privileges) and complicates statistics.
    2. (b) No credit for fire and poison: lingering effects would kill for free.
7. **W70 size class and facing.** Chosen: measure relative to facing, because schematics rotate with the facing and
   a footprint that fits one way may not fit turned.
    1. (a) Require square-tolerant spots (largest side in both directions): wastes wall space, which § 3 tried to save.
8. **W71 idle lease.** Chosen: an idle timeout on top of the heartbeat, because a teammate with the page open but
   not firing blocks a weapon the team paid for.
    1. (a) Let a teammate "request" the lease and the holder accept: needs a prompt the holder may never see.
    2. (b) No timeout: W36's heartbeat only catches closed tabs, not idle ones.
9. **W72 bolt damage.** Chosen: cancel vanilla arrow damage and apply the ammo's, because otherwise each bolt hits
   twice and armour rules (W49) would apply to two different numbers.
    1. (a) Use vanilla arrow damage and tune the bolt's speed: no control over explosive and incendiary effects.
10. **W73 map snapshot and tiles.** Chosen: admin-triggered offline render plus a credential-checking proxy, because
    in-game-maps M5 already chose offline snapshots and the area lock (§ 8) can't be done with static files alone.
    1. (a) Render at every match start: minutes of CPU on the NAS per match, for no player benefit.
    2. (b) Serve the whole world's static tiles: breaks the area lock; the page could scout the world.

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
| Start spread, minimum spread, ranging step | Indirect only: targeting circle radius at the first shot, its floor, and how much each consecutive shot at the same target takes off (W58). |
| Flight time at max range, arc height | Indirect only (W66). |
| Lease idle timeout | Seconds without a shot before the lease ends (W71); a global default with a template override. |
| Cone half-angle | Direct-fire weapons only; default 60° (W24, W52). |
| Gate damage multiplier | Factor on structure damage against gates (W25, W65). |
| Weapon damage multiplier | Factor on structure damage against enemy siege weapons, default ×1 (W65). |
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
| Structure damage | Damage to gates and siege weapons in gate HP units, same fall-off and line of sight (W59, W65). |
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

A spot accepts any weapon whose class is the same size or smaller, with footprints compared as width across the
facing × length along it (W70). *Proposal:* schematics are authored facing one
fixed direction (for example north) so they can be rotated in 90° steps to the spot's facing.

## 4. Weapon spots (scenario authoring)

1. Each scenario has reserved **weapon spots**, and each spot belongs to one team, attacker or defender (W44).
2. An admin creates a spot through a **world task** (W4): they make a WorldEdit selection or pick a WorldGuard region,
   and the task stores its bounds.
3. The **size class is derived from the selection's dimensions,** measured as width across the facing × length along
   it, and derived again when the facing changes (W70). A selection smaller than the small class is rejected.
   *Proposal:* the class is the largest one whose footprint fits.
4. **Facing** is pre-filled from the admin's look direction when they confirm the task, and the admin can change it
   (W5). *Proposal:* rounded to the nearest of north, east, south, west, matching the 90° schematic rotation.
5. **Team** is a field on the spot. **Active spots per team** is a field on the team or scenario (W30).
6. A spot on a wall or tower must hold the paste exactly: the world task should warn when the selection's floor isn't
   solid or the volume isn't clear (*proposal*, W44).
7. *Proposal:* spots join the scenario readiness check (DESIGN §3.9) as a warning, not a blocker, so a scenario
   without spots stays playable.

## 5. Player flow

### 5.1 Buying and placing

1. The player has unlocked the weapon type (W32).
2. During the match, they open the **siege shop** (#611) and choose a weapon in the siege weapons category. A command
   does the same as a fallback.
3. They pick one of their team's **free, active spots** that fits the weapon's size class (V1: a menu list;
   *proposal:* each entry shows a rough location, and hovering briefly highlights the spot with particles).
4. The plugin checks everything first (unlock, spot free and active, paste area clear, enough siege points); a
   refusal charges nothing and says why (W67). Then the match charges the siege-point price, players inside the spot
   are pushed to its edge, the spot area is snapshotted (W41, W43), and the schematic is pasted, rotated to the spot's
   facing. The weapon is the team's from now on; the buyer gets no priority and no refund (W61).
5. The **build phase** runs (§6). At its end the weapon is ready, for the whole team (W31).

### 5.2 Firing a trebuchet or catapult

1. A team member right-clicks any block of the weapon (W45). If no one holds its lease, they get it (W36) and two
   clickable choices in chat: the **targeting page** link with a one-time token (W29, W42) and **"aim in game"** (W62).
2. **Page:** the link opens the targeting page (§8), which redeems the token for a page credential (W64). It shows the
   scenario map with range rings, the targeting circle at its current spread (W58) and the allowed ammo types with
   their prices.
3. **In game (W62, W75):** the operator looks at a block within range; a particle arc runs from the weapon to the
   targeting circle at that point, shown only to them, in a warning colour when the point is out of range. The
   action bar shows the ammo type and price (scroll wheel to change, as W51). A click fires.
4. On fire, the plugin, which owns the weapon's state (W63; page commands arrive through the API relay), checks the
   lease, range, reload and the shooter's siege points, charges the shot and starts the reload (W21, W67).
5. The weapon swaps to its **fired** schematic (W55) and the plugin launches one visible projectile on an arc to a
   random point inside the current targeting circle (W16, W54, W58), landing on the highest solid block there (W59)
   after the template's flight time (W66). Players near the impact hear the whistle on the way down (W53). On impact
   it applies the ammo type's damage, effect, knockback and structure damage (W17–W19, W47–W49, W65) to everyone and
   everything with line of sight to the impact (W59), skipping players inside their own spawn safe zone (W56), and
   plays the explosion effect. Kills, assists and lingering fire or poison are credited to the shooter (W69).
6. The page and the in-game display show the reload countdown; when it ends the weapon swaps back to **armed**. Firing
   again at about the same point narrows the circle (W58). The lease ends when the operator closes the page, stops
   aiming, walks away, dies, or doesn't fire for the idle timeout (W36, W71).

### 5.3 Firing a ballista

1. A team member mounts the ballista and gets its lease (W36). The scroll wheel cycles the bolt type, shown with its
   price on the action bar, without changing the inventory (W51); a menu is the fallback.
2. They aim by looking, inside the cone around the spot's facing (W24), and fire. The server checks reload and siege
   points and charges the shot.
3. The ballista swaps to **fired** until the reload ends (W55). The bolt, a real arrow entity whose vanilla damage is
   cancelled (W72), flies straight and applies its ammo type's damage, effect and knockback along its flight direction
   (W47, W49), structure damage with the gate or weapon multiplier against gates and weapons (W25, W65), and no effect
   on players in their own spawn safe zone (W56). Kills are credited to the shooter (W69).
4. Dismounting, dying, leaving the match or the idle timeout (W71) releases the lease.

## 6. Health, build phase and destruction

1. **Health (W6):** every weapon has HP. Damage sources: enemy players through the gate hit model (melee, projectiles,
   fire; W68), enemy siege weapon shots (structure damage × weapon multiplier, W65) and explosions; allies only when
   friendly fire is on (W23).
2. **Build phase (W7):** HP starts at 0 and rises evenly to the template's max over its build time. The weapon can be
   attacked while it builds and can't fire until it's built.
3. **Damage feedback (W9):** reuse the gate approach: health-based cracks per viewer (`GateCrackVisuals`, Paper
   `Player#sendBlockDamage`) and sounds, plus particle effects (for gates too, if they don't have them yet; to check in
   knk-plugin).
4. **Destruction (W8):** at 0 HP the system plays the destruction sound and particles, ends any operator lease, and
   **swaps the schematic for the template's wreck schematic**.
5. **Spot cooldown (W10, W11):** only that spot is locked, for the template's cooldown or the scenario override. The
   wreck stays while the spot is locked and is cleared when the spot frees up.
6. **Spawn protection (W56):** players inside their own team's spawn safe zone take nothing from siege weapons: no
   damage, poison, fire or knockback. Checked per player at impact.
7. **Team info display (W21):** a per-player display near the weapon shows its state (building with HP, ready,
   reloading with countdown, in use) to the owning team only.
8. **Match end:** every weapon and wreck is removed and every spot restored from its snapshot (W41).

## 7. Economy

1. **Unlock (W32):** permanent, per weapon type, on the player's account, paid with personal coins (`User.Coins`).
   Needed to buy, not to operate.
2. **Siege points (W33, W34):** a per-match balance that starts at 0 and is reset every match. Earned from personal
   play (W34). Spent on weapon placements and shots (W13, W20), and on other shop items (#611). Never converts to
   personal coins. This is the same concept as Siege Survival's match currency (S12, S33); #356 builds it once for both
   modes where possible.
3. **Pricing (W14):** price each weapon and shot in minutes of good play. *Example only:* if a good player earns about
   100 siege points a minute, a ballista costs about 2 minutes' worth (200) and a trebuchet about 8 (800). Earn rates
   and prices are configuration, tuned during the alpha.

## 8. Tactical and targeting map (#613)

One BlueMap-based web page in the player's browser, in two modes (W28):

1. **Tactical map:** for every participant. At match start the player gets a clickable chat link; logged-in players
   can also get a web app notification over SignalR (nice to have). Shows the scenario area on the pre-game snapshot
   tiles, live markers of the player's own team, and gate and objective markers (W27).
2. **Targeting mode:** opened from a trebuchet or catapult (§5.2). Adds the weapon's range rings, the targeting circle
   under the cursor, ammo choice with prices, the player's siege points, the reload countdown and the fire button.
   Spawn safe zones are shaded; a target circle that overlaps one shows "Be advised: projectiles don't harm players
   inside their spawn zone." The shot is still allowed (W56).
3. **Usability:** the page ships with usability logging and a few scripted tasks for test runs, such as "pick a target
   and fire a trebuchet" (#653).
4. **Later:** a spot picker mode (#357) and the in-game battle map tables (#224).

Rules:

1. **Area lock:** the view is limited to the scenario's bounds and zoom levels, and the tile server refuses tiles
   outside them, so the page can't be used to scout the rest of the world.
2. **Team-only markers:** BlueMap's public live-player layer is switched off; the page fetches markers for the
   player's team with its token.
3. **No login by link** (W29). A token proves player, match and weapon; an existing web session must match that
   player.
4. **Token, page credential and lease** as in W36, W42, W64 and W71. The page talks only to knk-web-api, which relays
   commands to the plugin (W63).
5. **Snapshot tiles** are rendered offline per scenario on an admin's request and served through a proxy that checks
   the page credential and the scenario area (W73).

## 9. Configuration: entities, forms and menus

CRUD in the web app runs through the **form wizard**: every API entity with metadata can get form configurations, so
the work is defining the entities and seeding default forms (W38).

*Proposal*, following the siege domain conventions in DESIGN §3:

1. `SiegeWeaponTemplate`: the fields in §3, with schematic references into the schematic pipeline (#614).
2. `SiegeAmmoType`: the fields in §3; many-to-many with `SiegeWeaponTemplate`.
3. `SiegeWeaponSpot`, owned by `SiegeScenario`: `SiegeTeamId`, bounds (min/max corner or WorldGuard region id),
   derived `SizeClass`, `Facing`, `Name`, `SortOrder`; created through a world task.
4. `SiegeTeam.ActiveWeaponSpots` (W30).
5. `SiegeScenario.WeaponSpotCooldownOverrideSeconds` (nullable, W11) and `SiegeScenario.FriendlyFire` (W23).
6. `UserSiegeWeaponUnlock`: user, weapon template, unlocked at (W32).
7. Siege points earn rates and the kill-streak cap: scenario or global siege settings (#356).
8. Runtime only (plugin, match state with local checkpoint): placed weapons with HP, build progress, reload timers,
   operator leases, spot snapshots and lock timers, and each player's siege-point balance, spread state per lease (W58); the plugin owns all of it (W63).
9. *Proposal:* **API surface for the page** (W63, W64): `POST api/SiegeWeapons/page-session` redeems a link token for a page credential (`[AllowAnonymous]` plus the token check, rate-limited like `lookup`); lease, heartbeat and fire go over the SignalR hub with the credential, relayed to the plugin as request/response messages; the link token itself is minted by the plugin through a plugin-key endpoint.
10. **Default form seeds** for templates, ammo types and the scenario's spot list.

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

1. **Crash and outage safety (W41):** spot snapshots are recorded with the match and in a local file before each paste;
   on startup and at match end the plugin restores every recorded spot, without needing the API, and syncs later. The
   same applies to siege fire restores (#615).
2. **Concurrency (W36):** one lease per weapon, heartbeat expiry and idle timeout (W71), atomic fire decided by the plugin
   (W63), re-validation on every shot, checks before any charge (W67).
3. **Paste safety (W43):** push players out, refuse a paste over unexpected blocks.

## 11. Effects outside this feature

1. **Siege fire** (#615) changes fire rules for the whole match area; it is a Siege minigame feature that incendiary
   ammo uses.
2. **Notable events** (#612) are a Siege and Siege Survival feature; they pay siege points (W34) and mission score.
3. **Siege shop** (#611) is shared by weapons and future consumables and magic.
4. **Schematic pipeline** (#614) is shared infrastructure.
5. **Balancing statistics** (#651), **test-run recording** (#652) and **usability testing** (#653) cover the whole
   Siege minigame and the web app; siege weapons add their own events to them (W57). Plan balance runs with the
   [alpha balance test plan template](../../guides/alpha-balance-test-plan-template.md).

## 12. Current state and legacy behaviour

1. **Built today (V3, `next` on 2026-11-19):**
    1. knk-plugin: Siege match state and checkpoint in `SiegeService`; combat rules in `knk-core` `SiegeCombatRules`,
       including the own-spawn safe zone as a **sphere** around each spawnpoint (`safeZoneRadius`, default 4), which
       W56's per-player 3D check reuses as is.
    2. knk-plugin: gate damage through `GateDoorHitService` (causes such as melee left-click, projectile and fire, a
       cancellable `GateDoorDamageEvent`), `HealthSystem`, and `GateCrackVisuals` (`Player#sendBlockDamage`); gates
       default to **500 HP** (`GateLoaderAdapter`). W65 and W68 reuse these.
    3. knk-plugin: the SignalR client to the API hub ([realtime-signalr](../realtime-signalr/DESIGN.md)); W63 adds
       request/response messages on it.
    4. knk-plugin: world tasks (spots, W4); schematic loading exists only in the test scenarios (`SceneSchematic`).
    5. Not built: siege points (#356), siege shop (#611), schematic pipeline (#614), tactical map (#613), siege fire
       (#615), block display projectiles, scroll-wheel interception.
2. **V1/V2:** `knk-v1-archive` and `knk-v2-archive` have no siege weapons (searched for catapult, trebuchet, ballista,
   cannon and siege weapon); nothing to keep or drop.
3. **Vision:** § 4.2 (Professions, open) has the Engineer profession gating siege vehicles; handled by W74.
4. **Related open work:** #355, #356, #357, #611–#616, #651–#653, #224.

## 13. Platform-specific parts and risks

### 13.1 Platform-specific parts

Game rules stay in Bukkit-free `knk-core`: the weapon state machine (building, ready, reloading, in use, destroyed,
spot cooldown), lease and idle rules (W36, W71), spread and ranging (W58), range and cone checks, damage fall-off and
armour-piercing maths (W48, W49), check-before-charge (W67), kill credit (W69) and size class from a footprint and a
facing (W70).

| Part | Why platform-specific | Lives in | Port in `knk-core` |
|---|---|---|---|
| Schematic paste, rotation, area snapshot and restore | WorldEdit and Paper block API | `knk-paper` siege weapons package | `WeaponStructurePort` (paste, swap armed/fired/wreck, snapshot, restore) |
| Line of sight and highest solid block (W59) | Paper ray tracing | `knk-paper` | `ImpactGeometryPort` |
| Projectile flight: block display entity, particles, whistle (W53, W54, W66); aiming preview arc and circle (W75) | Paper entities, sounds, particles | `knk-paper` | `ProjectileViewPort` (no game logic; the arc's points come from the core trajectory) |
| Applying damage with vanilla damage types, effects, knockback (W47, W49) | Bukkit damage sources and potion effects | `knk-paper` | `ImpactEffectsPort` |
| Ballista mount, scroll-wheel cycling, in-game aiming (W51, W62) | Bukkit input events | `knk-paper` listeners | none: input adapter calling core commands |
| Weapon block hits (W68) | Bukkit events, gate hit model | `knk-paper`, beside `GateDoorHitService` | none beyond the core damage rule |
| Cracks and the team info display (W9, W21) | `sendBlockDamage`, per-player displays | `knk-paper` | none: presentation |
| Targeting and tactical page, tiles | BlueMap (web, not the plugin) | knk-web-app, proxy | none |

### 13.2 Risks and integration checks

1. **Weapon blocks vs gate doors:** weapon hits must not reach `GateDoorHitService`'s spatial index and the other way
   round; a ballista bolt hitting a gate must apply structure damage once (W72), not also as a vanilla projectile hit.
   Check before building P4.
2. **Projectile and preview cost:** a block display moved every tick per projectile, and the operator's preview arc
   every few ticks; measure with several weapons firing
   (`PluginMetrics.timed`, KNG-232).
3. **Relay latency and outages (W63):** a page shot crosses page → API → plugin and back; measure, and show
   "server unreachable" on the page when the plugin is disconnected.
4. **Snowball (W60):** watch weapon kill share in the balance runs (#651).
5. **Crash restore (W41):** test a restart mid-build and mid-flight; no weapon, wreck or fire may stay behind.
6. **Siege fire (#615):** fire bombs and incendiary bolts need it for ground fire; without it they only set players
   alight.
7. **Feature flag:** `siege.weapons.enabled` in the plugin's `config.yml`, default `false`; the shop category and
   spots stay hidden while it is off.

## 14. Acceptance checklist and phases

### 14.1 Acceptance checklist

| ID | Check | Phase |
|---|---|---|
| A01 | Templates, ammo types (with structure damage), spots and unlocks can be created and edited in the web app's form wizard from seeded forms | 1 |
| A02 | A spot world task stores bounds, team and facing pre-filled from the admin's look direction; the size class follows width across × length along the facing and changes when the facing is overridden | 2 |
| A03 | A selection smaller than the small class is refused | 2 |
| A04 | With `siege.weapons.enabled` off, no siege weapon appears in the shop and no spot is used | 3 |
| A05 | A player without the unlock can't buy; a player with it can, and only into a free active spot of their team that fits | 3 |
| A06 | A refused placement (blocked area, no points, no fitting spot) charges nothing and names the reason | 3 |
| A07 | Players inside the spot are pushed to the edge before the paste; the paste is rotated to the facing | 3 |
| A08 | HP rises evenly from 0 over the build time; the weapon can be damaged and can't fire while building | 3 |
| A09 | Enemies damage the weapon by melee, projectiles and fire like a gate; allies don't unless friendly fire is on | 4 |
| A10 | Cracks show as HP drops; at 0 HP the wreck replaces the weapon, the lease ends, and only that spot locks for the cooldown (template or scenario override) | 4 |
| A11 | No refund when a weapon is destroyed, also during its build; the buyer has no lease priority | 4 |
| A12 | After a restart mid-match (also with the API down) every spot is restored from its local snapshot | 3 |
| A13 | At match end every weapon and wreck is removed and every spot restored | 3 |
| A14 | The team info display shows state, HP and reload to the owning team only | 4 |
| A15 | Mounting the ballista takes the lease; a second player can't take it | 5 |
| A16 | The scroll wheel cycles bolt types without changing the hotbar; the action bar shows bolt and price | 5 |
| A17 | Shots outside the template's cone are refused | 5 |
| A18 | A bolt deals only its ammo damage (no vanilla arrow damage), knocks back along its flight, and applies structure damage × gate or weapon multiplier | 5 |
| A19 | The shooter pays per shot; at most one shot per reload; armed → fired → armed shows the state | 5, 6 |
| A20 | The lease ends after the idle timeout without a shot, on death, on leaving the match and on walking away | 5, 6 |
| A21 | Kills, assists and fire or poison deaths from a shot credit the shooter with full siege points and streak | 5, 6 |
| A22 | Enemies can damage but never operate a weapon | 5, 6 |
| A23 | Right-clicking a trebuchet or catapult gives the page link and "aim in game" | 6 |
| A24 | In-game aiming fires at the looked-at block within min/max range, with scroll-wheel ammo choice | 6 |
| A25 | The projectile is visible along its arc and lands after the template's flight time; a whistle sounds on the way down | 6 |
| A26 | The spread starts at the start radius, narrows by the ranging step on consecutive shots at about the same point, and resets when the point moves, the operator changes or the lease ends | 6 |
| A27 | The impact is on the highest solid block; players and structures without line of sight to it take nothing | 6 |
| A28 | Damage, knockback, fire and poison follow the ammo's effect curve and vanilla damage types, so armour and shields count | 7 |
| A29 | Players in their own spawn safe zone take nothing; players above it on another floor do | 7 |
| A30 | The link token works once and is exchanged for a page credential; a reused or expired token is refused | 8 |
| A31 | A page shot reaches the plugin through the API relay; the plugin re-checks lease, range, reload and points; a race fires at most once | 8 |
| A32 | The page shows range rings, the current spread, ammo with prices, siege points, the reload, and shaded spawn zones with the advisory note | 9 |
| A33 | Tiles outside the scenario area and requests without a valid credential are refused; only own-team markers show | 9 |
| A34 | With the plugin disconnected the page says the server is unreachable and fires nothing | 8 |
| A35 | Siege weapon statistics (shots, hits, damage, kills per weapon and ammo type) are recorded per match | 4 |
| A36 | While aiming in game, only the operator sees a particle arc from the weapon to the targeting circle at the looked-at point, at the current spread; it turns to the warning colour out of range, under min range or with no block, and firing is then refused | 6 |

### 14.2 Phases

The feature is `tier:3` (new entities, schema, game feel). Each phase merges into `next` on its own; every plugin
phase stays behind `siege.weapons.enabled` (default `false`). The draft's six phases were split to nine on approval so
each fits one link. Sub-issue numbers: see the table.

| Phase | Scope | Acceptance | Repos | Tier | Flag | Sub-issue | Depends on |
|---|---|---|---|---|---|---|---|
| 1 | Entities, API, form seeds, unlocks | A01 | knk-web-api, knk-web-app | tier:3 | none (data only) | #782 | #614 (schematic references, nullable until then) |
| 2 | Spots through world tasks | A02–A03 | knk-plugin, knk-web-api | tier:2 | `siege.weapons.enabled` | #783 | 1 |
| 3 | Buying, placement, paste, build phase, crash and match-end restore | A04–A08, A12–A13 | knk-plugin, knk-web-api | tier:3 | `siege.weapons.enabled` | #784 | 2, #356, #611, #614 |
| 4 | Weapon damage by players, cracks, wreck, spot cooldown, team info display, statistics | A09–A11, A14, A35 | knk-plugin, knk-web-api | tier:3 | `siege.weapons.enabled` | #785 | 3 |
| 5 | Ballista direct fire | A15–A22 | knk-plugin | tier:3 | `siege.weapons.enabled` | #786 | 4 |
| 6 | Trebuchet and catapult in game: lease, look-to-target aiming with preview arc, projectile, spread, impact and line of sight | A19–A27, A36 | knk-plugin | tier:3 | `siege.weapons.enabled` | #787 | 4 |
| 7 | Ammo effects: vanilla damage types, fall-off, knockback, fire, poison, spawn protection | A28–A29 | knk-plugin | tier:3 | `siege.weapons.enabled` | #788 | 5 or 6; #615 for ground fire |
| 8 | Page credential and API relay over SignalR | A30–A31, A34 | knk-web-api, knk-plugin | tier:3 | `siege.weapons.enabled` | #789 | 6 |
| 9 | Targeting mode on the map page, snapshot tiles and proxy | A32–A33 | knk-web-app, knk-web-api | tier:3 | `siege.weapons.enabled` | #790 | 8, #613 |

Smoke test: [guides/siege-weapons-smoke-test.md](../../guides/siege-weapons-smoke-test.md).

## 15. Open questions

None open. Answered on approval (2026-11-19, developer, recommended options):

1. **Size classes (was Q2):** (a) confirmed in phase 3 once the first armed, fired and wreck schematics exist; the
   classes are configuration and change then if needed.
2. **Balance numbers (was Q4, Q5):** (a) ship with the *proposal* defaults in this spec and tune them in the alpha
   balance runs (#651).
3. **Object store (was Q7):** (a) decided in #614 with its own decision matrix.

Resolved earlier: Q1 (right-click, W45), Q3 (objectives, W46), Q6 (cone and bolt choice, W51, W52).

### After v1

1. Engineer profession as an unlock path (W74; vision § 4.2).
2. Turning ballista (#616), spot picker on the web map (#357), battle map tables (#224).
3. NPC "siege engineer" at weapons (W45).
