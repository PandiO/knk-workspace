# NPC behavior model — perception, psychology, decisions and combat (guards first)

**Status:** Working concept from a developer design session; not approved defaults, not an implementation plan, nothing implemented. Items marked *(future update)* belong to the overall vision but are not planned for the first version.
**Last updated:** 2026-11-04 (hybrid navigation decision in §2: K&K plans, Citizens moves); 2026-11-04 (initial concept, developer voice design session)
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

Open: situational states (fire, monster attack).

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

## 14. Debugging tools

Proposed for the first version: an inspector that shows what an NPC perceives, its suspicion per target, mood/emotions, the scored actions and why one was chosen. Without it, tuning is guesswork.

## 15. Future updates (overview)

Not in the first version: Law & Order (local/global laws, crimes, punishments, jail, bounties, witnesses, wanted lists; see [vision §6](../../vision/vision.md#6-law-crime--safety)) · reputation and renown · persistent memory · personal place knowledge and knowledge sharing · barracks and training · smell · disguises · routines and off-duty life · command hierarchy and squads beyond the basic blackboard · trading influence on mood · distilled models, Generative Agents, RL, local LLM dialogue.

## 16. Open questions

- Citizens verification and benchmark for the hybrid (§2); whether Siege attackers also use Citizens; how traits map onto DESIGN §2 template/instance/trait/behavior boundaries.
- Axis ranges, baselines, drift and decay rates; default influence sources; personality presets.
- How alert states enable actions; situational states (fire, monster attack).
- Proficiency growth curve and talent caps; ranged/melee switching thresholds.
- Config format, template inheritance and precedence (shared with DESIGN §5b/§6 open items).
- Performance budgets for perception and appraisal with many NPCs.
- Gate-guarding session: staffing, shifts, schedules per post.
