# NPC behavior model — perception, psychology, decisions and combat (guards first)

**Status:** Working concept from a developer design session; not approved defaults, not an implementation plan, nothing implemented. Items marked *(future update)* belong to the overall vision but are not planned for the first version.
**Last updated:** 2026-11-04 (developer decisions on design pass 2: alert states weight but never lock §7.1, four situations §7.2, guard-specific orders §7.3, presets §9.7, influence sources incl. gate state §9.8, five weapon-skill modifiers §11.1, inspector and web decision viewer §14, templates §15); 2026-11-04 (design pass 2: §7.1 action gating, §7.2 situations, §9.7 personality presets, §9.8 default influence sources, §11.1 proficiency growth, §11.2 ranged/melee switching, §14 debugging tools, §15 configuration and templates; all proposals); 2026-11-04 (hybrid navigation decision in §2: K&K plans, Citizens moves); 2026-11-04 (initial concept, developer voice design session)
**Issue:** [PandiO/knk-workspace#234](https://github.com/PandiO/knk-workspace/issues/234)
**Parent design:** [npc-platform/DESIGN.md](DESIGN.md) (KNG-36), mainly its O11 (city guard profile) and O12 (combat, stats, factions, debugging, performance); related [#146](https://github.com/PandiO/knk-workspace/issues/146)
**Authority:** Developer statements in the 2026-11-04 session. Where this document says "agreed" or "developer", the developer chose it; everything else is a proposal recorded for discussion. Library, schema and numeric values are examples, not defaults.

## 1. Purpose and goals

Reusable, highly configurable NPC traits with a focus on combat behavior and decision making. The first concrete use case is **gate guards and town guards**; every building block must also serve other NPC types (merchants, farmers, villagers, monsters, Siege attackers).

- **Immersion first** (developer): behavior should feel believable, using real-life behavior (military, police, human psychology) as the reference instead of typical game shortcuts.
- **Configurable and data-driven**: templates with inheritance (for example `town_guard` extends `soldier`); schema open.
- **Composable** traits instead of one monolithic combat trait (consistent with NPC-01).
- **Extensible** (developer): later systems (trading, crime, politics, events) plug into mood and behavior without changes to the core.

## 2. Fit with the platform design

This document adds a behavior model on top of the existing platform boundaries; it does not replace them.

| Existing decision | How this model uses it |
|---|---|
| NPC-01 composable capabilities | Every layer below is a trait/capability or a shared service |
| §5a utility target scoring, minimum commitment, switch margin | The decision model (§8) scores actions the same way; "hysteresis" in this document means §5a's minimum commitment + switch margin |
| §5b combat and speed profiles, modifier pipeline | Combat style profiles and proficiency (§10) feed the §5b resolver as modifiers; they don't own cooldown/damage mechanics |
| §6 automatic navigation, optional lane overrides, caller-supplied ruleset | Dynamic routes (§12) choose destinations; KnK navigation executes them |

### Execution layer: hybrid navigation (developer decision 2026-11-04)

The developer chose a **hybrid**: K&K navigation plans, Citizens moves.

- **Route planning: K&K navigation.** The road graph and the walk pathfinder ([navigation](../navigation/DESIGN.md), [last-mile](../navigation/LAST_MILE_PATHFINDING.md)) plan long routes and hand Citizens the waypoints (proposed API: `Navigator.setTarget(Iterable<Vector>)`, to verify against the Citizens version in use).
- **Movement: Citizens.** Citizens executes stepping, jumping, doors and unstuck handling. For short off-road legs (for example to a post on a wall) it pathfinds itself; its block examiners are configured to respect K&K movement rulesets and domain/gate access, so DESIGN §6's rules stay binding.
- **Reason:** K&K runs many human-like (player-shaped) NPCs. Those have no vanilla AI, and Citizens' movement code is mature and maintained across Minecraft updates; building and maintaining that ourselves would cost far more.
- **Consequence:** V3 takes on a Citizens dependency again (the V3 plugin has none today). Main risk: waiting on a Citizens release after a Minecraft update. The DESIGN §2 platform-adapter boundary keeps behavior Citizens-free so the executor can still be swapped.

Still to do under the DESIGN §9 audit: check the Citizens API version and licence, confirm waypoint following and block-examiner hooks, and benchmark on the castle map (many NPCs, closed gates, changed permissions, unloaded chunks). Siege Survival's mob-based plan (Paper MobGoals, DESIGN §5b) is not changed by this decision; whether Siege attackers also move through Citizens is open.

## 3. References

**Libraries and plugins**

- **Citizens**: NPC base and navigator; selected as the movement executor (§2). No meaningful library of combat presets.
- **Sentinel** (mcmonkeyprojects, open source): the main Citizens combat add-on: targeting, melee/ranged, weapon switching, chasing, guarding, respawning. Useful for targeting filters and the attack loop; monolithic, not composable.
- **MythicMobs**: skills/targeters/triggers; best reference for describing combat behavior in config.
- **Paper Mob Goals API**: priority-based goals; pattern for small reusable behaviors (keep distance, flee at low health, strafe). §5b already proposes a MobGoals adapter.
- **Behavior-tree libraries** (for example gdx-ai): option for decision trees.

Direction: a hybrid of Sentinel-style targeting, Mythic-style config and goal-style composable traits.

**Games**

- **Assassin's Creed**: detection meter, restricted zones, guard paths, archetypes (brute, seeker, captain), captains buffing guards and morale loss when they fall. The developer finds its alert states too coarse.
- **Red Dead Redemption**: witnesses who report crimes (delayed response; *future update: Law & Order*), escalation by severity, search around the last known position instead of omniscient guards, gate confrontation ("state your business", also Skyrim).
- **Shadow of Mordor (Nemesis)**: NPCs remembering players personally.
- **Crysis tactical point system, Hitman level annotation, The Sims smart objects, F.E.A.R. GOAP**: see §8 and §12.

**Literature and models**

- **Big Five / OCEAN** (HEXACO as alternative, adds honesty-humility): stable personality traits.
- **Core affect / PAD** (Russell; Mehrabian & Russell): mood as Pleasure, Arousal, Dominance.
- **OCC appraisal model** (Ortony, Clore & Collins): emotions from how an event relates to goals, standards and attitudes.
- **Action tendencies** (Frijda), approach/avoidance (BIS/BAS), fight/flight/freeze/appease.
- **Utility AI / Infinite Axis Utility System** (Dave Mark).
- **Generative Agents** (Park et al., Stanford 2023): memory stream, reflection, planning.

## 4. Architecture layers

1. **Perception & targeting** (§5): who is hostile, line of sight, threat per target.
2. **Knowledge & recognition** (§6).
3. **Awareness / alert states** (§7): per-target suspicion turned into named states that enable or disable actions.
4. **Psychological model** (§9): personality, physical state, mood, emotions, relationships.
5. **Decision layer** (§8): utility-scored actions.
6. **Combat** (§10): style profiles, proficiency, weapon switching.
7. **Execution**: K&K route planning + Citizens movement (§2 hybrid decision; DESIGN §6, §12 here) and the §5b attack/speed adapters.

## 5. Perception

Agreed: sight, hearing and being hit; senses build per-target suspicion gradually instead of instant detection. Values configurable per template.

**Sight**

- Focal cone, about 60° ahead: clear identification at long range.
- Peripheral area, about 180°: movement and shapes only, short range.
- Modifiers: light level at the target's block (torches near the gate matter), weather, time of day, target state (sneaking, sprinting, armour/clothing, invisibility, cover).
- Line of sight by raycasts, time-sliced.

**Hearing**: noise events with a radius (combat, footsteps, sprinting, doors, block breaking, shouts). Gives direction and approximate location, not identity; the guard turns or investigates.

**Being hit**: instant awareness of the attacker, or only of the direction (an arrow from the dark).

**State modifiers**: high arousal sharpens senses; fatigue and boredom narrow the cone and slow detection.

**Smell** *(future update, optional)*: dogs, hunters; scent trails.

## 6. Knowledge and recognition

Agreed for the first version: each guard knows a set of people; anyone outside it is a stranger.

- Recognises **residents** of his town (K&K domain/citizenship data), **faction members/citizens**, and **familiar faces** (familiarity builds with repeated sightings and fades).
- Visible allegiance markers (heraldry, tabards, banners) are a hint, not proof.
- Levels: known by name · familiar face · stranger · known enemy.
- Recognition needs a clear sighting (focal cone, enough light); a known person can read as a stranger at distance or in the dark.
- Guards at one post share recognition through a group blackboard. Wanted lists, rumours and reports between towns: *future update (Law & Order)*. Disguises: *later expansion*.

### Reputation and renown *(future update)*

Developer idea, inspired by Red Dead Redemption 2's honour system:

- **Honour** (hero ↔ outlaw) and **renown** (how widely known, for example from slaying dangerous monsters) as separate values.
- Scoped per town, region and faction; deeds spread outward over time and distance.
- Famous players can be recognised on sight or when they announce themselves; reputation shifts attitudes in the appraisal model, eases persuasion (talking past a checkpoint, calming a confrontation) and raises suspicion for outlaws.

## 7. Alert states

The developer wants more nuance than Assassin's Creed: a guard's **mood** (for example agitated during war) sets the baseline, and the **reason** someone is suspicious matters (a stranger at the outer gate is less alarming than someone in a restricted area).

**Per-target suspicion** builds and decays from: recognition (§6), faction/allegiance, location context (outer gate, inner town, market, restricted keep/armoury/treasury), and behavior (armed, sprinting, sneaking, climbing, stolen goods, loitering, disguised). Mood multiplies build-up rate and thresholds.

**States per target** (draft thresholds):

1. **Calm**: no attention.
2. **Watchful**: background awareness.
3. **Curious**: notices, glances, follows with the eyes.
4. **Wary**: actively watches, hand near weapon.
5. **Confronting**: stops the person, asks their business, may demand they leave or disarm.
6. **Alarmed**: draws weapon, warns, alerts nearby guards.
7. **Hostile**: engages.
8. **Searching**: lost sight; searches the last known position.
9. **Aftermath**: after a fight or search, stays on edge, patrols tighter, talks about the incident, then calms down.

Example: a stranger at the outer gate in peacetime may only reach *curious*; the same stranger in the keep during wartime goes straight to *alarmed*.

**Three levels**

- **Per target**: the states above. Rising thresholds lower than falling ones; decay rates depend on personality (an anxious guard stays suspicious longer); instant jumps for unambiguous events (being hit or witnessing a killing → hostile).
- **Per guard**: the most serious target state, coloured by mood; drives posture, speed, attention.
- **Per post / town**: a shared alert level (alarm, bell) that lowers thresholds for all guards there and can summon reinforcements.

### 7.1 How alert states influence actions (developer decision 2026-11-04)

**Decided: alert states never lock actions.** They only make actions more or less likely (weighting). The only hard locks are the platform's existing hard rules: §5a eligibility and consumer overrides, permissions (NPC-12), Siege rules.

- **Weighting by action tags.** Each action carries tags (`idle`, `observe`, `verbal`, `force.nonlethal`, `force.lethal`, `pursue`, `support`, `withdraw`); each state gives each tag a weight multiplier. A new action plugs in by tagging itself. The consideration reads continuous suspicion, so behavior changes smoothly inside a state.
- **Curves must be steep.** With no locks, a calm guard must practically never draw a weapon; the weights near 0 for `force.*` in Calm/Watchful/Curious carry that. The inspector (§14) shows when a curve is too flat.
- **Orders and rules of engagement** (§7.3) shift the same weights, for example kill on sight makes `force.lethal` dominant from the first sighting.
- A targeted action uses that target's state; patrol or rest use the guard-level state and post alert level.
- States also carry **effects** that are not actions: weapon drawn, walk speed, head tracking, perception bonus from Wary up.
- States are a registry (id, thresholds, tag weights, effects), retunable without code changes.

Proposed starting weights (examples to tune; × = multiplier on the action score):

| State | Strongly favoured | Strongly suppressed (near 0, never locked) |
|---|---|---|
| Calm | `idle`, `duty` | `force.*`, `pursue`, `verbal.demand` |
| Watchful | `duty`, `observe` (glance) | `force.*`, `pursue` |
| Curious | `observe` | `force.*`, `pursue` |
| Wary | `observe`, `verbal`, `position` | `idle`, `force.lethal` |
| Confronting | `verbal.demand` | `idle`, `force.lethal` |
| Alarmed | `threaten`, `force.nonlethal`, `support` | `idle` |
| Hostile | `force.lethal`, `pursue`, `withdraw` (when fear is high) | `idle`, `verbal.demand` |
| Searching | `search`, `support`, `duty` | `idle`, `force.lethal` until the target is seen again |
| Aftermath | `duty`, `idle.talk` | `idle.rest` until calm |

### 7.2 Situational states (developer decision 2026-11-04)

A **situation** is an event that is not about one suspect: fire, a monster attack, a siege, the alarm bell. It is a registry entry with:

- `detection`: event or scan (fire blocks in the zone, hostile mobs in the zone, Siege match start, bell rung).
- `scope`: post, town or domain; `severity` levels.
- `influence`: an influence source (§9.6) it switches on, for example `core:monster_attack` raises arousal.
- `unlocks`: action tags only this situation allows (fire: `situation.fire`).
- `orders`: default orders the situation hands to the guards it affects (go to the muster point, hold the gate); see §7.3.
- `targets`: how it changes per-target handling (monsters count as known enemies).
- `end`: condition that clears it, then guards enter Aftermath.

| Situation | First version | Effect |
|---|---|---|
| Monster attack | Yes | Hostile mobs in the zone count as known enemies and go straight to Hostile on sight, inside leash and ROE. Raises the post alert level; players keep the normal ladder with lowered thresholds. |
| Alarm bell / post alarm | Yes | Raises the post or town alert level (§7 three levels); guards in earshot muster at the post or the alarm source. |
| Siege | Yes (follows Siege rules) | Siege controller supplies eligibility and ROE; the situation sets mood and alert level. |
| Fire | Yes, basic | Raise the alarm, keep people away, avoid burning blocks (navigation). Extinguishing and bucket chains *(future update)*. |
| Riot, crime wave | No | *(future update: Law & Order)* |

**Decided:** all four (monster attack, alarm bell, siege, basic fire response) are in the first version.

Situations stack; the highest severity sets the alert level. A situation never bypasses eligibility or permissions.

### 7.3 Orders (developer decision 2026-11-04)

Orders are separate from mood. They are scoring modifiers and rules of engagement, not emotions; they can change how a guard feels only through appraisal (for example an order he disagrees with), never directly.

- **Orders belong to the guard, not the region.** Guards are assigned to regions and each guard holds the orders for his assignment. There are no region-wide rules that every NPC inside obeys automatically.
- An order has: the assignment or region it applies to, a rules-of-engagement preset or explicit tag weights, an optional **target filter** (everyone, everyone except permission group X, members of clan Y, monsters), and optional duty targets (posts, POIs).
- **First version:** admins assign orders to guards directly (web app and in game).
- Situations (§7.2) can hand default orders to the guards they affect.
- *(future update)* **Command hierarchy:** a regional commander delegates orders to his subordinates and briefs guards transferred in from other regions. Until briefed, a newcomer does not know the local orders; briefing gaps and miscommunication are wanted behavior. Builds on knowledge sharing (§12.3).

**Example, the palace during the alpha:** the palace entrances stay blocked by closed gates (no hard district entry deny). A few secret paths still lead in. Palace guards get the order "kill on sight", filtered to everyone except staff permission groups. Anyone matching the filter goes straight to Hostile on sight and lethal actions dominate the scoring.

## 8. Decision model

Agreed goal: scalable but intricate. Emotions never map to actions directly.

**Pipeline**

1. Events → appraisal → emotions (§9.4).
2. Emotions + mood + personality → **action tendencies** (urges, 0–1).
3. Each **action** declares the tendencies it serves (with weights), preconditions and a few reusable **considerations** with response curves.
4. Score = tendency fit × considerations × orders/role modifiers. Selection follows §5a: hard eligibility first, then scoring, minimum commitment and switch margin.

Adding an emotion = map it to tendencies once. Adding an action = tag it with tendencies once.

**Action tendencies (draft)**: attack/confront (anger) · escape/avoid (fear) · freeze/hesitate (fear, low dominance) · appease/submit (fear, shame, low dominance) · seek help/affiliate (fear with high agreeableness or extraversion) · investigate/approach (curiosity, suspicion) · guard/hold (duty, conscientiousness) · rest/withdraw (fatigue, boredom, distress).

**Reusable considerations (examples)**: own health · distance to threat · threat strength vs. own · allies nearby · captain nearby · distance from post · time since last order · fear/anger intensity · fatigue · line of sight · alert state of target.

**Gate guard actions (draft)**

| Action | Main tendencies | Key considerations |
|---|---|---|
| Hold post / patrol | Guard/hold | Distance from post, boredom, orders |
| Watch target | Investigate | Suspicion, line of sight |
| Confront / question | Attack/confront, Investigate | Suspicion, distance, allies nearby |
| Warn / order to leave | Attack/confront, Appease | Suspicion, target armed |
| Raise alarm | Seek help | Threat level, allies in earshot |
| Call for backup | Seek help, Escape | Threat vs. own strength, fear |
| Engage melee | Attack/confront | Health, distance, proficiency |
| Engage ranged | Attack/confront, Escape | Distance, line of sight, ammo |
| Pursue | Attack/confront | Distance from post, stamina, orders |
| Search last known position | Investigate | Time since lost sight, alert state |
| Retreat / fall back | Escape | Health, allies, fear |
| Surrender / plead | Appease | Health, dominance, group morale |
| Freeze | Freeze | Fear, neuroticism, experience |
| Rest / chat / idle | Rest/withdraw | Fatigue, boredom, conscientiousness |

**Other patterns to keep in mind**: smart objects (situations advertise what they offer), GOAP for multi-step plans later.

**Role of LLMs** (discussed and agreed)

- Design time: generate and review weights, curves, mappings, presets, goal/standard sets and test scenarios; the output is versioned config, balanced by hand.
- Runtime, limited: rare asynchronous moments (dialogue, gate questioning, a captain's strategy, backstories).
- Not for per-tick decisions: too slow, costly at scale, non-deterministic, hard to debug.

## 9. Psychological model

Developer request: follow the consensus in psychology literature. Stable **traits** shape how easily **moods** and **emotions** arise; emotions are short and targeted; repeated emotions slowly shift mood. Every layer is a **registry**: core ships defaults, other modules and config add entries.

Timescales: traits = lifetime; mood = hours to days, diffuse; emotions = seconds to minutes, about something.

### 9.1 Personality (stable)

Big Five per NPC (or template + random variance):

- **Openness**: curiosity, tolerance of strangers and unusual behavior.
- **Conscientiousness**: discipline, duty, sticking to post and protocol.
- **Extraversion**: talkative, confronts people, seeks company.
- **Agreeableness**: friendly vs. hostile; how quickly force is used.
- **Neuroticism**: emotional stability; how hard fear and stress hit.
- Optional **honesty-humility** (HEXACO): corruptibility, bribery, greed.

Named traits (nervous recruit, jaded veteran, zealot, coward, lazy) are presets on these dimensions.

### 9.2 Physical state and needs

Fatigue (lowers perception and reaction) · hunger/thirst · injury/pain · cold/heat · **stress** (accumulates over days; breakdowns, snapping, desertion) · **boredom** (quiet posts; lowers alertness, wandering, chatting) · **contentment** (pay, food, housing, treatment).

### 9.3 Mood (PAD)

Three axes with a personality-based baseline the NPC drifts back to: **Pleasure**, **Arousal**, **Dominance**. Named moods are regions of PAD plus physical modifiers, for example relaxed (+P −A +D), vigilant (0 +A +D), agitated (−P +A +D), jittery (−P +A −D), demoralised (−P −A −D), complacent (+P −A with high fatigue/boredom), exhausted (−A with very high fatigue). Named moods change dialogue, posture, patrol speed, suspicion multipliers and action weights.

### 9.4 Emotions (OCC appraisal)

Short emotions aimed at a person, group or event: fear, anger, distress, relief, pride/shame, gratitude, contempt, hope. Intensity scaled by personality and mood; emotions feed mood over time.

Each NPC holds three registries that every event is measured against:

- **Goals** with importance weights (personality can modify them).
- **Standards** for judging actions; others breaking one → anger/contempt; breaking one oneself → shame.
- **Attitudes**: likes/dislikes towards people, factions, objects.

Gate guard defaults (draft): goals: stay alive (cowards higher, zealots lower) · protect town and gate · follow orders and hold post · earn respect · get through the shift. Standards: no violence in town · respect the guard · no trespassing · honesty in trade · loyalty to the lord. Attitudes: distrust of foreigners · liking known traders · hatred of the enemy town.

Worked example, a stranger draws a sword at the gate: threatens "stay alive" → fear; threatens "protect the town" and violates "no violence in town" → anger. A nervous recruit freezes or calls for help; a veteran engages.

### 9.5 Relationships and attitudes

Loyalty (lord, town, faction, captain) · trust · liking · familiarity (§6) · memory of past events with a person, Nemesis-style *(future update: persistent memory)*. Feeds suspicion and alert states.

### 9.6 Influence sources (extensible)

Anything that affects an NPC registers under one shape (developer: new systems such as trading must plug in later):

- `id`, namespaced (`core:war`, `trade:price_gouged`).
- `scope`: global, world, region/domain, town, faction, group, single NPC.
- `targets`: physical state, mood (PAD deltas), appraisal (which goal/standard/attitude it touches), relationship.
- `mode`: lasting offset while active, or one-off impulse.
- `duration`, `decay` (linear/exponential), `stacking` (none, refresh, additive with cap, diminishing).
- `conditions` (time, weather, role, trait) and `trigger` (event bus, config, commands, web app).

Examples: war, siege, curfew, festival, crime in town, fallen comrade, captain nearby, night shift, long watch, bad weather, bribe, insult, praise; later trading events (fair trade, price gouging, scarcity, smuggling).

### 9.7 Personality presets (developer decision 2026-11-04)

Traits are stored −1…1 internally and shown 0–100 in config and the web app (50 = population average). A preset sets trait values; everything else is **derived** from traits, so presets don't repeat tuning. A preset may add a few explicit goal-weight overrides where traits alone don't capture it (a zealot's low "stay alive").

| Preset | O | C | E | A | N | Extra | Plays as |
|---|---|---|---|---|---|---|---|
| Steady guard (default) | 50 | 65 | 50 | 50 | 40 | — | Reliable, proportional |
| Nervous recruit | 55 | 55 | 40 | 60 | 75 | — | Notices a lot, freezes or calls for help |
| Jaded veteran | 35 | 55 | 40 | 35 | 25 | — | Hard to rattle, quick to use force once sure |
| Zealot | 20 | 85 | 60 | 25 | 40 | "stay alive" weight low | Distrusts strangers, holds to the end |
| Coward | 50 | 35 | 40 | 55 | 85 | "stay alive" weight high | Calls backup, retreats early |
| Lazy | 45 | 20 | 60 | 60 | 40 | — | Leaves post, chats, slow to react |
| Sergeant / captain | 40 | 85 | 70 | 40 | 30 | — | Confronts, gives orders, steadies others |
| Friendly gatekeeper | 65 | 55 | 75 | 75 | 35 | — | Talks first, tolerant of strangers |
| Brute | 25 | 45 | 55 | 15 | 45 | — | Escalates fast |
| Noble knight | 45 | 80 | 55 | 65 | 25 | Standard "warn before striking" weighted high | Disciplined, calm, fair; always warns first |
| Royal guard (Praetorian-style) | 55 | 95 | 45 | 40 | 10 | Loyalty to the lord very high; template starts with high proficiency | Elite, sharp, observant, unshakeable; suits the palace |
| Paranoid watchman *(future update)* | 30 | 60 | 35 | 30 | 80 | — | Sees threats everywhere |
| Mercenary *(future update, needs contentment)* | 50 | 50 | 50 | 40 | 35 | Low loyalty | Competent, retreats once the pay isn't worth the risk |
| Corrupt *(future update, needs bribery)* | 50 | 35 | 55 | 40 | 40 | HH 15 | Takes bribes |

Values are examples to tune. **Decided:** the set above, including noble knight and royal guard, ships in the first version; paranoid watchman, mercenary and corrupt are future updates. **Variance:** each instance rolls each trait once at creation (normal distribution, proposed σ = 8, clamped 0–100), seeded by the NPC id and persisted, so two recruits differ but a guard does not change on restart.

**What traits derive** (direction only; curves to tune):

| Derived value | Raised by | Lowered by |
|---|---|---|
| Baseline PAD | Proposed start: Mehrabian's temperament mapping from Big Five (as used by the ALMA affect model; coefficients to verify against the source) | — |
| Suspicion build-up, stranger tolerance | Low O, low A | High O |
| Suspicion decay time | High N | Low N |
| Fear intensity, freeze chance | High N, low dominance | Experience (fights survived) |
| Leash strength, protocol, post duty goal | High C | Boredom, fatigue |
| Confront and talk tendency | High E | Low E |
| Force threshold (escalation ladder) | High A | Low A, zero-tolerance orders |
| Boredom rate on quiet posts | High E, high O | High C |

### 9.8 Default influence sources (developer decision 2026-11-04)

**Decided:** this list, plus gate state, is the first-version default. Core ships these under `core:`; everything else comes from feature modules. Sizes are relative (S/M/L) until tuned.

| Id | Scope | Mode | Main effect | First version |
|---|---|---|---|---|
| `core:war` | Faction, town | Lasting | A +M, P −S; hatred attitude to the enemy faction; suspicion of its members ×L | Yes |
| `core:siege` | Town, domain | Lasting | A +L, P −M; lowers alert thresholds at the town's posts | Yes |
| `core:alarm` | Post, town | Lasting until cleared | A +L; raises the alert level (§7) | Yes |
| `core:monster_attack` | Post, town | Lasting | A +M; fear for high N, anger for low N | Yes |
| `core:curfew` | Town, time-conditional | Lasting | Anyone outside at night is suspicious (location context) | Yes |
| `core:night_shift` | NPC, time-conditional | Lasting | Fatigue and boredom rates +S; perception −S | Yes |
| `core:long_watch` | NPC | Grows with time on duty | Fatigue and boredom +S per hour | Yes |
| `core:bad_weather` | World, region | Lasting | P −S; sight range −M | Yes |
| `core:attacked` | NPC | Impulse | Appraisal: threat to "stay alive"; fear or anger | Yes |
| `core:comrade_hurt` / `core:comrade_fallen` | Group | Impulse | Distress M/L; anger or fear by personality; D −M if fallen | Yes |
| `core:captain_nearby` | Group, in range | Lasting while near | D +S; suppresses `idle` actions | Yes |
| `core:captain_fallen` | Group | Impulse | D −L, P −M (morale loss, as in Assassin's Creed) | Yes |
| `core:threat_repelled` | Group | Impulse | Relief and pride; P +M, D +M | Yes |
| `core:gate_damaged` / `core:gate_destroyed` / `core:gate_repaired` | Gate, seen or heard nearby | Impulse; damaged also lasting while under attack | Neutral event, appraised per NPC (below) | Yes |
| `core:festival` | Town | Lasting | P +M; stranger suspicion −M (crowds), boredom −M | Yes |
| `core:insulted` / `core:praised` | NPC | Impulse | Standard "respect the guard" violated or honoured | With dialogue |
| `core:paid`, `core:fed`, `core:housing` | NPC, group | Lasting | Contentment | *(future update: routines and needs)* |
| `core:bribe` | NPC | Impulse | Honesty-humility check | *(future update)* |
| `trade:*` | Town, NPC | Mixed | Fair trade, price gouging, scarcity, smuggling | *(future update)* |

**Gate state is appraised, not hard-coded** (developer 2026-11-04). The event only says "this gate was damaged, destroyed or repaired"; each NPC judges it against its own goals and allegiance (§9.4):

- **Defenders** of that gate (same side as its owner): the gate protects the town, so "protect the town" is threatened. Destroyed → large morale loss (D and P down, like captain fallen); damaged → tension (A up); repaired or held → relief and pride.
- **Attackers**: their goal is achieved. Destroyed → morale gain.
- **Non-violent or fearful bystanders** (villagers, high neuroticism, a "no violence" standard): the gate meant safety, so its fall threatens "stay safe" → fear; the violence itself breaks their standard → distress. They tend to flee or hide.

**Dependency:** this needs NPCs to belong to a clan or faction and gates to have an owning side ([PandiO/knk-workspace#236](https://github.com/PandiO/knk-workspace/issues/236)). Without it, the NPC cannot tell whose gate fell.

## 10. Reaction to being attacked

Agreed: **proportional response by default**, with escalation shifted by orders and personality (developer: a rough guard under zero-tolerance orders meets a bare-handed punch with lethal force; a mellow guard under "keep it cool" orders does not).

**Four beats**: reflex (1–2 ticks: flinch, turn, raise shield) → appraisal (who, severity, intent; a stray arrow is not a murder attempt) → emotion and decision (utility system) → group response (noise and shouts reach nearby guards through perception, so backup arrives believably).

**Escalation ladder**: ignore/glare → verbal warning → shove → non-lethal subdue → threaten with drawn weapon → lethal force. Guards step up or down as the situation changes.

**Modifiers**: rules of engagement per post, town or captain (presets: lenient, standard, strict, zero tolerance, kill on sight) · personality · mood/emotion · recognition and relationship · reputation *(future update)*.

First version outcome of a non-lethal subdue: knocked down, warned or pushed out. Arrest, fines, jail: *future update (Law & Order)*.

The §5a note that a damage-triggered score bonus is still open applies here; the reflex beat does not bypass minimum commitment by itself.

## 11. Combat

- **Style profiles**: archer, swordsman, shield-bearer, spearman; preferred and backup weapons, engagement range, tactics (circling, holding a line, kiting).
- **Weapon proficiency** per type (swords, axes, spears, bows, crossbows, shields): affects damage, accuracy, attack speed, blocking, parrying. Agreed: **grows with experience** (combat and practice), with diminishing returns and a talent cap. Applied as §5b modifiers.
- **Weapon switching**, utility-scored: distance, proficiency, ammo, allies in the line of fire, the target's weapon; a switch delay stops flickering.
- **Melee variety**: quick strike, heavy blow, thrust, shield bash; block, parry, dodge; weighted by proficiency and personality.
- **Barracks and training** *(future update)*: barracks, training grounds and academies per town with a quality level; towns with good training produce better soldiers; trainer skill, equipment, drill time and wartime experience as factors.

### 11.1 Weapon skill: five modifiers (developer decision 2026-11-04)

**Decided:** weapon skill has two kinds of growth on two levels, plus item familiarity, for **five modifiers** in total. This replaces the earlier practice-ceiling proposal.

| Modifier | Level | Grows from | Notes |
|---|---|---|---|
| Proficiency, type | Weapon type (swords) | Training, drills and combat | Drills can reach 100 % |
| Proficiency, kind | Weapon kind (diamond sword) | Training, drills and combat with that kind | Extra skill on top of the type |
| Combat experience, type | Weapon type | Real fights only | Adds on top of proficiency; mastery beyond training |
| Combat experience, kind | Weapon kind | Real fights only with that kind | |
| Item familiarity | One item instance (this exact sword) | Time owning and using that item | Shared with players; lost when the item is lost |

**Item familiarity** reuses the developer's vision mechanic (the longer you keep one item instance, the better you fight with it), so players and NPCs share one system. It is not yet written in `docs/vision/`; tracked in [PandiO/knk-workspace#237](https://github.com/PandiO/knk-workspace/issues/237). A guard who has carried the same sword for years fights better with it, and disarming him costs him something.

**Proposed curve** (not decided): each of the four skill values uses the same saturating shape, giving diminishing returns and a talent cap:

```latex
p(xp) = p_0 + (cap - p_0)\,(1 - e^{-xp / k})
```

- `p0` from the template (recruit 15, soldier 35, veteran 60; the royal guard template starts high), `cap` rolled per NPC (talent), `k` lowered a little by conscientiousness and openness.
- Combat experience per hit, block or parry = `base × challenge`, challenge = opponent power ÷ own power clamped 0.25–2, so trivial opponents teach almost nothing.
- How the five combine (additive bonuses vs. multiplied factors) and familiarity's growth curve: open, to settle with #237.
- Transfer between related weapon types and rust when unused: *(future update)*.

**What skill changes** (combined skill applied as §5b modifiers; values are examples):

| Effect | Novice | Master |
|---|---|---|
| Melee damage multiplier | 0.85 | 1.15 |
| Attack cooldown multiplier | 1.15 | 0.90 (still clamped by §5b floors) |
| Ranged spread | 2.5° | 0.3° |
| Reaction delay | 400 ms | 150 ms |
| Block / parry window | narrow | wide |

### 11.2 Ranged/melee switching thresholds (proposal, design pass 2)

Weapon choice is two utility actions, *engage ranged* and *engage melee*, under §5a scoring.

**Hard eligibility for ranged**: has a ranged weapon and ammo; line of sight; no ally in the line of fire (raycast corridor); target not inside the **panic distance** (proposed 3 blocks; you don't draw a bow while being hit).

**Considerations**: distance (curve per style), proficiency ratio ranged ÷ melee, own health (low health favours keeping distance), the target's weapon (an archer at range → close in behind a shield or take cover), allies already in melee (favours ranged support), and target reachable by navigation (unreachable, for example on a wall or across water → ranged if possible, otherwise hold and call archers).

**Hysteresis by distance band**: the switch to melee happens at a shorter distance than the switch back, so a target moving at the edge doesn't cause flickering. On top come §5a minimum commitment and switch margin, plus a physical swap time (proposed 10 ticks).

| Style | Switch to melee at | Back to ranged at | Preferred range | Notes |
|---|---|---|---|---|
| Archer | ≤ 3 blocks or cornered | ≥ 7 blocks | 10–25 | Backs off to regain distance if allowed |
| Swordsman | ≤ 8 | ≥ 15 and has a bow | melee | Ranged mainly for unreachable targets |
| Spearman | ≤ 6 | ≥ 12 and has a bow | 3–4 (reach) | Keeps the target at spear length |
| Shield-bearer | — | — | melee | Advances on archers with shield raised |

Band values are examples for tuning and live testing.

## 12. Posts, patrols and dynamic navigation

### 12.1 Posts and patrols (concept)

Gate-specific staffing, shifts and schedules are deferred to a dedicated gate-guarding session (developer).

- **Posts**: position, facing, watch area; idle behavior (glancing, shifting, turning).
- **Patrol routes**: waypoints with optional pause, look direction, action; looping, back-and-forth or branching.
- **Leashing**: how far a guard leaves post or route before duty pulls him back; set by conscientiousness and orders.
- **Coverage**: guards at a post coordinate so a post is not left empty when one investigates.

### 12.2 World annotation and dynamic routes

**Priority high** (developer 2026-11-04): admins must not hand-record every path. Shared by all NPC types.

- **Zones**: an NPC gets an area, for example existing WorldGuard regions (domains, gate structures).
- **Points of interest (POIs)** with a type label and weight, defined per structure type. Gate: wall left, wall right, inner wall/gate, outer wall/gate, tower, wall walk. Town: market stall, tavern, bench, well, armoury door.
- Walls between gates have no regions and don't fit the road navigation profiles (mostly one block type), so labelled POIs cover them (developer).
- Road navigation paths can be tagged (main road, wall walk) as preferred routes.
- NPCs pick their next POI by utility (time since last watched, importance, distance, role, mood); a **coverage map** cools recently seen areas and heats unseen ones so groups spread out. K&K navigation plans the route and Citizens walks it (§2 hybrid decision; DESIGN §6 rules apply). Hand-placed fixed routes stay possible (ceremonial guards); they map to DESIGN §6 lane overrides.

**Phase 2, learning POI patterns** (developer request; build after labels and heuristics):

1. Templates: typical POI positions relative to a structure's region, learned from labelled examples.
2. Heuristics: block scans for wall tops (walkable at height with drops on both sides), ladders, stairs, battlements, doors, chokepoints.
3. Suggest-and-confirm: the system proposes POIs, admins accept or reject in game or in the web app, each answer trains a small classifier.

Learning is grouped per **race build style**, since each K&K race builds with different materials and layouts.

### 12.3 Personal place knowledge *(future update)*

- Recruits know only the standard POIs and routes; veterans remember personal hotspots (enemy spotted, thief chased, danger met) as private POIs with their own weight, checked depending on personality and mood; memories fade unless reinforced.
- **Knowledge sharing** (developer): NPCs pass on places, experiences and players during idle chat, shift changes, briefings or meetings at posts; driven by extraversion, agreeableness, mood and trust. Second-hand knowledge is weaker and can distort. Foundation for rumours and wanted lists (Law & Order).

## 13. Performance and scaling

Agreed: build the utility system first with level of detail and time-slicing; investigate the rest later.

**Phase 1**: AI level of detail (full model near players, simplified further away, summary updates when unloaded) · time-slicing (staggered re-planning) · event-driven perception and appraisal · heavy scoring off the main thread · shared group blackboard and influence map.

**Later, to investigate**: distilled small models trained from LLM output or recorded tuned behavior · Generative Agents architecture for memory and relationships · reinforcement learning for combat micro-behavior (for example Unity ML-Agents) · small local LLMs for dialogue.

Numeric budgets follow the platform audit (DESIGN §9).

## 14. Debugging tools (developer decision 2026-11-04)

Without an inspector, tuning is guesswork. **Decided** for the first version: in-game inspector (with vision and hearing visualisation), decision trace with JSON export, sandbox controls, scenario test harness in core, and a web admin decision viewer. Staff-only (a permission node), shown per viewer, and it costs nothing unless someone is inspecting.

### 14.1 In-game inspector

`/npc inspect` on the NPC you look at (or by id) opens an InventoryMenu (UI-first, command only to open it) and toggles a live overlay for you alone.

| View | Shows |
|---|---|
| Overlay above the NPC | Guard-level alert state, named mood, current action, commitment time left |
| Perception debug mode (particles, per viewer) | Focal cone and peripheral arc; hearing range as a particle circle; a line to each target, coloured seen / peripheral only / blocked; heard noise events as fading markers; last known position |
| Suspicion | Per target: value, state, and the top contributing factors with their share (stranger +, restricted area ×, agitated mood ×) |
| Psychology | Traits (rolled values), PAD now vs baseline, named mood, active emotions with intensity and decay, active influence sources with scope and time left |
| Decision | All actions ranked: score, tendency fit, each consideration's input → curve output, modifiers; ineligible actions with the gate that blocked them (state, ROE, precondition, consumer); the margin a challenger still needs |
| Navigation | Current POI and route waypoints; coverage heat around the post (with dynamic routes) |
| Effective config | The resolved template, each value labelled with the layer it came from (§15) |

A "why not *X*?" button on any action explains the gap to the winner in one line.

### 14.2 Decision trace

- Per NPC, a ring buffer of the last N decisions (proposed 200): time, trigger event, winner, runner-up, margin, inputs. Recording is on for inspected NPCs and for NPCs an admin marks.
- Export as JSON (command or web app) so the developer or an AI agent can study a bad decision and propose weight changes.
- Each NPC has a seeded random source, so a trace can be replayed exactly.

### 14.3 Sandbox controls

Pause one NPC's AI and step it one decision at a time; inject an event or influence source (`core:war`, a noise at a position); set mood, a trait or a suspicion value temporarily; reset to template. Changes made this way are marked in the inspector and dropped on reset or restart.

### 14.4 Scenario test harness

The decision model lives in Bukkit-free core, so scripted scenarios run as unit tests: a timeline of events (stranger enters focal cone at 20 m, draws sword at 6 m) with a seeded NPC, asserting the chosen actions ("nervous recruit calls backup, veteran engages"). These double as the regression suite for the LLM-generated test scenarios from §8. Recorded traces can be turned into scenarios.

**Observer effect:** an inspected NPC runs at full level of detail (§13); the overlay says so, so nobody tunes a far-away NPC by watching it up close.

### 14.5 Web admin decision viewer (first version, developer 2026-11-04)

An admin page in knk-web-app built on the decision trace JSON (§14.2):

- Select NPC instances; browse each one's decision history (log, newest first).
- Open one decision as a **flow-chart visualisation**, laid out like a neural-network diagram: inputs (suspicion, mood, health, distance, orders…) on the left, considerations in the middle, every candidate action on the right; the chosen action highlighted, edge thickness showing how much each input contributed, and the main reasons listed.

Timelines of mood and suspicion over a shift: *(future update)*.

## 15. Configuration and templates (developer decision 2026-11-04)

### 15.1 Where configuration lives

**Decided:** templates live in the database and are edited in the web app; shipped presets are JSON seed files; one parent via `extends` plus `include` fragments. A template bundles traits, behaviors, mood modifiers, combat style and the other modules; each NPC rolls its own variance; **orders sit on the individual guard** (§7.3), on top of the template. Exact merge rules, depth limit and the precedence order below are the agreed direction; details can still change during implementation.

Follows the existing K&K pattern (code defaults, admin-editable data in knk-web-api, plugin cache through the API client, JSON seed files in the repo):

- **Code defaults** in Bukkit-free core: every value has one, so an empty template still works.
- **Templates and fragments** are authored in the web app (FormWizard pages) and stored by knk-web-api; the plugin caches them and gets changes pushed through the realtime channel.
- **Shipped presets** are JSON seed files in the repo (like form seeds): versioned, reviewable, and the natural output of design-time LLM work (§8). Importing a seed creates or updates the database entry.
- **Runtime state** (rolled traits, proficiency and xp, mood, memory) is per-NPC data persisted separately; it is not configuration and survives template edits.

### 15.2 Template structure and inheritance

A template is a named set of **modules**: perception, recognition, alert (states, thresholds, ROE), personality, psychology (goals, standards, attitudes, influence settings), actions, combat style, proficiency, navigation ruleset, post/patrol references. Each module has a schema version.

- **Single parent**: `extends` one template (for example `knk:town_guard` extends `knk:soldier`); depth limit (proposed 5); cycles rejected on save.
- **Fragments**: `include` an ordered list of partial templates (personality preset, combat style, night shift). This is how presets combine without multiple inheritance.
- **Merge rules**: objects merge by key; scalars override; collections are keyed maps by namespaced id (actions, goals, influence sources), so a child changes one entry without copying the rest; `"$remove": true` deletes an inherited entry; plain lists replace.
- **Variance fields** (`variance`, `range`) are rolled once per instance at creation, seeded by NPC id.

### 15.3 Precedence

Lowest to highest:

1. Code defaults
2. Parent chain, root first
3. Fragments, in `include` order
4. The template's own values
5. Instance overrides (one specific NPC), including the guard's orders (§7.3)
6. Assignment context from the controller (gate post orders and ROE, Siege rules, tutorial profile)
7. Runtime modifiers (§5b pipeline, influence sources, situations), which stack on the resolved values rather than replace them

Hard rules sit outside this order and no layer can override them: §5a eligibility and consumer overrides, permissions (NPC-12), §5b clamps and floors. Clamping is reported (§5b), and the inspector's effective-config view shows which layer won.

This ordering is proposed as the shared answer to the precedence questions left open in DESIGN §5a, §5b, §6 and O06/O08; it needs the developer's confirmation there too.

### 15.4 Validation and reload

- Schema validation on save (API) and in the form; the web app offers a resolved preview of the effective template.
- Template change → pushed to the plugin → NPCs re-resolve at their next decision tick; runtime state and current commitment are kept.
- Unknown registry ids (an action from a module that isn't loaded) are reported and skipped, not fatal.

### 15.5 Example

```json
{
  "id": "knk:town_guard",
  "extends": "knk:soldier",
  "include": ["knk:personality/steady_guard", "knk:combat/swordsman"],
  "personality": { "conscientiousness": 70, "variance": 8 },
  "alert": { "rulesOfEngagement": "standard" },
  "actions": {
    "knk:chat_idle": { "weight": 0.8 },
    "knk:pursue": { "maxDistanceFromPost": 24 },
    "knk:engage_ranged": { "$remove": true }
  },
  "influences": { "core:night_shift": { "enabled": true } }
}
```

## 16. Future updates (overview)

Not in the first version: Law & Order (local/global laws, crimes, punishments, jail, bounties, witnesses, wanted lists; see [vision §6](../../vision/vision.md#6-law-crime--safety)) · reputation and renown · persistent memory · personal place knowledge and knowledge sharing · barracks and training · smell · disguises · routines and off-duty life · command hierarchy and squads beyond the basic blackboard · trading influence on mood · distilled models, Generative Agents, RL, local LLM dialogue · fire extinguishing and bucket chains · weapon proficiency transfer and rust · bribery (corrupt preset) · mood and suspicion timelines in the web app · command hierarchy with order delegation and briefing (§7.3) · paranoid watchman and mercenary presets.

## 17. Open questions

Decided 2026-11-04 (developer, design pass 2): §7.1, §7.2, §7.3, §9.7, §9.8, §11.1 (structure), §14, §15. Still proposals: §11.2 switching thresholds and the §11.1 curve.

- Guard entity: stored data, ties to regions, clans and orders (next design session, together with gate staffing).
- Numeric tuning: tag weights per state, axis ranges and decay rates, preset values, influence magnitudes, skill curves and how the five skill modifiers combine, switching bands; Mehrabian coefficients to verify.
- Allegiance for NPCs and gates ([#236](https://github.com/PandiO/knk-workspace/issues/236)); item familiarity mechanic ([#237](https://github.com/PandiO/knk-workspace/issues/237)).
- Citizens verification and benchmark for the hybrid (§2); whether Siege attackers also use Citizens; how traits map onto DESIGN §2 template/instance/trait/behavior boundaries.
- Performance budgets for perception and appraisal with many NPCs.
- Gate-guarding session: staffing, shifts, schedules per post.
