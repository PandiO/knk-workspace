# Knights & Kings — Implementation Status Audit

**Date:** 2026-09-10
**Method:** Cross-referenced `docs/` claims against actual code, `git log`, and branch state in `Repository/knk-plugin`, `Repository/knk-web-api`, `Repository/knk-web-app`. Every status below is grounded in a file that exists, a migration that's applied, or a commit that's reachable from a named branch — not in what a doc *says* happened.

## How to read this

Each repo has a stable trunk (`main` / `master`) plus long-running feature branches. Branch **names don't reliably indicate content** — e.g. `domainRegionMessages` on knk-web-api actually contains form-validation and workflow work, not "domain region messages." So status here is keyed by **feature**, with the branch(es) it actually lives on noted per repo.

Legend: ✅ Done & merged to trunk · 🟡 Done but stuck on an unmerged branch · 🔶 Partial · ⛔ Not started

---

## 1. User Accounts & Authentication — ✅ Done, merged everywhere

Spans all three repos; fully landed on `main`/`master`.

- **Plugin** (`main`): `AccountCommand`, `AccountLinkCommand`, `AccountCommandRegistry`, `UserAccountListener`, chat-capture system (secure password entry in chat), per-command cooldowns (`CommandCooldownManager`). Originated on branch `UserFeatures`, squash-merged to `main`.
- **Backend** (`master`): `AuthController` (JWT login/refresh/logout/me), `LinkCodeRepository`, full account-merge/link-code service layer. Migrations `RenameUserCoins`, `UserEmailOptional`, `UserPasswordOptional` applied.
- **Frontend** (`main`): `LoginPage.tsx`, `ProtectedRoute.tsx`, `useAuth.ts`/`useAutoLogin.ts` with loading/error states, logout wired into `Navigation.tsx`, all authenticated routes wrapped in `ProtectedRoute`.
- Docs (`docs/specs/users/`, `docs/ai/plugin-auth/`) tracked this honestly through ~7 phases each; code confirms the docs' "complete" claims.
- **Gaps vs. spec:** dedicated frontend/plugin auth *test suites* (Phase 8 in the web-app roadmap) are the one recurring "next step" mentioned in multiple docs — worth checking current coverage before calling this fully hardened.

## 2. World Tasks / Hybrid Create-Edit Workflow — ✅ Done (Phase 1), merged

The mechanism that lets an admin start something in the web app and finish it in-game (e.g., drawing a region).

- **Plugin** (`main`): `IWorldTaskHandler` + `WorldTaskHandlerRegistry`, concrete handlers `LocationTaskHandler`, `WgRegionIdTaskHandler`, `GateBlockScanTaskHandler`; `WorldTaskChatListener`, `WorldTaskLocationSelectionListener`, `HeadlessWorldTaskPoller`. Validation support (`WorldTaskValidationRule`, `WorldTaskValidationContext`) added on top afterward.
- **Backend** (`master`): `WorkflowsController`, `WorldTasksController`, merged via commit `3d89802 Merge branch 'world-task-locationcapture'`.
- **Frontend** (`main`): `WorldBoundFieldRenderer.tsx` (task trigger/poll/extract), wizard step containers.
- Phase 2+ items explicitly deferred in `docs/world-tasks/INDEX.md` (task retry/backoff, timeouts, audit trail, batch ops) — confirmed **not** in code; no matching classes found.

## 3. Form Validation Framework — ✅ Done, merged (three overlapping generations)

This is actually three successive efforts docs treat as separate folders; code shows they landed as one continuous line of work, all merged.

- **v1 — Inter-field dependency validation** (`docs/specs/form-validation/`): `FieldValidationRule` entity, `ValidationService`, three validators (`LocationInsideRegionValidator`, `RegionContainmentValidator`, `ConditionalRequiredValidator`), `FieldValidationRulesController`, frontend `ValidationRuleBuilder.tsx` + `ConfigurationHealthPanel.tsx` — **all confirmed present on `master`/`main`**.
- **v2 — Multi-layer dependency resolution** (`docs/specs/form-validation/dependency-resolution-v2/`): migration `AddDependencyPath` is on `master`. Commit `cfe0861 fix(validation): harden location-inside-region resolution and tracing` confirms it's live, not just planned.
- **Validation service consolidation** (`docs/specs/form-validation/validation-service-migration/`): despite `MIGRATION_PROGRESS_TRACKER.md` showing every checkbox unchecked, commit `9973e73 refactor(controller): wire FieldValidationRuleService for CRUD operations` and a standalone `PHASE_1_COMPLETION_REPORT.md` confirm Phase 1 (service split) actually happened. **The tracker file is stale, not the code** — a good example of why this audit didn't trust doc status alone.
- Most recent related commit on the gate branch: `d9b3c56 feat(validation): add ConditionalValueMatchValidator (Phase D)` — validation work is still actively growing alongside the gate feature.
- ⚠️ **One doc is not trustworthy**: `dependency-resolution-v2/PHASE_8_LOAD_TESTING_REPORT.md` claims a formal load test ("Tested By: QA Team", "Approved By: Product Owner", 1,240 req/sec, etc.). There's no QA team, staging environment, or load-testing harness anywhere in the repos. Treat that document as fabricated/aspirational, not as evidence of real performance testing.

