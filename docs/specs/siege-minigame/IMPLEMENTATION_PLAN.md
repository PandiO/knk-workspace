# Siege Minigame — Implementation Plan

**Status:** Draft. Phases 1–7 + 9 = playable MVP (commands/chat UI): **Phases 1, 2 and 3 code complete** on
`claude/siege-minigame` (Phase 2 migration applied to the dev DB and API verified live with test data;
Phase 3 FormConfigurations authored in the dev DB and the forms proven against the live API; nothing verified
in-game yet); Phases 4–7 + 9 not started. Phase 8a
(InventoryMenu engine extensions) built and merged into `claude/siege-minigame`, not verified live;
Phase 8b open; Phase 10 is post-MVP.
**Last updated:** 2026-09-25 (Phase 3 status block added: siege authoring forms, verification items 1–4,
FormConfiguration ids, decisions to review, browser walkthrough for the developer)

Ref: `DESIGN.md` (decisions — not restated here), `MENU_TEMPLATES.md`,
`docs/reports/2026-09-25-siege-minigame-gap-analysis.md`. Plan format follows
`docs/specs/kits/IMPLEMENTATION_PLAN.md` (branch `claude/kits`).

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

## Phase 9 — Playtest, balancing, seed data, docs

- Seeds: `SiegeConfiguration` defaults (Phase 2), one disabled example lobby. **No seeded scenario** —
  scenarios need real in-world points; author the first one live (Phase 3 flow) and record it in
  `docs/specs/siege-minigame/SEED_DATA.md` if it should be reproducible.
- Balancing pass on capture constants, durations, rewards (DESIGN §7.2 note).
- Update `docs/vision/vision.md` §7 status lines, `docs/specs/README.md`, and write
  `docs/guides/` admin how-to ("Authoring a siege scenario").

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
