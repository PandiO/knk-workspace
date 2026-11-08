# NPC runtime architecture — engine decoupling and scale (analysis)

**Status:** Analysis and proposals for developer review; nothing here is decided except where it cites an existing decision. Nothing implemented.
**Last updated:** 2026-11-08 (initial analysis, developer request: decouple the behaviour and traits model from Paper, Citizens and Sentinel; efficient spawning, behaviour and interaction for many NPC types; option to run behaviour in the API or a separate non-GUI system)
**Issue:** [PandiO/knk-workspace#234](https://github.com/PandiO/knk-workspace/issues/234) (guard behavior model); related [#241](https://github.com/PandiO/knk-workspace/issues/241) (Citizens verification: [#242](https://github.com/PandiO/knk-workspace/issues/242) desk check, [#243](https://github.com/PandiO/knk-workspace/issues/243) spike, [#244](https://github.com/PandiO/knk-workspace/issues/244) benchmark)
**Parent designs:** [DESIGN.md](DESIGN.md) (KNG-36 platform boundaries, §2 platform adapter), [BEHAVIOR_MODEL.md](BEHAVIOR_MODEL.md) (guard behaviour model)
**Authority:** The developer's request of 2026-11-08 and the principle in [vision §5.1](../../vision/vision.md#51-rank--permission-architecture-decided): minimise dependence on Minecraft/Bukkit-ecosystem plugins because a future migration off Minecraft (Unreal Engine or a custom engine) is a live possibility. Code facts were checked on 2026-11-08 against knk-plugin `main` (`33122cf`); library facts against current Paper and Citizens documentation (§11). Everything else is a proposal.

## 1. Question and scope

1. How can the NPC behaviour and traits model (perception, knowledge, alert states, moods, emotions, personality/character traits, proficiency and skills, decisions, combat) be kept independent of Paper and of plugins such as Citizens and Sentinel, so it survives a move to another game engine?
2. KnK will run many NPCs: guards, traders, shopkeepers, quest NPCs, tutorial guides, villagers, monsters and more. What makes spawning, behaviour and player interaction efficient at that scale?
3. Can part or all of the behaviour run in knk-web-api or in a separate headless (non-GUI, non-Minecraft) system?

Out of scope: choosing numeric budgets (those follow the #244 benchmark) and the content of the behaviour model itself ([BEHAVIOR_MODEL.md](BEHAVIOR_MODEL.md)).

## 2. Summary of recommendations

| # | Recommendation | Why |
|---|---|---|
| R1 | Put the whole behaviour and traits model in a new Gradle module **`knk-npc-core`** with **no** Paper, Bukkit, Citizens or Sentinel dependency, not even `compileOnly`. A build check enforces it. | The existing `knk-core` is meant to be framework-free but has `compileOnly` on `paper-api` and 13 files import `org.bukkit` (§3). A module that cannot see Bukkit cannot leak it. |
| R2 | The kernel talks to the engine only through a small set of **ports** (world queries, body commands, sensing events, interaction channel, clock). Paper code implements them in an adapter. | The DESIGN §2 platform-adapter boundary, made concrete. A new engine reimplements the adapter, not the model. |
| R3 | Keep **Citizens behind the locomotion port** only (the §2 hybrid: KnK plans, Citizens moves). **Do not adopt Sentinel**; use it as a reference. | Sentinel's value is targeting and the attack loop, which is exactly the part KnK wants to own (§4.4). |
| R4 | Guards are player-shaped (developer decision, [BEHAVIOR_MODEL §16.7](BEHAVIOR_MODEL.md#167-appearance-player-shaped-body-and-configurable-skin-developer-decision-2026-11-08)). Compare a **Citizens player NPC** with Paper's **`Mannequin`** entity plus a KnK mover in the #242–#244 track. Attack timing and damage run in KnK code for both. | Neither body has vanilla AI, so the §5b MobGoals adapter does not apply; owning the attack loop is also what decoupling asks for (§5). |
| R5 | Make cost follow **capabilities and distance**: an NPC only pays for the systems it has, and only at the detail its distance to players needs. Four simulation tiers, from data-only to full (§6.3). | Most NPCs (a shopkeeper at a stall) need almost nothing per tick; most of the world's NPCs are far from any player. |
| R6 | **Spawn bodies only near players**, through a budgeted spawn queue, with pooling and lazy catch-up of slow state (§7). | Entity count, not behaviour, is usually what costs the most on a Minecraft server. |
| R7 | Split behaviour by **timescale**: reflexes and movement execution stay next to the body (game server); tactical decisions run in the kernel, in-process at first but behind a message contract so they can move out; slow and strategic work (mood drift while unloaded, staffing, schedules, offline simulation, dialogue generation) runs in knk-web-api or a later headless **NPC simulation service** (§8). | Latency rules out running reflexes over a network; the slow layers have no such limit and benefit from leaving the game server. |
| R8 | Do **not** reimplement the psychology or decision model in C# for the API. If the decision layer leaves the game server, it goes to a separate JVM service that runs the same `knk-npc-core`. | One implementation of the model; the API keeps its role as system of record (§8.3). |
| R9 | Interactions are **engine-neutral intents and sessions**; trading, quests and shops keep their logic in the API and the kernel, the engine only presents them (§9). | The §17 gate confrontation already works this way (clickable answers map to intents). |

## 3. Starting point: what exists today

Checked in knk-plugin `main` (`33122cf`) on 2026-11-08:

- **No Citizens or Sentinel anywhere in V3** (no dependency, no import). The §2 hybrid decision would add Citizens; nothing depends on it yet, so the boundary can be designed before the first line of NPC code.
- **`knk-core` is not engine-free.** `knk-core/build.gradle.kts` declares `compileOnly("io.papermc.paper:paper-api:…")`, and 13 main-source files import `org.bukkit` (mostly `org.bukkit.util.Vector`): `util/{VectorMath,CoordinateParser}`, `gates/{RigidTransform,GateManager,DrawbridgeKeyframes,GateFrameCalculator,GateBlockPairing,GateSpatialIndex,safety/GateSweep}`, `domain/gates/{BlockSnapshot,CachedGateDoor}`, `domain/clan/KnkBannerLayer`, `domain/item/KnkShieldBanner`. [plugin-architecture.md](../../architecture/plugin-architecture.md) already records this as the only boundary violation.
- **Navigation planning is already engine-free.** `knk-core/.../core/roads/` (`route/`, `walk/`, `survey/`) and `core/navigation/` have no Bukkit import. The road graph and walk pathfinder that the §2 hybrid uses for planning can be reused by a kernel as they are.
- **The ports pattern exists**: `knk-core/.../core/ports/` (`api/`, `enchantment/`, `gates/`), implemented in `knk-api-client` and `knk-paper`. The NPC kernel's ports follow the same style.
- **A realtime channel exists**: knk-api-client uses the official SignalR Java client (`com.microsoft.signalr`, #178) to receive pushed changes from knk-web-api, with coalescing, sequence tracking and fallback polling in `knk-core/.../core/realtime/`. Template pushes ([BEHAVIOR_MODEL §15.1](BEHAVIOR_MODEL.md#151-where-configuration-lives)) and any later out-of-process behaviour (§8) can build on it.
- **knk-web-api already runs background services** (`BackgroundService`/hosted services such as `RealtimeDispatchService`, `PresenceSweepService`, `LeaderboardSnapshotService`), so periodic server-side NPC jobs (auto-fill, offline drift) fit an existing pattern.

## 4. Engine-neutral NPC kernel

### 4.1 What is engine-specific and what is not

Per layer of [BEHAVIOR_MODEL §4](BEHAVIOR_MODEL.md#4-architecture-layers):

| Layer | Engine-neutral (kernel) | Engine-specific (adapter) |
|---|---|---|
| Perception (§5) | Cone/peripheral rules, suspicion build-up, noise interpretation, modifiers from light/weather/target state as numbers | Raycasts against blocks, reading light level and weather, entity positions, turning game events (sound, damage) into sensing events |
| Knowledge and recognition (§6) | Recognition levels, familiarity, group blackboard | None (identities come from KnK data: users, clans, domains) |
| Alert states (§7), situations, orders | All of it: registries, tag weights, ROE, situations, orders | Detecting a situation's raw trigger (fire blocks, mobs in zone) and reporting it as an event |
| Psychology (§9) | Traits, PAD mood, OCC appraisal, influence sources, presets, variance | None |
| Decisions (§8) | Tendencies, considerations, utility scoring, §5a commitment and switch margin | None |
| Combat (§10, §11) | Escalation ladder, style profiles, skill combination and growth, weapon switching, §5b resolver (cooldowns, damage, speed with clamps) | Executing a swing, a block, drawing a bow, applying damage, item stacks |
| Navigation (§12, DESIGN §6) | Route planning on the road graph and walk grid, POI choice, coverage map, rulesets | Capturing world geometry into the walk grid; executing steps, jumps and doors (Citizens or a KnK mover) |
| Appearance (§16.7) | A reference to a look (`knk:skin/...`), equipment as KnK item data | Rendering: player profile/skin texture, equipment slots, name tag |
| Interaction (§17) | Dialogue graph, intents, believability, inventory-check logic | Chat lines with clickable answers, inventory reading, menus |
| Debugging (§14) | Decision trace, replay, scenario harness | Particle overlay, inventory-menu inspector |

Almost the whole model is neutral; the engine supplies senses and a body. That ratio is what makes the decoupling cheap if it is set up before implementation.

### 4.2 Module layout and dependency rule

Proposed Gradle modules in knk-plugin:

| Module | Contains | May depend on |
|---|---|---|
| `knk-npc-core` (new) | The kernel: model, registries, decision loop, ports, neutral value types, scenario test harness | JDK, Jackson (config), nothing engine-related |
| `knk-core` | Existing shared domain; road graph and walk pathfinder | Should drop `paper-api` too (move the 13 `Vector` uses to a KnK vector type); until then `knk-npc-core` must not depend on it, or the planner moves into a shared engine-free module |
| `knk-paper` (adapter package `paper/npc/`) | Port implementations: world snapshot, body (Citizens or `Mannequin`), sensing listeners, chat/menu presentation, overlay | Paper, Citizens (if chosen), `knk-npc-core` |
| Optional later: `knk-npc-sim` | Headless host for the kernel (§8) | `knk-npc-core`, a network transport |

**Enforcement:** the module simply has no Paper repository or dependency, so a `org.bukkit` import fails to compile. A small test (ArchUnit or a source scan) can additionally forbid `net.citizensnpcs`, `org.mcmonkey` and `net.minecraft` packages in case a transitive dependency ever brings them in.

### 4.3 Ports

Names are conceptual. All are interfaces in `knk-npc-core`; the Paper adapter implements them.

| Port | Direction | Purpose |
|---|---|---|
| `WorldQuery` | kernel → engine | Line of sight between two points, light level, block passability for the walk grid, weather. Batched and allowed to answer asynchronously from a snapshot (§8.5). |
| `SensingFeed` | engine → kernel | Events: entity seen/lost (position, identity, held item, sprint/sneak), noise (position, radius, type), damage taken (source, amount), gate/situation events. |
| `NpcBody` | kernel → engine | Spawn/despawn a body with a look and equipment; face/look at; play an animation (swing, block, draw); equip/swap item; set name tag. |
| `Locomotion` | kernel → engine | Follow these waypoints with this movement ruleset and speed; stop; report arrived/blocked/failed (DESIGN §6 result contract). Citizens sits here, nowhere else. |
| `CombatExecutor` | kernel → engine | Perform melee hit / release arrow / raise shield as decided; report hit results. Damage numbers come from the kernel's §5b resolver. |
| `InteractionChannel` | both | Show a line with answer options to one player; receive the chosen intent; open a trade/quest view; read the player's inventory for an inspection. |
| `SimulationClock` | engine → kernel | Simulation time in milliseconds (the adapter converts ticks) and the scheduling hook for the decision loop. |
| `NpcDataStore` | kernel → API client | Templates, instances, runtime state (traits, skills, mood), skin library; implemented by `knk-api-client` with the existing cache-first data access. |

### 4.4 Citizens and Sentinel

**Citizens** stays acceptable as the movement executor because the §2 hybrid decision already confines it to stepping, jumping, doors and unstuck handling, and that is a body concern. Under this analysis it is reachable only through `Locomotion` (and `NpcBody` if it also provides the player-shaped body). Behaviour, scoring and targeting never call Citizens types. If a Minecraft update leaves Citizens behind, or KnK moves engine, only those adapters change. A KnK mover on a `Mannequin` (§5.1) is the fallback that would remove the dependency entirely.

**Sentinel** (mcmonkeyprojects, MIT licence; last push December 2024) adds targeting, melee/ranged attacks, weapon switching, chasing, guarding and respawning to Citizens NPCs. Those are exactly BEHAVIOR_MODEL §5, §7, §8, §10 and §11, which KnK designs in far more detail (suspicion, alert states, psychology, skill-based switching). Using Sentinel would mean either:

- letting Sentinel decide (then the KnK model is reduced to configuration of a Minecraft plugin, which is the dependency the vision wants to avoid), or
- overriding most of its decisions from outside (fighting the library, with two sources of truth for "who is my target").

**Proposal:** do not add Sentinel as a dependency. Read its source as a reference for hard-won Minecraft details (attack reach, bow arc and lead, shield timing, avoiding friendly fire) and reimplement those in the `CombatExecutor` adapter or the kernel. Its MIT licence permits studying and reusing code with attribution.

### 4.5 Neutral value types, identity and time

- **Geometry:** KnK's own immutable `Vec3`, `BlockPos` and `WorldRef` (id, not a `World` object). Adapters convert at the boundary. Fixing the existing `org.bukkit.util.Vector` leak in `knk-core` with the same types removes the inconsistency.
- **Identity:** NPCs, players and items are referred to by KnK ids (NPC id, user id, item-instance id), never by Bukkit `Entity` or `UUID` of an entity. The adapter keeps the body ↔ NPC id map. This also fixes stale callbacks after respawn (DESIGN §5 robustness proposal): a body event that maps to no live NPC id is dropped.
- **Time:** simulation milliseconds from `SimulationClock`, not ticks. Values like "20-tick bow draw" are expressed in milliseconds in the kernel and converted by the Minecraft adapter.
- **Randomness:** the seeded per-NPC random source of [BEHAVIOR_MODEL §14.2](BEHAVIOR_MODEL.md#142-decision-trace) lives in the kernel; replay and the scenario harness then work identically in a unit test, the plugin and a headless host.
- **Looks and items:** a look id (`knk:skin/...`) and KnK item definitions, mapped to Minecraft textures and `ItemStack`s by the adapter. Another engine maps the same ids to its own assets.

### 4.6 What a migration to another engine would rewrite

| Survives unchanged | Rewritten per engine |
|---|---|
| `knk-npc-core` (all behaviour, psychology, skills, decisions, combat resolution, dialogue logic, traces, scenario tests) | The adapter: sensing, body, locomotion, combat execution, presentation |
| Templates, presets, skin/look references, runtime NPC state in knk-web-api | World snapshot provider feeding `WorldQuery` and the walk grid |
| Web app pages (templates, military management, decision viewer §14.5) | Asset mapping (look id → character model, item id → model) |
| Road graph and route planner (if moved off `org.bukkit.util.Vector`) | Possibly locomotion entirely, if the new engine has its own navmesh |

If the kernel runs headless (§8), a new engine can even start as a thin client that only implements the ports over the network.

## 5. Player-shaped bodies on Paper

### 5.1 Body options

| Option | What it is | Strengths | Concerns (to measure in #243/#244) |
|---|---|---|---|
| A. Citizens player NPC | Citizens creates a fake server-side player entity (EntityType `PLAYER`) | Mature movement, doors and unstuck handling; skins through `SkinTrait`; well-known | A fake player is the heaviest body type (player tracking, tab-list handling, per-viewer skin packets); Citizens follows NMS changes after each Minecraft update |
| B. Paper `Mannequin` + KnK mover | Vanilla player-model entity (Minecraft 1.21.9+), in the Paper API as `org.bukkit.entity.Mannequin`, skin via `setProfile(ResolvableProfile)` | Plain API entity, no fake connection, no NMS; probably cheaper per body; survives updates with Paper | Not a `Mob`: no pathfinder or goals, so KnK must move it (teleport/velocity per tick along planned waypoints, jumping, doors); whether Citizens can drive a `Mannequin` is unknown |
| C. Packet-only (client-side) NPC | No server entity; packets show a player to chosen viewers | Cheapest; per-player visibility for personal NPCs (tutorial guide, DESIGN O05) | Needs a packet library or NMS (another ecosystem dependency); no server-side collision or damage; unsuitable for combat |

**Proposal:** add a row to the #242 desk check for option B (API surface, `setProfile` behaviour on 26.3, whether Citizens supports it as an NPC type) and measure A vs B per active body in #244. C is only worth considering for non-combat personal NPCs. All three sit behind `NpcBody`/`Locomotion`, so the choice can differ per archetype (a combat guard on A, a stall keeper on B) and change later.

### 5.2 Skins

- Store the **signed texture** (value + signature) in the skin library ([BEHAVIOR_MODEL §16.7](BEHAVIOR_MODEL.md#167-appearance-player-shaped-body-and-configurable-skin-developer-decision-2026-11-08)); never resolve a profile from Mojang at spawn time. Citizens takes it through `SkinTrait.setTexture(value, signature)` (its wiki recommends signing uploaded images with MineSkin and storing the result); a `Mannequin` takes it inside the `ResolvableProfile`.
- Signing a new uploaded skin is an admin action through the API (one external call per new skin), so the game server never depends on an external skin service at runtime.
- Spigot issue SPIGOT-8084 (a `Mannequin` given a player's profile kept the default skin) is marked resolved; the spike should still verify signed textures on Paper 26.3.

### 5.3 Attack loop without vanilla AI

DESIGN §5b proposes a custom MobGoals attack goal that calls the vanilla attack. A player-shaped body is not a `Mob`, so for guards:

- The **kernel** decides when to attack, with what, and with which timing (cooldown, draw time, reaction delay from §11.1 skill) through the existing §5b resolver; the clamps and floors (for example the 10-tick melee floor because of invulnerability frames) stay binding.
- The **`CombatExecutor` adapter** performs it: swing animation, a reach and line-of-sight check, `damage(amount, source)` on the target, arrow launch with the resolved speed and spread, shield raise.
- Mob-bodied NPCs (Siege attackers) keep the MobGoals adapter; both adapters consume the same resolver output, so §5b's "Siege only supplies values" decision holds.

## 6. Population and cost model

### 6.1 Expected population

Guards: [BEHAVIOR_MODEL §13](BEHAVIOR_MODEL.md#13-performance-and-scaling) estimates about 720 in the first year, with 60–100 active near players as the main target and 200 as a stress test. Other types are not estimated anywhere yet. **Illustrative assumption only:** 20–40 traders, shopkeepers, quest givers and villagers per town across about 21 towns adds 400–800 more, so the world holds low thousands of NPCs, while only those near online players need a body. The developer's own numbers should replace this.

### 6.2 Cost follows capabilities

NPC-01 already makes capabilities composable. The scaling consequence: **systems are attached per capability and run only for NPCs that have them**.

| Archetype | Typical capabilities | Per-tick cost when near players |
|---|---|---|
| Shopkeeper at a stall | Body, interaction, look-at-nearest-player, simple idle animation, opening hours | Near zero: event-driven (right-click), occasional head turn |
| Trader/caravan | Movement on roads, interaction, optional escort reaction | Movement execution; decisions rarely (route legs) |
| Quest giver | Body, dialogue, quest state (in the progression system, DESIGN §8) | Event-driven |
| Villager/bystander | Roam, needs, flee reaction, light perception (hearing, being hit) | Low: coarse decisions every few seconds |
| Guard | Full perception, alert, psychology, decisions, combat | Highest: the BEHAVIOR_MODEL budget applies |
| Tutorial guide | Movement, proximity sensing, dialogue | Low |

A shopkeeper never pays for raycasts or utility scoring. Perception in particular should be event-driven and only reach the "sight" check when a candidate entity is within range, as BEHAVIOR_MODEL §13 already proposes.

### 6.3 Simulation tiers (level of detail)

Proposed, extending BEHAVIOR_MODEL §13 phase 1 to every NPC type:

| Tier | When | Body | What runs |
|---|---|---|---|
| T0 Dormant | Region not loaded and nothing needs the NPC | None | Nothing. State is data in the API. Slow values (mood drift, fatigue, familiarity decay) are recomputed in closed form from timestamps when the NPC wakes ("lazy catch-up", as BEHAVIOR_MODEL §11.1 already does for familiarity). |
| T1 Abstract | NPC matters to the world but no player is near (a caravan between towns, a guard rotation, a besieged town without spectators) | None | Coarse simulation on a schedule (seconds to minutes): position along a route, staffing, outcomes resolved statistically. Candidate to run outside the game server (§8). |
| T2 Embodied, far | A player is in the area but not close (beyond, say, 48 blocks; values to measure) | Spawned | Movement execution, cheap perception (hearing, damage), decisions about once per second or slower |
| T3 Embodied, near | A player is close or interacting, or staff inspect the NPC | Spawned | Full model at the BEHAVIOR_MODEL §13 cadence (re-plan every 5–10 ticks), full perception |

Tier transitions are driven by player proximity and chunk state, with hysteresis so an NPC at the boundary does not flap. An NPC in combat or confrontation stays at T3 until the interaction ends (minimum commitment, §5a, must not be broken by a tier change).

## 7. Spawning and despawning

1. **Bodies only near players.** An NPC gets a body when it enters T2 and loses it when it falls to T1/T0. A garrison of 30 with nobody in town has no entities at all.
2. **Spawn queue with a per-tick budget.** Spawn requests (tier changes, auto-fill, respawns) go through one queue; each tick spawns at most N bodies (to measure). Priority: NPCs a player is about to see or interact with first. Proposed budgets in BEHAVIOR_MODEL §13 already say "queued spawns" as the last degradation step.
3. **Prepare off-thread, apply on the main thread.** Resolving the template, picking the skin, building equipment and loading state happen asynchronously (cache-first data access); the main thread only creates the entity and applies the prepared data.
4. **Pool where the body type allows it.** Reusing a despawned body for the next NPC (change look, equipment, position) avoids create/destroy churn for busy markets. Whether this beats fresh spawns depends on the body option (§5.1) and is a benchmark item.
5. **Persist state on despawn, not continuously.** Runtime state is written when an NPC drops to T1/T0 or on meaningful events (skill gain, death), batched to the API.
6. **Stale-body safety.** Every body carries its NPC id and a spawn generation; sensing events and callbacks from an older generation are dropped (DESIGN §5 robustness proposal, NPC-05/06).
7. **Chunk policy stays with DESIGN §6:** spawning never loads or generates chunks on its own.

## 8. Where behaviour runs

### 8.1 Layers by timescale

| Layer | Timescale | Examples | Latency need |
|---|---|---|---|
| Reflex and execution | 1–2 ticks (50–100 ms) | Flinch, turn to attacker, raise shield (BEHAVIOR_MODEL §10 first beat), stepping, swing timing | Must be next to the body |
| Tactical decisions | 250 ms – 1 s | Alert-state updates, utility scoring, target choice, weapon switch | Tolerates a few ms to tens of ms, not seconds |
| Strategic / slow | Seconds to days | Mood drift, needs, influence sources, staffing and auto-fill (§16.4), schedules and shifts, offline (T1) simulation, knowledge spread, reputation | Tolerates seconds |
| Generative | Seconds | LLM dialogue, free-text answers at a checkpoint (§17 future update) | Asynchronous by design |

### 8.2 Options

**A. Everything in the plugin process.** `knk-npc-core` runs inside Paper; tactical decisions run on a worker pool against immutable snapshots, results are applied on the main thread. Lowest latency and simplest operations. Load still competes with the Minecraft server for the same CPU and memory.

**B. Behaviour in knk-web-api.** The API is C#/.NET; the plugin is Java. Running the model there means a second implementation of the whole psychology and decision model (or a cross-language runtime), every tactical decision crossing the network, and the system of record and web backend sharing load and failure with a simulation loop. During an API outage NPCs would stop deciding (the plugin's outage handling, `ApiOutageSignal`, keeps gameplay going without the API today). Good fit only for the slow layer that is mostly data: template resolution and validation, auto-fill and staffing (#238 back end), offline drift jobs, skin signing, decision-trace storage for the web viewer (§14.5).

**C. A separate headless NPC simulation service.** A JVM process with no GUI and no Minecraft that hosts `knk-npc-core`, receives sensing snapshots and events from game servers, and sends back intents and commands. It reads and writes NPC data through knk-web-api. It scales separately from the game server, can simulate T1 NPCs for every town at once, could serve several game servers sharing one world population, and is the most engine-portable shape (a new engine becomes a thin client). Costs: another service to deploy, monitor and secure; a network hop for every tactical decision; world state needed for perception and planning must either stay engine-side (raycasts answered by the adapter) or be replicated (walk grid captures); and a defined behaviour when the link drops (bodies fall back to a local "hold position, defend self" reflex).

### 8.3 Comparison

| Criterion | A in plugin | B in API | C headless service |
|---|---|---|---|
| Reflex latency | Fits | Does not fit | Does not fit |
| Tactical latency | Fits | Network, tens of ms if not co-located | Few ms on the same host/LAN |
| Engine portability | Kernel portable, host is not | Kernel portable but in C# twice | Best |
| One implementation of the model | Yes | No (Java + C#) | Yes |
| Offline (T1) simulation | Only while the server runs, competes with ticks | Natural for data jobs | Natural |
| Operations | None extra | None extra, but heavier API | New service |
| Failure isolation | NPC load can lag the server | NPC load can slow the web | Separate; needs a fallback reflex |

### 8.4 Recommendation

1. **Start with A** for reflex, execution and tactical decisions, but build the kernel so the tactical loop is called **only through a message contract** (§8.5) even in-process. That keeps option C open at no extra cost.
2. **Put the slow, data-shaped layer in knk-web-api** where it already belongs: templates, presets and the skin library (already decided, §15.1), staffing and auto-fill (#238), periodic offline jobs as hosted services, decision-trace storage. These are CRUD and scheduled jobs, not the psychology model.
3. **Extract tactical and T1 simulation into the headless service (C)** when one of these happens: the #244 benchmark or live metrics show NPC work breaking its tick budget even after level of detail; KnK runs more than one game server sharing NPCs; T1 simulation of many towns becomes a gameplay requirement; or an engine migration starts.
4. Reflexes and movement execution stay with the body in every option.

### 8.5 Message contract

The same contract serves in-process calls (option A) and the network (option C):

- **Inbound to the kernel:** a per-NPC snapshot at decision time (own position, health, equipment; visible/heard entities with positions; relevant gate and situation state) plus queued sensing events since the last decision; world queries answered by the adapter.
- **Outbound from the kernel:** intents and commands (`MoveTo(waypoints, ruleset)`, `LookAt`, `Attack(target, kind)`, `Say(player, line, answers)`, `Equip`, `Despawn`) with the NPC id and spawn generation, plus trace records.
- Messages are plain data (JSON or a binary schema), versioned like the template modules (§15.2), and carry simulation time, so replay from a trace (§14.2) works the same in every host.

## 9. Player interaction at scale

- **Event-driven, never polled.** A right-click, a chat-answer click or entering conversation range produces one event routed by NPC id to the kernel. Idle interaction costs nothing.
- **Interaction sessions** are small state machines per (player, NPC) pair: dialogue node, pending answers, timeout. They hold no engine objects, so they survive a body respawn and work identically in another engine. DESIGN NPC-04/05 (pause and resume on leaving range) is one policy of such a session.
- **Logic in the API or kernel, presentation in the engine.** Shops and trading use the currency and item services that already live in knk-web-api; quests use the progression system (DESIGN §8); the gate confrontation uses intents (§17). The engine adapter only renders lines, clickable answers, menus and inventories. A future engine swaps chat for its own UI.
- **Concurrency rules:** one active session per player per NPC; a busy NPC (in combat, already talking) answers with a short "busy" line chosen by the kernel; per-player rate limits on interactions to stop spam-clicking from triggering work.
- **Shared NPCs, personal views:** a shopkeeper serves many players at once by keeping a session per player; only personal NPCs (tutorial guide) need per-player bodies, which is where the packet-only option (§5.1 C) might pay off.

## 10. Proposed decisions for the developer

| ID | Proposal | Default if accepted |
|---|---|---|
| RA-01 | New `knk-npc-core` module with no Paper/Bukkit/Citizens/Sentinel dependency, enforced by the build | Yes |
| RA-02 | Ports as in §4.3; Citizens only behind `Locomotion` (and `NpcBody` if it supplies the body) | Yes |
| RA-03 | Sentinel is a reference only, not a dependency | Yes |
| RA-04 | Add `Mannequin` + KnK mover as option B to the #242 desk check and #244 benchmark; body choice may differ per archetype | Yes |
| RA-05 | Replace the `org.bukkit.util.Vector` uses in `knk-core` with KnK geometry types (small refactor, separate issue) | Yes |
| RA-06 | Four simulation tiers (§6.3) for every NPC type, with capability-based systems | Yes |
| RA-07 | Spawn queue with per-tick budget, async preparation, persist on despawn (§7) | Yes |
| RA-08 | Behaviour split by timescale; start in-process behind a message contract; slow data layer in the API; headless service later on the §8.4 triggers | Yes |
| RA-09 | No C# reimplementation of the psychology/decision model | Yes |
| RA-10 | Replace the §6.1 illustrative population with the developer's own estimates per NPC type | Developer input |

Suggested follow-up issues once accepted (not filed by this analysis): the `knk-npc-core` skeleton with ports and the scenario harness; the `Vector` refactor in `knk-core`; extending #242–#244 with the `Mannequin` option, skin handling and per-archetype costs; the skin library in knk-web-api and the web app.

## 11. Sources

- knk-plugin `main` `33122cf` (2026-11-08): `knk-core/build.gradle.kts`, the `org.bukkit` imports listed in §3, `core/roads/`, `core/navigation/`, `core/ports/`, `core/realtime/`, `knk-api-client/build.gradle.kts` (SignalR client).
- knk-web-api `Realtime/`, `Services/` hosted services.
- Paper `Mannequin` API: [jd.papermc.io Folia 26.2 `Mannequin`](https://jd.papermc.io/folia/26.2/org/bukkit/entity/Mannequin.html), [Paper 1.21.11 `Mannequin`](https://jd.papermc.io/paper/1.21.11/org/bukkit/entity/Mannequin.html); [Minecraft wiki: Mannequin (added 1.21.9)](https://wiki.ronlab.site/content/minecraftwiki_en_all_maxi_2025-11/Mannequin); [SPIGOT-8084](https://hub.spigotmc.org/jira/browse/SPIGOT-8084).
- Citizens skins: [SkinTrait Javadoc](https://jd.citizensnpcs.co/net/citizensnpcs/trait/SkinTrait.html), [Citizens wiki: Skins](https://wiki.citizensnpcs.co/Skins).
- Sentinel: [mcmonkeyprojects/sentinel (ecosyste.ms listing: MIT, last push December 2024)](https://awesome.ecosyste.ms/projects/github.com%2Fmcmonkeyprojects%2Fsentinel).
