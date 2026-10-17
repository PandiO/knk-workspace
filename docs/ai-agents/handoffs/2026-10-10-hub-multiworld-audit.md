# Codex handoff: hub implementation-readiness and general multiworld audit
**Date:** 2026-10-10
**Status:** Executed 2026-10-10 (code/schema-source audit; no live/DB validation) — see [report](../../reports/2026-10-10-multiworld-capability-audit.md) and hub DESIGN §16. PR #11 was already merged, so the docs went to a follow-up workspace PR.
**Issue:** KNG-109
**Workspace branch:** codex/hub-design, draft PR #11 (unmerged)
**Scope:** Investigation and documentation; do not implement, merge or deploy the hub yet.

## Task prompt
Read AGENTS.md in every repo, workspace docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md and current docs/ACTIVE_SESSIONS.md. Refresh the coordination board from default branch, inspect overlapping claims and publish a scoped claim before edits. Preserve parallel road-navigation work. Use the existing workspace feature branch. Inspect actual current default branches of knk-plugin, knk-web-api and knk-web-app, recording their SHAs; do not treat feature-branch code as shipped.

Read workspace docs/specs/hub/DESIGN.md including newest sections 13–15, docs/reports/2026-10-10-hub-multiverse-research.md, KNG-109, KNG-52 and KNG-58. Resolve conflicts in favor of current developer decisions.

Perform an evidence-backed audit of **general concurrent Minecraft multiworld support**, independent of the hub. First deployment has separate simultaneously running hub/gameplay worlds; a hub may also be a region in the same world. Both can contain Domain hierarchies, Districts and GateStructures.

Trace database entity/schema/migrations -> DTO/service/repository -> web create/edit/search/select -> plugin mapping/cache -> WorldGuard/runtime operations for Domain, Town, District, Structure, GateStructure, Location and their relationships. Inspect real DB read-only if accessible; otherwise distinguish migration evidence from actual schema and mark DB inspection unverified. Check:
- explicit/derived world identity, null/defaults, world-name/UUID mapping, parent/child consistency and uniqueness;
- region-manager selection, region-to-domain cache keys, equal region names/XYZ in different worlds;
- location resolution, teleports/spawn/respawn, gate block operations/animations, domain enter/leave, proximity/distance, NPC/navigation/minigame consumers;
- startup/load order, unloaded/renamed/missing worlds, disk-cache hydration/invalidation and API-down restart;
- whether player admission can avoid a brief appearance in gameplay before hub placement.

Inspect existing HealthApiImpl/HealthDataAccess and any connectivity/readiness/circuit-breaker/channel consumers, plus backend /health mapping. Reuse existing detection. Cached healthy data must not establish current connectivity. Determine what is already implemented versus missing orchestration.

Verify group precedence from PermissionGroupPrecedence and TeleportGroupPolicy. Trace effective permission resolution (direct grants, group parents, node children, wildcards/denials) for knk.mode.staff and knk.mode.owner. Propose API/UI eligibility reuse for conditional mode-exemption checkboxes; do not reverse group inheritance.

Evaluate an illustrative IsHub flag on **base Domain** so all subtypes can be hubs. Propose storage/migration/DTO/form changes and selection of a global hub Domain+spawn. Do not silently decide multiple-hub/nested-hub semantics. SEND_TO_WORLD_SPAWN is definitively the player's current world at execution, not a configured different world.

Trace outage evacuation while a player participates in Siege: match bookkeeping, pending death/respawn, kit/inventory swaps, disconnect/end-match handling and listeners that could return them to gameplay. Recommend minimal containment integration and list the explicit pause/abort/resume decision if needed. No new routine mid-match hub flow was requested.

Compare **only required capabilities**:
A. Multiverse Core world lifecycle + KnK portal.
B. Minimal KnK loading of pre-existing configured world folders + KnK portal.
C. Core+Portals adapter if it actually saves work.
Do not assume we need to clone every Multiverse feature. Account for import/create needs, generators, persistence, missing-world failures, thread requirements, startup readiness, unloading safeguards, tests and upgrade maintenance. Verify official sources and candidate pinned dependency version/license. Explain whether Core's competing spawn/respawn/gamemode rules can be disabled cleanly. Leave provider decision a recommendation.

Verify exact vanilla Java Peaceful healing/feeding behavior for the deployed Minecraft version using versioned server source or direct controlled observation. Explain units, intervals, interaction with natural regeneration/saturation and how a region-scoped implementation avoids stacking with native behavior. Do not guess rates.

## Deliverables
1. Dated docs/reports multiworld capability/gap matrix: subsystem, supported/gap/unverified, exact code paths+SHAs, hub blocker vs general follow-up, suggested fix, evidence type.
2. Update hub design with concrete implementation-readiness findings and minimal phased plan.
3. Provider recommendation comparing required-scope in-house work with Core; no inflated full-clone comparison.
4. Proposed live checklist with two players, identical region names/XYZ, districts and gates in both worlds; API-down restart; outage during portal transfer; Siege respawn containment; mode transitions.
5. Remaining developer decisions only where behavior cannot be derived. Create/update linked Linear gap issues within requested audit scope without claiming fixes are implemented.
6. Publish docs to existing PR #11, update Linear and close out claim. No automatic merge/deploy.

Do not claim the live tests ran without a real server. If no live access is available, complete code/schema-source audit and identify precise remaining validation. No hub runtime implementation is authorized by this handoff alone.