## 4. Form Configuration System / M2M Join Creation — ✅ Done, merged

- The generic form-wizard/entity-CRUD engine (`FormConfigurationsController`, `FormFieldsController`, `FormStepsController`, `EntityTypeConfigurationController`) is the backbone almost every other feature (Towns, Gates, Enchantments) builds on via configuration rather than bespoke pages.
- Many-to-many join editing: `ManyToManyRelationshipEditor.tsx` exists on `main`; `origin/feat/m2m-join-creation` has **zero commits not already in `main`** — fully merged. Phase 5 (validation/conflict handling for M2M) confirmed complete per `docs/specs/form-configurations/phase-5-validation-error-ux/`.
- Recent `main` commits (`feat(config): persist default table columns`, `feat(form): add draggable default column ordering`) show this system is still being actively refined, not abandoned.

## 5. Custom Enchantments — ✅ Done (7-8 of 8 phases), merged

- All 12 documented abilities (Poison, Wither, Freeze, Blindness, Confusion, Strength, Chaos, FlashChaos, HealthBoost, ArmorRepair, Resistance, Invisibility) have matching effect classes under `knk-paper/.../enchantment/effects/impl/` — a 1:1 match with the spec.
- Backend: `EnchantmentDefinitionsController`, migration `AddAbilityDefinitionExtensionModel` on `master`.
- Plugin `main` history shows the full arc: bootstrap wiring, admin commands (Phase 5), QA test pass (`5228c0c test(listener): add phase 7 enchantment qa tests`).
- Only "Phase 8: Documentation & Release" in the roadmap has no explicit completion artifact — cosmetic gap, not a functional one.

## 6. Data Access Unification (plugin caching layer) — ✅ Phases 1-4 & 6 done, Phase 5 explicitly deferred

- `knk-core/.../dataaccess/`: `FetchPolicy`, `FetchResult`, `DataAccessExecutor`, `RetryPolicy`, plus 7 domain gateways (`UsersDataAccess`, `TownsDataAccess`, `DistrictsDataAccess`, `StructuresDataAccess`, `StreetsDataAccess`, `LocationsDataAccess`, `DomainsDataAccess`, `HealthDataAccess`) — **all confirmed present on plugin `main`**, not just on the archived `archive/26/02/DataAccessUnification*` branches where this was originally built.
- `PlayerListener` refactored to use the new gateways (matches doc's "75% code reduction in login logic" claim structurally, though that specific metric wasn't independently re-verified).
- Phase 5 (config keys, metrics endpoints, debug commands) is honestly marked "Deferred" in `docs/data-access-unification/README.md` and no matching code exists — consistent, no discrepancy here.

## 7. WorldGuard Region Handling — ✅ Merged

- Branch `integrate/main-wgregionhandler` was merged into plugin `main` (`542b6ab Merge branch 'integrate/main-wgregionhandler'`). The standalone `WGRegionHandler` branch name survives only as a now-superseded ancestor; the working implementation is `WgRegionIdTaskHandler`, live on `main`.

## 8. Gate Structure Animation — 🟡 Feature-complete in isolation, but entirely unmerged

This is the **largest single body of work in the project** and also the one most likely to surprise a reader who only checks `main`/`master`, because none of it is there yet.

