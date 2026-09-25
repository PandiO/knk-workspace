# Siege Minigame — Implementation Plan

**Status:** Draft. Phases 1–7 + 9 = playable MVP (commands/chat UI), not started; Phase 8a (InventoryMenu
engine extensions) built and merged into `claude/siege-minigame`, not verified live; Phase 8b open;
Phase 10 is post-MVP.
**Last updated:** 2026-09-25 (standing branch `claude/siege-minigame` created from current trunk in
knk-web-api and knk-plugin with Phase 8a merged in; §0 trunk note corrected — user-management is on
trunk)

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
