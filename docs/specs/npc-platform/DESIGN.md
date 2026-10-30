# Shared NPC platform — traits, behavior and tutorial guide

**Status:** Working design; agreed tutorial requirements recorded, platform architecture and implementation investigations still open. No NPC implementation delivered by this document.
**Last updated:** 2026-10-30 (automatic navigation and shared optional lane overrides; developer decision, #146)
**Linear:** [KNG-36](https://linear.app/kngpandi/issue/KNG-36/design-shared-npc-traits-and-pathfinding-platform)
**Standing workspace branch:** none; `codex/kng-36-npc-platform-design` was merged into `main` on 2026-10-18 and deleted
**Authority:** Developer navigation correction on 2026-10-30 and discussion through 2026-10-06 and KNG-36 description/comments read on that date. Confirmed decisions below preserve that discussion; proposed interfaces and unresolved questions are explicitly labeled. This is the consolidated design reference for continued discussion, not a completed platform design or implementation plan.

## 1. Purpose and scope

NPCs are central to Knights and Kings: enemies, allies, guards, shopkeepers, quest givers, tutorial guides and later companions/bosses. Shared capabilities must be composable. A quest giver may also trade, walk a route and react when attacked. Possessing a capability does not mean using it continuously: behavior decides when it runs.

Start with a personal tutorial guide as the first concrete design slice, then use a city guard to challenge reuse across patrol, dialogue and combat. KNG-36's wider remit remains: audit V1 Citizens integrations, V2 remnants and current V3 before selecting Citizens adapters or replacements; define engine-neutral domain/configuration versus Paper runtime boundaries; address stats, equipment, factions, combat, persistence, authoring, diagnostics, security and performance. The tutorial example does not silently finalize those areas.

KNG-36 is sequenced after [KNG-35](https://linear.app/kngpandi/issue/KNG-35). Its later consumers include [KNG-37](https://linear.app/kngpandi/issue/KNG-37) and [Siege survival / KNG-50](../siege-survival/DESIGN.md). Recording these decisions does not start gameplay-mode implementation or complete KNG-36.

## 2. Conceptual boundaries

| Concept | Responsibility | Status |
|---|---|---|
| NPC template | Reusable configuration for capabilities, movement rules and behavior choices | Proposed vocabulary; schema, inheritance and overrides remain open |
| NPC instance | A particular runtime actor, including the tutorial participant association | Per-player tutorial instances agreed; identity/persistence schema open |
| Trait / capability | What the actor can do: move, converse, fight, trade, etc. | Composability agreed; exact trait granularity pending audit |
| Behavior | Chooses actions, responds to events and arbitrates competing capabilities | Separation agreed; scheduler/state-machine technology open |
| Lifecycle | Validates spawn requests and creates/removes runtime actors | Separate from movement; feature supplies locations and fallback policy |
| Progression system | Owns completable steps, conditions and durable per-player progress | Separate from NPC traits and behavior |
| Platform adapter | Executes platform-neutral intentions in Paper/Citizens or another runtime | Required design boundary; implementation choice pending audit |

Do not embed tutorial state, spawn coordinates or permission inheritance from a nearby player inside a generic movement trait. Avoid conflicting patrol, combat and dialogue movement requests through behavior arbitration; target scoring, switch margin and minimum commitment are agreed in §5a; wider interruption contracts remain open.

## 3. Confirmed decisions

| ID | Decision |
|---|---|
| NPC-01 | Roles/capabilities can be combined; NPCs are not restricted to exclusive quest-giver/shopkeeper/guard classes. |
| NPC-02 | Tutorial guide first, city guard next as a reuse/design check. Each tutorial participant has a personal NPC instance. |
| NPC-03 | The guide appears at a configured location, approaches the participant and stops at conversation range to offer a start/resume. |
| NPC-04 | When the participant walks out of interaction range, the guide stays in place, pauses interaction and starts a configurable absence timer. It does not follow the departing participant. |
| NPC-05 | Returning before expiry cancels that timer and resumes the interaction. Expiry removes the NPC while retaining tutorial progress. The same rule applies to a rejoin invitation. |
| NPC-06 | Logout removes the personal NPC and preserves progress. On a later login with paused progress, the guide can approach and ask whether to continue. Acceptance resumes the unfinished step; completed steps remain completed. |
| NPC-07 | A paused tutorial must always be manually resumable, including during the same login session. The entry point is not yet selected. |
| NPC-08 | Progress is stored independently of the NPC entity. Distance timeout/despawn never completes, skips or resets the tutorial. |
| NPC-09 | Initial tutorial movement: supported walkable terrain, stairs, slabs, at most one block upward jump and at most one block downward step/drop. The downward limit is configurable. No ladders, swimming or gap jumps. |
| NPC-10 | Paths respect movement capability and body/head clearance, including jumps. A safe spawn is not proof of reachability. |
| NPC-11 | Tutorial configuration supplies preferred/fallback spawn locations. Generic lifecycle validates the supplied location and returns a failure reason; tutorial behavior chooses any fallback. |
| NPC-12 | NPCs must participate in KnK permissions with configurable per-NPC exceptions for domain entry/exit and gate access. Do not assume inheritance of the accompanying player's rights. |
| NPC-13 | Domain entry/exit authorization, gate/door operation authorization and physical passage are separate concerns. Existing person-scoped gate pass-through must be investigated before selecting an integration. |

Thirty seconds was suggested for the absence timer but not confirmed as a default. A fixed tutorial starter at spawn, automatic following, a maximum approach time and blanket access revocation on pause are not agreed decisions.

## 4. Tutorial behavior cycle

The names here are conceptual states, not existing enums. “Removed” is the cleanup transition back to Absent, not a second persistent progression state.

| State | Entry/action | Transitions |
|---|---|---|
| Absent | No runtime guide; progression remains in its own system | Initial tutorial trigger, rejoin with paused progress or manual summon requests a configured spawn |
| Approaching | Spawn succeeds; request movement to participant with configured conversation range | Arrival → Invitation; failure/participant moving during approach requires the open policy in §10 |
| Invitation | Offer tutorial or ask to resume unfinished tutorial | Accept → Guiding; out of range → Waiting; explicit “not now”/no-response policy open |
| Guiding | Read current step; present its dialogue/actions; await progression signals | Step signal → next appropriate action; out of range → Waiting; completion → cleanup behavior to be detailed |
| Waiting outside range | Stop dialogue and movement; remain at current location; run absence timer | Timely return → previous Invitation/Guiding state; expiry → cleanup → Absent |
| Any present state | React to participant logout | Cleanup → Absent, with progress retained |

Entering Waiting pauses the interaction/tutorial session; the earned progress remains intact. No completion condition should be inferred from disappearance. The progression engine, not the dialogue callback itself, owns step completion. Whether unrelated world events can advance a paused step remains a progression-system question.

Personal instance does not yet specify who else can see or collide with it. Invitations and responses must belong to the correct participant; visibility and simultaneous-guide crowd handling remain open.

## 5. Reusable capability contracts — proposed decomposition

These describe responsibilities to evaluate, not final API/class names.

| Building block | Inputs/configuration | Results/events | Exclusions |
|---|---|---|---|
| Lifecycle | Actor specification and a supplied world/location | Spawned actor or concrete failure; cleanup result | Tutorial location selection, progression storage |
| Movement | Destination or target, movement profile, speed/stop distance to be decided | Arrived, blocked/unreachable, cancelled or failed | Deciding to resume a tutorial, automatic follow policy |
| Dialogue | Participant, content and choices | Participant response/cancel/end | Completing tutorial steps or awarding progress independently |
| Proximity sensing | Participant, actor and configured range | Left/returned to range | Choosing timeout/despawn behavior |
| Event integration | Join/logout/manual request, progression signals | Events delivered to the correct behavior instance | Embedding tutorial logic in a general event listener |
| Access evaluation | NPC identity, domain/gate/action and contextual rights | Allowed/denied and a usable reason | Assuming authorization removes physical collision |

Distance sensing and event integration may be shared services rather than Citizens traits. Audit first. Lifecycle must remain distinct from movement even if a consuming behavior calls both.

Proposed robustness requirements for later implementation: one active guide per participant/tutorial session; idempotent summon/cleanup; ignore stale movement or dialogue callbacks after cleanup; isolate player responses. These are engineering proposals for review, not claims about existing support.

## 5a. Shared target scoring and commitment (confirmed 2026-10-30)

Developer decisions under [#146](https://github.com/PandiO/knk-workspace/issues/146) establish utility-based target selection with two complementary stability controls. This belongs to shared behavior arbitration, not to navigation or a Siege-only implementation.

1. Filter candidates through hard eligibility rules first: permitted target/action, faction/team and match membership where relevant, and hard pursuit constraints. High scores never override these rules.
2. Compare eligible goals using configurable target-type preference and proximity. Closer candidates have higher proximity contribution; do not multiply preference by raw distance and thereby reward distant targets. A preference-times-normalized-proximity expression is an illustrative model; the final curve, normalization and numerical weights are not approved defaults.
3. On adopting a target/behavior decision, start a configurable **minimum commitment duration**. While the current action remains valid and unfinished, ordinary score changes do not replace it before that duration expires. Continue updating the route to the same moving target; navigation replanning is not a new target decision.
4. After the minimum duration, allow score-driven replacement only when the challenger exceeds the current target by a configurable **switch margin** (hysteresis). Duration expiry permits reevaluation, not a mandatory switch. Exact absolute/relative margin semantics, equality/tie handling and reevaluation cadence remain open.
5. Hard invalidation ends commitment immediately: target death, leaving the match, authorization loss, exceeding the hard pursuit limit, or terminal unreachable/failure after the navigation recovery policy. Ordinary route recalculation or temporary blockage is not automatically terminal failure. Completed actions may advance immediately; the hold must not force continued attacks on a destroyed gate.

Minimum commitment and switch margin are configurable by NPC profile, with per-behavior configuration supported in the design. Exact schema/override precedence and numeric tuning remain open. Each NPC owns its current target and commitment state; the shared arbitration layer ensures one movement owner and delegates route execution to navigation. On invalidation/failure it decides whether to resume the previous assignment, choose another target, wait or stop under the consuming feature's rules.

Acceptance scenarios: small score fluctuations do not cause oscillation; a higher-scoring player does not interrupt a valid gate action during its minimum commitment; after expiry the switch margin still applies; invalidation/completion is handled without waiting; path updates toward the same target do not restart commitment; guards and Siege attackers reuse the same mechanism with different configuration.

A temporary score bonus for being attacked was discussed separately, but its inclusion/stacking/decay and interaction with commitment are not finalized by this decision. Do not introduce an implicit damage-triggered bypass of commitment. Behavior-tree/library selection and wider combat rules remain open; this is design only, not implemented gameplay.

## 6. Movement and spawn details

### Automatic navigation and optional lane overrides (confirmed 2026-10-30)

Developer decision, tracked in [#146](https://github.com/PandiO/knk-workspace/issues/146): automatic navigation is the default. Reuse the roads infrastructure for suitable route legs and local walkable pathfinding (A* or the selected equivalent) for connections and off-road travel. NPCs must not require an admin-authored lane or be restricted to roads. This is a required design direction, not a claim that physical NPC execution is implemented.

Optional admin lane overrides belong to the shared navigation trait/capability, not exclusively to Siege Survival. Guards, escorts and other consumers can reuse this support. A concrete override is configuration on the NPC or movement assignment; the generic trait must not hard-code scenario routes. Behavior chooses the destination, while navigation selects automatic routing or the applicable ordered routepoint override and performs local pathfinding between points.

Overrides guide routing but do not bypass movement profiles, domain/gate permissions or physical collision. Report an unusable segment with a reason. **Failure policy confirmed 2026-10-30:** first retry local pathfinding toward the next required routepoint within a bounded retry budget; routepoints remain binding during these attempts. If the segment remains unusable, navigation reports a blocked/failed result with a reason. Behavior owns the response (for example waiting, selecting another target or ending the assignment); the generic navigation trait must not hard-code Siege or guard decisions.

Each lane override has an "allow automatic alternative route" setting, **off by default**. When explicitly enabled, navigation may leave the override after bounded retries and attempt an automatic route to the assignment's destination, still respecting movement, access and collision rules. If that attempt fails, report failure to behavior. This policy applies to every NPC consumer, not just Siege. Exact retry counts/timing, configuration schema, precedence between NPC and assignment overrides, and interruption/resume remain open under #146; no numeric defaults are approved.

For the first Siege gate-targeting slice, spawning immediately triggers target selection/path planning, followed by movement as soon as a usable path is ready; no intentional startup delay. This does not override the tutorial's distinct invitation/waiting behavior. The gate destination is a reachable attack/approach position, not a path through a closed door. Nearest-by-route target selection remains a proposal, not an approved universal policy.

Acceptance additions: navigate from a configured spawn without any lane, use appropriate road and off-road legs, follow an optional override, report an invalid override without bypassing access/collision, and reuse the same navigation capability outside Siege. Verify bounded retry to the next required point, blocked-result delivery to behavior when fallback is off, opt-in automatic routing to the destination when enabled, and failure reporting if that route also fails. Benchmark physical execution and search budgets before choosing a library.


### Caller-supplied navigation ruleset (confirmed 2026-10-30)

The consuming feature/controller supplies the NPC's assignment context. In Siege this is the Survival game manager; guards, escorts and tutorials use their own controllers. No Siege-specific manager dependency belongs in the shared navigation trait.

- The controller supplies a spawn request/location to lifecycle. Lifecycle validates and creates the actor. Navigation starts from the actor's actual position; it does not own spawning or assume the original spawnpoint is the current position.
- The controller supplies eligible goals and gameplay constraints. Behavior selects the current goal and arbitrates competing actions; navigation receives that destination/target, the effective movement ruleset and any applicable lane override.
- The shared navigation capability uses suitable road infrastructure and local pathfinding under that ruleset, or follows the optional override with the agreed bounded-retry/default-off automatic fallback policy.
- Movement rules must be configurable and may be supplied by the caller for an assignment. Ladder use and door opening are explicit examples. Candidate settings to finalize include swimming, gap jumping, maximum upward step/jump, maximum drop, and door/gate interaction. These are a mix of flags and numeric limits, not all booleans. The transcript's first movement example was unclear; do not infer an additional confirmed capability from it.
- Capability, authorization and physical execution remain separate: allowing door interaction in a ruleset does not itself grant access to every door or imply a usable opening. The selected mover must support permitted actions. Door opening is not gate breaching; breaching still requires the relevant capability and behavior.
- Planner and executor must use consistent effective movement constraints, including during override fallback. Proposed implementation guard: reject/report unsupported combinations instead of silently treating them as executable.

The configurable-ruleset requirement is confirmed; the complete field catalogue, defaults per archetype, precedence between template/instance/assignment rules, and update semantics are still open under #146. Existing tutorial movement restrictions remain its specific profile, not universal NPC defaults. HTTP endpoints and DTOs are not selected by this decision.

Acceptance additions: the same navigation capability accepts different caller-supplied rulesets; ladder-disabled planning does not select a ladder route; door-opening permission in a profile cannot bypass domain/gate authorization; assignment rules remain effective during lane retries and automatic fallback. Physical traversal support must be verified for each selected capability.

### Tutorial movement profile

| Capability | Initial rule |
|---|---|
| Walk on supported safe terrain | Allowed |
| Stairs and slabs | Allowed; account for actual geometry and clearance |
| Jump upwards | Maximum 1 block |
| Step/drop downwards | Maximum 1 block; configurable limit |
| Jump across a gap | Disallowed |
| Ladders | Disallowed |
| Swimming | Disallowed |
| Body/head clearance | Required along the traversed motion, including jumps |
| Doors, trapdoors and GateStructures | No blanket bypass; access and physical traversal integration pending §7 |

The profile describes allowable physical movement; behavior determines destination and when to stop. More capable NPC types may later use different profiles. The exact hazard list, numeric speed, clearance model, range values and vertical-distance calculation remain open.

### Generic spawn validation

Validate the supplied world's existence, chunk availability, collision-free space appropriate to the actor and safe support. Return a concrete reason when invalid. Chunk availability validation does not authorize automatically loading/generating arbitrary chunks; that policy remains open.

Tutorial configuration owns candidate locations and selection order. If the preferred location fails, the tutorial behavior may try its configured fallback. Do not silently introduce a generic “spawn anywhere near the player” rule. Separately check whether the spawned NPC can reach the intended target under its movement/access profile.

## 7. Permissions and closed gates

NPC identity must be usable in the permission system independently of player identity. Per-NPC exceptions should be configurable for entry, exit and gate access; exact holder representation, template defaults and precedence rules still need design.

The motivating scenario is a tutorial visit to a normally restricted throne room behind a closed GateStructure. The tutorial participant and guide need a way through without granting general access to everyone.

The developer reports that access checks already operate separately from physical gate state and recalls a GateDoor pass-through action scoped to a person, not visible to other players. This session has not inspected that implementation. Do not treat client-visible opening as proof of server-side passage or NPC pathfinding support.

Required investigation:

1. Locate the current GateDoor pass-through entry point and identify its person/player binding.
2. Establish whether it changes client-visible blocks, server collision, position or another mechanism; inspect viewer isolation and cleanup.
3. Test whether a non-player NPC can use it, and whether the path planner and movement executor agree about collision.
4. Determine the smallest extension that lets participant and guide traverse without opening the shared gate for everyone.
5. Design narrowly scoped temporary rights: subject, domain/gate/action, tutorial step/session, lifetime and cleanup.
6. Decide safe exit/recovery if the tutorial pauses, the NPC disappears or the player logs out while inside. Do not blindly revoke exit access and strand a participant.
7. Handle gate/access changes between planning and execution. A route is usable only when the actor is authorized and can physically execute it.

No access-grant schema, packet strategy, teleport fallback or global gate-opening policy is selected yet.

## 8. Separate progression-system note

The developer recalls a V2 abstract Progressable-style design with Creation as its concrete implementation: entity create/edit flows divided into steps with configurable completion conditions. The intended abstraction could also support quests, parkour and tutorials.

Investigate that legacy design and compare current [Siege objectives](../siege-minigame/DESIGN.md) and their actual implementation before deciding whether conditions, transitions and persistence fit a common core. Names and reusable implementation are unverified. Siege objectives need not be forced into a linear tutorial model.

For KNG-36, describe only the boundary: read the active step, present requested interaction, receive progression signals and pause/end presentation. The progression system owns durable completed/current step data. A restartable unfinished step must preserve completed work; details of partial progress within a step belong to that separate design.

## 9. Navigation reuse and platform audit

[Road navigation](../navigation/DESIGN.md), [KNG-27](https://linear.app/kngpandi/issue/KNG-27) and [KNG-51](https://linear.app/kngpandi/issue/KNG-51) may supply reusable pathfinding components, but player guidance is not NPC locomotion.

The KNG-36 comment dated 2026-10-02 points to [LAST_MILE_PATHFINDING.md §13](../navigation/LAST_MILE_PATHFINDING.md) (then on its design branch, now on `main`): walkable grid, chunk capture/cache, bounded A* search, movement profiles and per-cell access are candidates. The comment described that branch as unmerged at the time; the document is on `main` now (link updated 2026-10-18). Recheck implementation status before reuse. NPC path following, crowds, factions and interaction remain KNG-36 responsibilities.

Audit V1/V2/V3 and compare a Citizens navigator with reusable KnK pathfinding on the castle test map. Cover off-road/vertical travel, closed gates, changed permissions, unloaded chunks, concurrent actors and cancelled tasks. Set measurable path-computation, tick-time, entity-count, asynchronous-work and degradation budgets after collecting evidence; none are approved yet.

## 10. Open decisions and next design passes

| ID | Question / work |
|---|---|
| O01 | Manual summon UI/command; explicit “not now”, no response and invitation frequency |
| O02 | Conversation range, leave/return thresholds, absence timer default and distance semantics |
| O03 | Initial approach if player keeps moving, target becomes unreachable or navigation stalls; bounded retry/cancel policy without changing agreed no-follow behavior |
| O04 | Safe-terrain hazard set, speed, obstacle replanning, ordinary doors/trapdoors and chunk-load policy |
| O05 | Personal NPC visibility/collision, concurrent instances and lifecycle on server restart/teleport/world change |
| O06 | Permission holder/schema, override precedence, temporary grant scope and safe exit |
| O07 | Verified GateDoor pass-through mechanism and NPC-compatible traversal |
| O08 | Exact trait boundaries, engine-neutral contracts and runtime/library choice; scoring + switch margin + minimum commitment agreed in §5a. Remaining arbitration work: numeric tuning, margin semantics, reevaluation cadence, configuration precedence and wider interruption contracts |
| O09 | Dialogue delivery/authoring, response timeout, tutorial completion/departure presentation |
| O10 | V2 Progressable/Creation and Siege comparison; progression boundary only in KNG-36 |
| O11 | City guard profile: patrol, aggro/defense, dialogue interruptions and return to patrol |
| O12 | Wider platform: combat, HP/damage/stats, equipment, factions, scripting, persistence, admin tools, debugging/security and numerical performance budgets |

Suggested sequence: finish movement/gate investigations → dialogue/proximity/lifecycle decisions → city guard reuse check → platform design and phased implementation plan → minimal NPC vertical slice. Do not silently convert unresolved options into implementation defaults.

## 11. Acceptance scenarios for the eventual slice

These are design checks, not tests already performed.

1. Two participants receive independent guides, invitations, responses and stored progress.
2. Valid spawn approaches to configured conversation range; invalid spawn returns a reason and only configured fallback policy is used.
3. Stairs/slabs and a one-block rise/drop work with adequate clearance; a two-block rise/drop, ladder, swim or gap route is rejected under the initial profile.
4. Body/head obstruction prevents an impossible jump/path. Safe spawn with unreachable target is reported separately.
5. Leaving range stops the guide; timely return resumes the previous interaction; expiry removes it without progress loss or completion.
6. Rejoin invitation obeys the same range/timer rule; accepting resumes the unfinished step; manual summon works in the same session.
7. Logout removes the instance and saves/retains progression independently; stale callbacks cannot act on a replacement guide (proposed robustness check).
8. NPC access uses its own configured identity/exceptions. Domain entry, exit, operation permission and physical passage are checked separately.
9. Throne-room pass-through is not accepted until both participant and NPC can traverse, unauthorized outsiders remain excluded and interruption permits safe recovery.
10. Eventual guard behavior reuses the platform without competing movement owners; performance meets budgets to be set in the platform audit.

## 12. Documentation handoff

This pass consolidates developer decisions and verified issue text only. It does not audit game code, assert Citizens/gate/progression support, run live tests or implement NPCs. The specs hub and feature register point here; Linear remains the work/dependency tracker and links to the design. Keep future decisions and resolved investigations in this living document, with dates and source evidence, rather than allowing the issue and document to diverge.
