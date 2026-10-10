# Hub, outage policy and world portals — draft design

**Status:** Draft for developer review; not implemented.
**Last updated:** 2026-10-10
**Target:** Prefer implementation this weekend (10–11 October), before the closed alpha planned for 17–18 October 2026.
**Linear:** [KNG-109](https://linear.app/kngpandi/issue/KNG-109)
**Scope:** Requirements and investigation plan. No runtime changes or deployment.

## 1. Confirmed requirements

- All joining players first enter a designated hub, including joins while the API is unavailable.
- Players may walk around and use explicitly allowed hub activities, but cannot fight.
- The hub is an enclosed safe area with its own gameplay rules.
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

The outage action applies to players already online when the server transitions into an outage. NONE means no automatic relocation or kick; it does not disable existing protections. New joins still enter the hub. No default outage action has been chosen.

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

## 6. Required Multiverse investigation

Compare:
1. Multiverse Core plus whichever maintained extension supplies the required portal behavior.
2. Multiverse for world loading, with KnK-owned portal authorization.
3. Minimal KnK world loading and portal implementation.

Verify current Paper/Minecraft compatibility, support and licensing, world persistence/load order, spawn ownership, portal API/events, permission bypasses, event ordering, restart and missing-world behavior, and maintenance cost. Prototype join-with-API-down and outage-during-portal-transfer before choosing.

Deliver a short decision record with verified official sources, recommended option, dependency versions and integration boundaries. This research is explicitly pending; the draft makes no claim about current Multiverse compatibility.

## 7. Implementation sequence

1. Resolve the decisions below and inspect current default-branch code.
2. Complete the focused Multiverse investigation and select an approach.
3. Add configuration and administrator controls (API/web app plus plugin persistence).
4. Implement hub admission, local protections and guarded portal travel.
5. Implement the four outage actions and recovery behavior.
6. Verify unit/integration behavior and run the live alpha smoke checklist.

## 8. Acceptance and smoke checklist

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

1. Default outage action and whether it is global or has group/staff overrides.
2. Exact outage thresholds and which dependencies count as unavailable.
3. Which world's spawn SEND_TO_WORLD_SPAWN uses; fallback if it is unavailable.
4. Separate hub world versus region inside an existing world; concrete Domain type.
5. Portal destination and interaction with KNG-52 overrides/last logout location.
6. Full hub activity/protection catalogue and staff bypass rules.
7. Missing-hub fallback, recovery behavior and minigame/respawn precedence.
8. Multiverse versus KnK implementation, after investigation.
