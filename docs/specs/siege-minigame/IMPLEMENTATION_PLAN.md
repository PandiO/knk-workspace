# Siege Minigame — Implementation Plan

**Status:** Done (MVP). Phases 1–9 are implemented and were **merged into the default branches on 2026-09-26**
(knk-web-api `master` `67f451e`, knk-plugin `main` `716fb3c`, knk-web-app `main` `4fba7d0`) after the developer's two
live smoke-test rounds passed (`docs/reports/2026-09-26-siege-smoke-test-checklist.md`). Phase 10 (Scheduled lobbies)
is post-MVP and not started. The per-phase status blocks below are the historical record; where later work changed a
decision, "Current behaviour" and "Audit" below win.
**Last updated:** 2026-09-26 (merged to trunk; plan audit; earlier the same day: overnight chain phases 6–9 and two
smoke-test rounds)

Ref: `DESIGN.md` (decisions — not restated here), `MENU_TEMPLATES.md`,
`docs/reports/2026-09-25-siege-minigame-gap-analysis.md`. Plan format follows
`docs/specs/kits/IMPLEMENTATION_PLAN.md` (branch `claude/kits`).

## Current behaviour and audit (2026-09-26, after the merge)

**Current behaviour** — later decisions that supersede text in the status blocks below (details: the "Smoke-test
follow-ups" and "Second smoke-test round fixes" bullets under the Phase 9 status block):
- **No scenario-area lockdown.** Non-members are never moved out of or kept out of the area; they can't fight members,
  capture, or use siege gates. `SiegeAreaLockdown`, its listener and `knk.siege.bypass.lockdown` are gone;
  `SiegeScenario.LockdownScenarioArea` has no effect (column kept) and the `LOCKDOWN_WITHOUT_DISTRICTS` warning is
  removed. Supersedes the 7a/7b status text about the lockdown, decision 3 of 7b and 7a's manual step 7.
- **Non-member gate view:** locked siege gates are removed for non-members; walking into a really closed door carries
  them across (TELEPORT pass-through). No pre-lockdown frames, no virtual collision. `PassThroughOnly` still turns it
  off. Supersedes the 7b "Behaviour" paragraph and manual steps 1–3.
- **Respawn:** the spawn choice is remembered (picker at match start; after a respawn only without a stored choice); a
  captured objective resets its choosers to the team default. Supersedes Phase 5 decision 11 and 8b manual step 5.
- **Objectives:** rings, capture distance and banners use the floor under the capture point; banners show the holder's
  full team banner, the v2 gradient while being captured, and are protected. Supersedes Phase 5 decision 16.
- **Capture feedback** (horns, bell, chime every 5 s, particles, chat) — `SiegeCaptureFeedback`.
- **Rewards:** coins × personal salary × rank multipliers; shared `TitleProgression` with scaled bonuses (KNG-16);
  printed in the shared `RewardMessageFormat`.
- **Menus:** `siege.overview`/`siege.information` are Dynamic height; a lobby in cooldown isn't opened; `/siege menu`,
  `/siegemenu`, `/sgm`. Supersedes 8b's fixed heights.
- **Plugin keys:** siege writes accept `Security:PluginApiKey` when `Security:PluginServiceKey` is empty (one key).
- **Scoreboards:** hourly salary and rank refreshes no longer replace a siege member's match scoreboard.

**Audit** (every phase's scope against the code on the merged branches): every Phase 1–9 scope item has code behind
it and every commit the status blocks cite is on the branches. Fixed during the audit: web-api `139fc33`
(Locations/Towns/Districts deletes return 409 instead of 500; `LocationInsideRegionValidator` binding flags),
`d0bac59` (one plugin key; lockdown warning removed), plugin `fda4373` (scoreboard guard, stale comments).
Still open (none blocking):
- **Decisions for the developer:** admin auth on the siege/FormConfig CRUD controllers (DESIGN §11.2 says admin
  auth; none has `[Authorize]` today); whether to drop `LockdownScenarioArea` with the next siege schema change.
- **Not recorded live:** Phase 1's `/knk clans list|banner` check and Phase 3's browser walkthrough with in-game
  "Send to Minecraft" captures (the smoke tests used scenario `test-cinix`); readiness with spatial checks running.
- **Follow-ups:** `AnimateDuringSiege` isn't honoured; `/siege info` is chat-only; `minTitleName` isn't in
  runtime-config; no unique `(SiegeMatchId, UserId)` index on participants; retry policy not configurable; the web-api
  `.sln` points at `tests\` (folder is `Tests/`); ordinary block placement isn't denied during a match; arrows stay in
  the world after the restore; `MenuItemBukkitMapper.applyBannerPatterns` duplicates `BannerDesignBukkitMapper`;
  menu C.1 hub tile without `siege.open-own`/entry hint, C.2 without filler panes, C.3 without gate status; wizard
  follow-ups from Phase 3 ("save and stay", hidden-step defaults, multi-pick M2M); `Clan.DefaultForTownId`'s unique
  index isn't filtered (harmless on MySQL); `ProvisionalRewardCalculator`/`LoggingSiegeMatchesCommandApi` unused;
  leftover `[TEST]` rows in the dev DB (cleanup orders in the Phase 2/3 blocks); optional `SEED_DATA.md`.
- **Stale outside this folder:** `knk-plugin/CLAUDE.md` still says there is no menus package (left for the developer).

## 0. Branching and sequencing

- **One standing branch per repo, `claude/siege-minigame`** (ACTIVE_SESSIONS branch convention, adopted
  2026-09-24) — not one branch per phase.
- **Branch state (2026-09-25):** `claude/siege-minigame` exists in **knk-web-api** (forked from `master`
  `3be3226`) and **knk-plugin** (forked from `main` `be2573d`), pushed, with Phase 8a
  (`claude/inventorymenus`) merged in — see Phase 8. User-features + user-management (`TitleBracket`,
  permission groups, `KnkPermissible`, `AuditLogService`) and gate structure animation are all on trunk
  now, so the branch has every dependency. **knk-web-app** has no branch yet — create
  `claude/siege-minigame` from `main` when Phase 1's web-app part starts. Merge trunk into the branch
  before each phase if trunk has moved.
- **Kits is not a dependency** (DESIGN D2: own gear, no team kits). InventoryMenu Phases 1–9 are a
  dependency only for Phase 8 (Phase 9 = siege 8a, already on the siege branch).
- Add an `ACTIVE_SESSIONS.md` row per phase when starting; move it to "Recently completed" when done.

```
Phase 1 Clan/Banner ─► Phase 2 Siege schema ─► Phase 3 Authoring (web app)
                               │
                               └─► Phase 4 Plugin core (Bukkit-free) ─► Phase 5 Paper runtime ─► Phase 7 Gates ─► Phase 9 Playtest/seed
                                                                              ▲
                               Phase 6 Matches & rewards (API side parallel to 5; plugin side wired in 5)
Phase 8 Menus = InventoryMenu Phase 9 engine extensions ─► siege menu handlers + template seeds   (after 5; independent of 7)
```

---

## Phase 1 — `BannerDesign` + `Clan` (knk-web-api, knk-web-app, knk-plugin)

**Scope** (DESIGN §3.1–3.2)
- web-api: `Models/Clan/{BannerDesign,BannerLayer,Clan}.cs`, `Enums/BannerDyeColor.cs`, a static
  `BannerPatternKeys` list (Bukkit `PatternType` keys, current server version), DTOs, AutoMapper
  profile, repositories/services/controllers (`ClansController`, `BannerDesignsController`), migration
  `AddSiegePhase1ClanBanner`. Unique index on `Clan.DefaultForTownId` (filtered, not null). `Restrict`
  on `Town`/`BannerDesign` FKs; cascade `BannerDesign → BannerLayer`.
- Validation: ≤ 16 layers, `PatternKey` in the known list, colour enum valid.
- web-app: FormConfigurations (`BannerDesign` with owned `Layers` list; `Clan`) authored live via
  `FormConfigBuilder` (no seeder mechanism exists — Items/Kits precedent). Optional nicety, not
  required: a banner preview component.
- plugin: `ClansQueryApi` + DTO/mapper; `BannerDesignBukkitMapper` (→ `BannerMeta` patterns) in
  `knk-paper`, unit-tested for layer order.

**Tests:** service validation (layer cap, unknown pattern, duplicate default-for-town), mapper order.
**Exit:** an admin can create a banner and a default clan for a town in the web app; the plugin can
fetch it and build the banner `ItemStack` (verified with a debug `/knk clans banner <id>` if cheap).

> *Since (2026-09-25/26): steps 1–2 of "To finish Phase 1" were done in Phases 2–3; team banners were seen in game in the siege smoke tests; the `/knk clans` check itself isn't recorded.*

**Phase 1 status (2026-09-25): code complete on `claude/siege-minigame` in all three repos, pushed;
not verified live.** Commits: web-api `3f19c9c`, plugin `11b0f3a`, web-app `ac7ea41`.
- **web-api:** entities/enum/`BannerPatternKeys` (43 keys, paper-api 1.21.10) as designed; migration
  `20260925153517_AddSiegePhase1ClanBanner` (three new tables only). Layers are an **owned child
  collection** (GateStructure → GateDoor pattern), not part of the banner payload: `GET/POST
  /api/BannerDesigns/{id}/layers`, `GET/PUT/DELETE /api/BannerLayers/{id}`; the banner's own create/update
  ignores `layers`. Also `GET /api/BannerDesigns/pattern-keys`, `GET /api/Clans/default-for-town/{townId}`.
  Rules: ≤ 16 layers; pattern keys normalized (`stripe_top` → `minecraft:stripe_top`) and whitelisted;
  omitted `sortOrder` appends on top; `SortOrder` deliberately **not unique** (so two layers can be
  swapped one edit at a time; render order is `(SortOrder, Id)`); read DTO flags
  `exceedsSurvivalLoomLimit` (> 6); banner delete while a clan uses it → 409; second default clan for a
  town → 409; `ChatColor` limited to the 16 Bukkit colour names; a `DefaultForTownId` of 0 means none.
  Tests: `BannerDesignServiceTests` + `ClanServiceTests` (30), suite 443/448 with the same 5
  pre-existing failures as `master`.
- **plugin:** `ClansQueryApi` port + `ClansQueryApiImpl` (404 → null), `KnkClan`/`KnkBannerDesign`/
  `KnkBannerLayer` (layers always sorted), `KnkBannerDesign.toPatternSpec()` → the InventoryMenu
  `BannerPatternSpec`, so 8b's menus and item building share one form. knk-paper
  `paper/clan/BannerDesignBukkitMapper` + `/knk clans list|info|banner|design <id>` (`knk.admin.clans`).
  No DataAccess/cache gateway yet — that's Phase 4's `SiegeDataAccess`. Tests green: knk-core 516 /
  api-client 30 / knk-paper 249.
- **web-app — plan correction:** the plan said "FormConfigurations authored live, no web-app code". Not
  quite: the FormWizard/dashboard only work for entity types registered in
  `src/utils/entityApiMapping.ts` (five switches) and `src/config/objectConfigs.tsx`, so Phase 1 added
  `bannerDesignClient`/`bannerLayerClient`/`clanClient`, `types/dtos/clan/ClanDtos.ts` and those
  registrations. Every later siege entity (Phase 2/3) needs the same wiring. The typecheck is clean; the 4
  failing FormWizard test suites fail identically on `main`.
- **To finish Phase 1 (developer, needs the dev DB + server):**
  1. `dotnet ef database update` in knk-web-api (on this branch that also applies the 8a migration).
  2. In FormConfigBuilder author **BannerLayer** (`BannerDesignId` Object → BannerDesign as the parent
     link, `SortOrder` Integer optional, `PatternKey` String — see `GET /api/BannerDesigns/pattern-keys`,
     `Color` Enum), **BannerDesign** (`Name`, `BaseColor` Enum, `Layers` List → BannerLayer with
     settingsJson `{"ownedChildCollection": true}`), **Clan** (`Name`, `IsNpc`, `ChatColor` String,
     `BannerDesignId` Object → BannerDesign, `DefaultForTownId` Object → Town).
  3. Create a banner (save, then add layers) and a default clan for a town; in-game `/knk clans list`,
     `/knk clans banner <id>` and check the banner matches.
- **Follow-ups (not blocking):** `PatternKey` and `ChatColor` are free-text fields in the wizard
  (validated server-side) — a picker for `pattern-keys` would be nicer; `MenuItemBukkitMapper`
  duplicates the few lines of pattern application now in `BannerDesignBukkitMapper` (could share).

## Phase 2 — Siege schema, services, API (knk-web-api)

**Scope** (DESIGN §3.3–3.10, §11.2)
- `Models/Siege/`: `SiegeScenario`, `SiegeScenarioDistrict`, `SiegeTeam`, `SiegeSpawnpoint`,
  `SiegeObjective`, `SiegeScenarioGate`, `SiegeLobby`, `SiegeLobbyScenario`, `SiegeConfiguration`
  (singleton, seeded with legacy defaults), `SiegeMatch`, `SiegeMatchParticipant`,
  `SiegeMatchObjectiveResult`, `SiegeMatchGateSnapshot` (scenario flags `LockdownScenarioArea`,
  `AllowRecapture`, `EnchantDropsEnabled`; `SiegeConfiguration` incl. enchant-drop tunables and
  `NonMemberGateView`); enums `SiegeTeamRole`, `SiegeLobbyMode`,
  `SiegeMatchStatus`, `SiegeMatchEndReason`. `[FormConfigurableEntity]` + `[RelatedEntityField]` /
  `[NavigationPair]` on authored entities only.
- Migration `AddSiegePhase2Schema`, including **`GateStructure.CurrentSiegeId` → FK `SiegeMatch.Id`
  (`SetNull`)**. Delete rules per DESIGN §3 (owned children cascade; shared rows `Restrict`).
- `SiegeScenarioService`: CRUD + the full §3.9 validation (reusing `LocationInsideRegionValidator` /
  `RegionContainmentValidator` logic for spatial checks) + `GetReadinessAsync`.
- `SiegeLobbyService`: CRUD + `GetRuntimeConfigAsync` (enabled lobbies, rotation, **ready** scenarios
  only, team identity resolved from Clan).
- Controllers: `SiegeScenariosController` (incl. owned-child endpoints for teams/spawnpoints/objectives
  following the `GateStructures/{id}/doors` pattern), `SiegeLobbiesController`,
  `SiegeConfigurationController`, `GET /api/siege-scenarios/{id}/readiness`,
  `GET /api/siege-lobbies/runtime-config`. Match endpoints come in Phase 6.

**Tests:** readiness matrix (each §3.9 rule failing alone), identity resolution (clan / override /
ad-hoc), delete behaviour (deleting a scenario leaves `GateStructure`/`Location`/`Clan` intact; deleting
a referenced gate is refused), runtime-config excludes unready scenarios.
**Exit:** Swagger round-trip of a complete scenario graph; readiness goes green only when valid.

**Phase 2 status (2026-09-25): code complete on `claude/siege-minigame` (knk-web-api), pushed; migration
applied to the dev DB and the API round-trip run live with test data (see "Applied to the dev DB" below).** Commits: `366f9e4` (schema + migration), `a58d388` (services/API),
`a5e73e8` (tests). `origin/master` hadn't moved since the branch fork, so no trunk merge. Local `master`
has the unpushed promotion-sync merge `2d256eb`; it wasn't merged here, to avoid publishing unpushed trunk
commits. It has no migration, so it will merge cleanly later.
- **Schema** (`Models/Siege/*`, `Enums/SiegeEnums.cs`, one commented "Siege Phase 2" block in
  `KnKDbContext`, migration `20260925162632_AddSiegePhase2Schema`: 13 new `siege_*` tables plus the
  `gate_structures.CurrentSiegeId` index/FK). `has-pending-model-changes` is clean. The migration clears
  any stale placeholder `CurrentSiegeId` values before it adds the FK (hand-added `UPDATE`). Delete rules:
  owned children cascade. Town/District/Location/GateStructure/Clan/BannerDesign/TitleBracket/User are
  `Restrict`. Team references from objectives, gates and match history are `SetNull`. `SiegeMatch`
  restricts its lobby/scenario. `CurrentSiegeId` is `SetNull`, with no navigation property (the gate's
  form metadata and DTOs are unchanged). `[FormConfigurableEntity]` is on the 8 authored entities
  (including the 3 join entities), not on `SiegeConfiguration` or `SiegeMatch*`.
- **Endpoints** (PascalCase `api/[controller]` like every other controller). The two DESIGN §11.2
  kebab-case paths are also served:
  - `SiegeScenarios`: GET, GET `{id}`, POST, PUT `{id}`, DELETE `{id}`, POST `search` (filter `townId`),
    GET/POST `{id}/teams`, GET/POST `{id}/objectives`, GET `{id}/readiness` = GET
    `/api/siege-scenarios/{id}/readiness`.
  - `SiegeTeams`: GET/PUT/DELETE `{id}`, POST `search` (filter `siegeScenarioId`, the picker for holder
    and owner teams), GET/POST `{id}/spawnpoints`.
  - `SiegeSpawnpoints` and `SiegeObjectives`: GET/PUT/DELETE `{id}`.
  - `SiegeLobbies`: CRUD + `search`, plus GET `runtime-config` = GET `/api/siege-lobbies/runtime-config`.
  - `SiegeConfiguration`: GET/PUT.

  Scenario districts/gates and lobby rotation are M2M joins in the parent payload (replace-set; `null`
  keeps them, `[]` clears them). Teams, spawnpoints and objectives are owned children, and the parent's
  create/update ignores them. World-bound locations follow `GateStructureDto`: pass `xLocationId`, or an
  inline `xLocation` (created when it has no id).
- **Readiness** (`GET …/readiness` → `isReady`, `errors[]`, `warnings[]` with stable `code`s from
  `SiegeReadinessCodes`, plus `spatialChecksRun`). There are 15 structural rules (`SiegeScenarioReadiness`,
  a pure class shared with runtime-config) and 3 spatial ones. The spatial rules check the hub, the
  spawnpoints and each objective's capture point (its own location, else its gate's) against the town's
  WorldGuard region through the registered `LocationInsideRegion` `IValidationMethod` (the real validator,
  so the plugin's region endpoint). Warnings never block: no instant-victory objective, lockdown with no
  districts, spatial checks unavailable.
- **Runtime-config**: the global `SiegeConfiguration` plus every enabled lobby with its rotation. Each
  rotation scenario is fully resolved: team identity (team value, else Clan), the "first Defender"
  default for objective holders and gate owners, objective capture point from the gate, and
  `isObjectiveGate`. Only ready scenarios are included; unready ones appear per lobby under
  `skippedScenarios`, with their errors.
- **Delete guards on shared rows:** `GateStructureService` (selected gate / objective gate / match
  snapshot), `ClanService` and `BannerDesignService` (used by a siege team) now throw → 409
  `BusinessRuleViolation` instead of a raw FK error. `GateStructuresController` and `ClansController`
  gained that catch.
- **Tests:** 133 new (`SiegeScenarioReadinessTests`, `SiegeScenarioServiceTests`,
  `SiegeDeleteBehaviourTests`, `SiegeLobbyServiceTests`, `SiegeConfigurationServiceTests`,
  `Api/SiegeApiRoundTripTests`). The readiness matrix breaks each rule alone: exactly one error, 15
  structural + 4 spatial cases. There are delete-rule assertions for every siege FK, and InMemory
  real-repository tests for scenario/team deletion, runtime-config and identity. The round-trip test runs
  the Swagger script below through the real controllers with the same JSON bodies. Suite **576/581**: the
  5 failures are the ones that also fail on `master` (ClientActivityStore, 2× PathResolution `Town.*`,
  FieldValidation ConditionalRequired, FormSubmissionProgressRepository).
- **Decisions taken without the developer (review; each is cheap to change):**
  1. **Spatial checks don't block when they can't run.** A missing town region or an unreachable
     plugin/server is a warning, and `spatialChecksRun = false`, so authoring without the Minecraft server
     can still reach "ready". A point that *is* checked and found outside is an error. Saves never call
     the plugin; spatial rules exist only in readiness.
  2. **Runtime-config uses the structural rules only.** The spatial check calls the plugin's region
     endpoint, and the plugin is the one calling runtime-config (possibly during `onEnable`), so it stays
     an authoring-time check.
  3. **`RegionContainmentValidator` isn't used.** District and gate membership come from the
     authoritative FKs (`District.TownId`, `Structure.DistrictId`), which the district/gate forms already
     validate spatially. `LocationInsideRegion` is reused for points.
  4. **"Selected gates belong to the scenario's town/districts"** means: the gate's district must be one
     of the scenario's districts when any are selected, else any district of the town.
  5. **Match history pins its lobby/scenario (`Restrict`).** Deleting a played scenario or lobby → 409
     ("remove it from rotations / disable it instead"). History keeps rows when teams/objectives are
     edited (`SetNull`).
  6. **Deleting a team** resets objective holders and gate owners that named it to the first-Defender
     default (`SetNull`) instead of refusing. Deleting a scenario silently drops it from lobby rotations
     (cascade).
  7. **`Scheduled` lobby mode is refused (400)** until Phase 10, rather than saving a lobby that would
     never run. Lobby key: `[a-z0-9_-]{1,64}`, stored lowercase, unique (409). `MatchmakingSeconds` ≥ 60,
     `VoteCandidateCount` 1–3, weights ≥ 1. Unready scenarios may sit in a rotation.
  8. **Also checked on save** (not only in readiness): an ad-hoc team needs name + colour + banner; an
     objective's gate must already be in the scenario's Gates (Gates is step 6, Objectives step 7);
     holder/owner teams must belong to the scenario; `InitialState`/`GateStateOnCapture` must be OPEN or
     CLOSED; districts must be in the town and gates in the area. Removing a gate that an objective uses
     is still allowed; readiness flags it.
  9. **`SiegeConfiguration`** is seeded lazily with the legacy defaults on first GET (the
     SalaryConfiguration precedent, no migration `InsertData`). PUT is partial. List settings are CSV
     columns exposed as arrays. Field naming: `KillAnnouncementThresholds` (5,10,15) +
     `KillStreakAnnounceAbove` (3), `EnchantDropChancePerMille` (30). Two new values have no legacy
     equivalent: **`MaxBooksAlive = 10`** (v2 had no cap) and **`AllowedEnchantmentKeys`** (v2 picked from
     every weapon/wearable/bow/breakable enchantment at runtime; the default is that set's combat subset,
     without curses or mending). Validation: voteClose ≥ draw ≥ hub ≥ teamSplit ≥ 1, headshot 1–10,
     levels 1 ≤ min ≤ max ≤ 255.
  10. **No `[Authorize]`** on the siege controllers, including runtime-config. That matches every
      existing FormConfig CRUD controller (Phase 1 too); see the doc discrepancy below.
- **Doc/code discrepancies found:**
  - DESIGN §11.2 says the CRUD endpoints "require admin auth like every other FormConfig entity", but no
    FormConfig CRUD controller has `[Authorize]` (only `Users`/`Auth`/`AdminClients` do). Either the doc
    or the whole CRUD surface needs a decision; Phase 6's service-client auth on match writes is
    unaffected.
  - DESIGN §11.2 writes kebab-case routes, while every controller is PascalCase `api/[controller]`. Both
    are served for the two named endpoints; the rest are PascalCase.
  - DESIGN §8.5 says `IsSiegeObjective` is removed from the gate's admin form in "Phase 2", but that is
    FormConfiguration data (web-app side), and this plan lists it under Phase 3. It's left for Phase 3;
    Phase 2 only updated the model comment.
  - DESIGN §4 says the `SiegeConfiguration` form is "like `SalaryConfiguration`", but the web-app has **no
    UI for `SalaryConfiguration`** (raw GET/PUT only). Phase 3 needs a small singleton page or must defer
    it (Swagger PUT works meanwhile).
  - Code bug, not fixed (outside scope, one line): `LocationInsideRegionValidator.ExtractPropertyValue`
    calls `GetProperty(name, IgnoreCase | Public)` without `BindingFlags.Instance`, so a plain entity
    object's properties are never found (dictionaries/JSON work). Siege passes the town as a dictionary
    for that reason.
- **Applied to the dev DB and verified live (2026-09-25, developer-approved):**
  - Backup first: `C:\Users\Pandi\Documents\Werk\db-backups\knightsandkings_dev_v2_before_siege_phase2_20260925_192041.sql`
    (full `mysqldump`). Phase 1 and 8a were already applied, so `dotnet ef database update` applied only
    `AddSiegePhase2Schema`. No gate had a stale `CurrentSiegeId`. All 31 siege FK delete rules were
    checked in `information_schema`.
  - **Test data**, created through the running API (port 5099, this branch's Release build), which ran the
    Swagger script below live against real Cinix data:
    - banners `[TEST] Cinix crown` (id 1, 2 layers) and `[TEST] Raider skull` (id 2)
    - clan `[TEST] Cinix Garrison` (id 1, **default clan for Cinix**, town 5)
    - Locations 62–65: hub, two spawns and the Keep objective, copied from Market/Keep/Merchant Square and
      the Keep Stair House coordinates
    - scenario `[TEST] Siege of Cinix` (id 1): districts 6/7/8; Defender team 1 (clan-sourced) and Attacker
      team 2 (ad-hoc "Raiders"); a spawnpoint each; South Gate (13) and Northern Gate (14) selected;
      objectives "The Keep" (instant victory) and "South Gate" (gate 13, the gate's location as capture
      point)
    - **enabled** lobby `[TEST] Siege — Cinix` (id 1, key `test-cinix`)
    - `SiegeConfiguration` seeded with the defaults

    Readiness went red → green. Runtime-config resolved both identities and the first-Defender defaults.
    `DELETE GateStructures/13` and `DELETE Clans/1` returned 409. The plugin wasn't running, so readiness
    carries the `SPATIAL_CHECKS_UNAVAILABLE` warning; start the server and re-check readiness to have the
    points verified against the Cinix region. **Cleanup** (API, in this order): `DELETE`
    `SiegeLobbies/1`, `SiegeScenarios/1`, `Clans/1`, `BannerDesigns/1` and `/2`, `Locations/62`–`65`.
  - Existing-data typo, **fixed 2026-09-25 (developer-approved)**: Location 6 ("Market Square", Cinix's
    own location) had world `world_KNK_DEV`, while every other location uses `world_KNK-DEV`. It was
    updated to `world_KNK-DEV`; no other `World` column in the DB had the misspelling.
  - **Still open from Phase 1, now folded into Phase 3:** the dev DB has **no FormConfigurations for
    `BannerDesign`, `BannerLayer` or `Clan`** yet (Phase 1's manual step 2 was never done). Phase 3's team
    form needs the Clan and BannerDesign pickers, so author them first.
- **Swagger script** (the manual version of the round-trip; already run live, see above):
  1. (Already done: `dotnet ef database update`.)
  2. Swagger round-trip. Prerequisites: a Town with a `WgRegionId`, a District of that town, a
     GateStructure in that district that has a Location, the Phase 1 Clan (+ its banner) and a second
     BannerDesign, and 5 Locations (`POST /api/Locations`, or capture them in-game). Replace `{…}` with
     your ids:
     1. `POST /api/SiegeScenarios` `{ "name": "Siege of Cinix", "townId": {town}, "hubLocationId": {hub},
        "playersMin": 2, "playersMax": 20, "districts": [ { "districtId": {district} } ] }` → 201, id `{s}`
     2. `GET /api/siege-scenarios/{s}/readiness` → `isReady: false` (`TEAMS_MIN_TWO`, `DEFENDER_REQUIRED`,
        `OBJECTIVES_MIN_ONE`)
     3. `POST /api/SiegeScenarios/{s}/teams` `{ "role": "Defender", "allianceGroup": 1, "clanId": {clan} }`
        → `{t1}` (`resolvedName` = the clan's name), then `{ "role": "Attacker", "allianceGroup": 2,
        "name": "Raiders", "chatColor": "RED", "bannerDesignId": {banner2} }` → `{t2}`
     4. `POST /api/SiegeTeams/{t1}/spawnpoints` `{ "name": "Keep", "locationId": {loc1} }`, then
        `POST /api/SiegeTeams/{t2}/spawnpoints` `{ "name": "Camp", "locationId": {loc2} }`
     5. `PUT /api/SiegeScenarios/{s}`: the step-1 body plus `"gates": [ { "gateStructureId": {gate},
        "initialState": "CLOSED", "damageable": true } ]` → 204
     6. `POST /api/SiegeScenarios/{s}/objectives` `{ "name": "Keep", "instantVictory": true, "locationId":
        {loc3} }`, then `{ "name": "Gatehouse", "gateStructureId": {gate} }`
     7. `GET /api/siege-scenarios/{s}/readiness` → `isReady: true`, and `spatialChecksRun: true` if the
        server + plugin are up. Otherwise `SPATIAL_CHECKS_UNAVAILABLE` is a warning.
     8. `GET /api/SiegeScenarios/{s}` → the full graph (2 teams with a spawnpoint each, 2 objectives,
        1 gate, 1 district)
     9. `POST /api/SiegeLobbies` `{ "name": "Siege — Cinix", "key": "cinix", "isEnabled": true, "rotation":
        [ { "siegeScenarioId": {s}, "weight": 1 } ] }`, then `GET /api/siege-lobbies/runtime-config` → the
        lobby with the resolved scenario (holders/owners = `{t1}`)
     10. `GET /api/SiegeConfiguration` (creates the defaults), then `PUT` `{ "headshotMultiplier": 1.0 }`
         → other values unchanged
     11. `DELETE /api/GateStructures/{gate}` → 409 `BusinessRuleViolation`
     12. `PUT /api/SiegeScenarios/{s}` with `"gates": []` → readiness shows `OBJECTIVE_GATE_NOT_SELECTED`
         (red again)
     13. `DELETE /api/SiegeLobbies/{lobby}`, then `DELETE /api/SiegeScenarios/{s}` → 204; the gate,
         locations and clan still exist
- **Follow-ups (not blocking):** the delete endpoints for `Locations`/`Towns`/`Districts`/`TitleBrackets`
  don't catch `DbUpdateException`, so deleting one that a scenario still uses returns 500 rather than 409
  (the FK `Restrict` still protects the data). Locations captured for a deleted scenario stay behind as
  orphans (shared rows are never cascaded). Runtime-config doesn't yet list the *other* gates in the
  scenario area that §8.1 forces open; add that in Phase 7 if the plugin's gate cache can't derive it.
  Fix the `ExtractPropertyValue` binding-flags bug above.
- **Note for Phase 3 (plan correction, same as Phase 1's):** every new `[FormConfigurableEntity]` needs
  web-app wiring before the FormWizard/dashboard can use it: an API client, registration in
  `src/utils/entityApiMapping.ts` (all five switches) and in `src/config/objectConfigs.tsx`. That covers
  `SiegeScenario`, `SiegeTeam`, `SiegeSpawnpoint`, `SiegeObjective` and `SiegeLobby`. The three join
  entities need no client (the ItemBlueprint join precedent), and `SiegeConfiguration` needs its own page.
  Client shapes: create a team with `POST SiegeScenarios/{siegeScenarioId}/teams`, a spawnpoint with
  `POST SiegeTeams/{siegeTeamId}/spawnpoints`, and an objective with
  `POST SiegeScenarios/{siegeScenarioId}/objectives`. Get/update/delete use `SiegeTeams|SiegeSpawnpoints|
  SiegeObjectives/{id}` (the `BannerLayerClient` shape). Only teams have a search endpoint; like
  `bannerlayer`/`gatedoor`, spawnpoints and objectives don't.

## Phase 3 — Authoring in the web app (knk-web-app + FormConfig data)

**Scope** (DESIGN §4)
- Author FormConfigurations: `SiegeScenario` (8 steps), `SiegeTeam` (child, with owned `Spawnpoints`),
  `SiegeSpawnpoint` (child, `Location` world-bound → `LocationSelection` WorldTask), `SiegeObjective`
  (child, gate picker or world-bound location), `SiegeScenarioGate` M2M join fields,
  `SiegeLobby` (+ rotation M2M with `Weight`), `SiegeConfiguration` singleton form.
- **Verification items (resolve first; each may become a small web-app change):**
  1. Two-level owned nesting (Scenario → Team → Spawnpoint) via `ownedChildCollection` List fields,
     including the `ChildFormModal` own-`WorkflowSession` fix from gate QoL 5.11 at depth 2.
  2. Clan picker filtered or ordered by the scenario's `TownId` (form-validation dependency resolution
     v2 may already support a dependent filter; otherwise order by "default for this town" server-side).
  3. M2M join editor with 3 join fields incl. a picker (`InitialOwnerTeamId`) scoped to the scenario's
     teams.
  4. Readiness panel: a read-only step rendering `GET …/readiness` (new small component if no existing
     "display-only" step type fits).
- Remove `IsSiegeObjective` from `GateStructure`'s "Siege Behaviour" form step (DESIGN §8.5 — now
  runtime-maintained).

**Exit:** an admin authors a complete scenario end-to-end in the browser, capturing hub/spawn/objective
points in-game via "Send to Minecraft", and sees readiness go green.

**Phase 3 status (2026-09-25): code complete on `claude/siege-minigame` (knk-web-app + a small knk-web-api
change), pushed; FormConfigurations authored in the dev DB. Not yet clicked through in a browser, and
nothing captured in-game (no Minecraft server) — see "Manual steps left".** Commits: web-app `dbf2fb6`
(clients/DTOs/wiring), `b90d41f` (FormWizard engine: verification items 1–4), `4fc63e6` (API error reasons),
`0fe5174` (SiegeConfiguration page), `d85c2d7` (page tests); web-api `c8ab607` (picker filters +
TitleBrackets). Both branches were current with trunk (`origin/master` hadn't moved; web-api was
fast-forwarded to the pushed `11788fe` merge first). Payloads and ids: `PHASE_3_FORMCONFIGS.md`.
- **Phase 1 leftover done:** FormConfigurations **BannerLayer (23)**, **BannerDesign (24)** (`Layers` = owned
  List, the GateDoor precedent), **Clan (25)**. `PatternKey` and `ChatColor` are dropdowns (String +
  `enumValues`), which closes Phase 1's "free-text field" follow-up.
- **Siege FormConfigurations:** join entries **SiegeScenarioDistrict (26)**, **SiegeScenarioGate (27)**,
  **SiegeLobbyScenario (28)**; **SiegeSpawnpoint (29)**, **SiegeTeam (30)**, **SiegeObjective (31)**,
  **SiegeScenario (32)**, **SiegeLobby (33)**. All pass the configuration health check. Scenario steps:
  General · Districts (M2M) · Hub & entry · Match length · Rewards · Teams (owned) · Gates (M2M, 3 join
  fields) · Objectives (owned) · Readiness. Objective: General · Capture point · Gate behaviour (shown only
  when a gate is picked). Lobby: General · Timings · Voting · Rotation (M2M + Weight).
- **`IsSiegeObjective` removed** from GateStructure form 9's "Siege Behaviour" step (form field 92 deleted by
  the PUT; nothing referenced it; the other field ids are unchanged).
- **Web-app wiring:** clients `siegeScenarioClient`/`siegeTeamClient`/`siegeSpawnpointClient`/
  `siegeObjectiveClient`/`siegeLobbyClient`/`siegeConfigurationClient`/`titleBracketClient`,
  `types/dtos/siege/SiegeDtos.ts`, all five `entityApiMapping` switches (spawnpoint/objective have no search,
  like bannerlayer), `objectConfigs` entries for `siegescenario`/`siegelobby` + picker columns for
  `siegeteam`/`siegelobby`/`titlebracket`. Teams, spawnpoints and objectives have no dashboard entry of their
  own (BannerLayer precedent: owned children, edited inside the scenario).
- **SiegeConfiguration:** built, not deferred — `/admin/siege-configuration` (nav "Siege Settings"),
  `pages/admin/SiegeConfigurationPage.tsx`: grouped fields, lists as CSV/one-per-line, Save sends only the
  changed values (partial PUT), shows the API's range errors.
- **web-api (`c8ab607`):** GateStructure search `filters.townId` and `filters.siegeScenarioId` (gates saved in
  that scenario); Clan search `filters.preferTownId` (the town's default clan first, then the usual sort —
  orders, doesn't filter); a read-only `TitleBracketsController` (GET, GET {id}, POST search) because no
  title-bracket endpoint existed for the scenario's `MinTitleBracketId` picker. 7 tests.
- **Verification items:**
  1. **Two-level owned nesting — works** with the existing `ownedChildCollection` + `ChildFormModal`: each
     modal creates its own WorkflowSession (the gate QoL 5.11 fix holds at depth 2), so "Send to Minecraft"
     renders on a spawnpoint opened from a team opened from the scenario, and the spawnpoint is created
     under that team. Proven by `FormWizard.siegeNesting.ui.test.tsx` (real `ChildFormModal` at both depths).
     Small fixes: an updated owned child's card re-reads the entity (a clan team shows its resolved name,
     not the raw payload); cards/pickers label entities by name/displayName/`resolvedName`.
  2. **Clan picker — ordered by the scenario's town.** Neither `ObjectField` nor `PagedEntityTable` could pass
     any filter (form-validation dependency resolution v2 feeds validation rules/placeholders, not pickers), so
     there is now a generic FormField setting: `settingsJson.pickerFilters` maps search filters to
     `{parent.X}` (the record a child/join form was opened from — the wizard now passes this `parentContext`
     for edits too, not just creates), `{X}` (the form's own field) or literals; `?` = optional; an unresolved
     required token (e.g. an unsaved parent's -1 id) blocks the picker with a message instead of listing every
     row (the paged searches ignore non-positive ids). The team form's `ClanId` uses
     `{"preferTownId": "{parent.TownId?}"}`. Standalone team edits (no parent) get the plain order.
  3. **M2M with 3 join fields — works after three engine fixes** (`FormWizard.siegeGatesJoin.ui.test.tsx`):
     saved join rows were never hydrated for edit (every saved gate/district showed "Missing Entity" and
     "Edit Join Entry" started from the form defaults) — now `utils/forms/manyToManyEditLoad.ts` re-keys them
     to metadata names and builds `relatedEntity` from the row's `<nav>Name`, and the join form is seeded
     with the row's saved values (initial values now win over a field's untouched default); the M2M editor
     compared metadata types against the lowercase route name, so it resolved the parent's own FK as the
     related side (the Items Phase 2 bug class — now passed the real type); enum fields can keep an authored
     subset (`"enumValuesSubset": true`) so `InitialState`/`GateStateOnCapture` offer only OPEN/CLOSED. The
     owner-team picker uses `{"siegeScenarioId": "{parent.id}"}` (blocked until the scenario is saved).
  4. **Readiness panel — new small component.** No display-only step type existed. A field whose settingsJson
     has `{"displayPanel": "siegeScenarioReadiness"}` renders `components/siege/SiegeReadinessPanel.tsx`
     instead of an input; it sits on the read-only, not-required `Id` field (the template validator requires a
     real property, and `Id` never changes the payload). Shows ready/not ready, errors and warnings with code
     and entity (`TEAM_NO_SPAWNPOINT · Team #2`), the spatial-checks status, and Re-check; before the first
     save it says to Submit first. It checks the *saved* scenario and says so.
- **Proof against the live API** (dev DB, API on :5099): a temporary harness (not committed) rendered the real
  FormWizard with the live FormConfigurations, metadata and entities, clicked Next through every step to
  Submit, and sent the payload to the API exactly as the web-app clients do.
  - **Scenario 1 is editable through the forms:** no-op edits of scenario 1, teams 1–2, spawnpoint 1,
    objectives 1–2, lobby 1, banner 1 and clan 1 all saved (204) with **zero changed fields**; readiness
    unchanged (ready + `SPATIAL_CHECKS_UNAVAILABLE`).
  - **Create path:** scenario **2** `[TEST] Siege of Cinix (forms)` (districts 6/7/8, gate 13, hub = new
    location 66), Defender team 3 (clan 1) + ad-hoc Attacker team 4 "Forms Raiders", spawnpoints on new
    locations 67/68, objectives 3 "The Keep (forms)" (instant victory, location 69) and 4 "South Gate
    (forms)" (gate 13, holder team 3, CLOSED on capture — the conditional step showed), and **disabled** lobby
    **2** `test-forms` with scenario 2 (weight 2). Readiness went red (`TEAMS_MIN_TWO`, `DEFENDER_REQUIRED`,
    `OBJECTIVES_MIN_ONE`) → **ready**. Picker selections and in-game captures were simulated by pre-filling
    the values (existing town/districts/gate/clan/banner; new inline locations standing in for captures),
    so the browser clicks themselves are still the developer's to do.
  - An ad-hoc team without a banner returns `400 text/plain` "A team without a clan needs a name, a chat
    colour and a banner." — before `4fc63e6` the web-app showed only "HTTP 400: Bad Request"
    (`serviceCall` read `result.message` only); now both the child modals and the top-level "Submit failed"
    dialog show the API's reason.
  - Cleanup of the create-path data (API, in this order): `DELETE SiegeLobbies/2`, `SiegeScenarios/2`,
    `Locations/66`–`69`. Scenario 1's cleanup order (Phase 2 status) is unchanged.
- **Tests:** web-app typecheck clean; `npm run test:ci` **241 passed / 16 failed in 10 suites** — the failing
  tests are *identical* (names diffed) to the unchanged tree (`git stash`: 220 passed / 16 failed), +21 new
  tests in 7 new suites. web-api **583/588**, the same 5 failures as before (+7 new). **Baseline
  correction:** the brief said "the 4 failing FormWizard suites"; on the unchanged tree 10 suites fail — the 4
  FormWizard ones plus ConfigurationHealthPanel ×2, PathBuilder, LoginForm, useEnrichedFormContext and
  authService.
- **Decisions taken without the developer (review; each is cheap to change):**
  1. **The scenario form has 9 steps, not 8:** an M2M step can hold nothing else, so Districts is its own
     step after General (DESIGN §4 put it inside General).
  2. **Picker scoping is a generic `pickerFilters` FormField setting** (above) rather than per-entity code.
  3. **Clan picker orders, doesn't filter** (any clan may still be chosen; the town's default is first).
  4. **Gate pickers are narrowed server-side:** the Gates step lists the town's gates; an objective's gate
     picker lists only gates *already saved* in the scenario. The Phase 2 save rule (an objective's gate must
     be in the saved Gates) is kept; the Gates/Objectives step descriptions say to Submit after adding gates.
  5. **Owned-child parent links are read-only** (prefilled from the parent; children are only created from
     their parent's form).
  6. **Read-only `TitleBracketsController`** added. Quirk: the lowest bracket ("Serf") has id 0, which the API
     treats as "no minimum" — equivalent for a *minimum* title.
  7. **Lobby `Mode` offers only `Continuous`** (the API refuses `Scheduled` until Phase 10).
  8. **Engine-wide behaviour changes** (all forms, not only siege): initial values beat untouched defaults;
     an edit-loaded FK whose DTO has only `<nav>Name` shows `{id, name}`; the API's error text is shown on
     failed saves.
- **Doc/code discrepancies found:**
  - DESIGN §4: scenario "8 steps" with Districts in General → 9 steps (decision 1).
  - DESIGN §4: `SiegeConfiguration` "singleton form (like SalaryConfiguration)" → a dedicated page; there is no
    SalaryConfiguration UI (already flagged in Phase 2).
  - DESIGN §8.5 says `IsSiegeObjective` leaves the gate form in "Phase 2" — done here in Phase 3.
  - Web-app test baseline: 10 failing suites, not 4 (above).
  - Workspace gotcha (ACTIVE_SESSIONS, Phase 1): "`git add Tests/...`" only works for files already tracked. A
    **new** file under `tests/` isn't matched by either casing; stage it with `git hash-object -w <disk path>`
    + `git update-index --add --cacheinfo 100644,<hash>,Tests/<path>`.
- **Manual steps left (developer; needs the web app, API, and the Minecraft server + knk-plugin for
  captures) — browser walkthrough:**
  1. **Banner** — `/forms/bannerdesign` → Name, Base colour → Submit. Open it again (dashboard → Edit) → Layers
     → Create New → Pattern, Colour → Submit (the layer saves immediately) → repeat, close.
  2. **Clan** — `/forms/clan` → Name, NPC, Chat colour → Identity: Banner, Default clan for town → Submit.
  3. **Scenario, first save** — `/forms/siegescenario`: General (Name, Town via Select instance) → Districts:
     "Create New Join Entry" → District (only the town's districts are listed) → Submit the entry; repeat →
     Hub & entry: Hub location → **Send to Minecraft**, stand on the hub spot in-game and confirm → players,
     minimum title (optional), rules → Match length, Rewards (defaults are fine) → Teams/Gates/Objectives: Create
     New is disabled and the owner-team picker says to save first — expected → Readiness: "Submit to save the
     scenario first" → **Submit**.
  4. **Teams** — reopen the scenario (dashboard → Edit) → Teams → Create New: Role Defender, Alliance group 1,
     Clan (the town's default clan is listed first) → Submit. Create New again: Role Attacker, Alliance group 2,
     no clan → Name, Chat colour, Banner → Submit. For each team: **Edit instance** → Spawnpoints → Create New →
     Name → Location → **Send to Minecraft** (stand on the spawn) → Submit; close the team modal (saved already).
     Readiness now: `OBJECTIVES_MIN_ONE` (and `LOCKDOWN_WITHOUT_DISTRICTS` warning if you skipped districts).
  5. **Gates** — Gates step → Create New Join Entry → Gate (the town's gates), Owner team (the scenario's teams;
     empty = first Defender), State at match start, Damageable → Submit the entry → **Submit the scenario** (gates
     save only here).
  6. **Objectives** — reopen → Objectives → Create New: Name, Instant victory ✓ → Capture point: Location → **Send
     to Minecraft** (stand on the objective) → Submit. Create New again for a gate objective: Gate (only saved
     gates are listed) → the "Gate behaviour" step appears → state on capture → Submit.
  7. **Readiness** — go to the last step: expect **Ready**. With the server up, "Spatial checks ran"; any point
     outside the town region shows `HUB_OUTSIDE_TOWN` / `SPAWNPOINT_OUTSIDE_TOWN` / `OBJECTIVE_OUTSIDE_TOWN` —
     re-capture it and Re-check. With the server down: Ready plus the amber "spatial checks did not run" banner.
  8. **Lobby** — `/forms/siegelobby`: Name, Key (`[a-z0-9_-]`), Enabled → Timings (matchmaking ≥ 60) → Voting
     (1–3) → Rotation: Create New Join Entry → Scenario + Weight → Submit. A duplicate key shows the API's 409
     message.
  9. **Siege Settings** — nav "Siege Settings": change e.g. Headshot multiplier → Save (1) → Reload shows it.
  10. **Scenario 1** — open `[TEST] Siege of Cinix` → the Districts/Gates cards show names and join values
      (no "Missing Entity"); Edit Join Entry on a gate starts from its saved state; Submit without changes.
  11. **GateStructure form** — the "Siege Behaviour" step no longer has "Is siege objective".
- **Follow-ups (not blocking):** a "save and stay" wizard action would let an admin add gates and gate
  objectives in one sitting; fields of a *hidden* step are still submitted with their authored default
  (`flattenAllStepsData`, pre-existing; harmless here since each default equals the API's); the M2M editor
  has no inline "pick several existing" table, so districts are added one join entry at a time (existing UX);
  owned-list saves submit the child list back to the API as `TeamIds`/`Teams` (ignored by the API, like
  `GateDoors`); the dev DB keeps the scenario 2 / lobby 2 create-path data until cleaned up (above).

## Phase 4 — Plugin core, Bukkit-free (knk-core, knk-api-client)

**Scope** (DESIGN §5.2–5.5, §6.3–6.4, §7)
- Domain records `core/domain/siege/*`; ports `SiegeLobbiesQueryApi`, `SiegeScenariosQueryApi`,
  `SiegeMatchesCommandApi` (interface only here; impl in Phase 6); API-client DTOs/mappers/impls for
  runtime-config; `SiegeDataAccess` gateway (`DataAccessExecutor`, cache-first, refreshed between
  matches).
- `core/siege/`: `SiegePhase`, `SiegeLobbyStateMachine` (pure: `tick()` → list of effects such as
  `AnnounceEffect`, `DrawScenarioEffect`, `SendToHubEffect`, `SplitTeamsEffect`, `StartMatchEffect`),
  `VoteTally`, `TeamPartitioner` (snake draft), `AllianceResolver`, `CaptureCalculator`,
  `ObjectiveState`, `WinResolver`, `MatchDurationCalculator`, `SiegeRuntimeLocks`.

**Tests (JUnit, no server):**
- Legacy-formula golden tests for `CaptureCalculator` (1/2/5 attackers vs 0/1/3 defenders, IV and
  non-IV) and the side-capture reduction.
- Regressions: N1 (highest vote wins; ties random within the tied set), N2 (random vote counts and can
  win only when strictly greater), N17 (un-vote), 4 players / 3 teams split (v2 `Partition` crash),
  N-team holder-relative scoring (the `"cinixians"` bug can't recur: rename every team, same result).
- `WinResolver`: IV capture, timeout with single/mixed IV holders, no-IV scenario, elimination, draw.
- Recapture (D5): off → captured objective stops scoring; on → points reset with the new holder and
  the old holder's alliance attacks; side-capture pressure applies on first capture only; capture
  reward counted once per participant per objective.
- State machine timeline: announcements at the configured marks, draw at T-25, hub at T-15, split at
  T-10, not-enough-players → COOLDOWN, skip semantics (N9).

**Exit:** `knk-core` siege package green standalone (same `javac` + junit-console approach the
InventoryMenu phases used when Gradle/Paper repos are unavailable).

**Phase 4 status (2026-09-25): code complete on `claude/siege-minigame` (knk-plugin), pushed; tested
without a server; nothing is wired into the running plugin yet (that's Phase 5).** Commits: `1022f53`
(domain records + ports), `77f86a9` (api-client), `bb8b1ed` (`SiegeDataAccess` + `DataAccessFactory`),
`acf6edc` (core logic), `8e81b27` (tests). `origin/main` hadn't moved since Phase 1, so no trunk merge.
- **Packages and classes** (all under `net.knightsandkings.knk`):
  - `core.domain.siege`: `KnkSiegeRuntimeConfig`, `KnkSiegeConfiguration` (+ `legacyDefaults()`),
    `KnkSiegeLobby`, `KnkSiegeRotationEntry`, `KnkSiegeSkippedScenario`, `KnkSiegeScenario`, `KnkSiegeTeam`,
    `KnkSiegeSpawnpoint`, `KnkSiegeObjective`, `KnkSiegeGate`, `KnkSiegeDistrict`, `KnkSiegeMatchLength`,
    `KnkSiegeRewards`, `KnkSiegeReadiness`/`KnkSiegeReadinessIssue`, `KnkSiegeMatchRecords` (provisional Phase 6
    shapes); enums `SiegeTeamRole`, `SiegeLobbyMode`, `SiegeGateState`, `SiegeNonMemberGateView`,
    `SiegeEndReason`. They mirror the runtime-config payload; server-resolved values (identity, first-Defender
    holders/owners, capture points, `isObjectiveGate`) are taken as is. Teams, spawnpoints and objectives are
    kept in (sortOrder, id) order.
  - `core.ports.api`: `SiegeLobbiesQueryApi` (runtime-config), `SiegeScenariosQueryApi` (readiness),
    `SiegeMatchesCommandApi` (**interface only**).
  - `api.dto.SiegeDtos`, `api.mapper.SiegeMapper`, `api.impl.SiegeLobbiesQueryApiImpl`
    (`GET /SiegeLobbies/runtime-config`), `api.impl.SiegeScenariosQueryApiImpl`
    (`GET /SiegeScenarios/{id}/readiness`, 404 → null); both registered in `KnkApiClient`.
  - `core.dataaccess.SiegeDataAccess`: the whole runtime-config as one cache entry through
    `DataAccessExecutor`, read cache-first; `refreshRuntimeConfigAsync()` asks the API and, if that fails,
    keeps serving the last copy (stale if expired); readiness is passed through uncached. knk-paper:
    `DataAccessFactory.createSiegeDataAccess(...)` with its own `entities.siege` block (`KnkConfig`,
    `ConfigLoader`, `config.yml`: 30 min TTL, CACHE_FIRST, stale allowed; its own TTL like the permissions
    gateway). **Not instantiated in `KnKPlugin` yet.**
  - `core.siege` (no Bukkit/Paper import; grep in the final check found 0): `SiegePhase`,
    `SiegeLobbyStateMachine`, `SiegeEffect` (sealed; 12 effect records), `SiegeTimeline`, `VoteTally`,
    `WeightedPicker`, `TeamPartitioner`, `AllianceResolver`, `CaptureCalculator`, `ObjectiveState`,
    `SiegeObjectiveBoard`, `WinResolver`, `MatchDurationCalculator`, `SiegeRuntimeLocks`. Time is the
    `tick(memberCount)` call (one call = one second); randomness is an injected `RandomGenerator`.
- **Plan-required tests, all present and green:**
  - Legacy golden `CaptureCalculator` (`CaptureCalculatorTest`, 29): 1/2/5 attackers vs 0/1/3 defenders, IV and
    non-IV, each checked against a verbatim port of v1 `Objective.calculateCapturePoints` (same as v2 minus the
    "cinixians" check), plus a full 0–8 × 0–8 grid, capture times (lone attacker 100 s) and side-capture
    reduction vs the legacy `orig/5*2/n` integer maths.
  - N1/N2/N17 (`VoteTallyTest`, 13): highest wins; ties random within the tied set only; Random is counted
    and wins only when strictly greater (from the rotation minus the candidates); un-voting is a normal
    `REMOVED` result.
  - 4 players / 3 teams (`TeamPartitionerTest`, 6): every team gets a player, and the test records that v2's
    `Partition` made 2 chunks for 3 teams.
  - Holder-relative scoring (`HolderRelativeScoringTest`, 4): a scripted 400 s, 4-team, 3-alliance match gives
    identical step logs and result with the original names, the names swapped (including "cinixians" on an
    attacker team) and blank names.
  - `WinResolver` matrix (`WinResolverTest`, 13): IV capture; timeout with a single IV holder (defenders win
    although attackers hold more side objectives); mixed IV holders → most objectives → Defender alliance →
    draw; no-IV scenario; elimination; nobody left; admin stop/restart = aborted; `NOT_ENOUGH_PLAYERS` uses the
    normal rules; membership check.
  - Recapture D5 (`ObjectiveCaptureTest`, 10): off = final and stops scoring; on = points reset with the new
    holder and the old holder's alliance attacks; IV objectives are final even with recapture; side pressure
    only on an objective's first capture (no refund, no stacking); capture reward once per participant per
    objective.
  - State-machine timeline (`SiegeLobbyStateMachineTest`, 18): announcements exactly at 290/60/30/15 and nothing
    else; voting closes at T-30 ("hub in 15 s"); draw T-25, HUB + hub teleport T-15, split T-10, start T-0; a
    custom timeline and marks; not enough players at the draw → COOLDOWN with no draw effect and no lock, then
    matchmaking again after the cooldown; hub drop-outs cancel the start; full loop through timeout → ENDING →
    COOLDOWN; N9 skip in every phase; cross-lobby scenario and town locks; config frozen during a match.
  - Also: `KnkSiegeDomainTest` (5), `SiegeDataAccessTest` (6), `MatchDurationCalculatorTest` (10),
    `SiegeRuntimeLocksTest` (6), `SiegeMapperTest` (6, against the live sample), `DataAccessFactorySiegeTest` (2),
    `SiegeQueryApiLiveTest` (2, skipped unless `KNK_LIVE_API_BASE_URL` is set).
- **Test counts** (`./gradlew build --offline --rerun-tasks`, Gradle worked offline): knk-core **636** (baseline
  516, +120), knk-api-client **38** (baseline 30, +6 run, +2 env-gated skipped), knk-paper **251** (baseline 249,
  +2; the same 14 skipped). All green. **Standalone check (the exit criterion):** `core.siege` +
  `core.domain.siege` (+ the clan/location/`BannerPatternSpec` classes they use) compile with plain `javac
  --release 21` and **no Paper API on the classpath**; their 114 tests pass through the JUnit Platform launcher
  (a 10-line launcher main; the console-standalone jar isn't in the Gradle cache).
- **API sample and live check:** the mapper fixture `knk-api-client/src/test/resources/siege/
  runtime-config-dev-2026-09-25.json` is a real `GET /api/siege-lobbies/runtime-config` response (API on :5099,
  Release build of the web-api siege branch, dev DB, read-only; stopped afterwards). `SiegeQueryApiLiveTest`
  ran green against it (lobby `test-cinix`: 1 ready, 0 skipped; readiness of a missing scenario → null).
- **Decisions taken without the developer (review; each is cheap to change):**
  1. **The scenario lock is taken at the draw (T-25)**, not at match start as DESIGN §6.5 lists it, and held
     through ENDING (gate restore); released on cooldown/disable. The hub teleport at T-15 is already
     scenario-specific, so two lobbies must not both draw it.
  2. **The state machine draws itself** (it owns the `VoteTally` and asks `SiegeRuntimeLocks`);
     `DrawScenarioEffect` tells the runtime the outcome. This avoids a draw → report-back handshake. The
     runtime still removes title-excluded and over-capacity joiners (DESIGN §6.2) when it handles the effect.
  3. **PlayersMin is checked at the draw and again at T-0** (the member count passed to `tick`). The T-0 check
     catches hub drop-outs and joiners removed at the draw; it cancels with `membersInHub = true`. DESIGN only
     names the draw check.
  4. **Random votes draw by rotation weight**; if the rotation holds nothing besides the candidates, Random means
     "any candidate". Tie-breaks and the no-vote pick are uniform. Candidates locked by another lobby at the
     draw can't win; if all are locked, the draw falls back to the rest of the rotation (`CANDIDATES_UNAVAILABLE`),
     else the round is cancelled (`NO_SCENARIO_AVAILABLE`) → COOLDOWN.
  5. **No available scenario at matchmaking start** (all locked) → COOLDOWN, retried after a full cooldown. An
     **empty rotation** (nothing ready) → DISABLED + `LobbyDisabledEffect(NO_READY_SCENARIO)` (DESIGN §6.1).
  6. **ENDING lasts one tick:** the runtime does the whole end on `EndMatchEffect`; the next tick enters
     COOLDOWN and emits `RefreshConfigEffect`.
  7. **`stop()` (admin stop, shutdown) → DISABLED**, not COOLDOWN; `/siege admin start` restarts it.
  8. **Admin skip in matchmaking only moves forward** to `voteClose + 1` (legacy T-31) and answers `TOO_LATE`
     once there or past it (legacy set 31 again and re-ran the steps). A player's `/siege skip` works in
     cooldown only; HUB answers `TOO_LATE` to admins.
  9. **A capture needs an attacker:** it happens in a step with `delta > 0` that leaves the points at 0; the
     closest living attacker is credited. Side-capture pressure can push an IV objective to 0 but doesn't
     capture it; the next attacker step does (legacy would call `setCaptured` with possibly no capturer).
  10. **Side pressure is applied after every objective has stepped** (it shows the next second). If two IV
      objectives fall in the same second, the first in scenario order ends the match.
  11. **Timeout with mixed IV holders:** only alliances holding an IV objective are contenders for "most
      objectives"; a tie goes to the single tied alliance with a Defender team, else a draw (also when several
      tied alliances contain a Defender). Without IV objectives every alliance is a contender.
  12. **Spawnable objectives** are those held by the member's own team (not allies), with `SpawnWhenHeld`, not
      contested (`SiegeObjectiveBoard.spawnableObjectives`).
  13. **Snake-draft rank** is the title bracket (its MinExperience or index), not raw XP, so players in one
      bracket are shuffled. With uneven counts the extra player goes to the team that picked last in the
      previous round (4 players / 3 teams → 1/1/2).
  14. **`SiegeScenariosQueryApi` has readiness only**: resolved scenarios exist only inside runtime-config.
      `SiegeMatchesCommandApi` records are provisional and userId-based; gate snapshots are left to Phase 7.
  15. **Unknown enum values:** role → ATTACKER, lobby mode → SCHEDULED (never auto-run), gate states → the
      DESIGN defaults (initial CLOSED, on capture OPEN), gate view → PreLockdownView.
  16. **The plugin re-validates the timeline** (`voteClose ≥ draw ≥ hub ≥ split ≥ 1`, and matchmaking longer
      than voteClose); a bad config throws `IllegalArgumentException` (Phase 5: keep the old one, log).
  17. **`HUB` is its own `SiegePhase` value** (DESIGN §5.4 calls it a sub-state), so menus/conditions can test it.
- **Doc/code discrepancies found:**
  - **Match length is not the v2 formula.** DESIGN §3.3 says the defaults are "the v2 formula", but v2 used
    whole minutes: `ceil(members × 1.25)` min, at least 5 min, no cap. 5 players got 420 s in v2 and get 375 s
    now (`MatchDurationCalculatorTest` records it). Implemented per DESIGN; one for the balancing pass (Phase 9).
  - **Side-capture reduction** (DESIGN §7.4 `floor(cp × 0.4 / n)`) differs from legacy `cp/5*2/n` only when the
    capture points aren't divisible by 5 (503 → 201 vs 200). Implemented per DESIGN.
  - `legacy/siege-minigame.md` (business rules, step 4) words the IV values as "doubled to +5/+6"; the v1/v2
    source has A2 = 5 and D2 = 6 on IV objectives, which is what DESIGN §7.2 says. DESIGN is right; the legacy
    sentence is ambiguous.
  - DESIGN §6.5 puts "Lock scenario" first at match start; see decision 1. DESIGN §5.1 calls the port
    `SiegeMatchesApi`, §5.2 and this plan `SiegeMatchesCommandApi` (used).
  - `Repository/knk-plugin/CLAUDE.md` still says "No dedicated `gui/`/`menus/` package exists yet"; InventoryMenu
    (`menu/`) has shipped since. Stale, not touched here.
  - **Dev-DB data, not code:** lobby 1's name is stored as mojibake `[TEST] Siege â€” Cinix` (the em dash
    double-encoded when it was POSTed), and districts 6 and 7 have names ending in `\n`. Harmless now; both
    would show in Phase 5 chat/menus. Fix by editing them in the web app.
- **Runtime-config: prerequisites and notes for Phase 5/6 (API not changed):**
  - Entry denials need the minimum title's **name** ("requires title X"); runtime-config has
    `minTitleExperience` and `minTitleBracketId` only. Use the read-only `TitleBrackets` endpoint (Phase 3), or
    add `minTitleName` to `SiegeRuntimeScenarioDto`.
  - A lobby that is disabled simply disappears from runtime-config; Phase 5 must treat "missing after a
    refresh" as "stop it when it's between matches".
  - Still open from Phase 2: the other gates in the scenario area that §8.1 forces open aren't listed (Phase 7).
- **What Phase 5 must wire:**
  - **Startup:** `DataAccessFactory.createSiegeDataAccess(apiClient.getSiegeLobbiesQueryApi(),
    apiClient.getSiegeScenariosQueryApi())` in `KnKPlugin`; one shared `SiegeRuntimeLocks` and one long-lived
    `RandomGenerator` (don't create a new `Random` per draw: consecutive seeds give correlated first draws).
    `getRuntimeConfigAsync()` → main thread → a `SiegeLobbyStateMachine` per `CONTINUOUS` lobby (catch
    `IllegalArgumentException`: log, skip) → `start()` after ~2 s (§6.1).
  - **Ticker (sync, 1 s):** `effects = machine.tick(memberCount)`, apply in order. While IN_PROGRESS, build
    `Presence` per objective (living members within `captureRadius`, with distance) → `board.step(...)`. An IV
    capture → `machine.endMatch(INSTANT_VICTORY)`; after a leave/quit → `winResolver.membershipEnd(...)` →
    `machine.endMatch(reason)`. `onDisable` → `machine.stop(SERVER_RESTART)` for every lobby.
  - **Effect → Paper action:**

    | Effect | Paper runtime action |
    |---|---|
    | `PhaseChangedEffect` | refresh scoreboards/menus (`refreshOpenMenus` for `siege.*` in 8b) |
    | `AnnounceEffect` | chat/title to online players (with the join command while `joinable`) or to members |
    | `MatchmakingStartedEffect` | voting open for the candidates; `/siege vote` lists them |
    | `DrawScenarioEffect` | remove members the scenario excludes (title, capacity) with a message; announce; Phase 6 `createMatch` |
    | `SendToHubEffect` | `SiegePlayerVault` snapshot (memory + file), teleport to `hubLocation`; joining closed |
    | `SplitTeamsEffect` | `TeamPartitioner.partition(entries by bracket, scenario team ids, random)` |
    | `StartMatchEffect` | build `AllianceResolver`, `SiegeObjectiveBoard(scenario, new CaptureCalculator(machine.configuration()), …)`, `WinResolver`; §6.5 start (spawns, objectives, scoreboards, spawn picker); Phase 6 `startMatch` |
    | `StartMessageEffect` | each team's `startMessage` on the action bar |
    | `EndMatchEffect` | `WinResolver.resolve(reason, board, alliancesWithMembers)`; announce; restore members; release players; Phase 6 `completeMatch` (or `abortMatch` when aborted) |
    | `CancelMatchmakingEffect` | announce the reason; restore members if `membersInHub`; `locks.releasePlayers(lobbyId)` |
    | `RefreshConfigEffect` | `SiegeDataAccess.refreshRuntimeConfigAsync()` → main thread → `machine.offerConfiguration(...)` |
    | `LobbyDisabledEffect` | log once |
  - **Refresh points:** only `RefreshConfigEffect` (entering cooldown) and `/siege admin reload`. The machine
    applies an offer immediately between matches and holds it until the next cooldown otherwise, so calling
    `offerConfiguration` is always safe. New lobbies in the payload → new machines; missing ones → `stop(...)`
    once they're between matches.
  - **Locks:** join → `isJoinable()`, `joinCapacity()`, `joinMinTitleExperience()`, `locks.tryClaimPlayer(uuid,
    lobbyId)`; leave → `locks.releasePlayer` + `machine.removeMember`. Scenario/town/gate locks are handled by the
    machine; Phase 7 gate listeners use `locks.lobbyHoldingGate(gateId)`. Votes → `machine.vote(...)` and skip →
    `machine.skip(PLAYER|ADMIN)`: map `VoteResult`/`SkipResult` to messages.
- **Follow-ups (not blocking):** consider
  `minTitleName` in runtime-config (above); fix the dev-DB name quirks; update the stale knk-plugin `CLAUDE.md`
  line; the objective banner's 8-stage gradient maths (legacy `setCurrentCapturePoints`) is presentation and was
  left to Phase 5's `SiegeWorldPresenter` (`ObjectiveState.capturePercent()` is there).

## Phase 5 — Paper runtime (knk-paper)

**Scope** (DESIGN §5.3, §6, §7, §9, §11.1)
- `SiegeService` + single sync 1 s ticker applying state-machine effects; bootstrap on enable (§6.1).
- `SiegeCommand`: all player subcommands incl. **chat fallbacks** (`/siege vote`, `/siege spawn`,
  `/siege info`) so a match is fully playable without menus; admin subcommands.
- `SiegePlayerVault` (snapshot to memory + `siege-vault/<uuid>.dat`, restore on end/leave/quit/join).
- Listeners: `SiegeCombatListener` (alliance rule, safe zones, member↔non-member, headshots),
  `SiegeDeathRespawnListener` (keepInventory/keepLevel, credit, respawn at choice), `SiegeCommandFilterListener`,
  `SiegeInventoryGuardListener` (DESIGN §9.3 list), `SiegeSessionListener` (quit/join restore; later
  lockdown in Phase 7). Leave the existing stub `PlayerListener.onPlayerDeath/onPlayerRespawn` alone for
  non-siege players; siege listeners run at higher priority and only act for members.
- `SiegeWorldPresenter`: objective banner blocks with the 8-stage progress gradient built from the
  holder's and leading attacker's banner base colours, flame capture rings and happy-villager safe-zone
  rings **sent only to members**, percentage `TextDisplay` (not the legacy invisible `ArmorStand`).
- `SiegeScoreboardPresenter`: per-team sidebar (team, objectives sorted IV-first with viewer-relative
  colours, time remaining), tab-list prefix/colour + `[K/D]` suffix; restores the player's previous
  scoreboard (`ScoreboardUtil`) afterwards.
- Permission nodes (DESIGN §11.1) registered with the in-house permission system.
- **5c — Enchant books (DESIGN §9.4, D7):** drop ticker (chance/limit/allowed keys from
  `SiegeConfiguration`), PDC-tagged books, members-only pickup exception (un-cancel above
  `PlayerListener.onItemPickup`), cursor-onto-item application with vanilla validity rules, per-item
  `knk:siege_enchants` markers, ground cleanup at match end, and the restore/join-time stripping
  sweep. Tests: stripping reverts to `previousLevel`/removes, stray books deleted, non-member pickup
  blocked.

**Manual verification (live server, 3+ accounts):** full loop matchmaking → vote → hub → split → match
→ IV capture win and timeout win → restore → cooldown → next matchmaking; quit mid-match restores on
rejoin; drop/chest/ender-chest dupes blocked; friendly fire and safe zones; non-member can't hit
members; command filter.
**Exit:** playable end-to-end with commands, with Phase 6 wired (below).

**Phase 5 status (2026-09-26): 5a, 5b and 5c code complete on `claude/siege-minigame` (knk-plugin), pushed; wired
into `KnKPlugin`; tested without a server; not deployed and not played live yet (sign-off below is the
developer's).** Commits: `dfee9b1` (5a code), `bce4d27` (5a tests), `12cf3b6` (5b code), `865f366` (5b tests),
`1305552` (5c code), `80cdeb8` (5c tests). `origin/main` hadn't moved since the last siege merge (`807ca2c`), so no
trunk merge. No web-app or web-api change.
- **Classes** (all under `net.knightsandkings.knk`):
  - `paper.siege`: `SiegeService` (the runtime: lobbies, 1 s sync ticker, effects, every player/admin operation),
    `SiegeLobbyRuntime` (machine + members + round state), `SiegeMatch` (a running match: alliances, board, win
    resolver, roster, match token, spawn-pick windows, capture times), `SiegeMatchObserver` (hooks: lobbyChanged,
    matchStarted, secondTicked, objectiveCaptured, memberRemoved, matchEnded, shutdown), `SiegePlayerVault`,
    `SiegeWorldPresenter`, `SiegeScoreboardPresenter`, `SiegeEnchantBooks`, `SiegeMessages`, `SiegeBukkit`,
    `LoggingSiegeMatchesCommandApi` (**Phase 6 placeholder**).
  - `paper.commands.SiegeCommand`; `paper.listeners`: `SiegeSessionListener`, `SiegeCombatListener`,
    `SiegeDeathRespawnListener`, `SiegeCommandFilterListener`, `SiegeInventoryGuardListener`,
    `SiegeEnchantBookListener`. `BannerDesignBukkitMapper` gained `toPatterns`/`baseColor`/public `bannerMaterial`.
  - `core.siege` (still no Bukkit/Paper/Adventure import; grep = 0): `SiegeMatchRoster`, `SiegeSpawnOptions`,
    `SiegeCombatRules`, `SiegeCommandFilter`, `CaptureProgressGradient`, `SiegeEnchantMarkers`, `EnchantDropPlanner`,
    `ProvisionalRewardCalculator`, `SiegeDisplayText`, `SiegeTitleRanks`.
  - `core.domain.users.KnkTitleBracket` + port `core.ports.api.TitleBracketsQueryApi`; knk-api-client
    `TitleBracketDto` + `TitleBracketsQueryApiImpl` (`GET /api/TitleBrackets`, read-only, exists on the web-api
    siege branch since Phase 3), registered in `KnkApiClient`.
  - `KnKPlugin.initializeSiege()` (after the gate/region setup): `createSiegeDataAccess`, one `SiegeService` with one
    `SiegeRuntimeLocks` and one `SplittableRandom` shared with the book drops, presenters/books as observers, the
    `/siege` command and the six listeners; `onDisable` calls `siegeService.shutdown()` **first** (before the API
    client closes). `plugin.yml`: `/siege` and the §11.1 nodes; only `knk.siege.play` defaults to `true`.
- **5a (loop, service, commands, vault):**
  - Bootstrap: `getRuntimeConfigAsync()` → main thread → one machine per `Continuous` lobby (a bad timeline is
    logged and the lobby skipped) → `start()` 40 ticks later. Title brackets fetched alongside.
  - Ticker: `machine.tick(memberCount)` → exhaustive `switch` over `SiegeEffect` → while IN_PROGRESS, presence per
    objective (online, alive, not spectating, same world, within `captureRadius`, with distance) →
    `board.step` → captures (roster `Captures + 1`, capture time, announcements with sounds to the capturer's
    alliance / the losing alliance / everyone else, `objectiveCaptured` hook) → observers → an IV capture calls
    `endMatch(INSTANT_VICTORY)`. After every leave/quit/kick during IN_PROGRESS: `WinResolver.membershipEnd` →
    `endMatch(reason)`. Every effect and observer runs in its own try/catch so one failure can't stop the ticker.
  - Effects as in the Phase 4 wiring table: draw (match token + `createMatch`, title/capacity exclusions with a
    message), hub (close inventory, vault snapshot, teleport), split (`TeamPartitioner` with bracket ranks, team
    told), start (roster from the split, default-spawnpoint teleport, title, objective summary, spawn picker for
    teams with 2+ options, `startMatch`), start messages (action bar per team), end (`WinResolver.resolve`,
    announcement to everyone, per-member stats + **provisional** reward line, `completeMatch`/`abortMatch`,
    observers, restore + release everyone), cancel (reason to members, `abortMatch` if the draw had created a row,
    restore if in the hub, release), refresh, disabled (logged once per disable).
  - Refresh: only on `RefreshConfigEffect` and `/siege admin reload`; one request in flight; `offerConfiguration` per
    lobby (IAE → keep the old one); new lobbies → new machines; a lobby missing from the payload is stopped and
    removed when between matches, otherwise at its next cooldown's refresh.
  - `/siege` (overview), `join [lobby]`, `leave`, `info [lobby]` (per-phase chat fallback of `siege.information`),
    `vote [n|name|random]` (no argument = clickable list with counts), `spawn [option]` (no argument = clickable
    picker), `skip [lobby]`, `help`; `admin list|start|stop <lobby> [reason]|skip|kick <player>|reload|manage`, tab
    completion. Each subcommand is one `SiegeService` call returning a `Reply`; every `VoteResult`/`SkipResult`/
    cancel reason/end reason has a sentence (N9).
  - Vault: see decisions 1 and 8–10.
- **5b (listeners, presenters):**
  - Combat (`HIGHEST`): attacker from projectiles (null-safe), `SiegeCombatRules` (member ↔ non-member always
    denied, no fighting in the hub, allies denied, both own-spawn safe zones), allowed hits un-cancelled, headshot
    (projectile Y above feet + 1.33, v2) × `headshotMultiplier` between enemies only. No WorldGuard flag is touched.
  - Death (`HIGHEST`, members away in a match only): keepInventory/keepLevel, no drops/XP/death message, credit via
    `SiegeMatchRoster.recordDeath` and announcements to the killer's team at the configured kill counts and at
    streaks above the configured value, carrying the streak (N12). Respawn: spawn choice → default spawnpoint; hub
    during HUB; pre-siege location for a member restored while dead; picker after `SpawnPickerDelayTicks`.
  - Command filter (`LOWEST`), inventory guard (DESIGN §9.3, see decision 14), session listener (quit restore,
    join restore two ticks later, then the 5c sweep).
  - World: banner block with the 8-stage gradient (legacy index formula, verified for every point value 0–500) in
    the holder's and the leading attacker's banner base colours; `TextDisplay` above it (name, holder, %, "Under
    attack!"); flame capture rings and happy-villager rings round every spawnpoint's safe zone, sent with
    `Player.spawnParticle` to members within 64 blocks only.
  - Scoreboard: one board per team; sidebar = team, time left, objectives IV-first, green if the viewer's alliance
    holds it, red otherwise, ⚔ while contested; every team is a Bukkit team on each board (name-tag colour +
    `[Team]` prefix); tab list `[Team] name [K/D]`; previous scoreboard and tab name restored on leave/end/shutdown.
- **5c (enchant books):** drop roll per second (chance per mille, `MaxBooksAlive`, allowed keys, level range, only
  with `EnchantDropsEnabled`; uniform in the real radius, fixing v2's int cast), book level clamped to the
  enchantment's max; PDC `siege_book = <matchToken>`, non-persistent `Item`s tracked and removed at match end;
  pickup only by members of that match (un-cancelled at `HIGHEST` above `PlayerListener.onItemPickup` and the guard;
  mobs, allays and hoppers can't take one); left/right-click the book on the cursor onto an item in your own
  inventory: `canEnchantItem`, conflicts, `max(existing, book)`, book consumed, `siege_enchants` marker recorded
  (first application per match keeps the pre-siege level); stripping sweep over inventory, ender chest and cursor
  after every vault restore and on every join (reverts to `previousLevel` or removes; oldest record wins across
  matches; stray books deleted).
- **Test counts** (`./gradlew build --offline -x deployToDevServer`): knk-core **691** (baseline 636, +55),
  knk-api-client **38** (unchanged; the same 2 env-gated tests skipped), knk-paper **259** (baseline 251, +8; the
  same 14 skipped). All green. New test classes: `SiegeMatchRosterTest` (9), `SiegeSpawnOptionsTest` (6),
  `ProvisionalRewardCalculatorTest` (3), `SiegeDisplayTextTest` (4), `SiegeTitleRanksTest` (4), `SiegeCombatRulesTest`
  (8), `SiegeCommandFilterTest` (5), `CaptureProgressGradientTest` (4), `SiegeEnchantMarkersTest` (8),
  `EnchantDropPlannerTest` (4); knk-paper `SiegeMessagesTest` (4), `SiegeCombatListenerTest` (3),
  `SiegeWorldPresenterTest` (1). Plan-required 5c tests: stripping reverts/removes, stray books deleted,
  non-member pickup blocked - as pure rules in `SiegeEnchantMarkersTest` (`ItemStack` can't be built without a
  server; the Paper glue calls exactly these rules). The Paper runtime itself (effects, vault files, presenters,
  listeners) has **no automated test**: it needs a live server - see the checklist.
- **Decisions taken without the developer (review; each is cheap to change):**
  1. **Vault file** is `plugins/KnightsAndKings/siege-vault/<uuid>.yml` (YAML; items as base64 of Paper's
     `ItemStack.serializeItemsAsBytes`, data-version aware; written to a temp file then renamed). DESIGN says
     `plugins/KnK/siege-vault/<uuid>.dat`; the plugin's data folder is named after the plugin.
  2. **`knk.siege.play` also honours its `plugin.yml` default.** `KnkPermissible` fails closed for non-ops without a
     grant, so with it alone no ordinary player could join; `SiegeService.hasPermission` accepts Bukkit's
     `hasPermission` for this one node only. Every other siege node is `KnkPermissible`-only (ops always pass).
  3. **Match token ≠ match id.** Each drawn round gets a random UUID token used for PDC tags, vault files and
     markers; the Phase 6 match id is a separate future (the placeholder hands out negative ids).
  4. **Title names** come from a new read-only `TitleBracketsQueryApi`; if brackets can't be fetched, denials say
     "N XP" and the split ranks by raw XP. The split rank is the bracket MinExperience (Phase 4 decision 13).
  5. **Joining needs the player's cached user profile** (user id for Phase 6); otherwise "Your profile is still
     loading". A player with a leftover vault file is restored first and asked to join again.
  6. **Snapshot failure** (file can't be written) removes the player from the lobby instead of taking them in.
  7. **Hub location unresolvable** (world not loaded) → members are snapshotted but stay where they are; logged.
  8. **Quit mid-match:** inventory, XP, effects and game mode restored inside `PlayerQuitEvent` (health/food only if
     alive); the file is rewritten with `inventoryRestored: true` and the rest (location, health, food) is applied
     on the next join. A crash leftover (flag false) gets everything on join.
  9. **Dead at the end:** inventory/stats restored at once, pre-siege location applied on respawn.
  10. **Restore sets health to the snapshot value** (DESIGN "exact"); a snapshot taken at 3 hearts restores 3 hearts.
  11. **Spawn picks teleport only inside a 20 s window** after match start / a respawn (the chat picker's
      equivalent of "picker opened by a respawn"); outside it `/siege spawn x` only sets the respawn choice.
  12. **Respawn at a contested objective falls back** to the default spawnpoint, like the picker refuses it; the
      objective spawn teleports to the capture point itself (MENU_TEMPLATES C.4 says "within 3 blocks").
  13. **No fighting in the hub**; members who die in the hub keep their inventory and respawn at the hub.
      Un-cancelling allowed hits is skipped when either player is admin-frozen or still loading (those features
      cancel at HIGHEST/LOWEST on the same handler list).
  14. **Inventory guard opens nothing that persists**: all world storage (container blocks, double chests, ender
      chest, storage entities, merchants, crafters) is closed to members - taking out would also let the restore
      wipe world items. InventoryMenu GUIs stay usable. Item-holding blocks (lectern, jukebox, chiseled bookshelf,
      decorated pot, campfires, composter, flower pots) can't be used or placed; all entity/hanging placement is
      denied. **Ordinary block placement is not denied** - see follow-ups.
  15. **Command filter:** `/siege` is always allowed; labels compare case-insensitively without slash or namespace;
      aliases aren't resolved (list `/r` and `/reply` separately if both should work).
  16. **Objective banner** is placed only where the capture point block is air (logged otherwise); placed blocks are
      logged to `siege-vault/world-blocks.yml` and cleared on the next enable after a crash. v1's hard-coded RED base
      on stage 6 is not reproduced; a team without a banner uses its chat colour mapped to a dye.
  17. **K/D is in the tab list only**, not the sidebar (per-viewer lines on a per-team board would need a board per
      player).
  18. **Lobby lifecycle on refresh:** a lobby disabled for "no ready scenario" starts by itself once a refresh brings
      one, unless an admin stopped it (`/siege admin start` clears that). Non-Continuous lobbies are skipped (logged
      once).
  19. **Kill announcements go to the killer's team** (v2); captures are announced to every member of the match.
  20. **An abort after the draw** reports `NOT_ENOUGH_PLAYERS` for both NOT_ENOUGH_PLAYERS and NO_SCENARIO cancels
      (the only abort reasons besides admin stop / restart).
  21. **Book application:** left/right-click on an item in your own inventory only; a book of another or no running
      match is deleted when clicked; siege books can't be applied to books.
- **Doc/code discrepancies found:**
  - Vault path and format (decision 1); PDC keys are `knightsandkings:siege_book`/`siege_enchants` (plugin
    namespace, as `GateDisplayManager` does), DESIGN §9.4 writes `knk:`.
  - DESIGN §11.1 "no plugin.yml defaults beyond `knk.siege.play: true`" assumes Bukkit reads that default; siege
    permissions go through `KnkPermissible`, which doesn't (decision 2).
  - DESIGN §6.5 lists "Lock scenario → gate lockdown" at match start; the lock is taken at the draw (Phase 4
    decision 1) and gate lockdown is a Phase 7 hook.
  - `knk-paper/build.gradle.kts` makes `build` depend on `deployToDevServer`: a plain `./gradlew build` copies the jar
    into DEV_SERVER_1.21.10. The plugin `CLAUDE.md` doesn't mention it. This session's baseline build did that once;
    the deployed jar was already a siege-branch (Phase 4) build from 00:30 and the copy was byte-identical, so
    nothing changed there. All later builds used `-x deployToDevServer`.
  - `Repository/knk-plugin/CLAUDE.md` still says no gui/menus package exists (stale since InventoryMenu; not edited).
- **Runtime-config / API prerequisites (not changed here):** `minTitleName` in runtime-config would remove the
  `TitleBrackets` lookup; the Phase 6 `/api/siege-matches` endpoints; Phase 7's list of the scenario area's
  non-selected gates.
- **Manual live verification (developer; DEV_SERVER_1.21.10, API on :5099 from the web-api siege branch, dev DB,
  3+ accounts A/B/C where A is op).** Deploy with `./gradlew :knk-paper:dev` once ACTIVE_SESSIONS shows the dev
  server is free. For quick loops set lobby `test-cinix` to a short matchmaking time (≥ 60 s) and cooldown in the web
  app, then `/siege admin reload`.
  1. **Bootstrap:** server log shows "Siege runtime initialized", "Lobby test-cinix loaded (1 ready …)", and after ~2 s
     an online "Matchmaking for [TEST] Siege — Cinix has started" (name repaired, not `â€”`). `/siege` lists it;
     `/siege admin list` shows id 1, rotation 1 ready.
  2. **Join + vote:** B and C `/siege join test-cinix` (and A); a non-op must be allowed (checks decision 2).
     `/siege vote` lists `[TEST] Siege of Cinix` + Random with counts; vote, vote again → withdrawn; `/siege vote 9` →
     "isn't one of this round's scenarios".
  3. **Announcements:** countdown marks (290/60/30/15 or your marks) to everyone with a clickable join; at vote close
     members get "teleported to the hub in 15 seconds"; draw at T-25 names the scenario and method.
  4. **Hub (T-15):** members teleported to the hub; `plugins/KnightsAndKings/siege-vault/<uuid>.yml` exists for each;
     `/siege join` by a latecomer → "already under way"; `/spawn`, `/kit` blocked, `/msg` works; dropping an item,
     opening a chest/ender chest, placing a shulker box, using an item frame → denied; fighting in the hub denied.
  5. **Split (T-10):** each member told their team (Defenders = clan team 1, Raiders = team 2).
  6. **Start (T-0):** teleport to the team spawnpoint; title; sidebar (team, time left, The Keep ⚑ first, South Gate);
     tab `[Team] name [0/0]`; name tags coloured; banners at both capture points; `TextDisplay` above them; flame rings
     at the objectives and green (happy villager) rings at both spawnpoints - visible to members, **not** to a
     non-member standing next to them; start message on the action bar ~2 s in.
  7. **Combat:** attacker hits defender → damage; same-team hit → denied with a bass note; hit into or from inside a
     spawn safe zone → denied with a message; a non-member hitting a member (and vice versa) → denied; a bow shot
     above the head line → "Headshot!" and more damage (multiplier from Siege Settings).
  8. **Death:** kill someone → no drops, no death message, keeps items and level; killer's team sees the 5-kill
     message at 5 kills and a streak message with the streak number above 3; victim respawns at the team spawnpoint;
     tab K/D updates.
  9. **Capture + spawn choice:** a Raider stands in South Gate's ring → sidebar ⚔, banner gradient shifts toward
     Raiders' colour, % rises; defenders in the ring push it back; at 100 % "X captured South Gate!" (capturer's side,
     level-up sound) / "Lost objective South Gate" (defenders); Keep's % jumps by the side-capture reduction. Raider
     `/siege spawn` now lists South Gate if it has SpawnWhenHeld; pick it, die, respawn there; while a defender stands
     in its ring the option shows "being captured" and respawn falls back to the spawnpoint.
  10. **IV-capture win:** capture The Keep → everyone sees "Raiders won … captured the main objective"; each member
      gets stats + a provisional reward line; everyone is back where they were with their exact pre-siege inventory,
      XP, health, effects and game mode; vault files deleted; banners and displays gone; scoreboard back to normal;
      server log shows the `[match-api:no-op]` create/start/complete lines.
  11. **Cooldown → next matchmaking:** `/siege info` shows the cooldown; `/siege skip` (non-op without
      `knk.siege.skip`) denied, op skip → matchmaking starts again.
  12. **Timeout win:** another round, nobody captures The Keep → at 00:00 Defenders win ("held the main objective").
  13. **Leave / quit / kick:** mid-match `/siege leave` → restored at once, told no rewards; C quits mid-match →
      rejoin puts C back at the pre-siege spot with the pre-siege inventory, file deleted; if only one side is left
      the match ends "only one side has players left"; `/siege admin kick C` restores C.
  14. **Crash leftover:** during a match stop the server hard (kill the process); on restart the Keep/South Gate
      banners are gone ("Removed N objective banner(s)" in the log); each member's first join restores inventory +
      position and deletes the file.
  15. **Admin:** `/siege admin stop test-cinix too late` mid-match → aborted, everyone restored, no rewards, lobby
      stays stopped; `/siege admin start test-cinix` → matchmaking; `/siege admin skip` in matchmaking → "voting
      closes in 1 second", again → "Too late"; `/siege admin reload` → "Siege configuration refreshed"; `/siege admin
      manage` → web-app pointer.
  16. **Enchant books (5c):** with drops enabled and the chance raised in Siege Settings, books appear inside capture
      rings; a member picks one up, a non-member (even op) can't; click it onto a sword → enchanted, book gone, message;
      onto a book/unfit item → refused; at match end the sword is back to its pre-siege enchantments and ground books
      are gone; `/give` yourself an old tagged book outside a match → deleted at next join.
- **First live playtest (developer, 2026-09-26) and fixes** (plugin `1a8704c`, pushed; not redeployed by the session):
  checklist steps 1-6, 8, 9, 11-13 and 15 passed; 4 (guards), 7 (friendly fire), 10 (IV win) and 14 (crash) not run yet.
  Changes from the feedback:
  - **Objective labels are per audience** (`SiegeObjectiveLabels` in core): one `TextDisplay` per alliance, shown only
    to its members ("✔ Your side holds this" + Secure / Enemy progress X% / Under attack; "✖ Held by X" + Stand in the
    ring to capture it / Being captured X%), plus a neutral one for non-members. The old "- captured X%" read as if the
    holders still had to take it.
  - **`/siege skip` also shortens matchmaking** to 1 minute left (`PLAYER_SKIP_MATCHMAKING_SECONDS`, never below
    voteClose + 1); was cooldown-only (Phase 4 decision 8 revised for players; admin skip still goes to T-31).
  - **Siege books: right-click in hand opens an item chooser** (`SiegeEnchantMenu`, plain Bukkit inventory, lists only
    items the book can go on; v2 `PlayerEnchantMenu` behaviour). The developer expected a menu; cursor-onto-item stays.
  - **Owner/staff mode players are exempt from the inventory guards** (decision 14 narrowed). This reopens the
    duplication path for them: whatever they drop or store during a match is still given back by the restore.
  - **Capture speed (dev DB `siege_configurations` row `global`, two UPDATEs):** `CaptureAttackBase` 5 → 8 → **10**
    and `CaptureAttackPerExtraInstantVictory` 5 → **10** (side `CaptureAttackPerExtra` 2 and all defend values 6/3/6
    unchanged). Developer target: The Keep at 300 points (after South Gate falls) in 30 s for one attacker, 15 s for two
    (7.5 wasn't possible: the columns are ints). Undefended: Keep (500) 50 s / 25 s / 17 s for 1/2/3 attackers, South
    Gate 50 s / 42 s / 36 s. Defended: 1 v 1 now progresses on both (125 s); Keep 2 v 2 63 s, 3 v 2 28 s; South Gate
    2 v 1 84 s, 2 v 2 167 s. **Defenders can no longer hold even numbers on the main objective** (each extra attacker
    +10 vs each extra defender +6): **accepted by the developer as is** (2026-09-26; raising the defend values to
    12/12 to restore the equal-numbers standstill was offered and declined). Rationale and alternatives: DESIGN §7.2
    "Playtest tuning".
    Takes effect after `/siege admin reload` between matches. Seed defaults and `legacyDefaults()` still carry 5/2/5 (align in Phase 9). *(Phase 9: the web-api model defaults now
    carry 10/2/10; `legacyDefaults()` stays 5/2/5 on purpose - see "Phase 9 status".)*
  - Tests after the fixes: knk-core 694, knk-api-client 38, knk-paper 259, all green.
- **What Phase 6 must wire:** build the HTTP `SiegeMatchesCommandApiImpl` and pass it instead of
  `LoggingSiegeMatchesCommandApi` in `KnKPlugin.initializeSiege()` - the call sites already exist:
  `createMatch` in `SiegeService.onDraw` (future kept as `SiegeLobbyRuntime.matchIdFuture`), `startMatch` in
  `onStartMatch` (userId + team id per roster member), `participantLeft` in `removeMember` (leave/quit/kick during
  a match), `completeMatch` (with `completion(...)`: `WinResolver.Result`, roster stats, one `ObjectiveResult` per
  capture with capturer userId and time, or the final holder when never captured) or `abortMatch` in `onEndMatch`,
  `abortMatch` in `onCancel` when a row exists and via `stop(SERVER_RESTART)` on disable. `printRewardSummary`
  already prints a non-empty `RewardSummary`; then drop the provisional line (`rewardLine`). Still Phase 6: retry +
  `siege-vault/pending-results/<matchId>.json` spooling, startup recovery of rows left `InProgress`, and what to do
  when `createMatch` fails (today later calls are skipped for that round).
- **What Phase 7 must wire:** a `SiegeMatchObserver` for gates (`matchStarted` → lockdown; note it runs after the
  spawn teleports - add a "before start" hook if the lockdown must come first as DESIGN §6.5 orders it;
  `objectiveCaptured` → `transferOwnership(gate, capturer team, gateStateOnCapture)`; `matchEnded` → restore);
  `SiegeGateListener` via `service.locks().lobbyHoldingGate(gateId)`, `service.lobbies()`, `SiegeMatch.alliances()`
  and `SiegeMatch.board()` (current holder of an objective gate); lockdown and the non-member view in
  `SiegeSessionListener` (region entry, teleport, join, respawn) with `service.activeLobbyOf(uuid)` for membership;
  startup recovery of stale `CurrentSiegeId`.
- **Phase 8b notes:** menu actions call the same `SiegeService` methods (`join`, `leave`, `vote`, `spawn`, `skip`);
  `lobbyChanged` is the `refreshOpenMenus` hook; views read `SiegeLobbyRuntime`/`SiegeMatch`/
  `SiegeSpawnOptions.forTeam` (spawn-options source) and `CaptureProgressGradient.banner` (objective banners);
  replace the chat picker in `SiegeService.offerSpawnPicker` with opening `siege.spawnpoint`.
- **Follow-ups (not blocking):** decide whether members may place ordinary blocks (placing consumes an item the
  restore gives back; town WorldGuard build flags normally prevent it, but nothing siege-side does); arrows/tridents
  shot during a match stay in the world after the restore; `minTitleName` in runtime-config; the stale plugin
  `CLAUDE.md` menu line and its missing note that `build` deploys; the dev-DB name quirks (displayed repaired now);
  a Paper integration test harness for the runtime if the live checklist finds regressions.

## Phase 6 — Match persistence and rewards (knk-web-api + knk-plugin wiring)

**Scope** (DESIGN §3.10, §7.6, §11.2)
- web-api: `SiegeMatchService` + `SiegeMatchesController`: create, start (participants/teams), left,
  complete (compute + grant rewards transactionally, idempotent), abort, history query. Service-client
  auth on write endpoints.
- plugin: `SiegeMatchesCommandApiImpl`; `SiegeService` calls create at draw, start at match start, left
  on leave/quit, complete at end (then prints the returned per-player breakdown), abort on admin stop /
  shutdown (`onDisable`) / startup recovery.
- Retry policy: complete/abort calls retried with the existing `RetryPolicy`; if still failing, results
  are written to `siege-vault/pending-results/<matchId>.json` and replayed on next enable
  (idempotency makes replay safe).

**Tests:** reward matrix (winner/loser/left-early/captures/holding for 2- and 3-team scenarios),
idempotent double-complete, abort grants nothing, XP increments move the player's `TitleBracket`.
**Exit:** after a live match, `SiegeMatch` rows and balances match the in-game reward message.

**Phase 6 status (2026-09-26, overnight chain link 1): 6a (knk-web-api) code complete, tested and pushed on
`claude/siege-minigame`; 6b (plugin wiring) at first NOT started - blocked (**superseded: done later the same night
on the developer's go-ahead, see "Phase 6b status" below**): knk-plugin can't be built in the cloud
container (the environment's network policy denies `repo.papermc.io` and `maven.enginehub.org`, so Gradle can't
resolve `paper-api`/WorldEdit/WorldGuard).** Commits (knk-web-api): `b86d692` (TitleProgression extraction),
`82b78a4` (match service/API), `7d4fd44` (tests). Trunk had already been merged into both siege branches before this
link started (web-api `6a480e6`, plugin `d41be49`, both bringing in `claude/menu-content`), so no trunk merge here.
No migration: the Phase 2 match tables were complete (no model change, `has-pending-model-changes` unaffected).
No knk-plugin, knk-web-app or DB change.
- **Classes** (knk-web-api):
  - `Services/SiegeMatchService` (+ `ISiegeMatchService`): create, start, left, complete, abort, abort-unfinished,
    get, history. `Services/SiegeRewardCalculator` (pure: `Outcomes` = start/end holder per objective + capturers,
    `For` = one participant's reward). `Services/TitleProgression` (pure: the bracket-crossing logic moved out of
    `UserService.AdjustBalancesAsync` unchanged; both callers use it).
  - `Repositories/SiegeMatchRepository` (+ interface): loads, history query, `RunLockedAsync` (one READ COMMITTED
    transaction starting with `SELECT … FROM siege_matches … FOR UPDATE`; plain call on InMemory), `LockUsersAsync`.
  - `Controllers/SiegeMatchesController`, served at `api/siege-matches` (DESIGN) and `api/SiegeMatches`:
    `GET ?userId=&lobbyId=&status=&limit=` (history, newest first, default 50, max 200; with `userId` each row carries
    that user's own participant row), `GET {id}`, `POST` (201), `POST {id}/start`, `POST {id}/participants/{userId}/left`
    (204), `POST {id}/complete`, `POST {id}/abort`, `POST abort-unfinished`. Errors: 404 `NotFound`, 400
    `ValidationFailed`, 409 `BusinessRuleViolation`. `GET {id}/gate-snapshots` is left to Phase 7.
  - `Attributes/RequirePluginServiceKeyAttribute` on every write endpoint (decision 1). `Dtos/SiegeMatchDtos.cs`
    (camelCase JSON, enums as PascalCase strings like the rest of the siege API).
- **Request shapes** (what 6b's `SiegeMatchesCommandApiImpl` sends; they fit `KnkSiegeMatchRecords` as they are):
  - create `{ siegeLobbyId, siegeScenarioId }` → `SiegeMatchDto` (`id`, `status`, …).
  - start `{ participants: [ { userId, siegeTeamId } ], startedAt? }`.
  - left `{ leftAt? }` (body optional).
  - complete `{ endReason, winningAllianceGroup?, endedAt?, participants: [ { userId, siegeTeamId, kills, deaths,
    highestKillStreak, captures } ], objectives: [ { siegeObjectiveId, finalHolderTeamId, capturedByUserId?,
    capturedAt? } ] }` → `SiegeMatchResultDto { matchId, status, endReason, winningAllianceGroup, alreadyCompleted,
    rewards: [ { userId, siegeTeamId, presentAtEnd, won, holdingCount, captureCount, coins, experience, gems,
    titleChange? } ] }`.
  - abort `{ endReason, endedAt? }` (default `ServerRestart`); abort-unfinished `{ endReason }` →
    `{ abortedMatchIds: [] }`.
- **Rewards** exactly per DESIGN §7.6: win (`CoinRewardWin`/`ExpRewardWin`/`GemRewardWin` when the participant's
  team's alliance = `winningAllianceGroup`), holding (per objective whose end holder is the participant's team and
  whose start holder wasn't: `InitialHolderTeamId`, else the first Defender - the runtime-config default), capture
  (per distinct objective the participant captured). Only participants present at the end. Coins/gems/XP are added
  to the `User` in the same transaction, amounts stored on `SiegeMatchParticipant`, match set `Completed`. No
  AuditLog row. A second `complete` returns the stored amounts (`alreadyCompleted: true`) and grants nothing.
- **Tests:** 33 new, all green: `SiegeRewardCalculatorTests` (12: 2-team winner/loser/left-early/captures/holding,
  recapture ping-pong paid once, draw, 3 teams in 2 and in 3 alliances, explicit vs first-Defender start holder,
  negative amounts, team-less participant), `SiegeMatchServiceTests` (16, InMemory with the real repository:
  lifecycle, idempotent double-complete, abort grants nothing, XP moves the `TitleBracket` and grants its bonus once,
  notification queued once, unreported participants, complete without start, invalid input, abort-unfinished,
  history filters), `Api/SiegeMatchApiRoundTripTests` (2: plugin-shaped JSON through the controller, status codes),
  `RequirePluginServiceKeyAttributeTests` (3). Suite **704/709**; the 5 failures are the known pre-existing ones
  (baseline at `6a480e6` was 671/676 with the same 5: ClientActivityStore, 2× PathResolution `Town.*`,
  FieldValidation ConditionalRequired, FormSubmissionProgressRepository). The row locks only run on MySQL, so the
  InMemory tests don't exercise them (live step 5 below).
- **Decisions taken without the developer** (review; ★ = review first):
  1. ★ **Service-client auth is opt-in and OFF by default.** There is no plugin service-client mechanism today:
     the plugin's `config.yml` ships `api.auth.type: none`, every endpoint it calls is anonymous, and
     `RequireAdmin` needs a JWT role claim the plugin doesn't have - requiring it would lock the plugin out. New
     `[RequirePluginServiceKey]`: with `Security:PluginServiceKey` empty (the shipped default) the match writes are
     open like every other plugin endpoint; once set, they need that key in `Security:PluginServiceKeyHeader`
     (default `X-API-Key`, what the plugin's existing `api.auth.type: apikey` + `api-key` sends on every request),
     else 401. To turn it on: set the same secret in the API's `appsettings` (or user-secrets/env) and in the
     plugin's `config.yml`. Cheap to change (one attribute).
  2. ★ **Siege XP goes through the shared title path, bonuses included.** `TitleProgression` is the logic
     `AdjustBalancesAsync` had (behaviour unchanged there), so a match that promotes a player also grants the crossed
     brackets' Coin/Gem/Exp bonuses, and a `TitleChanged` notification is queued for the plugin's existing poller
     (after the commit, only on the granting call). `SiegeMatchParticipant.*Awarded` store the siege amounts only;
     the bonus is reported in `rewards[].titleChange`. 6b: don't also announce the promotion from `titleChange`, or
     players see it twice.
  3. **No AuditLog for rewards** (DESIGN §7.6), so siege payouts don't appear in a user's audit history - the match
     rows are the trail. This is why siege doesn't call `AdjustBalancesAsync`.
  4. **Retry/replay rules:** start on an `InProgress` match is a no-op (200); abort on an `Aborted` match is a no-op
     and keeps the first reason; complete on `Completed` returns the stored result; complete on `Aborted`, abort on
     `Completed`, start after either, and left after either → 409. Left: the first `leftAt` wins; unknown
     participant → 404.
  5. **`complete` is accepted on a `Created` match** (its `start` call was lost): the reported participants are
     recorded then. Rows the report doesn't mention and that have no `leftAt` are closed with `leftAt = endedAt` and
     get nothing (their `left` call was lost). Participants reported with a `leftAt` already set are not rewarded.
  6. **Objective end holder** = the last entry for that objective in request order (the plugin sends captures in
     order); objectives with no entry keep their start holder. Entries with no capturer are "final holder" rows.
  7. `complete` rejects `AdminStopped`/`ServerRestart` (400, use abort) and accepts `NotEnoughPlayers` (the plugin
     resolves winners for it). `abort` accepts any reason (the plugin's cancel after the draw sends
     `NotEnoughPlayers`, Phase 5 decision 20).
  8. **Extra endpoints beyond DESIGN §11.2:** `GET {id}`, `POST abort-unfinished` (one call for 6b's startup
     recovery, returns the ids so Phase 7 can restore their gates), and `status`/`limit` on history.
  9. Negative configured reward amounts count as 0; a participant whose team was deleted later only keeps capture
     rewards in a rebuilt breakdown.
  10. `GateStructure.CurrentSiegeId` is not touched by complete/abort (Phase 7 owns gates).
  11. Validation on complete/start: teams must belong to the match's scenario, objectives too, users must exist
      (400); `winningAllianceGroup` must be an alliance of the scenario.
- **Doc/code discrepancies found:**
  - knk-web-api `knkwebapi_v2.sln` references `tests/knkwebapi_v2.Tests/…` but the folder is `Tests/`, so
    `dotnet build` of the solution fails on a case-sensitive file system, and the repo `CLAUDE.md`'s
    `dotnet test tests/knkwebapi_v2.Tests/...` path is wrong on Linux. Build `knkwebapi_v2.csproj` and test
    `Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` directly. Not changed here.
  - Charter §9's web-api baseline (633) predates the menu-content trunk merge; the real baseline is 676.
  - `UserService.AdjustBalancesAsync` writes an AuditLog row for every balance change, which DESIGN §7.6 says siege
    rewards must not - hence the extraction instead of reuse.
- **Manual live verification (developer; after 6b is wired - until then only steps 1-5 with Swagger):**
  1. Redeploy the web-api from `claude/siege-minigame` (no new migration). `GET /api/siege-matches` → `[]` (or
     rows the logging placeholder never wrote - it writes none).
  2. Swagger: `POST /api/siege-matches` `{ "siegeLobbyId": <test lobby>, "siegeScenarioId": <its scenario> }` → 201,
     `status: "Created"`.
  3. `POST /api/siege-matches/{id}/start` with two real user ids and the scenario's Defender/Attacker team ids →
     `InProgress`; `POST …/participants/{userId}/left` for a third participant you added → 204.
  4. `POST …/complete` with `endReason: "InstantVictory"`, the attackers' alliance, both participants, and one
     objective entry with the attacker as `capturedByUserId` → `rewards` show win + holding + capture for the
     attacker. Check `users.Coins/Gems/ExperiencePoints` in the DB moved by exactly those amounts (plus a bracket
     bonus if a title was crossed) and `siege_match_participants.*Awarded` match.
  5. Repeat the same `complete` twice quickly (two Swagger tabs or `curl … & curl …`) → one says
     `alreadyCompleted: true`; balances moved only once. `POST …/abort` on it → 409. A fresh match: abort → no
     balance change; `POST abort-unfinished` → aborts any leftover Created/InProgress rows.
  6. (6b) Play a match on the dev server: rows appear at the draw/start/end, the in-game reward line equals the
     `SiegeMatch` rows and the balance change (plan Phase 6 exit criterion).
  7. (optional, decision 1) Set `Security:PluginServiceKey` + the plugin's `api.auth` to `apikey` with the same key:
     writes without the header → 401, the plugin still records matches.
- **What 6b must wire (plugin, unchanged from the Phase 5 list plus the API facts above):** `SiegeMatchesCommandApiImpl`
  in knk-api-client (DTOs + mapper in the `SiegeLobbiesQueryApiImpl` style, register in `KnkApiClient`; paths
  `/siege-matches…` relative to `api.base-url`, which already ends in `/api`), pass it instead of
  `LoggingSiegeMatchesCommandApi` in `KnKPlugin.initializeSiege()`; `RewardSummary`/`ParticipantReward` may gain
  `holdingCount`/`captureCount`/`presentAtEnd` for the breakdown line; drop the provisional `rewardLine` wording
  (keep the stats line) and print the server's breakdown in `printRewardSummary`; `createMatch` returns `long` today
  while the API id is `int` (fine). Retry complete/abort with the existing `RetryPolicy`; spool failures to
  `siege-vault/pending-results/<matchId>.json` and replay on enable; call `POST abort-unfinished` on enable
  (after replaying the spool, so a spooled complete isn't aborted first); decide `createMatch` failure handling.
  Unit-test the spool/replay and the mapper in knk-core/knk-api-client.
- **Follow-ups (not blocking):** fix the `.sln` test path; decide whether siege payouts should appear in the user's
  audit history after all (DESIGN says no); a siege stats panel from `SiegeMatchParticipant` (DESIGN §13 Q7); the
  duplicate participant index `(SiegeMatchId, UserId)` isn't unique (the service prevents duplicates; a unique index
  would need a migration).

**Phase 6b status (2026-09-26, overnight chain link 1, continued on the developer's instruction "just continue
anyway, we will test at my PC"): code complete on knk-plugin `claude/siege-minigame`, pushed. knk-core and
knk-api-client parts compiled and unit-tested; the knk-paper part is NOT compiled** (the cloud container still can't
reach `repo.papermc.io`; the knk-paper edits were checked by reading and by a syntax-only parse). Commits: `14ca0c8`
(core), `a150719` (api-client), `378f8a1` (paper).
- **How it was verified:** a throwaway Gradle build in the session scratchpad compiled the real knk-core sources
  minus the 9 files that import Bukkit (gates + 2 utils) and all of knk-api-client against Maven Central only, and ran
  their tests. Baseline at `d41be49` in that build: knk-core 606 (non-Bukkit subset of the 694), knk-api-client 43
  (2 skipped); after 6b: **622 and 48 (2 skipped), all green** (16 + 5 new). knk-paper: no build, no tests run - **build
  it first** (`./gradlew build -x deployToDevServer`); expect 259 (14 skipped) as at `1a8704c` plus whatever the
  menu-content merge added.
- **Classes:** knk-core `core.siege.SiegeMatchRecorder` (implements `SiegeMatchesCommandApi`, wraps the HTTP one:
  `RetryPolicy` on every call; transient `complete`/`abort` failures → `SiegeResultSpool`; 4xx = the server's final
  answer, logged only; `spoolInFlight()` on disable; `recoverOnStartup()` = replay the spool, then
  `abortUnfinished(SERVER_RESTART)` only if nothing is left in the spool; `createMatch` waits for the recovery and
  completes with `null` after the retries → the round runs unrecorded; the spool is replayed again at each draw),
  `core.siege.SiegeResultSpool` (`siege-vault/pending-results/<matchId>.json`, temp file + atomic move, flat JSON with
  string enums/instants). Port: `abortUnfinished` added; records: `ParticipantReward(userId, presentAtEnd, won,
  holdingCount, captureCount, coins, experience, gems)`, `RewardSummary.alreadyCompleted`. knk-api-client
  `SiegeMatchDtos`, `SiegeMatchMapper`, `SiegeMatchesCommandApiImpl` (paths `/siege-matches…` under `api.base-url`;
  instants sent as ISO strings because the client's ObjectMapper writes numeric timestamps), `KnkApiClient
  .getSiegeMatchesCommandApi()`. knk-paper: `KnKPlugin.initializeSiege()` builds the spool + recorder, starts the
  recovery, passes the recorder to `SiegeService`; `onDisable` spools in-flight results after `siegeService.shutdown()`;
  `SiegeService` prints the server's breakdown ("Rewards granted: +250 coins +25 XP +1 gems (win, 2 objective(s)
  gained, 1 capture(s))" or "No rewards this time."), keeps the stats line, drops the provisional wording, and tells
  members when a round couldn't be recorded or the result couldn't be confirmed yet.
- **Decisions (6b; ★ = review first):**
  1. ★ **createMatch failure:** retried by `RetryPolicy` (network errors only, 3 attempts), then the round runs
     unrecorded: logged SEVERE, members told at the end "no rewards this round". No mid-round re-create.
  2. **Unfinished-match recovery is skipped while the spool still holds a result** (so a spooled completion is
     never aborted first); it runs on the next enable instead.
  3. **`LoggingSiegeMatchesCommandApi` kept** (unused; handy for running without the API). `ProvisionalRewardCalculator`
     (knk-core) is now unused by the runtime - kept with its tests; delete later if you like.
  4. Players without a cached userId are still skipped in `start`/`complete` (they can't be rewarded) - unchanged.
  5. A null summary (spooled or refused) shows "Your rewards couldn't be confirmed yet … recorded automatically later"
     - wrong wording for the rare refused case (logged SEVERE).
  6. The retry policy is `RetryPolicy.defaultPolicy()` (3 attempts, 100 ms → 5 s backoff), not configurable in
     `config.yml` yet.
  7. The recorder doesn't announce title promotions; the API queues `TitleChanged` for the existing poller (6a
     decision 2).
- **Manual live verification (6b):** plan Phase 6 checklist step 6, plus: (a) `/siege admin start test-cinix`, play
  a short match to the end → chat shows the stats line then "Rewards granted: …"; the `siege_matches` row is
  `Completed`, participants' `*Awarded` match the chat and the balances. (b) Stop the web-api during a match, end it
  → "couldn't be confirmed yet" and `plugins/KnightsAndKings/siege-vault/pending-results/<id>.json` appears; start
  the API, start the next round (draw) or restart the server → the file disappears and the rewards are granted (log:
  "Delivered spooled result"). (c) Kill the server mid-match, restart → log "Startup recovery aborted 1 match(es)".
  (d) `/siege admin stop` during a match → row `Aborted` (`AdminStopped`), no balance change.

## Phase 7 — Gate integration and area lockdown (knk-paper + knk-web-api)

**Scope** (DESIGN §8)
- web-api: `SiegeMatchGateSnapshot` write/read endpoints; override writes reuse
  `PATCH /api/GateStructures/{id}/overrides` (settle its still-open permission model — gate QoL 5.3
  item 5 — as "service client + admins").
- plugin: `SiegeGateController` (snapshot → `CurrentSiegeId` → overrides → `forceGateState`;
  ownership transfer on objective capture with `GateStateOnCapture`; restore at end), `SiegeGateListener`
  (`GateDoorInteractEvent` control by owner alliance; `GateDoorDamageEvent` enemy-only on `Damageable`
  selected gates; everything else in the area invincible/open), startup recovery of gates whose
  `CurrentSiegeId` is stale.
- Lockdown (`LockdownScenarioArea`): deny region entry to non-members into the scenario's districts
  during HUB/IN_PROGRESS; move non-members out at lockdown.

**7b — Non-member gate view (DESIGN §8.5, D6)** — separate sign-off, can follow 7a:
- `SiegeGateViewService`: pre-lockdown block sets from cached `GateBlockSnapshot`/
  `GateOpenedBlockSnapshot`, `Player.sendBlockChanges` to non-members in range; re-send on lockdown,
  every door change/animation frame (hook `GateAnimationTask`/`GateManager` completion callbacks),
  `PlayerChunkLoadEvent`, teleport/respawn/world change, dig/interact on faked blocks, and membership
  changes; clear at restore.
- Virtual collision for "pre-closed / real-open" doors (reuse `CollisionPredictor`/`EntityPusher`).
- Temporary pass-through for "pre-open / real-closed" doors via `GatePassThroughService` **`TELEPORT`**
  mode only (never `DEFAULT`/`INSTANT_OPEN`), conditions waived for the match, never into a locked-down
  district.
- `NonMemberGateView = PassThroughOnly` degrade switch.
- Manual verification with a member and a non-member side by side: the non-member sees pre-lockdown
  states through animations, chunk reloads and relogs; can't walk through a gate they see closed;
  is carried through a gate they see open; the member sees and collides with the real state.

**Manual verification:** selected gate toggles only for owner alliance; enemy damage destroys it and it
stays destroyed; objective capture opens and hands over control; non-selected gates forced open and
unbreakable; everything restored after end **and** after a hard kill of the server mid-match.
**Exit:** D3 behaviour demonstrated live.

> *Superseded in part (2026-09-26): the scenario-area lockdown described here was removed — see "Current behaviour" at the top.*

**Phase 7a status (2026-09-26, overnight chain link 1, on the developer's "just continue anyway"): code complete on
`claude/siege-minigame` in knk-web-api (tested) and knk-plugin (knk-core/knk-api-client compiled and tested;
knk-paper NOT compiled - the cloud container can't reach paper-api), pushed. Not played live.** Commits: knk-web-api
`9328c4e` (endpoints, runtime-config, overrides permission), `07e0a5f` (tests); knk-plugin `b69b786` (core +
api-client), `16a1436` (paper). No migration (the Phase 2 snapshot table and `CurrentSiegeId` FK were enough).
- **knk-web-api:** `SiegeMatchGateService` + `SiegeMatchesController` endpoints `POST {id}/gate-lockdown` (per gate:
  a `SiegeMatchGateSnapshot` with the structure values it changes + each door's open state/health/destroyed is written
  first, then `CurrentSiegeId`, `IsSiegeObjective` and the overrides - `AllowPassThroughOverride = false`,
  `CanRespawnOverride = false`, `IsInvincibleOverride` per role, `OpenedStateOverride = OPEN` for area gates - in one
  `SaveChanges`; a repeat keeps the first snapshot; a gate held by another running match → 409), `POST {id}/gate-restore`
  (re-apply + delete, door rows back, transient states collapsed, returns the snapshots), `POST restore-stale-gates`
  (startup recovery: every leftover snapshot + clears `CurrentSiegeId` on gates without one), `GET {id}/gate-snapshots`.
  Runtime-config scenarios gain **`areaGateStructureIds`** (the other gates in the scenario's districts, or in the
  town when it has none). `PATCH /api/GateStructures/{id}/overrides` now carries `[RequirePluginServiceKey(AllowAdmins
  = true)]` - the gate QoL 5.3 "still open #5" permission settled as "service client + admins" (open while the key is
  unset, as before). Tests: `SiegeMatchGateServiceTests` (6). Suite **710/715**, same 5 known failures.
- **knk-core / knk-api-client (compiled, tested):** `SiegeGatePlan` (roles SELECTED/AREA, runtime owners, `canControl`
  = owner's alliance, `canDamage` = enemies of the owner on damageable selected gates, `onCapture` = owner := capturer's
  team + GateStateOnCapture, every recapture), `SiegeGatesCommandApi` + `KnkSiegeGateRecords`,
  `SiegeGatesCommandApiImpl`, `KnkSiegeScenario.areaGateStructureIds`. Scratch build: knk-core 626, knk-api-client
  50 (2 skipped), all green (+4, +2).
- **knk-paper (uncompiled):** `SiegeMatchObserver.areaLockdownStarted` (fired at the hub, T-15) and `roundReleased`
  (fired in `releaseAll`, i.e. every end/cancel/admin stop/shutdown, after members were released, before the round is
  cleared). `SiegeGateController`: snapshots every affected structure from the gate cache, persists the lockdown, then
  (when the API answered, or failed - then without crash safety) sets the local overrides and drives each door with
  `GateManager.openGate/closeGate`; objective capture → hand-over; round release → local overrides back, destroyed
  doors respawned (`HealthSystem.respawnGate`), health and open state restored, `POST gate-restore`; `recoverOnStartup`
  → `restore-stale-gates`, then `GateManager.reloadGates()` (world blocks then follow via the gate world-sync
  mechanisms B/C). `SiegeGateListener`: right-click on a closed locked gate (`GateDoorInteractEvent`) opens it, on an
  open one (spatial-index lookup in `PlayerInteractEvent`) closes it - owner alliance only, pass-through never runs;
  `GateDoorDamageEvent`/`GateDoorIgniteEvent` cancelled unless an enemy of the owner hits a damageable selected gate.
  `SiegeAreaLockdown` + `SiegeAreaLockdownListener`: while a round is in HUB/IN_PROGRESS non-members can't walk or
  teleport into the scenario's district regions (WorldGuard query, same API as `WorldGuardRegionTracker`) and are moved
  just outside at lockdown; `knk.siege.bypass.lockdown` (new, plugin.yml) skips it. `KnKPlugin` keeps the gate
  `HealthSystem` as a field and wires both.
- **Decisions (7a; ★ = review first):**
  1. ★ **The gate lockdown happens at the hub (T-15), not at T-0**, via the new `areaLockdownStarted` hook (DESIGN §6.5
     "lock scenario" first; gives the API call time; players are at the hub, not at the gates).
  2. ★ **AnimateDuringSiege is not honoured:** every siege state change animates (`openGate`/`closeGate`); the gate
     package has no public instant-placement API (`GateRestingFramePlacer` is package-private). Instant changes need a
     small public method in `gates/` - left for a follow-up.
  3. ★ **Right-click is the control:** owners open a closed gate / close an open gate by right-clicking it (today a
     right-click only triggers pass-through, which is off during the match). Opening/closing moves every non-destroyed
     door of the structure.
  4. The API persists the lockdown before the runtime changes; if that call fails the match still gets its gates (logged,
     no crash safety for that match).
  5. Area gates are forced open + invincible; destroyed doors stay destroyed until the end (`CanRespawnOverride =
     false`); doors destroyed *before* the match are left alone at restore.
  6. Restoring respawns doors with `HealthSystem.respawnGate` (broadcasts its usual "respawned" message, persists full
     health once) and then sets the snapshot health in the cache; the API restore writes the snapshot health to the DB.
     The two async writes can race - a door may briefly persist at full health.
  7. On shutdown no blocks can change; the API restore (or next start's recovery + gate reload) fixes the database and
     then the world.
  8. Area lockdown only with districts (a scenario without districts isn't locked; readiness already warns). Exit point
     = just outside the union bounding box of the locked regions, nearest side, highest block - may land in a
     neighbouring locked district in odd shapes. Plugin-caused teleports are never blocked (the vault restore needs them).
  9. Gate structures not in the plugin's gate cache are skipped (logged); a gate already locked by another lobby is
     skipped (the runtime locks normally prevent that).
- **Manual live verification (7a; after `restore-stale-gates` has run once on start):**
  1. Start a round on `test-cinix`; at the hub (T-15): log "N gate structure(s) locked down for match X"; the DB
     `siege_match_gate_snapshots` has one row per affected gate; `gate_structures.CurrentSiegeId` = X; South Gate/Northern
     Gate go to their initial state, other gates in the districts open.
  2. As a defender right-click the closed selected gate → it opens; again → closes. As an attacker → "held by the
     enemy". A non-member → "part of the siege". Area gate → "held open".
  3. Attackers hit a damageable selected gate until destroyed → stays destroyed; defenders can't damage their own gate;
     area gates take no damage; nobody can pass through.
  4. Capture the objective gate's objective → the gate opens (GateStateOnCapture) and now the attackers control it.
  5. End the match → all gates back to their pre-lockdown state (destroyed door respawned, health, open/closed), snapshots
     deleted, `CurrentSiegeId` null.
  6. Kill the server mid-match, restart → log "Gate recovery restored N gate structure(s)"; DB back; gates in the world
     correct after walking into the district (or within the periodic sync).
  7. Area lockdown: a non-member inside a district at T-15 is moved out; walking or `/tp`-ing in is refused during the
     round; a member who leaves is teleported back to their saved spot even inside the area; after the end entry works.
- **What 7b must wire:** `SiegeGateController` owns the snapshot (`StructureSnapshot.doors`, pre-lockdown open state per
  door) and knows locked structures (`isLocked`, the plan's roles); the non-member view needs those plus the member test
  (`SiegeLobbyRuntime.isMember`) and the `areaLockdownStarted`/`roundReleased` hooks; `SiegeConfiguration.nonMemberGateView`
  is already in the runtime config (`KnkSiegeConfiguration`).

> *Superseded (2026-09-26): non-members now see locked gates removed and walk through them — see "Current behaviour" at the top.*

**Phase 7b status (2026-09-26, overnight chain link 1): code complete on knk-plugin `claude/siege-minigame`
(`d475195`), knk-paper only, NOT compiled (paper-api unreachable from the cloud) and not tested - there is no pure
logic to unit-test here; the view needs a live server with a member and a non-member side by side.** No web-api change
(`SiegeConfiguration.NonMemberGateView` already exists and reaches the plugin in runtime-config).
- **Classes:** `paper.siege.SiegeGateViewService` (a 5-tick task + listener), `paper.gates.GateViewCells` (new, public
  read-only access to `GateRestingFramePlacer.restingFrameCells` - no gate engine class changed),
  `SiegeGateController.lockedDoors()`/`LockedDoor` (pre-lockdown state per door of applied lockdowns) and
  `tryNonMemberPassThrough`, `SiegeAreaLockdown.isLocked(lobbyId)`; `SiegeGateListener` tries the pass-through first
  for non-members; `KnKPlugin` keeps the `GatePassThroughService` as a field and wires the view service.
- **Behaviour:** for each locked door whose real state differs from its pre-lockdown state, non-members within 96
  blocks get the pre-lockdown resting frame as `sendBlockChange`s and the real frame's other cells as air. Sent per
  (viewer, door) only when the door's real state/frame changed, the viewer entered range, or after a teleport, respawn,
  join or world change. Virtual collision: a non-member can't step (feet or head) into a cell that looks like a closed
  door but is open/destroyed in reality. A non-member right-clicking a door that is closed now but was open before
  gets the gate's **TELEPORT** pass-through (never DEFAULT/INSTANT_OPEN), refused while the scenario area is locked
  down. When a lockdown ends, everyone who got fakes is sent the real blocks 5 s later (after the restore animations).
  `NonMemberGateView = PassThroughOnly` → no fakes, no collision, pass-through only.
- **Decisions (7b; ★ = review first):**
  1. ★ **No per-frame hooks into the gate animation:** fakes are re-sent on the next 5-tick pass after a real change,
     so a non-member sees the real animation briefly before their view is restored. Cheap and needs no gate-package
     changes; if it looks bad live, switch the lobby's config to `PassThroughOnly` (the developer's stated minimum).
  2. ★ **The pass-through is triggered by right-click** (the gate's usual pass-through gesture), not by walking into
     the gate.
  3. The pass-through is refused while the scenario area is locked down (the far side is the siege area). So in practice
     it only helps on scenarios with `LockdownScenarioArea = false`; see follow-ups.
  4. No `PlayerChunkLoadEvent` hook: leaving the 96-block range drops the record, so coming back re-sends; chunk
     reloads happen beyond that range.
  5. Mid-animation the "hidden" cells are the target resting frame's, an approximation.
- **Manual live verification (7b; member A, non-member B):**
  1. With the default `PreLockdownView`: at the hub lockdown, B (outside the area) sees the gates as before; A sees
     the siege state. Walk around, relog, teleport away and back → B's view stays pre-lockdown.
  2. A gate that was open before and is closed now: B right-clicks it → refused while the area is locked ("this area is
     closed"); on a scenario without area lockdown → carried across (TELEPORT).
  3. A gate that was closed before and is open now (area gate): B can't walk through what they see as closed; A walks
     through.
  4. Owners animate a gate: B sees a short flicker, then the pre-lockdown view again.
  5. After the match: B sees the real (restored) gates within ~5 s.
  6. Set `SiegeConfiguration.NonMemberGateView = PassThroughOnly` (web app / PUT), `/siege admin reload` between
     matches → B sees the siege state, no collision; the pass-through still works where allowed.
- **Follow-ups:** decide whether the pass-through should also work *out of* a locked area or along its border (today
  refused whenever the area is locked); per-frame re-send via a `GateManager` hook if the flicker is a problem.

## Phase 8 — Menus (knk-web-api, knk-plugin) — after Phase 5

**8a — InventoryMenu Phase 9 "domain integration"** — *delegated 2026-09-25 to a separate Claude Code
session, branch `claude/inventorymenus` in knk-web-api and knk-plugin (forked from `master`/`main`);
built the same day (web-api `07b6174`, `86a72d9`; plugin `38abc14`, `2c3b0ad`, `216bb3b`), pushed,
not verified in-game; see `docs/specs/inventory-menu/IMPLEMENTATION_PLAN.md` Phase 9 for the syntax and the
findings 8b must follow (absolute `SlotOverride`, one phase-aware Body source, `MenuFeature` registration,
`menu.confirm.doubleclick` only on pinned items).* **Merged 2026-09-25 into `claude/siege-minigame`**
in both repos (no conflicts, no EF model drift; migration `20260925123418_AddInventoryMenuPhase9DomainIntegration`
is still the newest). The web-api test file `MenuTemplateServicePhase9Tests` had been left untracked
and was committed on the siege branch (`aaddbd5`). Post-merge tests: web-api 413/418 (the same 5 failures
as `master`), knk-core 512 / api-client 28 / knk-paper 246, all green. **Still open:** live verification
(the manual `example.domain` checklist in the InventoryMenu plan Phase 9) and applying the migration to a
DB, both before trunk merge; the siege branch carries 8a until then. Scope reference:
`MENU_TEMPLATES.md` Part B, E1–E9; Kits' future menu benefits from the same work.

**8b — Siege menus** (unblocked on `claude/siege-minigame`; still sequenced after Phase 5): register siege variable roots, content sources, actions and conditions
(DESIGN §10.2–10.3) before `MenuDefinitionValidationRunner`; seed `siege.overview`,
`siege.information`, `siege.spawnpoint` and the `siege.entry` item per `MENU_TEMPLATES.md` Part C
(create-only seeds, `MenuTemplateSeed` convention); switch `/siege`, respawn and match start from chat
fallbacks to menus (fallback commands stay).

**Manual verification:** every row of `MENU_TEMPLATES.md` C.5 against a live match, including the
N-number fixes.

> *Updated since (2026-09-26): both menus are Dynamic height and a lobby in cooldown isn't opened; the spawn picker no longer opens after every respawn — see "Current behaviour" at the top.*

**Phase 8b status (2026-09-26, overnight chain link 1): code complete on `claude/siege-minigame` - knk-web-api seeds
tested; knk-plugin knk-core/knk-api-client compiled and tested (including a seed ↔ plugin contract test); knk-paper
NOT compiled (paper-api unreachable from the cloud). Not verified in-game.** Commits: knk-web-api `78945ca`;
knk-plugin `901c599` (core + api-client), `0522e44` (paper).
- **knk-web-api:** `Models/Menu/MenuTemplateSeed.Siege.cs` (create-only, chained after the content-port seeds):
  `siege.overview` (Height 5, AutoRefresh 20: header with lobby/player counts and the viewer's "you are in …" line;
  `siege.lobbies` grid, matchmaking first, pager 36/44, empty-state BARRIER at 22 behind `siege.lobbies-empty`; a row
  opens `siege.information` with `ctx.lobbyId`), `siege.information` (Height 6: change-spawn COMPASS [IN_PROGRESS +
  participating], status banner, objective help [scenario known], back; `siege.vote-candidates` votes grid 9-12;
  join/leave at 14 [MATCHMAKING] - join click-checked by `siege.join-eligible`, leave behind `menu.confirm.doubleclick`;
  divider with the players/teams skull at 22; phase-aware `siege.body` grid 27-53 with pager 45/53), `siege.spawnpoint`
  (Height 3: current choice, close; `siege.spawn-options` grid with pager 18/26; click → `siege.spawn` + `menu.close`,
  re-checked by `siege.spawn-available`). `MenuTemplateSiegeSeedTests` (6): each template passes the API's create-path
  validation, wiring checks, and `SiegeSeeds_ExportAsApiJson` writes the fixture when `KNK_SIEGE_MENU_SEED_EXPORT` is
  set. Suite **716/721**, same 5 known failures.
- **knk-core (compiled, tested):** `core.siege.menu`: `SiegeMenuIds` (every key/root/source/action/condition id),
  `SiegeMenuSnapshot` (one lobby as the menus see it), `SiegeMenuFormat` (`&`-colours, durations, banner-pattern
  strings), views `SiegeLobbyMenuView`, `SiegeViewerMenuView`, `SiegeServerMenuView`, `SiegeVoteOptionView`,
  `SiegeBodyRowView`, `SpawnOptionView` (public zero-arg getters; rows implement `MenuRowKey`). `SiegeMenuViewsTest` (6).
- **knk-api-client (compiled, tested):** `SiegeMenuSeedContractTest` loads `src/test/resources/menu/siege-seeds.json`
  (exported from the web-api seeds) through the real DTO + mapper, assembles each template and runs knk-core's
  `MenuDefinitionValidator` (bindings against the view classes, action/condition/source ids) - proven to fail on a
  misspelled getter. Scratch build: knk-core **632** (+6), knk-api-client **53** (+3, 2 skipped), all green.
- **knk-paper (uncompiled):** `SiegeMenuFeature` (registered in `KnKPlugin`'s menu-feature list before validation, with
  a `SiegeService` supplier because the service is created later), `SiegeMenuSnapshots` (runtime → views),
  `SiegeMenuBridge` (observer: repaints open `siege.*` menus on `lobbyChanged`/`objectiveCaptured`; implements the new
  `SiegeService.MenuHooks`). `/siege` opens the viewer's own Information, else the overview (chat list stays as the
  fallback); the spawn picker at match start/respawn opens `siege.spawnpoint` (chat list stays as the fallback).
  `SiegeService` gains `vote(Player, VoteChoice)` (the text form reads small numbers as list positions), `joinDenial`
  (join's checks without side effects), `cachedUser`, `setMenuHooks`/`openMenu`.
- **Decisions (8b; ★ = review first):**
  1. ★ **The hub's Siege tile (C.1) is unchanged**: it already opens `siege.overview` behind `menu-available` (content
     port CP1), so it appears once the siege seeds validate. The `siege.open-own` action and the "you are in Siege N"
     line exist (`siegeServer.getEntryHintLine` is on the overview header) but aren't on the hub tile - the hub is
     already seeded in the dev DB (create-only); edit it via the CRUD API or re-seed with `scripts/reset-content-menus.ps1`.
  2. Lore that depends on the row kind uses one list getter (`$row.getLines$`, `$row.getStatusLines$`) instead of
     Part C's per-line bindings; the vote row has one `siege.vote` action (`scenarioId` = "random" for Random).
     `siege.vote.random` is registered too.
  3. Objective banners in the body are the holder team's banner, not the live capture gradient; the gate status in
     the objective row is left out (the menu snapshot has no gate state).
  4. "Rank" in member rows is the premium tier name (replaces v2's hard-coded "Donator"); "-" when none.
  5. The overview's pinned filler panes (C.2 slots 37-43) are left out; the empty-state item at 22 is pinned, so a
     15th lobby would skip that slot.
- **Manual live verification (8b; after applying nothing - seeds run on the web-api start):**
  1. Restart the web-api: the log's "MenuTemplate seed complete. Templates created: 3" (first start only); the plugin's
     startup validation lists no blocked `siege.*` menu (`/knk menu broken` or the log).
  2. `/menu` → the Siege tile appears → overview lists the lobbies (matchmaking first, banner colour by phase, member
     count as stack size); a lobby opens its Information.
  3. Matchmaking: vote candidates + Random with counts, your vote highlighted, click again removes it; non-members get
     "You must join the Siege…"; the join button (and its denial line when you can't join) → join → the button becomes
     "Click to leave" (double-click to confirm).
  4. The body lists members (heads, title, rank, team after the split); in progress it lists objectives (holder,
     captured %, captured by, gate, contested).
  5. At match start and after a respawn with ≥ 2 options the spawn picker opens; a contested objective is DISABLED
     and refused at click; picking sets the choice (teleports right after start/respawn).
  6. `/siege` opens your own siege's Information (else the overview); with the web-api seeds missing, `/siege` still
     prints the chat list.

## Phase 9 — Playtest, balancing, seed data, docs

- Seeds: `SiegeConfiguration` defaults (Phase 2), one disabled example lobby. **No seeded scenario** —
  scenarios need real in-world points; author the first one live (Phase 3 flow) and record it in
  `docs/specs/siege-minigame/SEED_DATA.md` if it should be reproducible.
- Balancing pass on capture constants, durations, rewards (DESIGN §7.2 note).
- Update `docs/vision/vision.md` §7 status lines, `docs/specs/README.md`, and write
  `docs/guides/` admin how-to ("Authoring a siege scenario").

**Phase 9 status (2026-09-26, overnight chain link 1): non-live parts done - seed/model defaults and the example
lobby on knk-web-api `claude/siege-minigame` (`ee29768`, tested), docs in the workspace. Playtesting and balancing are
the developer's (live).**
- **Capture defaults:** `SiegeConfiguration.CaptureAttackBase` and `CaptureAttackPerExtraInstantVictory` default to
  **10** (was 5): the dev DB's playtest tuning A1 10, A2 2, IV A2 10, D 6/3/6 (DESIGN §7.2 "Playtest tuning"). These
  are C# property initializers only (the model snapshot has no `HasDefaultValue` for them), so **no migration**; the
  API creates the configuration row from the model on first read, so this only affects a fresh DB. An existing row
  (the dev DB) keeps its values. `KnkSiegeConfiguration.legacyDefaults()` in knk-core stays 5/2/5 (the charter: leave
  it alone; it's the plugin's offline fallback, which mirrors the legacy plugin).
- **Example lobby:** `Models/Siege/SiegeLobbySeed.cs`, create-only by key `example`: "Example siege (disabled)",
  `IsEnabled = false`, Continuous, 300 s / 900 s, 2 candidates + Random, **no rotation**. Wired last in the
  `Program.cs` seed block. Disabled lobbies aren't in runtime-config, so the plugin never sees it. **No seeded
  scenario** (it needs real in-world points).
- **Docs:** new admin how-to `docs/guides/authoring-a-siege-scenario.md` (banner/clan → scenario → readiness codes →
  lobby → settings → `/siege admin reload`); `docs/vision/vision.md` §7 status lines; `docs/specs/README.md` siege
  entry.
- **Tests:** web-api **718/723**, the same 5 known failures (+2 new `SiegeLobbySeedTests`; 3 default assertions moved
  from 5 to 10).
- **Decisions (9):**
  1. Only the two differing values changed; the model comment names the legacy values.
  2. The example lobby has no rotation, so enabling it can't start a match until a ready scenario is added. That's
     deliberate: a seed can't know a scenario id.
- **Manual (developer):** on a **fresh** DB the configuration page shows A1 10 / IV A2 10 and the lobby list shows the
  disabled `example`. On the dev DB the only change is a new `example` lobby row at the next API start. The seed is
  create-only *by key*, so a **deleted** row comes back on the next start; to get rid of it, rename its key or just
  leave it disabled.
- **Left for the developer (live):** playtest and balance (durations, rewards, capture constants), and optionally record
  a reproducible first scenario in `SEED_DATA.md`.

**Smoke-test follow-ups (2026-09-26, the developer's first live pass):** both siege branches merged with trunk
(web-api `9069549`, plugin `d6753df`; the KNG-11 combat safezone now exempts hits the siege rules allow via
`SiegeService.allowsCombat`). The menu background default is now `GRAY_STAINED_GLASS_PANE` (`b4a9623`). Then
knk-plugin `0fa6d06` (knk-paper uncompiled):
- **Remembered spawn choice:** the picker opens at match start (ignoring it stores the team default) and after a
  respawn only while no choice is stored. A captured objective resets its choosers to their team's default spawnpoint,
  with a message pointing at `/siege menu` ("Change spawnpoint" in Information).
- **`/siege menu`**, plus `/siegemenu` (alias `/sgm`, because `/sm` is `/staffmode`): the member's own siege Information
  menu from matchmaking to match end, refused for non-members. Both labels always pass the in-match command filter.
- **Capture rings on the floor:** the ring and the capture distance use the floor under the capture point
  (`SiegeFloor`: up to 4 blocks down, lifted out of a solid block). Objective banners still sit at the stored point.
- **Coin multipliers** (web-api `843bca3`): siege coin rewards = base x `PersonalSalaryMultiplier` x rank multiplier
  (product of active groups' `SalaryMultiplier`, premium tiers included; shared `CoinRewardMultipliers`, also used by
  salary). Salary's `GlobalMultiplier` is not applied; XP and gems are unchanged. The reward DTO adds `baseCoins` and
  `coinMultiplier`, and the plugin's reward line shows "(xN bonus)".
- **Capture feedback** (plugin `002067c`, `CaptureActivityTracker` + `SiegeCaptureFeedback`): when an attack begins, the
  attackers' alliance hears a goat horn, sees crits and is told who began capturing (or retaking) what; the holder's
  alliance hears the alarm bell, sees angry-villager clouds and is told what is being captured, by which team, at how
  many percent. When a defence begins (the holder pushing the points back up), the holders hear a second horn and see
  happy-villager particles, and the other side hears a bass note and sees smoke; both get a chat line. Every second,
  the players doing it hear a pling (attack) or chime (defence) whose pitch rises with progress, with particles
  members nearby see. A capture adds a totem burst. Re-announce window 15 s per objective and activity, reset on
  capture. The cues are constants at the top of `SiegeCaptureFeedback`.
- **Objective banners** (plugin `725af30`): the holder's full team banner (patterns included) from match start while
  fully held, the v2 8-stage gradient towards the leading attacker's colour while being captured, the attacker's full
  banner at the capture moment. Fixed: an objective captured for good showed the old holder's colour. The banner now
  stands on the floor under the capture point; a blocked spot logs a warning with coordinates.
- **Trunk merges again** (KNG-7/8 chat and tab-list colours): web-api `37e589b` (771/776, same 5 known failures; new
  trunk migrations `AddPermissionGroupDisplayColors`, `PremiumRanksInheritDefault`), plugin `f5f696e` (core 741,
  api-client 67). Watch: trunk's tier re-sync calls `ScoreboardUtil.setScoreboard`, which would replace a siege
  member's match scoreboard if staff change their rank mid-match.
- **Third trunk merge (KNG-16 salary/multipliers)**: web-api `6757812` (siege coins now use master's
  `RankMultipliersDto`; master's scaled title bonuses moved into the shared `TitleProgression`, so siege promotions get
  them too; 806/811), plugin `277bd36`, web-app `3e5770e` (Siege Settings added to master's `NAV_LINKS`). Siege reward
  lines use the shared KNG-16 `RewardMessageFormat` (plugin `dfbdf79`). Live checklist:
  `docs/reports/2026-09-26-siege-smoke-test-checklist.md`.
- **Second smoke-test round fixes** (plugin `1d00d39`, web-api `066a171`, web-app `df3f756`): the **area lockdown is
  removed** (non-members stay in the area and just can't fight members, capture or use siege gates; the scenario's
  `LockdownScenarioArea` flag and the `LOCKDOWN_WITHOUT_DISTRICTS` warning no longer have an effect - clean up later);
  locked siege gates are **removed for non-members** and walking into a really closed door carries them across
  (TELEPORT pass-through); objective banners are protected; the gate hover shows state + `(JAMMED)` + `INVINCIBLE` and
  refreshes on animation start; the capture cue is a chime every 5 s; `siege.overview`/`siege.information` are Dynamic
  and a lobby in cooldown isn't opened (seeds are create-only: delete the three `siege.*` templates to pick it up);
  the web app hides Dashboard/Forms/builders/settings from non-staff.

## Phase 10 — Post-MVP

- `Scheduled` lobby mode (`ScheduleJson`, next-start computation, announcements ahead of the slot) —
  vision §3.4 cadence.
- Web-app live monitor (plugin heartbeat of lobby runtime state → read-only dashboard) and match
  history pages.
- Siege panel in the user-management player profile (DESIGN §13 Q7).
- Open questions Q4–Q6, Q8 as decided.

## Delegation notes

- Phases 1, 2 and 4 are mechanical and well-specified — good short-burst sessions, each testable alone.
- Phase 3 starts with its four verification items; don't author all forms before item 1 is confirmed.
- Phase 5 is the largest and needs a live server with several accounts for sign-off; split it into
  5a (loop + commands + vault) and 5b (combat/death/respawn + presenters) if a session runs long.
- Phase 7 touches the gate subsystem; read `docs/specs/gate-structure-animation/PHASE_STATUS.md` and
  `GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md` first.
- Phase 8a is engine work, not siege work — treat it as its own InventoryMenu phase with its own review.
