# Siege Survival — Defend the Castle

**Status:** Gameplay design recorded from developer decisions; not implemented. Integration details marked proposed or to verify are not approved balance values.
**Last updated:** 2026-09-30
**Linear:** [KNG-50](https://linear.app/kngpandi/issue/KNG-50/siege-survival-endless-npc-waves-gate-repair-and-match-economy), child of [KNG-37](https://linear.app/kngpandi/issue/KNG-37/design-dungeon-waves-and-siege-pve-defense-mode)
**Dependencies:** [KNG-36 NPC platform](https://linear.app/kngpandi/issue/KNG-36/design-shared-npc-traits-and-pathfinding-platform); existing Siege, gate runtime, inventory menus, item blueprints, lootboxes and currency ledger.
**Authority:** The developer's 2026-09-30 conversation and corrections define this mode. Existing PvP Siege rules remain unchanged. This document is the canonical survival specification, not a claim that the proposed entities, endpoints or gameplay already exist.

Related: [Siege design](../siege-minigame/DESIGN.md), [Siege implementation status](../siege-minigame/IMPLEMENTATION_PLAN.md), [scenario authoring](../../guides/authoring-a-siege-scenario.md), [lootboxes](../lootboxes/DESIGN.md), [currency payments](../currency-payments/DESIGN.md), [gate runtime](../gate-structure-animation/INDEX.md), [implementation plan](IMPLEMENTATION_PLAN.md).

## 1. Goal and first-release scope

A cooperative, lane-based survival variant within Siege. One human defender team protects a town/castle against an NPC attacker team. Waves are discrete, endless and increasingly difficult, inspired by Call of Duty Zombies. Gate-linked objectives form successive defensive lines. Players aim for the highest number of completed waves; there is no final wave or ordinary victory condition.

The first release includes BOTH inventory modes, cooperative gate repairs, explicit NPC spawnzones and lane routepoints, special waves, personal transferable match currency, fixed equipment purchases AND a Mystery Box based on the existing lootbox functionality. Mystery Box is not deferred. Material costs, repair puzzles and extra repair cooldowns are excluded from this release.

Keep the existing lobby, scenario, team identity, gate/objective references, spawnpoint selection, match history and restoration infrastructure wherever their semantics fit. NPCs are match actors, not fake player accounts. Do not apply player-team population checks to the NPC team.

## 2. Decision register

| ID | Confirmed decision |
|---|---|
| S01 | Endless escalating waves; configurable pause between waves. No fixed last wave. |
| S02 | One player defender team and one NPC attacker team. NPCs target players and objectives. |
| S03 | Defeat on capture of the main objective OR all remaining defenders dying during a wave. Losing a side objective does not end the game. |
| S04 | Dead players spectate until the pause preceding the next wave; reuse available Siege spawnpoints/held-objective spawn choices. |
| S05 | Objective recapture is configurable, default off. Main-objective capture always ends the match. |
| S06 | Gates are closed defensive barriers while intact and defender-owned; NPCs capture reachable zones, otherwise damage the blocking door. Door destruction is separate from objective capture. Target preference may vary with difficulty. |
| S07 | Destroyed doors can be repaired while their objective remains defender-owned, including during waves and objective pressure. |
| S08 | Repair requires staying nearby and performing a channelled interaction. No material/currency cost. Taking damage does not stop a player's contribution; fighting back requires stopping repair. |
| S09 | Repair work persists when interrupted; each active player adds configurable health-equivalent work per second. Difficulty sets the rate. Health is restored in one step only at completion, followed by the normal closing animation. No additional cooldown. |
| S10 | NPC spawnzone progression depends ONLY on objective capture, never merely on an open or destroyed door. |
| S11 | Both own-inventory Siege behavior and a Zombies-style isolated match inventory are available per scenario from the first release. |
| S12 | Zombies players hold individual match balances and can give a chosen amount to a teammate. Mystery Box uses configurable content and match-currency price. |
| S13 | Zombies death drops equipment at the death location; teammates or the returning player can retrieve it. Respawn gives the basic loadout; the match balance is retained. Inventory rules are scenario settings, not individual player choices. |
| S14 | Special waves support both recurring intervals and explicit wave numbers, with their own enemy profiles. |
| S15 | Permanent coins, gems and experience accrue during the match and are granted once after its end. Match currency is credited immediately for purchases during play. |
| S16 | Permanent reward amounts await developer-supplied progression targets (hours to levels/purchases, expected games and earnings/hour). Do not invent a payout table. |

## 3. Match and wave lifecycle

Reuse Siege's outer matchmaking/vote/hub/match/cooldown lifecycle. Proposed survival substates inside a running match are PREPARING, WAVE_ACTIVE, INTERMISSION and ENDING; these are design names, not current enums.

1. At entry, durably snapshot the player's ordinary state before teleport or inventory replacement; snapshot affected gates before applying match overrides.
2. Select scenario, equipment mode and difficulty; freeze that configuration revision for the match. All human participants join the defender team. Initial objective owners and gate states establish the castle defenses; initial NPC spawnzones are enabled.
3. Start wave 1 after the preparation countdown. Select its normal or special profile, generate the finite wave population and distribute it over configured lanes/spawnzones with configured pacing.
4. A wave completes only when its planned spawn queue is exhausted AND no wave enemies remain alive. A temporarily empty lane or a spawn delay cannot finish a wave. Technical despawns/stuck-enemy recovery must not count as earned kills; define recovery accounting explicitly.
5. Record the completed wave and eligible contributions. Enter intermission, respawn dead players with valid spawn choices, and display the configurable countdown. Survivors remain in play. No implied automatic gate repair or gear refill for survivors.
6. Start the next, harder wave. Repeat without a configured final wave.
7. Main-objective loss or an active-wave team wipe goes straight to ENDING: cancel remaining spawns and repairs, freeze results, settle permanent rewards, remove match entities/items, restore players and gates, then run ordinary lobby cooldown.

Persist both highest wave reached and last fully completed wave. A wipe in wave 10 means reached 10, completed 9; use completed waves for the base reward to avoid awarding a cleared-wave bonus for failure. Endless survival must not inherit PvP's timer-expiry defender victory. A technical duration/resource limit, if added, is an explicit abort policy rather than a secret win condition.

Player death is not quitting or roster removal. Dead spectators remain participants and are eligible for the result. Intermission respawns occur at its start, giving preparation time before the next active wave. Losing a selected spawn objective invalidates that choice; fall back to a valid defender team spawn. No mid-wave respawn.

Proposed first-release compatibility: keep Siege's no mid-match rejoin/late-join policy; explicit leave/disconnect restores ordinary state and forfeits rewards under existing rules. If nobody remains connected, abort rather than running indefinitely. Confirm disconnect/minimum-player semantics before implementation; do not let the empty NPC player roster trigger instant forfeit.

## 4. Objectives, gates and NPC targeting

Reuse a SiegeObjective referencing a scenario-selected GateStructure. The main objective is identified explicitly (reuse the instant-victory reference where compatible). The objective's capture points/holder and each GateDoor's health/destroyed/open state are independent.

| Objective/door state | Required behavior |
|---|---|
| Defender-held; intact closed door | Real door blocks the lane; NPCs may damage it. |
| Defender-held; capturezone reachable through a valid route | NPCs normally advance to capture the objective, engaging nearby defenders as appropriate. |
| Defender-held; route blocked by a selected breakable door | NPCs attack that door, then reroute through the breach. |
| Defender-held; destroyed door | Opening is traversable, objective remains held, repair allowed, deeper spawnzones remain inactive. |
| NPC-held side objective | Transfer ownership and use open-on-capture behavior; no defender repairs. Activate its configured next spawnzones. |
| NPC-held main objective | End the match immediately. |

A destroyed door has no remaining damageable body during repair. An intact closed door MUST be damageable by enemies; an ambiguous voice-transcript sentence about a closed door being invulnerable cannot override the repeated break-through design. Do not grant general invulnerability to closed gates.

Default NPC route logic: choose an eligible downstream defender objective on the assigned lane; if its capturezone is physically reachable without breaching, move there; otherwise select the blocking breakable gate on that lane. After gate destruction, repair closure or objective capture, reassess the route. Route eligibility must include planned breach actions: a blocked-but-breakable gate does not make the entire spawnzone unusable. Avoid arbitrary straight-line nearest-objective selection through walls or another lane.

Players within an aggro radius can temporarily divert enemies. Configure aggro range, leash distance and return behavior so a player cannot stall a wave by dragging its NPCs indefinitely outside the battle. A proposed difficulty option forces gate-first attacks even when an alternative capture route exists. Exact AI priorities, capture weight per NPC/archetype and chase parameters need balance tests, not invented constants.

NPC presence must participate in the objective capture calculation as the attacker team; the current player-only roster scan is insufficient. Reuse configurable capture/contest feedback rather than equating zone capture with gate health damage. Document whether existing side-capture reduction is enabled for this scenario; proposed default is off until explicitly balanced for survival.

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

## 6. Spawnzones and lanes — Defend the Castle

Author multiple NPC spawnzones within the scenario, each containing valid spawnpoints or a bounded spawn area, a lane assignment, wave/profile eligibility and an objective-ownership activation condition. Provide explicit lane routepoints guiding enemies through the intended defensive sequence; local pathfinding traverses between these points and handles combat detours.

Example progression: outside-castle zone initially active → NPCs breach outer gate → NPCs capture outer objective → courtyard zone becomes eligible → next defensive line. **Breach alone does not activate courtyard spawns.** An intact but open door likewise does not advance the spawn frontier.

Activation is ownership-driven. Define objective prerequisites with an explicit ALL/ANY policy when multiple objectives control a zone, validate their references and ensure at least one initial usable spawnzone. New eligible zones affect future queued spawn selections, not already spawned enemies. Never teleport or erase live enemies merely because a zone's eligibility changes.

The aim is for new NPCs to appear near the current fighting area. Proposed zone selection favors the active frontier and can retire earlier zones from future spawning; weighting and whether older zones remain enabled are scenario settings to confirm. Visibility/distance preferences must not accidentally permit spawns inside a closed defender-held line.

Recapture is optional and off by default. Proposed when enabled: reevaluate zone prerequisites against current ownership, stop future spawns in zones that become ineligible, preserve existing NPCs and move the spawn frontier outward. Confirm this policy before enabling recapture scenarios.

Physical NPC navigation is distinct from player `/navigate` visual guidance. KNG-27's road graph may help choose high-level lanes but does not by itself prove NPC traversal, crowd handling or gate breach behavior. Start with the existing NPC pathfinder plus explicit waypoints if it passes the representative castle tests; extend it only for demonstrated gaps. KNG-36 defines the shared NPC platform dependency.

## 7. Wave scaling and special rounds

Per difficulty, configure enemy count/composition growth, health, movement speed, attack damage, gate damage, capture contribution, spawn pacing, lane distribution and repair rate. Snapshot config at match start. Include server limits for live NPCs and spawning/pathfinding work; a large late-wave population can queue rather than spawning every enemy simultaneously.

Special profiles can replace a normal wave at an interval (for example every fifth wave) AND at explicit wave numbers. A wolf-only round is an example, not a required specific mob. Profiles can specify different archetypes, amounts and scaling. Configuration supports both scheduling methods together, not only an exclusive choice.

Proposed deterministic collision rule: explicit wave-number entry overrides recurring entries; conflicting recurring entries require unique priority or fail readiness. A special profile replaces the normal composition by default; additive boss events require a separate explicit setting. The global wave index still advances. No unrequested special-wave reward or ammo drop is implied.

## 8. Equipment modes, purchases and death

| Rule | OWN_INVENTORY | MATCH_PROGRESSION (Zombies-style) |
|---|---|---|
| Entry | Use existing personal gear; snapshot/restore. | Snapshot ordinary state, replace with configured baseline gear or empty inventory. |
| Death during active wave | Keep existing Siege inventory/death safeguards; wait for next intermission. | Drop match equipment at death location, then spectate. |
| Respawn | Retain the match's own-gear behavior. | Give baseline loadout; retain personal match balance. |
| Ground pickup | Existing Siege rules/exceptions. | Own-match equipment drops can be picked up by teammates or the returning player. |
| Exit/end/crash recovery | Restore ordinary snapshot. | Remove temporary gear and restore ordinary snapshot. |

Both modes ship together and are selected per scenario. In MATCH_PROGRESSION, each player has an individual temporary balance; earnings are immediately spendable. Transfer a chosen positive amount to a teammate in the same live match: debit sender and credit recipient atomically, reject overdrafts and cross-match recipients, and identify retries so they cannot pay twice. Match currency is separate from User.Coins/User.Gems and cannot be converted or taken home.

Provide fixed equipment purchase points and Mystery Box points with configured locations, interaction range, prices, item pools/blueprint references and eligibility. Earn currency from configured NPC kills/wave events/contributions; exact amounts and assists distribution remain tunable. Proposed v1 purchase availability: allow both active waves and intermission; disable for spectators. Confirm dead-player transfer permissions during implementation.

Mystery Box immediately ships using existing lootbox roll/catalog/enchantment/reel components where appropriate. Charge once and record one authoritative roll and one delivery per purchase id. Configure its pool and price per scenario. Adapt the components to match scope: do not blindly call ordinary world-lootbox redemption and mint persistent player-owned gear, consume world daily quotas, or leak its tokens into the restored ordinary inventory. Existing reel/pending-delivery behavior needs entry, death, match-end and restart checks (KNG-44 is a relevant follow-up). Define whether an interrupted reel delivers before death or into the same match's pending delivery, without rerolling or duplicating.

Tag and track every match equipment item, ground drop and pending grant by match id. Only members of that match can pick it up; deny outsiders, containers, hoppers and cross-match transfers. Items must survive long enough for a subsequent intermission retrieval; proposed lifetime is the match duration, subject to a configured count limit and explicit overflow handling, not vanilla despawn. On finish/abort remove all remaining items and pending deliveries. Do not duplicate a death loadout while also retaining it on the corpse and giving a new baseline set.

The current Siege keepInventory and no-drop guards need a mode-specific exception for Zombies death drops and pickup. Do not loosen safeguards for ordinary Siege or own-inventory mode. Ordinary persisted item-instance identity/ownership needs special care: transient Mystery Box rewards should reuse the roll result without creating claimable permanent instances unless a reviewed match-scoped lifecycle supports them.

## 9. Permanent rewards and balance calibration

Permanent coins, gems and experience are different from spendable match currency. Accumulate reward inputs during play; grant permanent rewards once when the match ends normally (wipe or main-objective capture). A loss is the expected terminal outcome of endless survival and must not automatically mean zero rewards.

Reward design: a configurable base per completed wave, scaling for later waves, plus measured contributions such as kills/assists, successful repair work and objective defense. Store raw inputs and the reward-policy version, and calculate authoritatively on the API. Values, curves, contribution weights and ceilings remain UNSET pending developer targets. A 'troostprijs' or hard per-match cap was only proposed in conversation, not a locked reward decision.

Calibration inputs supplied by Pandi: desired hours to representative levels and purchases, typical match duration/waves, minigame share of overall progression, other income sources, and expected average/high-performing hourly yield. An agent may then simulate candidate reward curves across scenarios and difficulties for review. Include salary/rank multipliers and title-promotion bonuses when measuring effective progression; do not add a second multiplier or award wave income twice.

Reuse the current ledger and Siege settlement's idempotency; separate survival formula selection from the PvP win/holding/capture calculator. Dead spectators still present at end qualify. Proposed leave/disconnect and abort policy inherits current Siege (no permanent reward on voluntary leave, admin abort or server restart); confirm desired accrued-reward recovery before changing it. No additional persistent payout per wave.

Persist an accrued result or pending settlement before attempting the API payout. Completion retries return the same stored breakdown; inventory/gate cleanup must not duplicate rewards or hang indefinitely behind an unavailable API. Display reached/completed wave, contributions, end reason and the permanent payout, separately from final temporary match balance.

## 10. Proposed configuration and runtime boundaries

These are required conceptual records, not approved class names or database migrations:

| Record/configuration | Required fields/relationships |
|---|---|
| Survival scenario settings | SiegeScenario reference, mode, human/NPC team references, main objective, inventory mode, difficulty profile, intermission timing, recapture policy, baseline loadout, reward-policy revision. |
| Difficulty/wave profile | Scaling rules, archetype composition, pacing, per-lane weights, capture/gate damage, aggro/leash values, repair work rate, resource limits. |
| Spawnzone | Scenario, location bounds/points, lane, initial availability, objective prerequisite ALL/ANY, eligibility/weight. |
| Lane | Ordered routepoints, successive objectives/gates, zone references and optional alternate route. |
| Special-wave schedule | Explicit wave numbers and/or interval/start offset, profile reference, deterministic priority. |
| Purchase/Mystery Box point | Scenario, location, price, pool/product references and interaction limits. |
| Runtime/checkpoint | Match/config ids, reached/completed wave, pending/alive NPC accounting, owners, repair work, personal match balances and transaction ids, item/drop/delivery tracking, contributions and pending settlement. |

Plugin owns live simulation and main-thread world mutations; API owns configuration, durable match results and permanent ledger grants. Pure wave/repair/scheduling logic belongs in Bukkit-free core. NPC platform provides combat, actor identity and path requests. Server validates all purchases/transfers/capture/repair membership; no client-supplied wave number or payout is trusted. Changes made in the editor apply to future matches, not the running snapshot.

Readiness validates human/NPC role identity, one main objective, compatible selected gates and capture locations, valid baseline gear/pools, initial spawnzone and lane routepoints, nonzero scaling/repair parameters, valid special-wave schedule and dependency references. NPC teams do not need fake user rows or ordinary player spawn requirements. Use existing FormConfiguration/DisplayConfiguration and configured location-validation rules; avoid hard-coded assumptions that all enemy spawns must be inside the town.

## 11. Player/admin experience and observability

Player HUD: wave number/type, enemies remaining plus queued spawns, pause countdown, objective ownership/pressure, gate state/health, repair work/contributors, own temporary balance and spectating/next-respawn status. Equipment purchases, Mystery Box odds/pool description and teammate transfers use the existing inventory-menu conventions. Result screen distinguishes match currency from permanent coins/gems/XP.

Admin authoring: select survival mode, difficulty and inventory variant; reference gates/objectives; capture NPC zones/spawnpoints, lane waypoints and purchase locations in-game through existing location tools; preview wave schedules/compositions/repair duration; run readiness. Defend the Castle is the first representative scenario. Label future authoring controls as planned until implemented; the existing Siege guide describes current PvP tooling only.

Record wave start/end, enemy spawn/death/removal reasons, target/path failures, objective capture, door destruction/repair, active repair contribution, currency earning/spend/transfer and box roll/delivery, player death/respawn/leave, cleanup and settlement retries. Aggregate per match/wave/player for balance and debugging; integrate with the shared player-telemetry design when available. Do not invent a full replay recorder as part of this feature. Track tick time, live NPC/item counts, spawn backlog, path work and stuck enemies.

## 12. Current-source checks and integration risks (2026-09-30)

Read-only checks used current workspace main `98372da0a54de6384334290208d70816288f22eb` and plugin main `27b4236a9e3578fe78ea7c32d0526cffa6257250`. API files were fetched from current default `master`; recheck exact defaults before coding. This is a targeted integration review, not a full code audit or live test.

- `knk-plugin/knk-paper/.../gates/GateAnimationTask.java` iterates general Bukkit Entity objects, excluding dead entities and Display objects, calls `CollisionPredictor`, then `EntityEvacuator`/`EntityPusher`. `CollisionPredictor.java` checks entity bounding boxes. Thus the animation path is not player-only; mob NPCs fall within its general entity treatment. `EntityEvacuator.java` uses a standing-spot check with feet/head clearance, so large/nonstandard NPC bodies and the initial respawn/rebuild still require live verification. Reuse it first; no parallel repair safeguard by default.
- `knk-paper/.../siege/SiegeGateController.java` has player-based gate damage attribution and sets `CanRespawnOverride=false`; restore can call `healthSystem.respawnGate`. Survival needs explicit authorized NPC gate damage and a deliberate repair path without enabling unrelated automatic gate respawns.
- Existing Siege design sections 6.6/9.3 retain inventory on death and prohibit drops/pickup. Zombies needs scoped death-drop/pickup behavior and durable ordinary-inventory restore. Existing roster elimination/capture scans must understand NPC teams.
- `knk-web-api/Services/SiegeMatchService.cs` grants rewards server-side exactly once with the currency ledger (`SIEGE_REWARD`, key `siege-match:{id}`) and currently delegates to the PvP `SiegeRewardCalculator`. Add survival reward inputs/logic while preserving settlement idempotency and title progression.
- `Services/Lootbox/LootboxRollEngine.cs` supplies pure roll and odds logic. It currently supports the Grade table's full scale; older lootbox design sections still say 1–5 only. Do not copy stale grade limits or world-claim ownership/quota rules into the match adapter.
- KNG-27 navigation was recorded as unmerged on its feature branches; KNG-36 shared NPC platform and KNG-37 consumers are still backlog. Do not describe either as a shipped physical NPC navigation dependency.

## 13. Open implementation clarifications (not missing core gameplay decisions)

1. Confirm repair interruption is objective ownership loss, consistent with repairing under zone pressure; resolve the isolated 'objective hit' wording before implementing a different condition.
2. Verify destroyed-door reconstruction uses collision handling, including large NPCs; choose the repair interaction input after Paper testing.
3. Confirm destroyed-only repair and per-door health/work semantics for multi-door structures; define animation-time damage/jam transitions.
4. Confirm old-zone weighting and recapture zone deactivation; default recapture remains disabled meanwhile.
5. Validate physical waypoint pathfinding, reachability including breach edges, chase leash and NPC capture weights with the castle map.
6. Confirm special-schedule collisions, purchase/spectator-transfer access, late-join/disconnect/abort policies and whether side-capture reduction is disabled.
7. Supply progression targets and review resulting reward curves. Configure gameplay values with previews, not fixed invented defaults.

## 14. Acceptance checklist

| ID | Required check |
|---|---|
| A01 | Endless waves advance only after all planned enemies spawn and die; queued/stuck/despawned enemies cannot manufacture a wave clear. |
| A02 | Final living defender death or main capture ends once; side capture does not end; dead spectators count for settlement. |
| A03 | Dead defenders return at intermission start with valid spawn choices, never during the active wave. |
| A04 | NPCs break blocked doors and capture reachable zones; closed intact doors are damageable; door destruction never changes objective ownership. |
| A05 | Opening/destruction never enables deeper spawnzones; objective capture does; already spawned NPCs remain in place. |
| A06 | One/two repairers have additive rates; interruption retains work; taking damage and capturezone pressure do not cancel. Death/action-stop/range loss removes only that contributor. |
| A07 | Complete repair restores health once and closes through normal gate behavior; no gradual healing, materials or extra cooldown. Lost objective prevents repair. |
| A08 | Reconstruction/animation do not trap players or representative NPCs; jam state and routing remain truthful. |
| A09 | Both inventory modes work; ordinary PvP/own-gear drop guards remain intact; Zombies death drops are reclaimable after the wave and removed at end. |
| A10 | Match balance pays immediately, survives respawn and transfers atomically only within the match; purchases cannot overdraft or duplicate on retries. |
| A11 | Mystery Box uses existing roll components and match-scoped delivery; no persistent gear/token/instance leakage on death, exit or restart. |
| A12 | Recurring AND explicit special waves select deterministically and continue scaling. |
| A13 | Permanent rewards accrue during play and settle once after normal loss; failed/repeated completion and promotion handling cannot duplicate funds or XP. |
| A14 | Gate/player snapshots restore on end/abort/restart; no match NPCs/items, overrides or pending grants leak into the shared world. |
| A15 | Admin configuration/readiness, player HUD/menus, result history, telemetry and representative late-wave load checks are documented and tested. |
