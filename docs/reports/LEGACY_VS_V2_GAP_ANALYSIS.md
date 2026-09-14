# Legacy (`knk`) vs. v2 — Feature Gap Analysis

**Date:** 2026-09-10
**Source of legacy inventory:** `Repository/knk-v2-archive/MIGRATION_OVERVIEW.md`, `MIGRATION_INVENTORY.md`, `MIGRATION_MAPPING.md` (a ~185-class, package-by-package catalog of the legacy plugin, written as pure documentation with no code changes to the legacy repo) and `Repository/knk-v2-archive/spec/SOURCES_TOWNS.md`.
**Method:** Every legacy subsystem named in those docs was checked against the actual v2 code (`Repository/knk-plugin`, `Repository/knk-web-api`, `Repository/knk-web-app`) as it stands today — model classes, controllers, and plugin packages — not against the migration docs' own "MOVE / REPLACE" intentions, which are 2026-01-era plans and don't reflect what actually got built since. This complements `docs/IMPLEMENTATION_STATUS_AUDIT.md`, which covers v2's *own* roadmap features; this document covers what v2 hasn't touched yet because it's still sitting in the legacy inventory.

---

## Summary

Most of the legacy plugin's *architecture* (Hibernate DAOs, in-game-only UI, tight WorldGuard/WorldEdit coupling) has been deliberately replaced, not carried over — that was the point of the rewrite. Below is a distinction between **things that were dropped by design** (a different, usually better, mechanism replaced them) and **things that simply haven't been rebuilt yet** (a real functional gap versus the legacy game).

## Confirmed functional gaps — legacy had it, v2 has no trace of it

| Legacy subsystem | Legacy evidence | v2 status |
|---|---|---|
| **Minigames** (teams, spawnpoints, objectives, scenarios) | `MinigameTeamDAO`, `MinigameSpawnpointDAO`, `MinigameObjectiveDAO`, `MinigameScenarioDAO`, `model/minigame/*` | **Zero trace** in any of the three v2 repos — no model, controller, or plugin package. |
| **Resource generation / production structures** | `GenerationDAO`, `ProductionStructureDAO`, `command/generation/*`, `GenerationCommandListener` — structures that produce resources over time | **Zero trace.** No `GameSettings`-adjacent or structure-linked production concept anywhere in the v2 backend models. |
| **Storage / warehousing** | `StorageDAO`, `Storage.java`, `StorageCache`, `StorageOverviewSection` (menu UI), `StorageCommand` | **Effectively gone.** The only remnant is a frontend type stub (`StorageItemDTO.ts`, `StorageViewConciseDTO.ts`) referenced only from mock test data (`src/data/testData.ts`) — no backend model, no controller, no plugin logic. This looks like dead scaffolding, not a working feature. |
| **Transport orders / logistics** | `TransportOrderDAO`, `TransportOrder`/`TransportOrderItem`/`TransportRouteNode` models, 4 transport commands, `TransportHandler` scheduler | **Zero trace.** This is downstream of Storage above — without a Storage concept, there's nothing for Transport to move between. |
| **In-game inventory/chest GUI framework** | `menu/*` package: `Menu`, `MenuItem`, `MenuSection`, `MenuSession`, pagination, clickable/dropdown abstractions — used for storage overview, item registration, kit selection, etc. | **Not built.** The `InventoryMenus` branch on `knk-plugin` has exactly one commit ("Initial requirement assessment"), no code. All v2 UI has moved to the web app; nothing has replaced the *in-game* GUI layer for the features (Storage, Kits) that depended on it. |
| **Player rank / required-title gating** | `Grade.java`; `Town.requiredTitle` (legacy field, confirmed in `docs/specs/towns/SPEC_TOWNS.md`) gated town creation by player rank | **Zero trace.** No rank/tier/title concept anywhere in v2 models. |
| **Item kits** | `model/item/kit/*` (predefined item loadouts), `RegisterSession.java` (item registration flow) | **Not present.** `ItemBlueprintDefaultEnchantment` is a different, narrower concept (default enchantments on *one* item), not a bundle/loadout of items. |
| **House / Village settlement tiers** | `model.House`, `model.Village` | **Zero trace.** v2's settlement hierarchy is Town → District → Structure only; no smaller "House"/"Village" tier exists below District. |
| **Player statistics tracking** | `UserStatistics`/`UserStatisticsDaily` — logins count, cash earned/spent, (likely more fields, truncated in this pass) | **Zero trace.** No statistics/analytics model anywhere in v2; `User.cs` has balance fields (Coins/Gems/XP) but nothing that tracks history or aggregates like "logins" or "cash earned to date." |
| **CoreProtect / Dynmap integration** | Mentioned in the legacy migration docs themselves as *unconfirmed* ("evidence: mentioned in migration docs but not found in explicit imports... TODO: verify") | Not found in v2 either — but since the legacy docs never confirmed this existed in the first place, treat this as an open question carried forward, not a verified regression. |

