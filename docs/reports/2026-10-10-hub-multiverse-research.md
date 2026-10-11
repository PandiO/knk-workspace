# Hub world management: Multiverse feasibility
**Status:** Research recommendation; not an approved dependency decision or live compatibility test.
**Date:** 2026-10-10
**Issue:** [KNG-109](https://linear.app/kngpandi/issue/KNG-109)
**Branch:** codex/hub-design / workspace PR #11

## Recommendation
Use **Multiverse Core for world lifecycle and KnK for the hub portal, authorization, destination selection and recovery**. This is an engineering recommendation based on the official documentation and a limited current-code inspection. It minimizes new generic world-management code while keeping KnK's game rules in one place. Do not require Multiverse for the conceptual existence of a hub: a same-world hub must also work. First deployment uses an extra world.

| Option | Benefit | Cost / constraint | Assessment |
|---|---|---|---|
| Core + Portals | Existing world and portal administration | Additional dependency and action/event integration for dynamic KnK destinations and readiness | Viable alternative |
| Core + KnK portal | Reuse world lifecycle; KnK owns existing game-specific rules | Implement bounded portal trigger and transfer guard | Recommended |
| KnK world lifecycle + portal | Fewer third-party dependencies and full control | Own startup persistence, imports, generators, errors, unload safety and maintenance | Technically viable; larger scope |

Paper already exposes world creation/loading through WorldCreator; separate concurrent worlds do not inherently require Multiverse. The cost of in-house ownership is the lifecycle around that API, not creating a new engine. [Paper 1.21.10 API](https://jd.papermc.io/paper/1.21.10/org/bukkit/WorldCreator.html).

## Verified upstream findings
- Official releases show Core **5.8.1** as latest stable; 5.8.2-pre is a prerelease. Use 5.8.1 as the candidate for a pinned pilot, not a moving "latest". [Releases](https://github.com/Multiverse/Multiverse-Core/releases).
- Publisher listings identify Paper support and 1.21.x compatibility; Hangar lists stable 5.8.1 with a supported range encompassing 1.21.10. This is declared compatibility, not proof of working with KnK/WorldGuard on the actual server. [Modrinth](https://modrinth.com/plugin/multiverse-core), [Hangar](https://hangar.papermc.io/Multiverse/Multiverse-Core).
- Core is BSD-3-Clause. Keep required notices with any redistribution; no source-copying or fork is proposed. [Repository/license](https://github.com/Multiverse/Multiverse-Core).
- Core documents world properties in worlds.yml, including auto-load. It also owns world-wide difficulty/PvP/hunger/auto-heal options. These cannot alone implement a region-scoped configurable hub within a shared world. [World properties](https://mvplugins.org/core/fundamentals/world-properties/).
- Core API covers world operations. Keep integration in knk-paper, behind a world-provider boundary; KnK domain/location identities must remain independent of Multiverse API types. [API usage](https://mvplugins.org/core/developers/api-usage/).
- Portals API provides world-qualified portal bounds, optional unloaded-world getters, cancellable MVPortalEvent and configurable actions. Therefore Core+Portals can be integrated, but stock teleport destinations alone do not resolve KnK's group-specific Game Settings or outage-return record. A KnK-owned command/action adapter is an alternative. Do not execute an elevated raw teleport command as a substitute for authorization. [Portals API](https://mvplugins.org/portals/developers/api-usage/).
- Portal permission gating is enabled by default; Core world gating depends on enforce-access. Audit OP/default/wildcard permissions and KnK SuperPerms compatibility. Independent KnK transfer guarding is still required. [Portal permissions](https://mvplugins.org/portals/fundamentals/permissions-setup/), [Core permissions](https://mvplugins.org/core/reference/permissions-list/).
- Additional modules must share the major version with Core. Neither Inventories nor NetherPortals is required merely to load a separate hub world. Avoid Inventories initially: independent per-world inventories were not requested. NetherPortals is only a candidate for explicit additional Nether/End linking requirements. [Installation](https://mvplugins.org/core/fundamentals/installation/).

## Integration boundaries
Core loads/imports named worlds from local configuration at startup, independently of the API. KnK verifies world availability and restores cached hub rules before admitting players. Missing dependency/world must fail admission safely.

KnK owns:
- initial hub admission before any gameplay exposure;
- region rules, mode exemptions and offline policy snapshots;
- guarded portal trigger, destination via KNG-52 group/default resolver;
- outage action/delay and persisted return lifecycle;
- transfer validation for every alternate exit.

Core configuration requires a reviewed profile: turn off its join/first-spawn overrides, default respawn routing and gamemode/flight enforcement where KnK owns those behaviors; remove conflicting per-world respawn targets. Keep world spawn/time/weather ownership explicit. Documented default event priorities include teleport HIGHEST and respawn LOW; audit actual pinned-version listener ordering with KnK and WorldGuard. Do not assume equal priorities guarantee ordering. Use exact world identities, not aliases. [Core configuration](https://mvplugins.org/core/reference/configuration-file/).

Use a declared dependency/load order or an explicit provider-readiness callback. Soft dependency absence must not silently enable a configured hub requiring an unloaded world. Disallow unload while it is needed for admission/outage containment.

## Limited current KnK evidence
Inspected default-branch files via GitHub on 2026-10-10:
- API Services/PermissionGroupPrecedence.cs: descending Weight, id tie-break, parent chain, deduplication; already solves override conflicts.
- Plugin knk-paper/src/main/resources/plugin.yml: WorldGuard dependency, WorldEdit soft dependency; no Multiverse dependency yet. Staff/owner commands use KnkPermissible and knk.mode.staff/knk.mode.owner.
- Plugin knk-api-client/.../impl/HealthApiImpl.java: existing asynchronous /health request; a TODO still flags endpoint contract. Existence is not proof of a service-wide outage state machine.
- Plugin knk-core/.../dataaccess/HealthDataAccess.java: cached health query and refreshAsync using API_ONLY policy. Outage detection must use fresh results, never treat a cached successful response as current connectivity. Check the actual endpoint and existing consumers before adding orchestration.
- KNG-52 design reports an existing game-settings disk copy and world-aware settings; integrate with KNG-58 shared cache rather than introducing another storage mechanism.

No full multiworld audit, real database inspection, runtime prototype or deployed-server test was performed. No plugin jar was installed, built or deployed. Peaceful numeric healing/feeding defaults remain a version-source verification item; the accepted preset is documented rather than guessing numbers.

## Pilot gates before dependency approval
1. Pin Paper/Minecraft, Core 5.8.1, WorldGuard and KnK jars; record hashes and Java version.
2. Boot both worlds with API up, then API down and local snapshots; prove pre-join hub admission and no gameplay flash.
3. Exercise first/repeat join, all group/mode overrides, respawns and Siege precedence without competing Multiverse rules.
4. Cut API during pending portal transfer; verify final readiness check, single evacuation, durable return record and no duplication.
5. Exercise alternate teleports, operator accounts, vehicles, Nether/End exit and repeated outage/recovery.
6. Restart offline, missing/renamed hub world, missing/corrupt snapshots; enforce clear fail-closed behavior.
7. Run matching region names/coordinates, Districts and gates concurrently in both worlds and validate no world leakage.
8. Same-world hub smoke test with region-only rules; healing/feeding must not stack native and custom regeneration.

Proceed with Core + KnK portal as the proposed implementation direction, subject to these pilot gates. Track general multiworld gaps separately from this provider decision.
