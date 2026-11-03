# Siege Survival — Defend the Castle

**Status:** Gameplay design recorded from developer decisions; not implemented. Integration details marked proposed or to verify are not approved balance values.
**Last updated:** 2026-11-03 (consistency pass over the 2026-11-02 decisions; open developer questions recorded in §13 items 9 and 17); 2026-11-02 (v1 answers: default kit, roller-only claim, admin-selected vanilla mob types, inventories kept on death in every mode, break deaths respawn next round, per-enemy stuck handling proposed; S38–S42); 2026-11-02 (v1 defaults: per-kill rewards and match currency, Mystery Box 1000 on an end portal frame, no kit switching, 1 player minimum, disconnect = leave; S32–S37); 2026-11-02 (v1 completeness review: end-condition defaults and lobby override for all-captured, 10 s round delay, stuck-enemy fallback, scaling presets, permanent rewards out of v1, S26–S31); 2026-11-02 (developer requirements review: configurable end conditions with lobby override, ghost state for dead players, per-stat round scaling, third equipment mode KITS, in-world Mystery Box animation with an enchanted-book variant); 2026-10-30 (navigation decision supersedes mandatory lanes; #146)
**Linear:** [KNG-50](https://linear.app/kngpandi/issue/KNG-50/siege-survival-endless-npc-waves-gate-repair-and-match-economy), child of [KNG-37](https://linear.app/kngpandi/issue/KNG-37/design-dungeon-waves-and-siege-pve-defense-mode)
**Dependencies:** [KNG-36 NPC platform](https://linear.app/kngpandi/issue/KNG-36/design-shared-npc-traits-and-pathfinding-platform); existing Siege, gate runtime, inventory menus, item blueprints, lootboxes and currency ledger.
**Authority:** The developer's 2026-09-30 conversation and corrections define this mode, with mandatory lanes superseded by the 2026-10-30 automatic-navigation/optional-override decision and the 2026-11-02 requirements review (S17–S25) superseding S03, S05, S11 and the chest-menu Mystery Box reel, refined by the 2026-11-02 v1 review (S26–S31) v1 defaults (S32–S37) and v1 answers (S38–S42, superseding S13's death drops). Existing PvP Siege rules remain unchanged. This document is the canonical survival specification, not a claim that the proposed entities, endpoints or gameplay already exist.

Related: [Siege design](../siege-minigame/DESIGN.md), [Siege implementation status](../siege-minigame/IMPLEMENTATION_PLAN.md), [scenario authoring](../../guides/authoring-a-siege-scenario.md), [lootboxes](../lootboxes/DESIGN.md), [currency payments](../currency-payments/DESIGN.md), [gate runtime](../gate-structure-animation/INDEX.md), [implementation plan](IMPLEMENTATION_PLAN.md).

## 1. Goal and first-release scope

A cooperative survival variant within Siege. One human defender team protects a town/castle against an NPC attacker team. Waves (rounds) are discrete, endless and increasingly difficult, inspired by Call of Duty Zombies. Gate-linked objectives form successive defensive lines. Players aim for the highest number of completed waves; there is no final wave or ordinary victory condition. The game ends on a team wipe or on an end condition the scenario enables (§3a).

The first release includes ALL THREE equipment modes (own inventory, kits, Zombies-style match progression), cooperative gate repairs, explicit NPC spawnzones and optional lane overrides, special waves, personal transferable match currency, fixed equipment purchases AND the Mystery Box in both variants (items and enchanted books) based on the existing lootbox roll functionality, with an in-world item-entity animation (§8a). Mystery Box is not deferred. **Permanent rewards in v1 are a simple per-kill default (S32); the full reward design and calibration of §9 come later.** Material costs, repair puzzles and extra repair cooldowns are excluded from this release.

Keep the existing lobby, scenario, team identity, gate/objective references, spawnpoint selection, match history and restoration infrastructure wherever their semantics fit. NPCs are match actors, not fake player accounts. Do not apply player-team population checks to the NPC team.

## 2. Decision register

| ID | Confirmed decision |
|---|---|
| S01 | Endless escalating waves; configurable pause between waves, default 10 s (S27). No fixed last wave. |
| S02 | One player defender team and one NPC attacker team. NPCs target players and objectives, may breach eligible gates, and can be occupied by eligible distractors. |
| S03 | *(Superseded 2026-11-02 by S17–S19.)* ~~Defeat on capture of the main objective OR all remaining defenders dying during a wave.~~ A team wipe always ends the game; objective-based endings are configurable (§3a). Capturing an objective without the game-ending flag never ends the game. |
| S04 | Dead players become ghosts (S20) until the pause preceding the next wave; reuse available Siege spawnpoints/held-objective spawn choices. |
| S05 | Objective recapture is configurable, default off. *(Updated 2026-11-02:)* ~~Main-objective capture always ends the match.~~ A game-ending objective ends the match only while objective endings are enabled (S18). |
| S06 | Gates are closed defensive barriers while intact and defender-owned; NPCs capture reachable zones, otherwise damage the blocking door. Door destruction is separate from objective capture. Target preference may vary with difficulty. |
| S07 | Destroyed doors can be repaired while their objective remains defender-owned, including during waves and objective pressure. |
| S08 | Repair requires staying nearby and performing a channelled interaction. No material/currency cost. Taking damage does not stop a player's contribution; fighting back requires stopping repair. |
| S09 | Repair work persists when interrupted; each active player adds configurable health-equivalent work per second. Difficulty sets the rate. Health is restored in one step only at completion, followed by the normal closing animation. No additional cooldown. |
| S10 | NPC spawnzone progression depends ONLY on objective capture, never merely on an open or destroyed door. |
| S11 | *(Updated 2026-11-02, S23.)* Three equipment modes per scenario from the first release: own inventory (Siege behavior), kits (S23) and a Zombies-style isolated match inventory. |
| S12 | *(Updated 2026-11-02, S33.)* Players hold individual match balances and can give a chosen amount to a teammate. Mystery Box uses configurable content; a roll costs 1000 match currency (S34). |
| S13 | *(Superseded 2026-11-02 by S40: inventories are kept on death in every mode.)* ~~Zombies death drops equipment at the death location; teammates or the returning player can retrieve it. Respawn gives the basic loadout; the match balance is retained. Inventory rules are scenario settings, not individual player choices.~~ |
| S14 | Special waves support both recurring intervals and explicit wave numbers, with their own enemy profiles. |
| S15 | *(v1: per-kill default only, S32.)* Permanent coins, gems and experience accrue during the match and are granted once after its end. Match currency is credited immediately for purchases during play. |
| S16 | *(After v1, S31.)* Permanent reward amounts await developer-supplied progression targets (hours to levels/purchases, expected games and earnings/hour). Do not invent a payout table. |
| S17 | *(2026-11-02)* Any number of objectives can carry the game-ending flag ("ends the game when captured by the enemy"), the same flag as Siege's main objective (`InstantVictory`). Survival needs no single main objective. |
| S18 | *(2026-11-02)* Scenario setting "objective captures end the game" (on/off) with a survival lobby override `Inherit` / on / off, following the Siege navigation-compass precedent (most specific wins: lobby → scenario). Off: no flagged objective ends the game. |
| S19 | *(2026-11-02)* Scenario setting "end when all objectives are captured" (on/off), independent of S18; both, either or neither can be enabled. With both off only a team wipe ends the game. |
| S20 | *(2026-11-02)* A player killed during a wave becomes a ghost until the next intermission respawn: invulnerable, no hunger loss, ignored by all NPCs, unable to interact or take part in any way, not in vanilla spectator mode (no flight, no passing through blocks). Teammates see ghosts translucent; NPCs and anyone else don't see them. Mechanics that revive a dead player mid-wave may be added later. |
| S21 | *(2026-11-02)* By default every new wave raises both the enemy count and the NPC base stats: health, walking speed, melee damage, ranged damage and attack speed. Admins can change the growth per stat. |
| S22 | *(2026-11-02)* Spawnpoints carry spawn conditions so admins can author "overrun": spawnzones inside a gate line activate only when that gate's objective falls (confirms S10). |
| S23 | *(2026-11-02)* Kits mode: admins select Kit instances for the scenario; each player picks one of them. The kits' own conditions (permission, title bracket, cooldown) and prices (claim cost, premium gems) do not apply. |
| S24 | *(2026-11-02)* The Mystery Box has two variants, items and enchanted books, both rolled from configured pools with percentage drop chances. The chest-menu reel is replaced by an in-world animation of a non-pickable item entity on a block, with sounds and particles. The roller claims the final item by right-clicking it; unclaimed it despawns after 10 seconds, then a new roll can start. Cost is to be determined. |
| S26 | *(2026-11-02, v1 review)* End-condition defaults: team wipe always on; "all objectives captured" off by default, set per scenario with a survival lobby override; each objective's game-ending ("insta-lose") flag off by default. The match ends on the first enabled condition met. |
| S27 | *(2026-11-02, v1 review)* A round ends when every enemy of that round is dead (planned queue exhausted); the next round starts after a 10 s delay. |
| S28 | *(Under review 2026-11-02; see §3c proposal.)* Stuck-enemy fallback: 1 minute into the fallback window the round's remaining enemies are respawned; any still alive 1 minute after that respawn are killed (§3c). |
| S29 | *(2026-11-02, v1 review)* Count and stat scaling each use a selectable preset (linear, logarithmic, exponential, hybrid), chosen separately, with a hybrid switch round, per-player scaling (count, optionally stats), max enemies alive at once, a stat cap and a count cap (§7). |
| S30 | *(2026-11-02, v1 review)* Round 1 enemies use the vanilla Minecraft stats of their mob type; tuning values come from balance tests. |
| S31 | *(Superseded 2026-11-02 by S32.)* ~~Rewards are out of scope for v1.~~ The full reward design (§9) stays after v1; v1 ships the per-kill default. |
| S32 | *(2026-11-02, v1 defaults)* Default permanent reward per NPC kill = Siege's objective-capture reward ÷ 10. The dev seed's Siege scenario ("Cinix under Attack!": `CoinRewardCapture` 300, `ExpRewardCapture` 30) gives **30 coins and 3 XP per kill**. A headshot or critical-hit kill pays ×1.1 (33 coins, 3.3 XP). Granted once at match end. |
| S33 | *(2026-11-02, v1 defaults)* **70 match currency per NPC kill**, with the same headshot/crit multiplier (×1.1 → 77). Per-kill amount and multiplier are configurable. |
| S34 | *(2026-11-02, v1 defaults)* A Mystery Box roll costs **1000 match currency**. |
| S35 | *(2026-11-02, v1 defaults)* The default Mystery Box block is the **end portal frame** (the block an eye of ender goes into). |
| S36 | *(2026-11-02, v1 defaults)* Players **cannot switch kits** between rounds; the kit picked at the hub is kept for the whole match. |
| S38 | *(2026-11-02, v1 answers)* In kits mode the admin selects a **default kit** for the scenario (one of its selected kits); a player who doesn't pick gets it. |
| S39 | *(2026-11-02, v1 answers)* Only the player who rolled the Mystery Box can claim the item. |
| S40 | *(2026-11-02, v1 answers)* **Inventories are not dropped and are kept when dying**, in every equipment mode. No death drops. |
| S41 | *(2026-11-02, v1 answers)* A player who dies during the 10 s break respawns when the next round starts. |
| S42 | *(2026-11-02, v1 answers)* v1 enemies are **vanilla Minecraft monster types** the admin selects per scenario. |
| S37 | *(2026-11-02, v1 defaults)* **Minimum players: 1.** A disconnect is a leave (no rejoin); the match ends when no players are left. |
| S25 | *(2026-11-02, confirms §3 step 1)* The ordinary player state is snapshotted when the player is sent to the pre-game lobby (the Siege hub) and restored when the game ends, the same as Siege. |

## 3. Match and wave lifecycle

Reuse Siege's outer matchmaking/vote/hub/match/cooldown lifecycle. Proposed survival substates inside a running match are PREPARING, WAVE_ACTIVE, INTERMISSION and ENDING; these are design names, not current enums.

1. When the player is sent to the pre-game lobby (the Siege hub, T-15), durably snapshot the player's ordinary state before teleport or inventory replacement, exactly as Siege's vault does (S25; Siege design §6.4/§9). Restore it when the game ends or the player leaves. Snapshot affected gates before applying match overrides.
2. Select scenario, equipment mode and difficulty; resolve the end-condition settings against the lobby override (§3a); freeze that configuration revision for the match. All human participants join the defender team. In kits mode each player picks a kit at the hub (§8). Initial objective owners and gate states establish the castle defenses; initial NPC spawnzones are enabled.
3. Start wave 1 after the preparation countdown. Select its normal or special profile, generate the finite wave population and distribute it over configured spawnzones with configured pacing.
4. A wave completes only when its planned spawn queue is exhausted AND no wave enemies remain alive. A temporarily empty combat area or a spawn delay cannot finish a wave. Enemies the stuck-enemy fallback kills (§3c) count as dead for completion but not as earned kills.
5. Record the completed wave and eligible contributions. Enter intermission, respawn dead players with valid spawn choices, and display the countdown (default 10 s, S27; configurable per scenario). Survivors remain in play. No implied automatic gate repair or gear refill for survivors.
6. Start the next, harder wave. Repeat without a configured final wave.
7. An active-wave team wipe or an enabled end condition (§3a) goes straight to ENDING: cancel remaining spawns and repairs, freeze results, settle the per-kill permanent rewards (S32), remove match entities/items, restore players and gates, then run ordinary lobby cooldown.

Persist both highest wave reached and last fully completed wave. A wipe in wave 10 means reached 10, completed 9; use completed waves for the base reward to avoid awarding a cleared-wave bonus for failure. Endless survival must not inherit PvP's timer-expiry defender victory. A technical duration/resource limit, if added, is an explicit abort policy rather than a secret win condition.

Player death is not quitting or roster removal. Dead players (ghosts, §3b) remain participants and are eligible for the result. Intermission respawns occur at its start, giving preparation time before the next active wave. Losing a selected spawn objective invalidates that choice; fall back to a valid defender team spawn. A player who dies during the 10 s break (fall, lava) becomes a ghost and respawns when the next round starts (S41); deaths during the break never count toward a team wipe. No mid-wave respawn in the first release; a future revive mechanic would be an explicit, separately designed exception.

**Players, leave and disconnect (confirmed 2026-11-02, S37).** Minimum players is 1, so a single player can start and play a match. No late join. A disconnect is treated as leaving: the player leaves the match for good (Siege's rejoin window does not apply to survival), their ordinary state is restored (on their next login if they are offline) and they forfeit rewards as in Siege. The match ends as soon as no players are left (end reason: no players left; nothing to settle). Do not let the empty NPC player roster trigger an instant forfeit. Leavers are no longer players: the team wipe checks the players still in the match, so if the last living player leaves during a wave while ghosts remain, every remaining player is dead and the match ends as a team wipe.

### 3a. End conditions (confirmed 2026-11-02, S17–S19)

A team wipe (every defender dead in the same active wave) always ends the game. The scenario adds two independent, configurable end conditions, both off by default (S26):

| Condition | Configuration | Effect when enabled |
|---|---|---|
| Game-ending objective captured | Per objective: the game-ending flag (Siege's `InstantVictory`; any number of objectives). Per scenario: "objective captures end the game", overridable per survival lobby. | NPCs capturing any flagged objective end the game immediately. |
| All objectives captured | Per scenario: "end when all objectives are captured" (default off), overridable per survival lobby. | The game ends when NPCs hold every objective of the scenario at the same time. |

Both, either or neither can be enabled. With both off only a team wipe ends the game. When objective captures are disabled, a flagged objective behaves like any other objective on capture (ownership transfer, open-on-capture, spawnzone unlocks) and the game continues.

**Lobby override.** The survival lobby holds `Inherit` / on / off for "objective captures end the game", resolved per match the way Siege resolves the navigation compass ([navigation-compass design](../navigation-compass/DESIGN.md), C9): the most specific level wins, lobby → scenario, and `Inherit` defers to the scenario. Survival only; ordinary Siege lobbies get no such setting. *(Updated 2026-11-02, S26:)* the lobby holds the same `Inherit` / on / off override for "all objectives captured".

Defaults (confirmed 2026-11-02, S26): every objective's game-ending flag OFF, "all objectives captured" OFF, both lobby overrides `Inherit`, so a new scenario is wipe-only until an admin flags an objective or enables all-captured. The scenario-level "objective captures end the game" switch (S18) stays, default ON, so flagging an objective is enough to make it end the game; turning the switch off (or the lobby override) disables every flag at once.

**First condition wins (S26).** The match ends on the first enabled condition met, evaluated after each state change. If one tick meets several at once (for example the last flagged objective is also the last objective, or the last defender dies on the tick of a capture), the match ends once and records a single reason with the precedence game-ending objective → all objectives captured → team wipe (proposed precedence; it only affects the recorded reason while rewards are out of v1). Readiness warns, without failing, when no end condition other than a team wipe is reachable (no flagged objective, or objective endings off, and all-captured off) so an admin sees that the game is wipe-only. With recapture enabled, "all objectives captured" checks ownership at the moment of each capture.

Record a distinct end reason per condition (team wipe, game-ending objective captured, all objectives captured) plus the technical aborts. These are conceptual reasons, not the current `SiegeMatch.EndReason` values.

### 3b. Dead players: ghost state (confirmed 2026-11-02, S20)

A defender killed during a wave does not respawn until the next intermission; until then they are a ghost:

- **Not vanilla spectator mode.** No flight, no passing through blocks, so hidden passages and easter eggs stay hidden. The ghost walks like a normal player (proposed: confined to the scenario area, returned to a team spawn if they leave it).
- **Invulnerable**: no damage from any source and no hunger loss.
- **Ignored by all NPCs**: ghosts fail hard target eligibility (§4) before any scoring, so no NPC selects, chases or keeps commitment to them; becoming a ghost invalidates every current NPC target on that player immediately.
- **No participation**: no block breaking/placing or block/entity interaction, no attacking, no item pickup or drop, no containers, no capturezone contribution, no repair work, no purchases, Mystery Box rolls or currency transfers, and no use of items or abilities. Chat and team communication remain.
- **Visibility**: teammates see ghosts translucent; NPCs and anyone else don't see them at all. Ghosts have no collision with players or NPCs. Implementation to verify on Paper: invisibility combined with the team's see-friendly-invisibles option, and hiding the player from non-members.

At the intermission respawn the ghost state ends and the player respawns under the equipment mode's rules (§8). The ghost state also ends when the game ends (restore). A team wipe means all defenders are ghosts (or gone) during an active wave. Mid-wave revive mechanics may be added later; they must clear the ghost state through the same path as the intermission respawn.

### 3c. Round end and stuck-enemy handling (S27 confirmed; S28 under review)

A round ends when the planned spawn queue is exhausted and no enemy of that round is alive. The next round starts after a 10 s delay (the intermission; configurable per scenario, default 10 s). The system knows when the last planned enemy of a round has spawned (queue exhausted); that moment is the reference point for the round-level backstop below.

**Status (2026-11-02):** the developer is unsure about a fixed round timer (S28's 1 + 1 minute, or 5 minutes after the last spawn) and asked how other games handle it. The proposal below replaces the fixed timer and needs confirmation (§13 item 12).

**How Call of Duty Zombies handles it (from general knowledge of the Treyarch games, not verified against a source):** there is no round timer. A zombie that is far from every player and out of their sight for some seconds is silently removed and respawned at an active spawner closer to the players, as the same zombie, so the round count is unaffected. When only the last one or two zombies remain they run straight at the players. Minecraft wave plugins often also make the last enemies glow after a while so players can find them.

**Proposed v1 behavior (to confirm):**

1. **Per-enemy stuck check.** An enemy counts as stuck when for N seconds it has made no progress: no damage dealt or taken and no meaningful reduction of its distance to its current target, or navigation reports it blocked. A stuck enemy is removed and respawned as the same planned enemy at an eligible spawnpoint of an active spawnzone, preferring zones nearest the players, keeping its round stats. Not a kill, not counted twice. Proposed N: 30 s, configurable.
2. **Last enemies.** When at most K enemies of the round remain and the queue is exhausted (proposed K = 3), they get the glowing effect so players can find them, and they target the nearest player directly.
3. **Respawn limit.** An enemy respawned R times (proposed R = 2) and stuck again is killed by the system.
4. **Round backstop.** If the round is still not finished T minutes after its last planned enemy spawned (developer suggestion: 5 minutes), the remaining enemies are killed by the system. Configurable; off is allowed.

System kills count as dead for round completion but not as kills: no rewards, no match currency, no statistics. Enemies respawned by these rules count toward the max-alive limit like any other. Log every stuck respawn, glow and system kill with the enemy, its last position and target, as stuck-enemy telemetry. Earlier S28 (respawn all after 1 minute, kill 1 minute later) stays recorded as the developer's first suggestion and is an alternative to this proposal.

## 4. Objectives, gates and NPC targeting

Reuse a SiegeObjective referencing a scenario-selected GateStructure. Game-ending objectives are marked with the per-objective flag (reuse `InstantVictory`; zero, one or several per scenario, §3a). The objective's capture points/holder and each GateDoor's health/destroyed/open state are independent.

| Objective/door state | Required behavior |
|---|---|
| Defender-held; intact closed door | Real door blocks the route; NPCs may damage it. |
| Defender-held; capturezone reachable through a valid route | NPCs normally advance to capture the objective, engaging nearby defenders as appropriate. |
| Defender-held; route blocked by a selected breakable door | NPCs attack that door, then reroute through the breach. |
| Defender-held; destroyed door | Opening is traversable, objective remains held, repair allowed, deeper spawnzones remain inactive. |
| NPC-held objective (no ending applies) | Transfer ownership and use open-on-capture behavior; no defender repairs. Activate its configured next spawnzones. |
| NPC-held game-ending objective, objective endings enabled | End the match immediately (§3a). |
| NPC-held last objective, all-captured ending enabled | End the match immediately (§3a). |

A destroyed door has no remaining damageable body during repair. An intact closed door MUST be damageable by enemies; an ambiguous voice-transcript sentence about a closed door being invulnerable cannot override the repeated break-through design. Do not grant general invulnerability to closed gates.

Default NPC route logic: choose an eligible defender objective under the scenario rules; if its capturezone is physically reachable without breaching, move there; otherwise select a blocking breakable gate on a valid candidate route. After gate destruction, repair closure or objective capture, reassess the route. Route eligibility must include planned breach actions: a blocked-but-breakable gate does not make the entire spawnzone unusable. Avoid arbitrary straight-line nearest-objective selection through walls or forbidden areas.

Players within an aggro radius can temporarily divert enemies. Configure aggro range, leash distance and return behavior so a player cannot stall a wave by dragging its NPCs indefinitely outside the battle. A proposed difficulty option forces gate-first attacks even when an alternative capture route exists. Shared utility scoring, switch margin and minimum commitment are confirmed below; numerical preferences, capture weight per NPC/archetype and chase parameters still need balance tests, not invented constants.

NPC presence must participate in the objective capture calculation as the attacker team; the current player-only roster scan is insufficient. Reuse configurable capture/contest feedback rather than equating zone capture with gate health damage. Document whether existing side-capture reduction is enabled for this scenario; proposed default is off until explicitly balanced for survival.

### Fourth target type: distractor (confirmed 2026-10-30)

Siege NPC target types are players, gates, objectives and **distractors**. The confirmed distractor action is to approach a reachable position near the distractor and then stand there to occupy the NPC. Do not attack or damage the distractor. It is a temporary target with a position, validity/lifetime and attractiveness used by target selection.

The physical representation is deliberately undecided: dropped item, entity or block are alternatives, not a requirement to implement all three. A representation adapter supplies the logical target and invalidates it when its backing object disappears or its lifetime expires. The shared behavior must not depend on a particular Minecraft representation.

Apply hard eligibility/match isolation before utility scoring. The distractor participates in the existing preference/proximity comparison, switch margin and minimum commitment; it does not automatically force aggro or bypass those rules. At arrival, remain near it while it is valid and remains the selected target. Once commitment expires, a sufficiently higher-scoring eligible target may replace it under the usual policy; lifetime is not an unconditional forced hold.

Disappearance/expiry invalidates the target immediately, including during commitment, and triggers target reevaluation. Navigation failure uses the existing bounded recovery and failure-to-behavior contract. Standing near a distractor does not damage it or count as capturing an objective.

Still open under #146: item/entity/block choice and adapter, creation/activation/ownership and removal mechanics, lifetime and attraction values, detection/arrival range, crowd placement and behavior if the distractor itself moves. No guaranteed lure, explosion, damage, purchase/consumption mechanic or numeric default is implied.

Acceptance: an eligible distractor can win scoring; NPC approaches and stands without attacking it; a lower-scoring distractor does not force a switch; commitment and switch margin remain effective; expiry/removal releases even a committed NPC; a distractor in another match is excluded; an unreachable distractor reports navigation failure rather than granting a teleport or bypass.

### Objective and gate eligibility overrides (confirmed 2026-10-30)

Admins can configure an independent three-state NPC targeting override for each objective and each gate in the Siege scenario: **follow standard rules**, **explicitly allow**, or **explicitly deny**. These are conceptual values, not implemented enum/API names. This is separate from spawnzone unlock conditions and from lane overrides.

Evaluate the override before utility scoring. A denied objective cannot be selected for capture. A denied gate cannot be selected for damage/breaching, including as an intermediate action on a route to an otherwise allowed objective. Navigation must not present that forbidden breach as an executable route; seek a permitted alternative or report failure for behavior to handle. Denying attack does not by itself forbid walking through a physically open, otherwise authorized passage.

Allow makes the action eligible under this scenario policy; it does not raise the target's utility score or bypass match isolation, physical reachability, the actor's capabilities, or independent authorization/safety constraints. Following standard rules adds no override. An allowed objective does not implicitly allow its blocking gate, and an allowed gate does not implicitly allow capture of its associated objective. Existing invalidation rules apply when a current action becomes forbidden.

Siege owns the override configuration and resolves it for the NPC/action/context. Shared target selection consumes an allowed/denied result with a reason, rather than embedding Siege settings. The same generic eligibility boundary can serve other NPC consumers. Exact persistence schema, gate-versus-door binding and runtime configuration-update mechanics remain implementation design questions; this decision does not add conditional unlock expressions or select new defaults.

The goal actions remain distinct: approach and attack a valid player; enter and remain in a reachable capturezone to contribute to objective capture; damage an eligible blocking gate where breaching is required. Destroying a gate is not objective capture. Target scoring, minimum commitment and switch margin govern ordinary choices; hard eligibility is never overridden by score or commitment.

Acceptance additions: verify all three override states independently for gates and objectives; denied targets never enter scoring; an allowed objective behind a denied gate uses an alternative permitted route or fails cleanly; allowing a gate does not allow a denied objective; explicit allow neither boosts utility nor bypasses match/access/collision constraints; forbidding gate damage alone does not close an open passage.

### Target preference and decision stability (confirmed 2026-10-30)

Use the [shared scoring and commitment policy](../npc-platform/DESIGN.md#5a-shared-target-scoring-and-commitment-confirmed-2026-10-30). After hard eligibility checks, compare player/gate/objective choices using configured preference and proximity contributions. A selected valid, unfinished action retains its target for a configurable minimum duration despite ordinary score fluctuations. After that duration, a challenger must exceed the current score by the configured switch margin; expiration alone does not force a change.

A gate-focused attacker can therefore commit to an eligible player without flipping back to the gate every moment the player moves. Continue replanning toward that same player. Hard pursuit limits, death, leaving the match, authorization loss or terminal navigation failure end commitment without waiting; completing/destroying a gate also releases the action. Siege supplies the eligible goals and scenario constraints; behavior owns target replacement, and navigation executes the current assignment.

NPC-profile and per-behavior commitment configuration are design requirements. Concrete values, score curves, absolute/relative switch margins and reevaluation intervals remain unset. Any existing gate-first difficulty proposal must be reconciled explicitly with this shared policy rather than silently bypassing it. Damage-response score bonuses remain a separate open design point.

## 5. Cooperative repair

Repair is free channelled work on a destroyed GateDoor associated with a defender-held objective. The interaction should feel like holding an action while staying near the repair point. Right-click and approximately twenty seconds were examples, not fixed protocol/UI or duration requirements. Verify a practical Paper interaction implementation; do not assume continuous held-right-click packets exist for arbitrary blocks.

Let H be the door's effective maximum health, P its accumulated repair work, r the configured repair-health-equivalent units/second/player for this difficulty, and n(t) the number of valid active repairers:

`P(t + dt) = min(H, P(t) + r * n(t) * dt)`

For constant n, remaining seconds are `(H - P) / (r * n)`. With zero contributors, progress stays put. Example only: H=1000 and r=50 requires 20 seconds with one player, 10 with two. These numbers are illustrative, not tuning defaults.

Actual door health remains destroyed throughout the channel. At P=H, recheck ownership and match state, consume the completion exactly once, restore full health and request closure through the existing gate animation API. Show work progress separately from the gate health indicator. A completed repair is not a gradual heal; do not physically rebuild one block per progress increment.

Each player contributes only while alive, a member of this match, within the interaction range and actively repairing that door. Taking damage alone does NOT cancel. Leaving range, releasing/cancelling the action, switching to combat, dying or leaving the match stops that player's contribution; other repairers continue and P is retained. Objective capture stops all associated repairs and invalidates remaining work. NPC pressure in the capturezone alone does not stop repairs.

The final voice phrase 'objective wordt geraakt' conflicts with the earlier explicit permission to repair under capturezone attack. Working interpretation: stop on ownership loss, not on capture pressure. This is recorded as an implementation clarification to confirm, rather than silently converting it into an attack-cancels rule.

No extra cooldown after completion. A subsequent destruction starts a new repair cycle at zero work. Scope work per door, not across unrelated doors. Partial-health maintenance of intact doors was not specified; proposed v1 is destroyed-door repair only. If added later, define required work from missing health separately.

Reuse existing obstruction/collision handling; do not introduce a separate 'zone must be empty' repair restriction. Test both the initial reconstruction of a destroyed door and subsequent animation: calling a respawn API that immediately places closed blocks may bypass animation collision handling. A jammed closure must report its actual state; completed work does not imply physically CLOSED while obstructed. Once reconstructed, normal enemy damage applies; do not reapply full health on every animation tick or retry.

## 6. Spawnzones, automatic navigation and optional lanes — Defend the Castle

Author multiple NPC spawnzones within the scenario, each containing valid spawnpoints or a bounded spawn area, wave/profile eligibility and an objective-ownership activation condition. A lane assignment is optional. Admins must be able to configure an initial outside-castle spawn and later objective-unlocked spawnzones without drawing routes.

**Confirmed developer correction, 2026-10-30 (#146):** NPCs use automatic navigation by default, combining suitable existing road infrastructure with local A* / walkable pathfinding, including off-road routes. An admin may supply an ordered lane override when automatic routing does not yield the intended route. Override support belongs to the shared NPC navigation capability and is reusable outside this mode; Siege supplies configuration, eligible targets and match rules. Local pathfinding connects override points while preserving access and collision constraints. See [shared navigation contract](../npc-platform/DESIGN.md#automatic-navigation-and-optional-lane-overrides-confirmed-2026-10-30).

**Caller contract (2026-10-30):** the Survival game manager supplies configured spawn requests to lifecycle, and eligible goals, movement rules and optional lane configuration to the NPC assignment/behavior. Behavior chooses the active goal; shared navigation plans from the actor's current position under the effective ruleset. Rules such as ladder use and door opening are configurable, with the complete catalogue/defaults still to be finalized. This is a consumer of the [shared navigation ruleset](../npc-platform/DESIGN.md#caller-supplied-navigation-ruleset-confirmed-2026-10-30), not a Siege-only navigation implementation. Rules cannot bypass access, physical capabilities or collision.

For the initial gate-only slice, a spawned NPC immediately starts target selection and route planning, then moves when a usable path is available, without an intentional waiting period. It approaches a reachable attack position at an eligible gate. The shared preference/proximity scoring and commitment model applies; numerical ranking and tuning remain open. This focused slice does not remove the full mode's player/objective behavior requirements.

**Spawn conditions and "overrun" (confirmed 2026-11-02, S22).** Admins configure a spawn condition on each spawnzone (its spawnpoints inherit it): always active from the start, or active once the listed objectives are NPC-held. Example: a walled town with two entrances, each blocked by a gate structure that doubles as an objective. Spawnzones authored just inside each gate activate only when that gate's objective falls, so NPCs then also appear inside the walls and overrun the town.

Example progression: outside-castle zone initially active → NPCs breach outer gate → NPCs capture outer objective → courtyard zone becomes eligible → next defensive line. **Breach alone does not activate courtyard spawns.** An intact but open door likewise does not advance the spawn frontier.

Activation is ownership-driven. Define objective prerequisites with an explicit ALL/ANY policy when multiple objectives control a zone, validate their references and ensure at least one initial usable spawnzone. New eligible zones affect future queued spawn selections, not already spawned enemies. Never teleport or erase live enemies merely because a zone's eligibility changes.

The aim is for new NPCs to appear near the current fighting area. Proposed zone selection favors the active frontier and can retire earlier zones from future spawning; weighting and whether older zones remain enabled are scenario settings to confirm. Visibility/distance preferences must not accidentally permit spawns inside a closed defender-held line.

Recapture is optional and off by default. Proposed when enabled: reevaluate zone prerequisites against current ownership, stop future spawns in zones that become ineligible, preserve existing NPCs and move the spawn frontier outward. Confirm this policy before enabling recapture scenarios.

Physical NPC navigation is distinct from player `/navigate` visual guidance. Road routing and walkable path search do not by themselves prove entity traversal, crowd handling or gate breach behavior. Compare reusable KnK pathfinding and candidate movers on the castle map, covering both automatic routing without lanes and optional overrides. KNG-36 defines the shared platform boundaries; #146 owns the follow-up design. No Citizens or behavior-tree library is selected by this decision.

Validation must include a complete scenario with no authored lanes, a configured override followed in order, an invalid override reported without bypassing collision/access, and route reassessment after gate destruction or repair. The shared failure policy first makes bounded retries toward the next required routepoint, then reports blockage with a reason to behavior. Automatic alternative routing is off by default and opt-in per override; when enabled, navigation may try an automatic route to the assignment destination after those retries. Access and physical constraints still apply, and failure is reported if no alternative succeeds. Siege behavior owns any subsequent target change, wait or stop decision. Exact retry budgets and override precedence remain open in #146. Objective-driven spawn unlocks and wave accounting remain unchanged.

## 7. Wave scaling and special rounds

Per difficulty, configure enemy count/composition growth, health, walking speed, melee damage, ranged damage, attack speed, gate damage, capture contribution, spawn pacing, spawnzone distribution and repair rate. Snapshot config at match start.

**Default progression (confirmed 2026-11-02, S21; presets S29–S30).** Higher waves are progressively harder by default: each wave raises the enemy count and the NPC base stats health, walking speed, melee damage, ranged damage and attack speed. Include server limits for live NPCs and spawning/pathfinding work; a large late-wave population queues rather than spawning every enemy simultaneously.

**Presets (S29).** Count and stats each select one preset, independently. With round r (starting at 1), round-1 value b, per-round step a, multiplier m and hybrid switch round s:

| Preset | Value in round r | Shape |
|---|---|---|
| Linear | `b + a·(r−1)` | Constant growth per round |
| Logarithmic | `b + a·ln(r)` | Fast early, flattening later |
| Exponential | `b · m^(r−1)` | Slow early, accelerating |
| Hybrid | `b + a·(r−1)` for `r ≤ s`; then `(b + a·(s−1)) · m^(r−s)` | Linear until the switch round, then exponential |

Hybrid follows CoD Zombies health: +100 per round up to round 9, then ×1.1 per round (`a = 100`, `s = 9`, `m = 1.1`; an example of the shape, not a default). For stats, the preset produces a **multiplier** on the mob type's round-1 value (`b = 1`), applied to health, walking speed, melee damage, ranged damage and attack speed alike (proposed; per-stat parameters stay possible later). For count, b is the configured round-1 enemy count.

**Settings (per scenario/difficulty, S29):** count preset and its parameters; stat preset and its parameters; hybrid switch round; per-player scaling of the count, and optionally of the stats (proposed: `× (1 + p·(players − 1))` with players counted at round start, ghosts included, and p per-player factor); max enemies alive at once (the rest of the round's queue spawns as others die); stat cap (maximum stat multiplier, plus Minecraft hard limits per stat such as movement speeds that break pathfinding); count cap (maximum enemies per round). Round values are rounded down for counts and never below 1.

**Enemy types (S42).** v1 enemies are vanilla Minecraft monsters. The admin selects which monster types a scenario uses (for example zombie, skeleton, spider, creeper), each with an optional weight; a round's enemies are drawn from the selected types by weight (proposed: equal weights by default; per-type unlock round optional later). Readiness checks that at least one hostile type is selected. Behavior comes from the vanilla mob plus custom targeting/goal hooks (Paper's mob goal API) for objectives, gates and ghost exclusion, so KNG-36's NPC platform is not a v1 dependency for the body.

**Round 1 = vanilla (S30).** Round 1 enemies use the vanilla Minecraft attribute values of their mob type; the stat multiplier is 1 there. All parameters, caps and per-player factors come from balance tests; no tuning values are fixed by this design. Admins can preview the resulting count and stat multiplier per round in the editor (§11).

Implementation to verify: vanilla mobs have no attack-speed attribute that governs their melee cooldown, and ranged damage is set on the projectile (for example arrow damage on skeletons) rather than through an attribute, so attack speed and ranged damage scaling need a custom hook on the NPC side.

Special profiles can replace a normal wave at an interval (for example every fifth wave) AND at explicit wave numbers. A wolf-only round is an example, not a required specific mob. Profiles can specify different archetypes, amounts and scaling. Configuration supports both scheduling methods together, not only an exclusive choice.

Proposed deterministic collision rule: explicit wave-number entry overrides recurring entries; conflicting recurring entries require unique priority or fail readiness. A special profile replaces the normal composition by default; additive boss events require a separate explicit setting. The global wave index still advances. No unrequested special-wave reward or ammo drop is implied.

## 8. Equipment modes, purchases and death

| Rule | OWN_INVENTORY | KITS (2026-11-02, S23) | MATCH_PROGRESSION (Zombies-style) |
|---|---|---|---|
| Entry | Use existing personal gear; snapshot/restore. | Snapshot ordinary state at the hub, clear the inventory, player picks one of the scenario's kits; grant it. | Snapshot ordinary state, replace with configured baseline gear or empty inventory. |
| Death | Inventory kept, nothing dropped (S40; Siege safeguards); become a ghost until the next respawn. | Inventory kept, nothing dropped (S40); become a ghost. | Inventory kept, nothing dropped (S40); become a ghost. |
| Respawn | Respawn with the kept inventory. | Respawn with the kept inventory; the kit is not granted again (no switching, S36). | Respawn with the kept inventory; retain personal match balance. |
| Ground pickup | Existing Siege rules/exceptions. | Existing Siege rules/exceptions. | Existing Siege rules/exceptions (no death drops). |
| Exit/end/crash recovery | Restore ordinary snapshot. | Remove kit items and restore ordinary snapshot. | Remove temporary gear and restore ordinary snapshot. |

All three modes ship together and are selected per scenario. In every mode, anything gained during the game (Mystery Box items, pickups, kit items) is wiped by the snapshot restore at the end, as in Siege (Siege D2).

**Kits mode.** Admins select one or more existing Kit instances ([kits design](../kits/DESIGN.md)) for the scenario. Each player picks one at the hub (proposed: in the same menu flow as the spawn picker; a player who doesn't pick gets the scenario's **default kit**, which the admin selects from the scenario's kits, S38). The grant reuses the kits grant pipeline (`BlueprintItemAssembler.assembleDefaults` and the grant-placement algorithm) but skips everything else of an ordinary claim: no permission/title-bracket/premium-tier condition, no cooldown, no `CostAmount` and no premium gems purchase, and no `KitClaim` or `KitPurchase` row. Kit items are tagged with the match id and never leave the match. Players cannot switch kits between rounds (S36): the kit picked at the hub is re-granted at every respawn for the rest of the match.

**Match currency in every mode (proposed reading of S33/S34).** Every player has an individual temporary balance in all three modes, because kills pay match currency and the Mystery Box costs match currency; fixed purchase points remain a MATCH_PROGRESSION feature (confirm, §13 item 9). Match currency exists only inside a match: it starts at 0, is never stored on the user and is gone when the match ends. Each player's balance starts at 0; earnings are immediately spendable. Transfer a chosen positive amount to a teammate in the same live match: debit sender and credit recipient atomically, reject overdrafts and cross-match recipients, and identify retries so they cannot pay twice. Match currency is separate from User.Coins/User.Gems and cannot be converted or taken home.

Provide fixed equipment purchase points and Mystery Box points with configured locations, interaction range, prices, item pools/blueprint references and eligibility. Earn currency per NPC kill: 70 by default, ×1.1 for a headshot or critical-hit kill (S33; both configurable per scenario). The killing blow decides who earns it; no assist share in v1. Kills by the stuck-enemy fallback (§3c), environment or other NPCs pay nothing. Other earnings (wave events, repairs) are not in v1. Proposed v1 purchase availability: allow both active waves and intermission. Ghosts cannot buy, transfer or receive-and-use anything (S20; resolves the earlier dead-player transfer question).

### 8a. Mystery Box: items and enchanted books (updated 2026-11-02, S24)

The Mystery Box ships in two variants, each placed as its own point in the scenario:

| Variant | Pool entries | Result |
|---|---|---|
| Items | Item blueprints, each with a percentage drop chance; optional enchantments per entry with their own chances | The assembled item (display name, enchantments) |
| Enchanted books | Enchantments (and level), each with a percentage drop chance | An enchanted book with the rolled enchantment |

The enchanted-book box is a variation of the same Mystery Box, not a separate system: same point type, roll path, animation and claim rules, with a different pool kind. Readiness validates that each pool's chances are valid (proposed: they sum to 100%) and that every blueprint/enchantment reference exists. Roll authoritatively with the existing lootbox roll components (`LootboxRollEngine` odds logic, `BlueprintItemAssembler.assemble`) adapted to percentage chances, and record one roll and at most one delivery per roll id. Do not call ordinary world-lootbox redemption, mint persistent player-owned item instances, consume world daily quotas or leak tokens into the restored inventory.

**In-world animation (replaces the chest-menu reel).** The box is a block in the world (default: an **end portal frame**, the block an eye of ender goes into, S35; the block type is configurable per box point). A roll plays a carousel draw on top of it, modeled on the lootbox opening reel (§3.9 of the [lootbox design](../lootboxes/DESIGN.md)): a non-pickable item entity above the block is replaced rapidly by passing items from the pool, each showing its display name and enchantment glint, slowing down until it stops on the rolled item. Ticking sounds and particle effects accompany the draw, with a distinct sound and particles for the final item. As in the lootbox reel, the result is rolled before the animation starts, passing items are drawn with the real odds and there are no fake near misses. No player can pick the displayed items up, and hoppers or mobs can't take them.

**Claim.** Only the player who started the roll can claim the final item, by right-clicking it (S39); teammates can't take it. It then goes into the roller's inventory, or drops as a match-scoped item owned by the roller if the inventory is full. Unclaimed, it despawns after 10 seconds (configurable) and is forfeited. Only after the claim or despawn can the box start a new roll; one roll at a time per box. Implementation to verify: a plain dropped item entity does not receive right-click interactions on Paper, so the claim likely needs an `Interaction` entity hitbox (or an `ItemDisplay` with one) over the shown item.

**Cost (S34).** A roll costs **1000 match currency** by default (configurable per box point), in every equipment mode, charged once per roll id before the roll. A player with less than the price cannot start a roll; the box shows the price.

**Interruptions.** Proposed: if the roller dies (becomes a ghost), leaves or the game ends during the animation or before claiming, the roll is forfeited and the shown item removed, without rerolling or duplicating; a charged price is not refunded. Plugin restart aborts the match (§3) and removes the box entities. KNG-44's pending-delivery follow-up does not apply to this in-world claim.

### 8b. Match item tracking and drop guards

Tag and track every match equipment item, kit item, Mystery Box item, ground drop and pending grant by match id. Only members of that match can pick it up; deny outsiders, containers, hoppers and cross-match transfers. There are no death drops (S40); the only match ground items are Mystery Box overflow drops and items players drop on purpose, removed with the match. On finish/abort remove all remaining items and pending deliveries.

The current Siege keepInventory and no-drop guards apply unchanged in every survival mode (S40); no exception is needed. Ordinary persisted item-instance identity/ownership needs special care: transient Mystery Box rewards should reuse the roll result without creating claimable permanent instances unless a reviewed match-scoped lifecycle supports them.

## 9. Permanent rewards and balance calibration

**v1 default: per-kill rewards (S32, 2026-11-02; supersedes S31).** v1 pays permanent coins and experience per NPC kill, nothing else (no gems, no wave base, no repair or objective contribution):

| Kill | Coins | Experience |
|---|---|---|
| Normal kill | Siege `CoinRewardCapture` ÷ 10 | Siege `ExpRewardCapture` ÷ 10 |
| Headshot or critical-hit kill | ×1.1 | ×1.1 |
| Dev seed ("Cinix under Attack!", 300 / 30) | 30 (33) | 3 (3.3) |

Store the per-kill coins, per-kill experience and the multiplier as survival settings, defaulting to the scenario's own `CoinRewardCapture`/`ExpRewardCapture` ÷ 10 and 1.1. A headshot is a projectile kill whose hit lands on the target's head; a critical-hit kill is a killing blow Minecraft marks as critical (verify the Paper API, e.g. `EntityDamageByEntityEvent#isCritical`, and the head-hit test for projectiles). A kill that is both counts ×1.1 once. Accumulate exact values (tenths) per player and round down once at settlement, so 3.3 XP per kill is not lost to per-kill rounding. Only the killing blow counts; fallback system kills pay nothing.

Settle once at match end through the existing ledger and idempotency (below) for every player still in the match, ghosts included. Leavers forfeit, as in Siege. Show the total on the result screen next to (not mixed with) the final match-currency balance. The rest of this section is the later full reward design.

Permanent coins, gems and experience are different from spendable match currency. Accumulate reward inputs during play; grant permanent rewards once when the match ends normally (team wipe or an enabled end condition, §3a). A loss is the expected terminal outcome of endless survival and must not automatically mean zero rewards.

Reward design: a configurable base per completed wave, scaling for later waves, plus measured contributions such as kills/assists, successful repair work and objective defense. Store raw inputs and the reward-policy version, and calculate authoritatively on the API. Values, curves, contribution weights and ceilings remain UNSET pending developer targets. A 'troostprijs' or hard per-match cap was only proposed in conversation, not a locked reward decision.

Calibration inputs supplied by Pandi: desired hours to representative levels and purchases, typical match duration/waves, minigame share of overall progression, other income sources, and expected average/high-performing hourly yield. An agent may then simulate candidate reward curves across scenarios and difficulties for review. Include salary/rank multipliers and title-promotion bonuses when measuring effective progression; do not add a second multiplier or award wave income twice.

Reuse the current ledger and Siege settlement's idempotency; separate survival formula selection from the PvP win/holding/capture calculator. Ghosts (dead players) still present at end qualify. Proposed leave/disconnect and abort policy inherits current Siege (no permanent reward on voluntary leave, admin abort or server restart); confirm desired accrued-reward recovery before changing it. No additional persistent payout per wave.

Persist an accrued result or pending settlement before attempting the API payout. Completion retries return the same stored breakdown; inventory/gate cleanup must not duplicate rewards or hang indefinitely behind an unavailable API. Display reached/completed wave, contributions, end reason and the permanent payout, separately from final temporary match balance.

## 10. Proposed configuration and runtime boundaries

These are required conceptual records, not approved class names or database migrations:

| Record/configuration | Required fields/relationships |
|---|---|
| Survival scenario settings | SiegeScenario reference, mode, human/NPC team references, per-objective game-ending flag, "objective captures end the game" and "end when all objectives are captured" settings, equipment mode (own inventory / kits / match progression), selected kits and default kit, selected vanilla monster types with weights, difficulty profile, intermission timing, recapture policy, baseline loadout, reward-policy revision. |
| Survival lobby override | Lobby reference; "objective captures end the game" and "end when all objectives are captured", each `Inherit` / on / off (navigation-compass precedent: lobby → scenario). |
| Difficulty/wave profile | Count preset and parameters, stat preset and parameters (applied to health, walking speed, melee damage, ranged damage, attack speed), hybrid switch round, per-player scaling (count, optional stats), max alive at once, stat cap, count cap; round-end delay (default 10 s) and stuck-handling settings (§3c: stuck time, last-enemy count, respawn limit, round backstop); other scaling rules, archetype composition, pacing, spawnzone weights, capture/gate damage, aggro/leash values, target preference/proximity settings, switch margin and minimum commitment duration, repair work rate, resource limits. |
| Spawnzone | Scenario, location bounds/points, optional lane override, spawn condition (initially active, or objective prerequisite ALL/ANY), eligibility/weight. |
| Objective/gate target override | Independent per-scenario target setting: standard rules / allow / deny; resolved before scoring and applied to intermediate gate breaching. Allow never grants physical or cross-match access. |
| Optional lane override | Shared navigation configuration with ordered routepoints, referenced by an NPC or movement assignment; optional scenario bindings. No mandatory route per spawnzone. |
| Special-wave schedule | Explicit wave numbers and/or interval/start offset, profile reference, deterministic priority. |
| Purchase point | Scenario, location, price, product references and interaction limits. |
| Mystery Box point | Scenario, block location, variant (items / enchanted books), pool with percentage chances, optional price, claim timeout (default 10 s), interaction limits. |
| Runtime/checkpoint | Match/config ids, resolved end conditions, reached/completed wave, ghost state per player, kit choice, active Mystery Box rolls, pending/alive NPC accounting, owners, repair work, personal match balances and transaction ids, item/drop/delivery tracking, contributions and pending settlement. |

Plugin owns live simulation and main-thread world mutations; API owns configuration, durable match results and permanent ledger grants. Pure wave/repair/scheduling logic belongs in Bukkit-free core. NPC platform provides combat, actor identity and path requests. Server validates all purchases/transfers/capture/repair membership; no client-supplied wave number or payout is trusted. Changes made in the editor apply to future matches, not the running snapshot.

Readiness validates human/NPC role identity, end conditions (warning when only a team wipe can end the game), selected kits in kits mode, valid Mystery Box pools, compatible selected gates and capture locations, valid baseline gear/pools, an initial spawnzone, optional override routepoints when configured, nonzero scaling/repair parameters, valid special-wave schedule and dependency references. NPC teams do not need fake user rows or ordinary player spawn requirements. Use existing FormConfiguration/DisplayConfiguration and configured location-validation rules; avoid hard-coded assumptions that all enemy spawns must be inside the town.

## 11. Player/admin experience and observability

Player HUD: wave number/type, enemies remaining plus queued spawns, pause countdown, objective ownership/pressure and which objectives end the game, gate state/health, repair work/contributors, own temporary balance and ghost/next-respawn status. Equipment purchases, the kit picker, Mystery Box odds/pool description and teammate transfers use the existing inventory-menu conventions; the Mystery Box roll itself plays in the world (§8a). Result screen distinguishes match currency from permanent coins/gems/XP.

Admin authoring: select survival mode, difficulty, equipment mode, kits and end conditions; reference gates/objectives; capture NPC zones/spawnpoints, optional override waypoints and purchase locations in-game through existing location tools; preview wave schedules/compositions/repair duration; run readiness. Defend the Castle is the first representative scenario. Label future authoring controls as planned until implemented; the existing Siege guide describes current PvP tooling only.

Record wave start/end, enemy spawn/death/removal reasons, target/path failures, objective capture, door destruction/repair, active repair contribution, currency earning/spend/transfer and box roll/claim/forfeit, player death/ghost/respawn/leave, end condition and reason, cleanup and settlement retries. Aggregate per match/wave/player for balance and debugging; integrate with the shared player-telemetry design when available. Do not invent a full replay recorder as part of this feature. Track tick time, live NPC/item counts, spawn backlog, path work and stuck enemies.

## 12. Current-source checks and integration risks (2026-09-30)

Read-only checks used current workspace main `98372da0a54de6384334290208d70816288f22eb` and plugin main `27b4236a9e3578fe78ea7c32d0526cffa6257250`. API files were fetched from current default `master`; recheck exact defaults before coding. This is a targeted integration review, not a full code audit or live test.

- `knk-plugin/knk-paper/.../gates/GateAnimationTask.java` iterates general Bukkit Entity objects, excluding dead entities and Display objects, calls `CollisionPredictor`, then `EntityEvacuator`/`EntityPusher`. `CollisionPredictor.java` checks entity bounding boxes. Thus the animation path is not player-only; mob NPCs fall within its general entity treatment. `EntityEvacuator.java` uses a standing-spot check with feet/head clearance, so large/nonstandard NPC bodies and the initial respawn/rebuild still require live verification. Reuse it first; no parallel repair safeguard by default.
- `knk-paper/.../siege/SiegeGateController.java` has player-based gate damage attribution and sets `CanRespawnOverride=false`; restore can call `healthSystem.respawnGate`. Survival needs explicit authorized NPC gate damage and a deliberate repair path without enabling unrelated automatic gate respawns.
- Existing Siege design sections 6.6/9.3 retain inventory on death and prohibit drops/pickup. *(2026-11-03:)* survival keeps that behavior in every mode (S40), so no death-drop exception is needed; it still needs durable ordinary-inventory restore. Existing roster elimination/capture scans must understand NPC teams.
- `knk-web-api/Services/SiegeMatchService.cs` grants rewards server-side exactly once with the currency ledger (`SIEGE_REWARD`, key `siege-match:{id}`) and currently delegates to the PvP `SiegeRewardCalculator`. Add survival reward inputs/logic while preserving settlement idempotency and title progression.
- `Services/Lootbox/LootboxRollEngine.cs` supplies pure roll and odds logic (2026-11-02: the survival Mystery Box needs percentage chances per entry; check whether the engine's weights map onto them or a small adapter is needed). It currently supports the Grade table's full scale; older lootbox design sections still say 1–5 only. Do not copy stale grade limits or world-claim ownership/quota rules into the match adapter.
- KNG-27 navigation was recorded as unmerged on its feature branches; KNG-36 shared NPC platform and KNG-37 consumers are still backlog. Do not describe either as a shipped physical NPC navigation dependency.

## 13. Open implementation clarifications (not missing core gameplay decisions)

1. Confirm repair interruption is objective ownership loss, consistent with repairing under zone pressure; resolve the isolated 'objective hit' wording before implementing a different condition.
2. Verify destroyed-door reconstruction uses collision handling, including large NPCs; choose the repair interaction input after Paper testing.
3. Confirm destroyed-only repair and per-door health/work semantics for multi-door structures; define animation-time damage/jam transitions.
4. Confirm old-zone weighting and recapture zone deactivation; default recapture remains disabled meanwhile.
5. Validate automatic physical navigation without lanes and optional waypoint overrides, reachability including breach edges, chase leash and NPC capture weights with the castle map.
6. Confirm special-schedule collisions and whether side-capture reduction is disabled. (Late join: none; disconnect = leave; minimum 1 player, S37.) (Ghost purchase/transfer access is resolved: none, S20.)
7. *(After v1; v1 uses the per-kill default, S32.)* Supply progression targets and review resulting reward curves. Configure gameplay values with previews, not fixed invented defaults.
8. *(Resolved 2026-11-02, S26.)* End-condition defaults: flags off, all-captured off, lobby `Inherit`. Still to confirm: whether the scenario-level "objective captures end the game" switch (S18) should stay alongside the per-objective flags, and the same-tick reason precedence.
9. *(Mostly resolved, S36/S38.)* No kit switching; the admin selects a default kit. Still open: whether purchase points (besides the Mystery Box) and teammate transfers also exist in own-inventory and kits mode (proposed: transfers yes, purchase points no). Asked the developer 2026-11-02; the answer "match points don't exist outside a match" confirmed that match currency is match-only but did not settle this.
10. *(Mostly resolved, S34–S35/S39: 1000 match currency, end portal frame, roller-only claim.)* Still to confirm: forfeit without refund on death/leave; pool chances must sum to 100%.
11. *(2026-11-02)* Ghosts: confinement to the scenario area; how to hide them from non-members and NPCs while teammates see them translucent (verify on Paper).
12. *(Open, developer unsure.)* Stuck enemies: confirm the §3c proposal (per-enemy stuck respawn after 30 s, glow and direct pursuit for the last 3, kill after 2 respawns, round backstop 5 min after the last spawn) or keep S28's fixed 1 + 1 minute rule.
13. *(Resolved, S32–S33.)* v1 pays per-kill permanent rewards and 70 match currency per kill.
14. *(Resolved, S42.)* Enemy roster: admin-selected vanilla monster types with optional weights. Still open: per-type unlock rounds and special-wave compositions after v1.
15. *(Resolved, S41.)* Deaths during the break respawn when the next round starts and never count toward a wipe.
16. *(Resolved, S42.)* v1 enemies are vanilla mobs with custom goal hooks; KNG-36 is not a v1 body dependency.
17. *(Open, asked 2026-11-02.)* Confirm that S40 (inventories kept, nothing dropped on death) applies to MATCH_PROGRESSION too. If so, that mode differs from kits mode only by its baseline entry loadout and its purchase points.

## 14. Acceptance checklist

| ID | Required check |
|---|---|
| A01 | Endless waves advance only after all planned enemies spawn and die, then the next starts after 10 s; queued/stuck/despawned enemies cannot manufacture a wave clear; stuck handling (§3c, as confirmed) respawns or system-kills enemies without counting them as kills. |
| A02 | Final living defender death ends once; a flagged objective ends the game only with objective endings enabled (scenario setting, lobby override wins); all-captured ends only when enabled; unflagged captures never end; with both conditions off only a wipe ends; ghosts count for settlement. |
| A03 | Dead defenders return at intermission start with valid spawn choices, never during the active wave; a death during the break respawns when the next round starts. Until then they are ghosts: no damage or hunger, never targeted by NPCs, no interaction of any kind, no flight or noclip, translucent to teammates and hidden from everyone else. |
| A04 | NPCs break blocked doors and capture reachable zones; closed intact doors are damageable; door destruction never changes objective ownership. |
| A05 | Opening/destruction never enables deeper spawnzones; objective capture does; already spawned NPCs remain in place. |
| A06 | One/two repairers have additive rates; interruption retains work; taking damage and capturezone pressure do not cancel. Death/action-stop/range loss removes only that contributor. |
| A07 | Complete repair restores health once and closes through normal gate behavior; no gradual healing, materials or extra cooldown. Lost objective prevents repair. |
| A08 | Reconstruction/animation do not trap players or representative NPCs; jam state and routing remain truthful. |
| A09 | All three equipment modes work; inventories are kept and nothing drops on death in every mode; ordinary PvP/own-gear drop guards remain intact; a player who doesn't pick gets the default kit; kits mode grants the selected kit without its conditions, cooldown, price or claim records. |
| A10 | Minimum 1 player starts a match; a disconnect leaves and restores; the match ends when no players are left. Match balance pays immediately, survives respawn and transfers atomically only within the match; purchases cannot overdraft or duplicate on retries. |
| A11 | Both Mystery Box variants roll from their percentage pools with existing roll components; the in-world animation shows non-pickable items with name/enchantments, sounds and particles and stops on the pre-rolled item; only the roller claims by right-click; unclaimed items despawn after 10 s before the next roll; no persistent gear/token/instance leakage on death, exit or restart. |
| A12 | Recurring AND explicit special waves select deterministically and continue scaling. |
| A13 | Per-kill rewards: 30 coins/3 XP (dev seed) per kill, ×1.1 for headshot/crit, settled once at end, rounded down once; 70 match currency per kill (×1.1) credited immediately; Mystery Box rejects a roll under 1000. *(After v1:)* Permanent rewards accrue during play and settle once after normal loss; failed/repeated completion and promotion handling cannot duplicate funds or XP. |
| A14 | Gate/player snapshots restore on end/abort/restart; no match NPCs/items, overrides or pending grants leak into the shared world. |
| A15 | Admin configuration/readiness, player HUD/menus, result history, telemetry and representative late-wave load checks are documented and tested. |
| A16 | Enemies are drawn from the admin-selected vanilla monster types; round 1 enemies have vanilla stats; each preset (linear, logarithmic, exponential, hybrid with switch round) produces the documented count and stat values; per-player scaling, max alive, stat cap and count cap apply. |
| A17 | Spawnzones with an objective condition stay inactive until that objective falls, then spawn inside the line (overrun). |
| A18 | The snapshot taken when sent to the hub restores on end, leave and crash in every equipment mode; gained items are wiped. |