## Re-architected, not missing — a different mechanism now covers the same ground

These aren't gaps; the legacy approach was intentionally replaced as part of the v2 rewrite, and the new mechanism is live.

| Legacy | Replaced by | Notes |
|---|---|---|
| In-game multi-stage `Creation`/`CreationStage*` wizard (everything done inside Minecraft) | WorldTask + web-app FormWizard hybrid workflow (`docs/world-tasks/`) | Deliberate UX shift: start in the web app, finish spatial steps (location/region capture) in-game. Functionally broader (validation, multi-step forms) but changes where the player/admin does the work. |
| 30+ Hibernate DAOs + `hibernate.cfg.xml` + Ehcache | Web API controllers + typed HTTP client (`knk-api-client`) + the Data Access Unification caching layer | This *is* the core purpose of the rewrite (see `docs/IMPLEMENTATION_STATUS_AUDIT.md` §6) — fully executed, not a gap. |
| `SelectionListener`/`RegionListener` + `WorldguardUtil` (manual WorldEdit/WorldGuard region selection) | `WgRegionIdTaskHandler` + WorldTask flow | Same underlying WorldGuard integration, now driven by the task/workflow system instead of bespoke listeners. |
| `GateAnimationUtil` + `ContinuousGateDamageUtil` + `TestGate1` fixture (basic gate open/close + damage) | The in-flight **Gate Structure Animation** feature | Actively being rebuilt with substantially more capability (rotation, health/respawn, fire/DoT, WorldGuard flag sync) — see audit §8. Currently complete but unmerged, so *functionally* this is temporarily still a gap in `main`/`master` even though the replacement code exists on a branch. |
| `ScoreboardUtil` | Same-named `ScoreboardUtil.java`, ported and wired into `PlayerListener` | Straight carry-over, confirmed active. |
| `model/category/*` | Generic self-referencing `Category.cs` (tied into the FormConfiguration/generic-entity system) | Modernized but conceptually equivalent. |
| `model/item`, `Itemtype`, `KNKBlock` | `ItemBlueprint`, `EnchantmentDefinition`, `MinecraftMaterialRef`/`MinecraftBlockRef`/`MinecraftEnchantmentRef` catalog system | Broader and more structured than the legacy item model. |
| CustomEnchantments-1.0.3.jar (separate legacy *addon*, not part of core `knk`) | Fully ported — see audit §5 | Mentioned here only to clarify it's unrelated to the core-plugin gap list above. |

## What's fully covered (no gap)

Users/accounts (exceeds legacy — legacy had no web app or password auth), Towns/Districts/Structures/Streets CRUD, WorldGuard region handling, and the Scoreboard utility are all present in v2 with no missing legacy capability identified.

---

## Caveat on the source material

The legacy migration docs themselves are explicitly a first documentation-only pass ("Do NOT refactor or change existing production code... Only add analysis documentation") written before v2 architecture was finalized, and they flag several areas as unconfirmed (`TODO: Confirm exact domain models`, `TODO: Verify usage`). Where the doc itself wasn't sure a legacy feature was real (CoreProtect/Dynmap), this analysis says so rather than treating it as a confirmed regression. Everything else in the "Confirmed functional gaps" table above was checked against actual legacy source files (`Repository/knk-v2-archive/src/...`), not just the migration docs' prose.

## Suggested next step (not actioned — flagging for a decision)

Given the current focus is finishing and merging Gate Structure Animation, the gaps above (Minigames, Storage/Transport/Generation economy loop, Kits, in-game menus, rank gating, statistics) are all still purely legacy-only. Worth an explicit decision on which of these are actually wanted in v2 at all versus intentionally left behind — several (Minigames, House/Village tiers) may no longer fit the game's current direction.
