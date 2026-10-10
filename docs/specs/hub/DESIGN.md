# Hub, outage policy and world portals — draft design

**Status:** Draft for developer review; not implemented.
**Last updated:** 2026-10-10
**Target:** Prefer implementation this weekend (10–11 October), before the closed alpha planned for 17–18 October 2026.
**Linear:** [KNG-109](https://linear.app/kngpandi/issue/KNG-109)
**Scope:** Requirements and investigation plan. No runtime changes or deployment.

## 1. Confirmed requirements

- All joining players first enter a designated hub, including joins while the API is unavailable.
- Players may walk around and use explicitly allowed hub activities, but cannot fight.
- The hub is an enclosed safe area with its own gameplay rules, in a **separate Minecraft world**. A region in the existing gameplay world does not meet the requirement.
- The hub and gameplay worlds run **simultaneously on the same Minecraft server**, with both loaded and players potentially active in each. This is not switching a single active world or a multi-server routing feature.
- The hub world must support ordinary KnK domain content, including GateStructures and potentially Districts. Verify the same entity and gameplay infrastructure can operate independently in both worlds.
- Prefer representing the hub as a KnK Domain with a linked WorldGuard region to enforce entry and exit; exact Domain representation remains to be designed.
- A portal provides access from the hub to the gameplay world when required services and player data are ready.
- Investigate using Multiverse Core and relevant extensions versus implementing the required world management and portal functionality in KnK. No dependency choice has been approved.
- API loss handling for players already online must be configurable, with these options: do nothing; send to hub; kick; send to world spawn. Developer confirmed 2026-10-10.
- Existing global and permission-group spawn/respawn settings from KNG-52 must be considered rather than silently replaced.

## 2. Proposed configuration and behavior

Names below are illustrative, not approved API contracts.

| Setting | Proposal |
|---|---|
| Hub destination | Domain reference plus explicit world-qualified safe spawn (coordinates and orientation) |
| API-loss action | NONE, SEND_TO_HUB, KICK, SEND_TO_WORLD_SPAWN |
| World-spawn target | Explicitly configured world; do not assume the player's current world |
| Outage detection | Defined health/readiness checks, timeout and retry threshold |
| Recovery | Revalidate service readiness and player data before enabling portal travel |
| Hub activities/rules | Explicit allowlist, with combat prohibited |

The outage action applies to players already online when the server transitions into an outage. NONE means no automatic relocation or kick; it does not disable existing protections. New joins still enter the hub. **Confirmed default (2026-10-10): SEND_TO_HUB immediately when API outage is detected, with no intentional grace period. Keep players in the hub while the API remains unavailable, even if cached data could support continued play.** The other three actions remain configurable alternatives. Detection thresholds are distinct from an intentional delay.

Avoid repeated kicks/teleports for every failed request. Define service-wide versus per-player loading failures and use recovery hysteresis to prevent flapping. Pending teleport requests must recheck readiness at execution time.

Proposed recovery behavior: players remain in the hub and choose the portal after recovery, rather than being automatically sent back. Needs developer confirmation.

## 3. Offline safety and local startup

The hub destination and essential protections must be available without a live API, including a cold server start. Required integration: use/extend the refreshable disk-backed cache from [KNG-58](https://linear.app/kngpandi/issue/KNG-58), alongside the existing region protection infrastructure. Developer explicitly confirmed that KNG-52 Game Settings must also be included, so both settings and hub rules survive an API outage followed by a server restart. Persist global settings, per-group overrides, resolved world-qualified destinations, hub protection policy and outage action; document which dependencies are needed to resolve a setting offline. Restore these before player admission. Refresh snapshots after successful API reads/updates, preserve the last valid snapshot on errors, use versioned atomic writes, and define missing/corrupt/expired snapshot handling. Cached rules are not authorization to resume API-dependent gameplay or writes.

Existing architecture documentation reports KNG-56 persists KnK access flags on WorldGuard regions. It also documents first-sync and bypass limitations; do not assume those flags alone implement the complete hub safety requirement. Inspect current code before implementation.

If the hub world, region or safe spawn cannot be loaded, never silently admit a joining player into unprotected gameplay. Proposed fallback is to refuse admission with an explanatory message; developer must confirm.

Ordinary hub exits, command teleports, portals, pearls, chorus fruit, mounts, respawns and plugin-driven teleports require a consistent policy. A permitted hub portal transfer needs an explicit, scoped exit authorization so that a hub exit restriction does not block the intended route. Do not use a broad permanent bypass.

## 4. Hub gameplay rules

Confirmed: no fighting and no unauthorized exit into the gameplay world.

Proposed rules requiring review: deny block breaking/placing, item dropping/pickup, container access, hostile mob damage, environmental damage and hunger unless individually enabled. Define whether no fighting covers PvP, PvE and projectiles/explosives (recommended: all combat). Do not present this proposed catalogue as already approved.

Define staff/operator bypass separately from normal region membership: ordinary members must not accidentally escape outage containment. Decide which offline staff privileges are trusted.

## 5. Integration points

- KNG-52: separate the initial hub admission point from the destination used when entering gameplay. Decide whether the portal resolves global/group join spawn, last logout location, or a portal-specific destination.
- KNG-17: integrate with the existing teleport pipeline and access checks.
- KNG-56: reuse locally persisted domain access rules and inspect exemptions/first-sync behavior.
- KNG-58: explicit offline-cache integration requirement for hub configuration and KNG-52 Game Settings. As checked on 2026-10-10 the issue is In Review; this does not establish that Game Settings are covered or that its changes are merged. Verify the current implementation and extend its shared mechanism instead of creating a second cache. KNG-57: align refresh/invalidation and readiness detection.
- Join loading guard, game modes, inventories and Siege respawn: define precedence explicitly. An outage relocation during a minigame must not lose or duplicate inventory, rewards or match state.

Evidence reviewed: Linear KNG-52 is Done; workspace active-session tracker reports its merge and live validation. Domain access architecture reviewed. Runtime code has not been audited for this draft.

## 6. Prerequisite: world management decision and multi-world audit

The separate, concurrently loaded hub world is mandatory. Research and choose Multiverse versus in-house world management **before implementing the hub**; this is an essential prerequisite, not an optional follow-up. No provider is preselected.

Compare:
1. Multiverse Core plus whichever maintained extension supplies the required portal behavior.
2. Multiverse for world loading, with KnK-owned portal authorization.
3. Minimal KnK world loading and portal implementation.

Verify current Paper/Minecraft compatibility, support and licensing, world persistence/load order, spawn ownership, portal API/events, permission bypasses, event ordering, restart and missing-world behavior, and maintenance cost. Prototype join-with-API-down and outage-during-portal-transfer before choosing.

Deliver a short decision record with verified official sources, recommended option, dependency versions and integration boundaries. This research is explicitly pending; the draft makes no claim about current Multiverse compatibility.

### Required end-to-end multi-world verification

Audit current default branches of knk-web-api, knk-web-app and knk-plugin plus the real database schema/migrations. A world-name field alone is not proof of support. Record evidence per subsystem: supported, gap, or unverified, with exact paths, required migrations/fixes and live test outcomes.

- **Database and entities:** Domain hierarchy (Town, District, Structure and GateStructure), Location relations, domain spawn/default locations, world identity representation and null/default behavior. Determine whether world identity is explicit or derived and check consistency, foreign keys and uniqueness constraints. Define whether parent/child domains must share a world and reject invalid cross-world associations.
- **API and UI:** DTOs, create/update/search/select flows and world selectors preserve the correct world; coordinates and region names must not resolve ambiguously across worlds.
- **WorldGuard:** use the correct world's region manager, parent/priority configuration, flag sync and region-to-domain mapping. Test identical region names and overlapping coordinates in different worlds without collisions.
- **Runtime and caches:** world-qualified lookup/cache keys, persistence and reload, invalidation, region enter/leave events, domain access and discovery, spawn/respawn and teleport destinations. No first-loaded/default-world assumptions or cross-world coordinate-only distance/proximity checks.
- **Gates and districts in the hub:** create/load a valid domain hierarchy including a District and GateStructure; verify door blocks/animations, interactions, access rules and any pass-through behavior are applied only in their own world. Repeat in the gameplay world concurrently, including overlapping coordinates.
- **Other world-sensitive features:** inventory current consumers of Domains/Locations (including navigation, NPCs and minigames) and identify single-world assumptions. Classify hub blockers versus explicitly deferred unrelated work; do not silently claim complete system support.
- **Lifecycle:** both worlds loaded at startup, API-down cold restart using KNG-58 snapshots, unload/reload or missing/renamed world, and portal transfers while players in the other world continue playing.

Required live scenario: keep both worlds running with one player in each, use matching XYZ coordinates and region names, configure different rules, and operate a gate in each. Verify no cross-world rule, cache, event, block or teleport leakage. Repeat after restart with the API down. Evidence must distinguish code review, automated checks and live tests.

This audit is now a required work item; it has **not** been performed as part of this documentation update.



### General KnK capability — confirmed 2026-10-10

Concurrent multi-Minecraft-world support is a **game-wide platform requirement independent of the hub feature**. The hub is its first immediate consumer, not the limit of the audit. Assess all current Domain/Location consumers and world-dependent systems across the game. Report every discovered single-world assumption and unsupported path, even when it does not block hub delivery. Prioritize hub-blocking fixes for the alpha, and track other gaps explicitly as follow-up work; deferral must not be reported as verified general multi-world support. The audit must yield a reusable capability/gap matrix for KnK as a whole, with evidence and a distinction between implemented, tested and unverified behavior.

## 7. Implementation sequence

1. Resolve the decisions below and inspect current default-branch code.
2. Complete the prerequisite Multiverse/in-house decision and end-to-end multi-world audit; identify and fix hub-blocking gaps before building the hub flow.
3. Add configuration and administrator controls (API/web app plus plugin persistence).
4. Implement hub admission, local protections and guarded portal travel.
5. Implement the four outage actions and recovery behavior.
6. Verify unit/integration behavior and run the live alpha smoke checklist.

## 8. Acceptance and smoke checklist

- Separate hub and gameplay worlds run concurrently; players, Districts and GateStructures function in both without world identity leakage, including identical coordinates/region names.
- Healthy join: player first appears in the hub, including groups with alternate join spawns.
- API-down join and cold restart: player enters the protected hub without briefly appearing in gameplay.
- Cache integration: configure global/group Game Settings and hub/outage rules, successfully persist them, stop the API, restart the server, and verify the same applicable rules and destinations. Include unknown users, expired grants, corrupt/missing snapshots and recovery refresh.
- NONE: online players are not moved or kicked, while normal protections continue.
- SEND_TO_HUB: online players move once to the configured hub.
- KICK: affected online players are disconnected with a clear reason; rejoining follows hub admission.
- SEND_TO_WORLD_SPAWN: online players move to the explicitly selected world's spawn.
- Hub combat is blocked; allowed movement/activities continue.
- Unauthorized exit paths fail, including alternative teleport methods.
- Healthy portal travel works with intended permissions and destination selection.
- API loss during transfer and recovery flapping cannot bypass containment or repeat destructive effects.
- Missing configuration/world/region follows the approved safe fallback.
- Outage handling during Siege and pending respawn preserves player state without duplication.

## 9. Open decisions

1. Whether outage policy has group/staff overrides. Default action is decided: immediate SEND_TO_HUB.
2. Exact outage thresholds and which dependencies count as unavailable.
3. Which world's spawn SEND_TO_WORLD_SPAWN uses; fallback if it is unavailable.
4. Concrete Domain type/hierarchy for the hub and world identity consistency rules. Separate, simultaneously loaded hub/gameplay worlds are already decided.
5. Portal destination and interaction with KNG-52 overrides/last logout location.
6. Full hub activity/protection catalogue and staff bypass rules.
7. Missing-hub fallback, recovery behavior and minigame/respawn precedence.
8. Multiverse versus KnK implementation, after investigation.


## 10. Future requirement: configurable outage grace period

Developer decision, 2026-10-10: add a configurable delay before applying the outage action in a future iteration. For now the delay is zero: send players directly to the hub on detected outage and retain them there until connectivity is restored. Future deployments may permit continued play using KNG-58 cached essential data during a temporary outage, then relocate players after a sustained outage because stale state and synchronization risk increase over time. Thirty minutes and one hour were examples, **not selected defaults or validated safe durations**.

Future design must define when the timer starts, what constitutes stable recovery/reset, repeated outage handling, restart persistence, and earlier containment when critical cached data expires or becomes unusable. A grace period does not authorize API-dependent writes or bypass other safety rules. Current new-join behavior remains hub admission. This is recorded future scope, not required timer implementation for the initial alpha.
