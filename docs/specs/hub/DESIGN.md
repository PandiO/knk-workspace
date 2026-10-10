# Hub, outage policy and world portals — draft design

**Status:** Draft for developer review; not implemented. Code/schema-source readiness audit done 2026-10-10 ([report](../../reports/2026-10-10-multiworld-capability-audit.md), §16); no live or DB validation yet.
**Last updated:** 2026-10-10
**Target:** Prefer implementation this weekend (10–11 October), before the closed alpha planned for 17–18 October 2026.
**Linear:** [KNG-109](https://linear.app/kngpandi/issue/KNG-109)
**Scope:** Requirements and investigation plan. No runtime changes or deployment.

## 1. Confirmed requirements

- All joining players first enter a designated hub, including joins while the API is unavailable.
- Players may walk around and use explicitly allowed hub activities, but cannot fight.
- The hub is an enclosed Domain/region with its own rules. Same-world hubs are supported; the first deployment requires a separate concurrently loaded hub world.
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
| World-spawn target | Player's current world at action execution |
| Outage detection | Defined health/readiness checks, timeout and retry threshold |
| Recovery | Revalidate service readiness and player data before enabling portal travel |
| Hub activities/rules | Explicit allowlist, with combat prohibited |

The outage action applies to players already online when the server transitions into an outage. NONE means no automatic relocation or kick; it does not disable existing protections. New joins still enter the hub. **Confirmed default (2026-10-10): SEND_TO_HUB immediately when API outage is detected, with no intentional grace period. Keep players in the hub while the API remains unavailable, even if cached data could support continued play.** The other three actions remain configurable alternatives. Detection thresholds are distinct from an intentional delay.

Avoid repeated kicks/teleports for every failed request. Define service-wide versus per-player loading failures and use recovery hysteresis to prevent flapping. Pending teleport requests must recheck readiness at execution time.

Confirmed recovery behavior: persist the pre-evacuation location on disk and offer a clickable return confirmation after recovery. Players remain in the hub unless they choose to return or use a permitted portal. See §12.

## 3. Offline safety and local startup

The hub destination and essential protections must be available without a live API, including a cold server start. Required integration: use/extend the refreshable disk-backed cache from [KNG-58](https://linear.app/kngpandi/issue/KNG-58), alongside the existing region protection infrastructure. Developer explicitly confirmed that KNG-52 Game Settings must also be included, so both settings and hub rules survive an API outage followed by a server restart. Persist global settings, per-group overrides, resolved world-qualified destinations, hub protection policy and outage action; document which dependencies are needed to resolve a setting offline. Restore these before player admission. Refresh snapshots after successful API reads/updates, preserve the last valid snapshot on errors, use versioned atomic writes, and define missing/corrupt/expired snapshot handling. Cached rules are not authorization to resume API-dependent gameplay or writes.

Existing architecture documentation reports KNG-56 persists KnK access flags on WorldGuard regions. It also documents first-sync and bypass limitations; do not assume those flags alone implement the complete hub safety requirement. Inspect current code before implementation.

If the hub world, region or safe spawn cannot be loaded, never silently admit a joining player into unprotected gameplay. Confirmed fallback: refuse admission or kick with an explanatory locally available message.

Ordinary hub exits, command teleports, portals, pearls, chorus fruit, mounts, respawns and plugin-driven teleports require a consistent policy. A permitted hub portal transfer needs an explicit, scoped exit authorization so that a hub exit restriction does not block the intended route. Do not use a broad permanent bypass.

## 4. Hub gameplay rules

Confirmed configurable catalogue and initial values are in §13: building/breaking and damage disabled; dropping/pickup, doors, NPCs and personal inventory allowed; storage and itemframe/painting interactions blocked. Healing/feeding use a version-verified Peaceful preset. Active-mode outage exemptions are separately configurable; they do not imply a blanket activity-rule bypass.

## 5. Integration points

- KNG-52: initial server admission goes to the hub; hub-to-gameplay entry resolves the default spawn and permission-group overrides through the existing Game Settings, extended internally for this flow. Preserve separate respawn settings and the existing administrator-facing configuration model (confirmed; see §11).
- KNG-17: integrate with the existing teleport pipeline and access checks.
- KNG-56: reuse locally persisted domain access rules and inspect exemptions/first-sync behavior.
- KNG-58: explicit offline-cache integration requirement for hub configuration and KNG-52 Game Settings. As checked on 2026-10-10 the issue is In Review; this does not establish that Game Settings are covered or that its changes are merged. Verify the current implementation and extend its shared mechanism instead of creating a second cache. KNG-57: align refresh/invalidation and readiness detection.
- Join loading guard, game modes, inventories and Siege respawn: define precedence explicitly. An outage relocation during a minigame must not lose or duplicate inventory, rewards or match state.

Evidence reviewed: Linear KNG-52 is Done; workspace active-session tracker reports its merge and live validation. Domain access architecture reviewed. Runtime code has not been audited for this draft. *Superseded 2026-10-10:* the default-branch code audit is in §16 and the [multiworld audit](../../reports/2026-10-10-multiworld-capability-audit.md).

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

*2026-10-10: the concrete minimal phased plan is §16.3; the steps below remain the outline.*

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
- SEND_TO_WORLD_SPAWN: online players move to their current world's spawn.
- Hub combat is blocked; allowed movement/activities continue.
- Unauthorized exit paths fail, including alternative teleport methods.
- Healthy portal travel works with intended permissions and destination selection.
- API loss during transfer and recovery flapping cannot bypass containment or repeat destructive effects.
- Missing configuration/world/region follows the approved safe fallback.
- Outage handling during Siege and pending respawn preserves player state without duplication.

## 9. Remaining decisions and checks

See §13 for confirmed policies and remaining engineering checks.

## 10. Configurable outage delay

Action and delay are required in the initial version. Delay **Uit** means immediate execution; SEND_TO_HUB is the default action. See §13.

## 11. Confirmed: extend existing Game Settings for hub-to-world entry

Developer decision, 2026-10-10: extend KNG-52 Game Settings using the same administrator-facing model and workflow. Internally distinguish server admission into the hub from entry into a gameplay world. The hub portal must resolve the destination through Game Settings: a default world-entry spawn with per-permission-group destination overrides. Preserve a separately configurable respawn location/policy and existing group override behavior. Reuse existing group precedence rather than adding a competing portal-specific configuration system. Preserve current administrator-facing semantics; adapt the underlying world-aware resolution and lifecycle integration.

This resolves the choice between a fixed portal destination and existing settings: **existing Game Settings, extended for hub teleportation**. Inspect current per-world settings (including Nether/End), world-change application rules and DTOs before implementation; do not assume that world-change behavior is already correct. Explicitly distinguish server join, hub-to-gameplay entry, other world transfers and death/respawn. Verify destinations in the correct world, group precedence, default fallback, separate respawn behavior and KNG-58 persistence through an offline restart.

The handling of an optional last-logout-location policy, ordinary Nether/End portal destination semantics, and returning after an outage must be made consistent with these settings without inventing developer decisions. Recovery is now explicitly opt-in through a clickable return offer (§12).


## 12. Confirmed: persisted pre-hub location and opt-in recovery return

Developer decision, 2026-10-10: when an outage sends a player to the hub, persist their location immediately before relocation in the KNG-58 disk-backed mechanism. Once connectivity returns and required player/service data is ready, send a message with a clickable confirmation offering to return to that saved location. Teleport only after the player accepts; no automatic return.

The return record must identify the player and original world, XYZ and orientation, and survive a server restart without the API. Keep this record distinct from ordinary logout location and Game Settings entry spawn. Repeated outage handling or movement/relogging inside the hub must not overwrite it with a hub location. Players without an outage-return record continue through normal hub portal/Game Settings flow.

Implementation safeguards proposed: persist before transfer, track successful evacuation and return, recheck connectivity/readiness and destination safety/access on click, bind the action to the player and current return record, prevent repeated/stale clicks, and consume the record only after a successful return. Determine safe handling of persistence/teleport failures. A missing world, unsafe destination or newly denied access must not result in an unchecked teleport. Confirmed: invalid destinations invalidate the record with a player notification; relog/restart preserves valid records and reminds the player. Successful voluntary gameplay entry clears the record (§13). Offline-at-recovery players need the offer when they next join and become ready. Define interaction with normal portal use and ended minigames explicitly.

Acceptance: evacuate from a non-hub world, restart with API unavailable, restore connectivity, receive the offer, and confirm return to the correct persisted world/location. Also verify no-click stays in hub, repeated evacuation preserves the original location, double-click cannot repeat a completed return, and a renewed outage or invalid destination blocks unsafe return.


## 13. Confirmed follow-up decisions (2026-10-10)

Supersedes conflicting proposals/open questions above.

- Hub functionality supports a Domain/region in the same world or a separate world. First deployment requires a separate concurrently loaded hub world; game-wide multiworld verification remains mandatory.
- Outside active staff/owner mode: global outage defaults or applicable PermissionGroup override. Two per-group exemption checkboxes (default off): active staff mode and active owner mode. Exemption covers outage action and gameplay entry during outage. Rank alone gives no exemption. Show each only when its corresponding effective permissionnode is granted, including inheritance and permission-node children; validate server-side. Verify knk.mode.staff/knk.mode.owner and actual group inheritance direction; the conversational word "children" must not reverse existing inheritance.
- Reuse Game Settings precedence: descending Weight, ties lower id, group then parent chain, deduplicated; first applicable override per field. Verify current PermissionGroupPrecedence/TeleportGroupPolicy.
- Inspect and reuse existing API connectivity/readiness detection. No competing health detector.
- Action and intentional delay separately configurable in the initial version. Default SEND_TO_HUB; delay UI "Uit" means immediate action, not disabled action. Enabled duration configurable; 15 minutes is only a future experiment, no proven safety limit. Supersedes future-only timer scope in §10.
- Gameplay entry requires API and player data ready, subject to configured active-mode exceptions. Guard portals, commands, other teleports and respawns; recheck at execution.
- Saved pre-outage location survives logout/restart. Next login notifies that it remains; clickable return after readiness, never automatic. Unavailable/unsafe/no-longer-authorized location is invalidated with a message, not silently redirected. Clear after successful return or successful voluntary gameplay entry. Repeated evacuation does not overwrite original with hub location.
- Missing usable hub/cache/world/region/spawn: refuse admission or kick with a clear locally available message.
- Every hub rule configurable: damage-players, damage-entities, take-damage; heal-amount/frequency and feed-amount/frequency; building/breaking, drop/pickup and interaction rules. Initial combat/damage off; build/break off; drop/pickup allowed; doors, NPCs and personal inventory allowed; chests/equivalent storage including shulkers/barrels blocked, and itemframe/painting interactions blocked. Preserve inventory; separate inventories not requested. Minigame transitions must not duplicate/lose inventory.
- Default healing/feeding preset matches vanilla Java Peaceful for deployed version. Verify exact amounts/frequencies against versioned source before encoding numeric defaults. Scope to hub region (same-world support); avoid doubling native and custom regeneration. Peaceful is not invulnerability.
- Remaining details: Domain representation, minigame/respawn precedence, mode transitions during outage, timer reset/restart semantics and actual connectivity detector.

Acceptance additions: direct/inherited/denied mode-node checkbox visibility; staff outside modes follows normal group policy; saved-location login notice across restart; invalidation message; voluntary entry clears return; alternate exits guarded; same-world rules do not affect surrounding gameplay; verify Peaceful preset without stacked healing/feeding.


## 14. Multiverse research recommendation

See [2026-10-10 research](../../reports/2026-10-10-hub-multiverse-research.md). Recommended: Multiverse Core 5.8.1 candidate for world lifecycle, KnK-owned portal/readiness/destination logic. Dependency choice is not yet approved or live-tested. *Updated 2026-10-10:* the multiworld audit's required-scope comparison recommended a minimal KnK loader (option B); **the developer chose it on 2026-10-10** (§16.4).

## 15. Follow-up clarification (2026-10-10)

- SEND_TO_WORLD_SPAWN uses the world the player is in at execution time. No separately configured target world. Snapshot that world before teleporting and use its world spawn; if unavailable follow safe failure behavior without selecting an arbitrary different world.
- Developer proposes a flag on base Domain (illustrative IsHub) so every Domain subtype can be a hub. Recommended design direction, pending concrete schema/UI validation. Hub destination still explicitly references an eligible Domain and its world-qualified spawn; a flag alone must not pick an arbitrary hub when multiple exist. No new Hub-only subtype is needed. Multiple flagged domains and the global default hub selection remain to be specified in implementation proposal.
- Minigame integration refers to API-outage evacuation of a current match participant, not routine hub transfers during healthy matches. Inspect active Siege death/respawn/inventory listeners and ensure they cannot teleport the player back out of containment or corrupt match/inventory state. Whether an outage pauses, aborts or leaves a match running remains an explicit decision if existing behavior does not settle it.
- Multiverse Core recommendation is about reducing generic lifecycle maintenance, not a technical necessity for two worlds. Re-evaluate against a minimal load-existing-worlds implementation; do not compare against recreating all Multiverse features. No provider approved yet.
- Audit handoff: [multiworld implementation-readiness prompt](../../ai-agents/handoffs/2026-10-10-hub-multiworld-audit.md).

## 16. Implementation readiness (audit 2026-10-10)

Source: [multiworld capability audit](../../reports/2026-10-10-multiworld-capability-audit.md) of plugin `main` `973aa68b`, API `master` `8cce48d0` and web app `main` `12c1d600`. It is a code and migration-snapshot audit only: **no live server, no database and no implementation**. Row IDs below refer to the report's matrix.

### 16.1 What already works

- **Location and teleport targets keep their world.** Location → Bukkit conversion never invents a world (L1), and the KNG-17 teleport engine uses the target's world (L4).
- **KNG-52 settings are world-aware.** Settings are per world, respawn uses the world the player died in (A7, L5), and a disk copy `game-settings-cache.json` already exists (§5 of the report).
- **Several systems already carry a world:** the gate block index (with a blank-world caveat), gate block operations, roads, navigation, lootboxes and Siege locations (G3, G4, S1).
- **Group precedence matches §13.** `PermissionGroupPrecedence` and `TeleportGroupPolicy` both order by Weight descending, ties by lower id, each group followed by its parent chain, with duplicates removed (P1). Inheritance runs child → parent (P2).
- **A Siege match runs locally once started**, and its results are spooled (SG5).

### 16.2 Hub blockers found

1. **No Domain stores its world** (D1–D6, A1–A4, U1). The region id is the only link from region to domain, in the API, the plugin caches, the region tracker, the access preview, the KNG-56 flags and managed-region repair (R1–R13). Identical region names in two worlds collide, and moving between them causes no enter/leave. Tracked as [KNG-111](https://linear.app/kngpandi/issue/KNG-111) and [KNG-112](https://linear.app/kngpandi/issue/KNG-112).
2. **Gates** ([KNG-113](https://linear.app/kngpandi/issue/KNG-113)):
   - A door with a blank world animates in every world (G1).
   - Gate tasks start only for worlds loaded during `onEnable` (G2).
3. **Admission and lifecycle** ([KNG-114](https://linear.app/kngpandi/issue/KNG-114)):
   - The join spawn is a teleport after `PlayerJoinEvent`, so the player can briefly appear in gameplay (H1). Paper 1.21.10's `AsyncPlayerSpawnLocationEvent` can place them before they appear.
   - Several paths fall back to `Bukkit.getWorlds().get(0)` (L2).
   - There is no world-readiness check or unload guard (LC1, LC2).
4. **Connectivity** ([KNG-115](https://linear.app/kngpandi/issue/KNG-115)):
   - The plugin's health probe calls a path the API doesn't serve and parses the wrong status values (C1, C2).
   - `/health/ready` ignores the database (C3).
   - There is no service-wide outage state (C5). The reusable piece is the HTTP client, not the detector.
5. **Offline state.** The KNG-58 P0 store is **not merged** (LC3, P5). On `main`, a rejoin during an outage reveals vanished staff and clears their mode.
6. **Mode-exemption checkboxes** ([KNG-116](https://linear.app/kngpandi/issue/KNG-116)) need an API that computes a group's effective permissions (P3).
7. **Siege containment** ([KNG-117](https://linear.app/kngpandi/issue/KNG-117)):
   - Siege's HIGHEST respawn handler would put an evacuated participant back in the arena (SG2).
   - The vault restore and the rejoin restore both teleport to the pre-siege location (SG4).

Gaps that do not block the hub are tracked in [KNG-118](https://linear.app/kngpandi/issue/KNG-118).

### 16.3 Minimal phased plan (proposal, not authorized)

| Phase | Scope | Issues | Gate to next phase |
|---|---|---|---|
| 0 | **Pinning.** Decisions are confirmed (§16.4); pin the Paper/WorldGuard/KnK versions. | — | Decisions recorded |
| 1 | **World identity.** API `Domain.WorldName` with backfill and a unique (world, region) index; same-world rules; world-qualified DTOs and lookups. Web app persists the captured world and shows the world in pickers. Plugin uses `world:regionId` keys and treats a world change as leave-all/enter-all. | KNG-111, KNG-112 | Unit tests; live checklist items 2, 3, 5 |
| 2 | **Gates and lifecycle.** Reject blank-world doors; start/stop gate tasks per world; the minimal KnK world loader with readiness and an unload guard; no first-world fallbacks on admission paths. | KNG-113, KNG-114 (lifecycle) | Checklist items 1, 4, 14 |
| 3 | **Connectivity and offline state.** Fix the probe and `ready`; an `ApiConnectivity` state machine; merge KNG-58 P0 and extend it with hub config, outage action/delay and return records. | KNG-115, KNG-58 | Checklist item 7 (API-down restart) |
| 4 | **Hub configuration.** `IsHub` on base Domain; a Game Settings hub block (`hub.domainId`, `hub.spawnReference`, outage action and delay, per-group exemption flags); the group eligibility endpoint and the UI. | KNG-116, KNG-109 | Server-side validation tests |
| 5 | **Hub runtime.** Admission via `AsyncPlayerSpawnLocationEvent`; hub rules, including the Peaceful preset (§16.5); a guarded portal with a scoped exit authorization; the four outage actions; return records; Siege containment. | KNG-114, KNG-117 | Checklist items 6–13, 15 |

**Phase 1 progress (2026-10-10):** implemented on branches `claude/blissful-fermat-b7ihrz` (API `bccd5f9`, web app `de1fa96`, plugin `08326d6`), not merged or live-tested; managed-region repair, discovery and roads/navigation still pending. See the [implementation handoff](../../ai-agents/handoffs/2026-10-10-kng-111-112-multiworld-implementation.md).

**Deadline risk:** Phase 1 alone touches all three repos plus a rebase-sensitive migration, which is substantial work for the 17–18 October alpha. The developer chose the full fix first (§16.4, decision 2).

### 16.4 Developer decisions (confirmed 2026-10-10)

These supersede the open questions in the audit report §11.

1. **World provider: a minimal KnK loader** (option B). KnK loads the world folders listed in `config.yml` at startup. It refuses joins when the hub world is missing and cancels unloading of required worlds. Multiverse is not used. The portal is built by KnK.
2. **Alpha scope: the full fix comes first.** Every Domain gets an explicit world before the hub is built (Phase 1).
   - The world is **extracted automatically** from a required world-task field of the domain entity, for example its region world task (`WgRegionIdTaskHandler` already reports `worldName`) or its Location world task.
   - Only when no such field gives a world does the web form **ask for it**.
   - The interim unique-region-name rule is **not** adopted.
3. **Main world: the gameplay world stays the `level-name` world.** The hub is the additional world.
4. **IsHub means eligible only.** Several domains may carry the flag, and the flag only makes a domain selectable. Hub rules apply only to the hub selected in Game Settings (`hub.domainId`). **Nested flagged domains are not allowed** for now and are rejected on save.
5. **Exemption checkboxes: only a ticked box counts.** An unticked box means "not set", so any of the player's applicable groups that ticks it exempts them. The exemption applies only while the player's **active** mode is staff or owner.
6. **Siege on outage: abort the match.** When an outage action evacuates any participant, the whole match is aborted: no rewards, and the abort is recorded through the existing spool. Every participant gets their inventory back exactly once. Their return point is their pre-match location, never the arena.
7. **Game Settings offline copy: fold it into the KNG-58 store** once KNG-58 P0 is merged. Until then, `game-settings-cache.json` stays the fallback.

**Smaller defaults, accepted:**
- **World identity:** domain worlds are keyed by world name. The world UUID from the runtime-worlds report is recorded so a renamed world is detected.
- **Same world:** a child domain, its gate Locations and its spawn Locations must be in the parent's world.
- **Peaceful preset:** it runs only while `naturalRegeneration` is on, and is skipped for players whose world is already Peaceful.
- **Group permission check:** a new API check tells whether a group effectively has `knk.mode.staff` / `knk.mode.owner` (KNG-116).

### 16.5 Peaceful preset (verified, not guessed)

Checked against vanilla 1.21.10 `ServerPlayer.tickRegeneration` in the official server jar and mappings, and Paper `ver/1.21.10` @ `8043efd4`. This only applies while the world's difficulty is PEACEFUL and `naturalRegeneration` is on:

- **Healing:** +1.0 HP every 20 ticks.
- **Saturation:** +1.0 every 20 ticks, up to 20.
- **Food level:** +1 every 10 ticks while below 20.

Paper only tags the heal with `RegainReason.REGEN`.

**To avoid stacking with vanilla:**
- Run the hub preset only inside the hub region.
- Skip it when the player's world is already PEACEFUL.
- Leave the native `FoodData` SATIATED regeneration alone.

Report §10 has the full source.

### 16.6 Live validation

The live checklist is in report §13. It covers:
- two players, with identical region names and XYZ, Districts and gates in both worlds;
- an API-down restart;
- an outage during a portal transfer;
- Siege respawn containment;
- mode transitions;
- the Peaceful measurement.

**None of it has been run.**