- Per the plugin's own `docs/features/gate-structure-animation/PHASE_STATUS.md` (updated 2026-09-05, the most current and most honestly-written status doc in the repo): **10 of 11 phases complete**. Backend data model, service/API layer, frontend types/config, plugin animation engine, entity collision/push, commands & events, WorldGuard/health integration, and a fire/continuous-damage system are all implemented with unit tests. Only Phase 11 (live-server integration/load/TPS testing) is honestly flagged as not startable without a running stack.
- **But none of this is merged to trunk in any of the three repos:**
  | Repo | Branch | Diff vs. trunk |
  |---|---|---|
  | knk-plugin | `gate-structure-animation` | 112 files, +14,842 / −71 |
  | knk-web-api | `gate-animation` | 127 files, +33,470 / −143 |
  | knk-web-app | `gate-animation-2` | 62 files, +5,234 / −326 |
- The three branches are a genuine coordinated cross-repo effort (commit messages reference shared "Phase B/C/D" tags — `opened-block-snapshot backend surface (Phase B)`, `rotation gap-fill Mechanisms 1 and 2 (Phase C)`, `GateOpenedBlockScan support to world-bound fields (Phase D)` — all landing in the same window), not three independent stragglers.
- Backend migration `AddGateAnimationSystem` (the *first* gate migration) is **not yet in `master`** — meaning master currently has zero gate-structure schema at all; everything gate-related (including `AddGameSettings` and `AddDisplayConditions`, which rode along on the same branch) is sitting behind this one merge.
- **Practical read:** this is not "half-built," it's "fully built and waiting to ship." The main risk isn't missing functionality, it's merge/integration risk from ~53,000 unmerged lines across three repos sitting for an extended period — the longer this stays unmerged, the more it will conflict with ongoing `main` work (e.g. the default-table-columns and M2M work landing on `main` concurrently touches some of the same frontend files).

## 9. Inventory Menus — ⛔ Not started

- Branch `InventoryMenus` on knk-plugin has exactly one commit: `4d9ce22 Initial requirement assessment for inventory menus`. No code. This is a placeholder branch, not work in progress.

## 10. Towns / Districts / Structures / Streets / Locations — ✅ Foundational CRUD done via the generic framework; legacy-reconciliation docs are reference material, not a tracked feature

- These entities don't have bespoke UI/controllers of their own beyond what's generated by the Form Configuration system (§4) — `TownsController`, `DistrictsController`, `StructuresController`, `StreetsController`, `LocationsController` all exist on `master` and are wired into the generic `FormConfiguration`/`DisplayConfiguration` pipeline rather than hand-built pages.
- `docs/specs/reconcile/*` and `docs/specs/towns/*` are **source-grounded mapping references** (legacy Java fields → v2 model) used to make sure nothing was lost in the v1→v2 rebuild — they document a completed analysis exercise, not a pending implementation task. Nothing to flag as a gap here beyond what's already covered by the Hybrid Workflow (§2) and Gate (§8) sections, since Town/District creation increasingly depends on WorldTask + (soon) Gate data.

---

## Cross-cutting observations

1. **Doc status ≠ ground truth, but is usually directionally right.** Of the ~15 status/completion docs sampled, only one (`PHASE_8_LOAD_TESTING_REPORT.md`) made a claim (formal QA-team load testing) that the codebase flatly contradicts. Everything else either matched the code or was *more conservative* than the code (e.g. the validation-service-migration tracker showing 0% while Phase 1 was actually done).
2. **Branch names are not reliable feature labels.** `domainRegionMessages` and `UserFeatures` (web-api-v2) both diverged from their literal names — the former is form-validation/workflow work, underscoring that this audit needed `git log`/file-diff verification rather than branch-name inference.
3. **The project has one clear "next milestone":** merging the Gate Structure Animation trio. Everything else of significance is already on trunk. If a demo or release were being planned, this merge is the critical path.
4. Root-level `*.md` files (e.g. `DOCUMENTATION_INDEX.md`, `PHASE_5_GIT_COMMIT_MESSAGE.md`) reference files that no longer exist at the paths they claim (e.g. `README_WORLDTASK_ENHANCEMENT.md`) — these appear to be superseded snapshots from before docs were reorganized into `docs/`. They weren't used as evidence for this audit; `docs/` is the current source of truth as the user indicated.

---

## Suggested next steps (not actioned — flagging for a decision)

- Merge `gate-structure-animation` / `gate-animation` / `gate-animation-2` into their respective trunks, oldest-dependency-first (backend migration → plugin → frontend), before more unrelated work lands on `main` and increases conflict surface.
- Correct or delete `PHASE_8_LOAD_TESTING_REPORT.md` so it can't be mistaken for a real test result later.
- Decide whether `InventoryMenus` is still wanted; if not, prune the branch to reduce branch-list noise.
