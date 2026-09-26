# Domain Discovery — Implementation Plan

**Status:** Draft — awaiting developer review (open questions in DESIGN.md §5)
**Last updated:** 2026-09-26
**Linear:** [KNG-20](https://linear.app/kngpandi/issue/KNG-20/domain-discovery-first-entry-rewards-for-townsdistrictsstructures)
**Sources:** [DESIGN.md](DESIGN.md); `docs/ACTIVE_SESSIONS.md` (branch convention); `specs/inventory-menu/CONTENT_PORT_PLAN.md`
(menu content pattern, CP7 auth status); `specs/user-features/DESIGN.md` §5 (salary multipliers).

## 0. Conventions and dependencies

- **Branches** (one standing branch per feature per repo, `ACTIVE_SESSIONS.md` convention): `claude/domain-discovery` in
  knk-web-api (off `master`), knk-plugin (off `main`), knk-web-app (off `main`). Reuse them for every phase; merge to trunk
  per phase once verified. Claim the feature row in `docs/ACTIVE_SESSIONS.md` before starting and update it at each pause.
- **Baselines:** record `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` (5 known pre-existing failures per
  CONTENT_PORT_PLAN), `./gradlew test`, `npm run test:ci` before Phase 1. Note: the web-api test project lives in `Tests/`
  (capital T), not `tests/` as `knk-web-api/CLAUDE.md` says.
- **Depends on (already present on the checked-out branches):** inventory-menu engine + content port (menu features,
  `menu-available`, `menu.filter.cycle`), user-features Phase 5/6 (`PermissionGroup.SalaryMultiplier`,
  `User.PersonalSalaryMultiplier`, `TitleBracket` real data), `TitleProgression`, `PromotionEffects`, siege spool pattern.
  Verify each is on trunk before merging; if not, merge order follows them.
- **Soft dependencies (don't block):** `specs/currency-payments/` (ledger + idempotency keys → Phase 5), inventory-menu CP7 /
  plugin API auth (DESIGN Q4 → Phase 5), `specs/teleport/` (future "teleport to discovered place" row action).
- No Linear issue among KNG-5/6/12/14/16 overlaps this feature.

| Phase | Repos | Size | Shippable alone? |
|---|---|---|---|
| 1 — Data model, rewards, grant API | web-api | M | Yes (API only, testable via Swagger) |
| 2 — Plugin detection, grant, effects, spool | plugin | L | Yes, with Phase 1 |
| 3 — Discoveries menu + commands | web-api (seed) + plugin | M | Yes, after 2 |
| 4 — Web-app admin + player views | web-app (+ small web-api reads) | M | Yes, after 1 |
| 5 — Ledger/idempotency + auth adoption | web-api + plugin | S | After currency-payments / CP7 |

---

## Phase 1 — Data model, reward calculation, grant API (knk-web-api)

**Tasks**
- New `Models/UserDomainDiscovery.cs`, `Models/DiscoveryRewardRule.cs`, `Models/DomainDiscoveryOverride.cs`,
  `Enums/DiscoverySource.cs`; `Enums/AuditAction.cs` add `DiscoveryReset = 12`.
- `Properties/KnKDbContext.cs`: DbSets + mapping (tables `user_domain_discoveries`, `discovery_reward_rules`,
  `domain_discovery_overrides`; unique `(UserId, DomainId)`; indexes `(DomainId)`, `(UserId, DiscoveredAt)`; FKs per DESIGN §3.1).
- Migration `Migrations/<ts>_AddDomainDiscovery.cs` — seeds the four type rules (DESIGN §3.1 table).
- Extract **`Services/RewardMultiplierService.cs`** + `Services/Interfaces/IRewardMultiplierService.cs` from
  `SalaryService.ComputeRankMultiplierAsync`; make `SalaryService` (and thus `GetCurrentRankMultiplierAsync`) delegate to it.
  Auto-registered by the `I<Name>` convention scan (`DependencyInjection/ServiceCollectionExtensions.cs:168-173`).
- `Services/DiscoveryRewardCalculator.cs` (pure static; `Random` injected) — DESIGN §3.3.
- `Repositories/DiscoveryRepository.cs` + interface: `RunLockedForUserAsync(userId, work)` (transaction + `SELECT Id FROM users
  WHERE Id = … FOR UPDATE`, non-relational fallback like `SiegeMatchRepository.RunLockedAsync`), discovered-id lookup,
  trailing-hour count, rule/override CRUD, progress/summary/stats queries.
- `Services/DiscoveryService.cs` + interface — DESIGN §3.4 (resolve region ids via `IDomainRepository.GetByWgRegionNameAsync`,
  ancestor expansion, rate cap, one `IUserService.AdjustBalancesAsync` call inside the transaction with `notifyPlayer: false`).
  Confirm `UserRepository.UpdateUserAsync` and `AuditLogService.RecordAsync` use the same scoped `KnKDbContext` (they must, for
  the transaction to cover them); if either opens its own transaction, add an overload that doesn't.
- `Services/DiscoveryConfigurationService.cs` — rules/overrides CRUD + validation + preview.
- `Dtos/DiscoveryDtos.cs`; `Controllers/DiscoveriesController.cs` — all routes in DESIGN §3.5 (grant, known, progress, summary,
  reset, rules, overrides, preview, stats).
- Metrics meter `knk.discovery` registered in `DependencyInjection/ObservabilityServiceCollectionExtensions.cs`.

**Tests** (`Tests/knkwebapi_v2.Tests/…`)
- `Services/DiscoveryRewardCalculatorTests.cs`: unit per bracket incl. top bracket and no-bracket fallback; v1 parity (Town XP at
  Serf 25–100, Count 100–400); salary-hours coins; flat gems; multiplier application and rounding; negative clamp; override
  inheritance (null fields fall back).
- `Services/DiscoveryServiceTests.cs`: first grant writes row + balances + one `BalanceAdjusted` audit; repeat call → nothing new,
  `alreadyDiscovered`; ancestors granted top-down; disabled type/override skipped; unknown region → `NotADomain`; case-insensitive
  region match; hourly cap → `RateLimited`; title crossing returns consolidated `titleChange`; >50 ids → 400.
- `Services/RewardMultiplierServiceTests.cs` + existing `SalaryServiceTests` unchanged and green.
- `Api/DiscoveriesControllerTests.cs`: status codes and DTO shape per route.
- A MySQL-backed integration test (in `Integration/` if the project runs one) for two concurrent grants → exactly one row.

**Acceptance**
- `POST api/users/{id}/discoveries {wgRegionIds:["<district region>"]}` for a fresh user grants District + its Town, balances
  and audit reflect Σ rewards; second identical call returns both under `alreadyDiscovered` and changes nothing.
- Migration applies on the dev DB; four rule rows present; `dotnet test` = baseline + new tests, no new failures.

**Size:** M. **Depends on:** nothing new.

---

### Phase 1 status — done 2026-09-26 (knk-web-api `claude/domain-discovery`)

Commits `f335d36` (tables, unique (UserId, DomainId), four seeded type rules incl. the developer's smaller Structure and
GateStructure rewards, `AuditAction.DiscoveryReset = 17`), `edf58eb` (reward calculator; shared `CurrencyMultipliersDto`
extracted from KNG-16's title-bonus code, `UserService` behaviour unchanged), `620f0a7` (grant endpoint, known/progress/
summary reads, reset, stats), `3245abf` (admin rules/overrides + per-title preview), `1110894` (DTOs — `620f0a7`/`3245abf`
don't build on their own). Tests 699 (694 pass, the 5 baseline failures; 106 new). Migrations CI green:
https://github.com/PandiO/knk-web-api/actions/runs/36253349661; also verified on local MySQL 8.0 (up/down/up; 10
concurrent identical grants → one credit, one audit row; admin endpoints 401 without login).

Deviations: multipliers per currency (coins = personal × rank salary, gems = GemBonus pair, XP = ExpBonus pair, mirroring
KNG-16 title bonuses), so rows store `CoinMultiplier`/`GemMultiplier`/`ExpMultiplier`; grant result returns base, granted
and per-currency multiplier lists for `RewardMessageFormat`; no `RewardMultiplierService` (uses `CurrencyMultipliersDto.For`);
reset route requires `knk.admin.discovery` (prevents reward farming); rules/overrides in a separate
`DiscoveryRewardsController`; hourly cap = config `Discovery:MaxNewPerHour` (default 120, 0 = off); metrics counters are
inert until OpenTelemetry metrics are wired (TODO in Program.cs).
Endpoints needing KNG-22 service auth: `POST api/users/{userId}/discoveries`, `GET …/discoveries/known`,
`POST …/discoveries/progress`, `GET …/discoveries/summary` (+ reset once the plugin calls it).
Developer to-do: apply `AddDomainDiscovery`; grant `knk.admin.discovery` to staff. Known: `Domain.WgRegionId` isn't
unique (lowest id wins); snapshot conflicts with other branches' migrations at merge.

## Phase 2 — Plugin detection, grant, effects, spool (knk-plugin)

**Tasks**
- knk-core: records `core/domain/discovery/{DiscoveryGrantResult, DiscoveryGrant, KnownDiscovery, DiscoverySummary,
  DiscoveryProgressRow}.java`; port `core/ports/api/DiscoveriesApi.java` (grant, known, progress, summary, reset).
- knk-core: `core/discovery/DiscoveryTracker.java` (per-player known / notDomain / pending / inFlight, batching, per-player
  request rate, response handling — DESIGN §3.6) and `core/discovery/DiscoverySpool.java` (modelled on
  `core/siege/SiegeResultSpool.java`), plus a small `DiscoveryRecorder` wrapper applying `core/dataaccess/RetryPolicy.java`
  and spooling transient failures (modelled on `SiegeMatchRecorder`).
- knk-api-client: `api/impl/DiscoveriesApiImpl.java`, DTOs + mapper, `api/client/KnkApiClient.java` getter.
- knk-paper:
  - `paper/events/UserDataLoadedEvent.java` (new) fired from `paper/listeners/UserAccountListener.java` right after
    `joinLoadingGuard.release(online)` (line ~104).
  - `paper/discovery/DomainDiscoveryListener.java` — `OnRegionEnterEvent` (MONITOR) + next-tick confirmation via WG
    `getApplicableRegions`; `UserDataLoadedEvent` (load known set, enqueue `JoinInside` regions); `PlayerQuitEvent` (spool pending,
    evict).
  - `paper/discovery/DiscoveryEligibility.java` — `ModeService`, `AdminFreezeManager`, `JoinLoadingGuard`, game mode,
    siege participation.
  - `paper/siege/SiegeService.java` — add `isParticipant(UUID)` (over the lobby runtimes' `isMember`).
  - `paper/discovery/DiscoveryEffects.java` — sound/particles/chat, `PromotionEffects.show` for `titleChange`, update cached
    `UserSummary` balances.
  - `paper/discovery/DiscoveryFlushTask.java` — repeating batch flush + spool replay timer.
  - `paper/config/KnkConfig.java`, `paper/config/ConfigLoader.java`, `src/main/resources/config.yml` — `discovery:` block
    (DESIGN §3.6).
  - `paper/KnKPlugin.java` — wiring (after `modeService`, `adminFreezeManager`, `joinLoadingGuard` exist; spool replay on enable).

**Tests**
- knk-core `DiscoveryTrackerTest`: known-set filtering, queued-before-load then filtered, batch size ≤ 50, per-minute limit,
  in-flight guard, each response bucket (granted/already/NotADomain/Disabled/RateLimited back-off).
- knk-core `DiscoverySpoolTest` / `DiscoveryRecorderTest`: transient failure spooled, 4xx dropped, replay removes file on success,
  atomic write.
- knk-api-client `DiscoveriesApiImplTest`: request/response JSON (use `src/test/resources` fixtures like the menu tests).
- knk-paper `DiscoveryEligibilityTest` (each exclusion), `DiscoveryEffectsTest` (message formatting: parent suffix, zero
  amounts omitted, v1 colours).

**Acceptance (in-game, dev server)**
- Walking into an undiscovered Town: one chat line + sound + particles; balances in `/account` and the API match; walking out and
  back in: nothing.
- Joining while standing inside an undiscovered District: District + Town discovered after the join messages.
- Teleporting into a Structure: Structure, District, Town discovered in that order.
- A `AllowEntry=false` domain: bounced player discovers nothing.
- `/staffmode`, creative, frozen players: nothing; after leaving the mode and re-entering: discovered.
- API stopped: discovery spooled (file appears), API restarted → rewards granted within ~60 s and summary chat shown.

**Size:** L. **Depends on:** Phase 1 deployed to the dev API.

---

### Phase 2 status — done 2026-09-26 (knk-plugin `claude/domain-discovery`)

Commits `42c582a` (knk-core `DiscoveriesApi` port, `DiscoveryTracker`, `DiscoverySpool`, `DiscoveryRecorder`), `163a7af`
(knk-api-client `DiscoveriesApiImpl`, DTOs matching Phase 1 field-for-field), `ac32dcf` (knk-paper `UserDataLoadedEvent`,
`DomainDiscoveryListener`, `DiscoveryEligibility`, `DiscoveryEffects`, `DiscoveryMessages`, `DiscoveryFlushTask`, `discovery:`
config block). Local: knk-core 523/523 (24 new), api-client 54/54 (7 new); CI green
https://github.com/PandiO/knk-plugin/actions/runs/36258798189.
Detection from raw WG region ids on block-change moves and teleports (monitor priority, ignores cancelled events, next-tick
re-check), plus join via `UserDataLoadedEvent` (loads the known set, queues current regions, replays the spool). Exclusions:
loading, staff/owner mode (incl. vanish), frozen, creative/spectator, siege participants (hook
`getDiscoveryEligibility().setSiegeParticipantCheck(...)` — siege isn't on trunk). Batching ≤ 50 ids, 12 requests/min/player,
60 s back-off on RateLimited. Effects per place top-down (Town → District → Structure): sound, particles (+ firework for
Towns), v1-coloured line, reward lines via KNG-16's `RewardMessageFormat` (new `discovery`/`discoveryTotals`), one
`PromotionEffects.show` on title change, balance/scoreboard refresh. Spool: per-player JSON in
`plugins/KnightsAndKings/discovery-spool/`, network/5xx only, replayed on enable / every 60 s / next join.
Deviations: top-down order (plan's acceptance line said bottom-up, contradicting DESIGN §3.4); chat template has no
`{rewards}` placeholder (separate lines); new keys `effects.spacing-ticks`, `effects.particle-spread`; leaving staff/creative
inside a place discovers it on the next block move. Endpoints needing KNG-22 service auth: `POST api/users/{id}/discoveries`,
`GET …/known`, `…/progress`, `…/summary`. Smoke test: new Town in/out/in; join inside a District; teleport into a Structure;
no-entry domain bounce; staff/creative/frozen excluded; API down → spool file → restart API → delivered within ~60 s.
Known: a refusal applied after a slow domain lookup can still reward; 4xx (incl. 401 bad key) only logged; one extra WG
lookup per block move.

## Phase 3 — Discoveries menu, hub tile, commands (knk-web-api seed + knk-plugin)

**Tasks**
- knk-web-api: `Models/Menu/MenuTemplateSeed.Discovery.cs` (new partial) — template `discoveries.main` (DESIGN §3.7);
  `Models/Menu/MenuTemplateSeed.Content.cs` — hub `main` tile at slot 20 (`menu-available discoveries.main`); register the new
  template in `CanonicalTemplates()`.
- **One-time step for existing DBs** (seed is create-only, `MenuTemplateSeed.cs:18-35`): add the slot-20 item to the existing
  `main` template through the MenuTemplates CRUD API, or delete the `main` row so the next start re-seeds it if it has no hand
  edits. Record which was done in the phase status.
- knk-plugin: `paper/menu/content/DiscoveriesMenuFeature.java` (root `discoveries` → `DiscoveriesView`, row source
  `discoveries.rows` → `DiscoveryRow`, engine page/filters → `progress` call, `summary` fetched in the same async step, per-viewer
  LRU like `FreshViewers`); `DiscoveryRow.java`, `DiscoveriesView.java`; add to the `menuFeatures` list in `KnKPlugin.java`
  (before `MenuDefinitionValidationRunner` locks the registries).
- Commands: `paper/commands/DiscoveriesCommand.java` (`/discoveries`, alias `/disc`, `registerSimpleCommand`); `plugin.yml`
  command + `knk.discoveries` (`default: true`); `/knk discovery list|reset|status` subcommand (`paper/commands/DiscoveryAdminCommand.java`
  registered in `KnkAdminCommand`'s `CommandRegistry`, gated by `knk.admin.discovery` through `KnkPermissible`); update
  `docs/specs/user-features/COMMAND_CATALOG_V3.md` in a docs follow-up.

**Tests**
- web-api `Services/MenuTemplateDiscoverySeedTests.cs`: seed round-trip, row template bindings, filter actions, hub tile present.
- plugin `DiscoveryRowTest` (discovered/undiscovered/masked/latest-highlight, materials by type), `DiscoveriesMenuFeatureTest`
  (filters forwarded, failure → empty page), startup validation passes with the feature registered.

**Acceptance**
- `/discoveries` and the hub tile open the menu; counts in the head match the API; type and status filters work; paging works;
  undiscovered Districts/Structures show "???" with their town.

**Size:** M. **Depends on:** Phase 2 (known/summary data exists), menu engine on trunk.

---

### Phase 3 status — done 2026-09-26 (all three repos, `claude/domain-discovery`)

KNG-22 merged first (api `bdd7bd8` = 7d441be, `UserService.ScaleBonus` now uses `BalanceLimits`; plugin `3f4fa65` = be0cfc3;
web-app fast-forwarded to 4a3c304). Auth (`98b4240`): grant + `known` `[RequirePluginService]`; `progress` + `summary` new
`[RequireServiceSelfOrPermission(ManageDiscovery)]` (plugin key, the player themself via JWT, or `knk.admin.discovery`);
reset `[RequireServiceOrPermission(ManageDiscovery)]` with actor from `GetKnkCaller()`. Menu: `fb94564` seeds
`discoveries.main` + hub tile slot 20; plugin `b72a6ba` (reset sends actor, `DiscoveryTracker.replaceKnown`), `1c9ae30`
(`DiscoveriesMenuFeature`, `DiscoveryRow`, `DiscoveriesView`, re-exported `content-seeds.json`), `5b55c4b` (`/discoveries` |
`/disc`, `/knk discovery list|reset|status`), `54b29ec` (config test fix after KNG-22's apikey default). API 799 tests (794
pass, the 5 baseline); plugin CI green https://github.com/PandiO/knk-plugin/actions/runs/36260205168.
Deviations: `/knk discovery` accepts the node via Bukkit or `KnkPermissible`; GateStructure in the Type filter (IRON_BARS);
grid marked searchable so filters are forwarded; `KnkAdminCommand.registerSubcommand(...)` helper; menu feature always
registered; staff need `knk.admin.discovery` to view another player's discoveries on the web.
Developer to-do: seeds are create-only — on an existing DB add the hub slot-20 item via the MenuTemplates API or delete the
`main` hub row to re-seed (`discoveries.main` seeds itself); API key on both sides (plugin refuses an empty key); grant
`knk.admin.discovery` to staff; smoke test `/disc` filters, hub slot 20, `/knk discovery list|reset|status` (reset then
re-enter rediscovers). Known: hub count/header use a summary cached ≤ 30 s; `COMMAND_CATALOG_V3.md` update pending.

## Phase 4 — Web-app views (knk-web-app)

**Tasks**
- `src/apiClients/discoveryClient.ts` (objectManager/serviceCall pattern); types in `src/types/dtos/discovery/`.
- `src/pages/admin/DiscoveryAdminPage.tsx` — rules grid, per-title preview, overrides (domain `SearchableDropdown`), statistics;
  route `/admin/discovery` in `src/App.tsx` (admin-protected like `/admin/siege-configuration`); link in `src/components/Navigation.tsx`.
- `src/pages/admin/PlayerProfilePage.tsx` — "Discoveries" section with reset action.
- `src/pages/AccountManagementPage.tsx` — "Discoveries" progress section for linked accounts.

**Tests**
- `src/apiClients/__tests__/discoveryClient.test.ts`; `src/pages/admin/__tests__/DiscoveryAdminPage.test.tsx` (edit + validation
  min ≤ max, preview renders per bracket, override add/remove); PlayerProfilePage discoveries section render + reset confirm.

**Acceptance**
- Editing the Town rule changes the preview immediately and the next in-game discovery uses the new values.
- A player's account page shows the same counts as `/discoveries`.

**Size:** M. **Depends on:** Phase 1 (endpoints). Can run in parallel with Phases 2–3.

---

### Phase 4 status — done 2026-09-26 (knk-web-app `claude/domain-discovery`)

Commits `42e8743` (`usePermission(node)` hook cherry-picked unchanged from private-messages `dceb5b3`), `35e04a3`
(`discoveryClient.ts`, `DiscoveryDtos.ts`), `d19bc15` (account page "Discoveries" section for linked accounts: per-type
progress + 10 latest; `PlayerDiscoveriesPanel` on the player profile for `knk.admin.discovery` holders with paged table,
type filter and confirmed Reset; `DiscoveryReset` audit label), `1282595` (`StaffRoute` optional `node`; pick-only
`SearchableDropdown`), `c84b77e` (`/admin/discovery`: inline type-rule editing with validation, live per-title preview using
the API's formula, per-domain overrides, statistics with first discoverer + top explorers). Tests 16 failed (baseline) /
282 passed (38 new); build + `tsc --noEmit` clean for touched files.
Deviations: preview follows unsaved edits (server stays authoritative, reloads after save); dedicated page instead of
FormConfig (computed preview); nav link after Game Settings. Known: domain picker loads ≤ 1,000 domains; own paging types
(`pageNumber` vs shared `page`); small merge conflicts expected with private-messages (profile panel/audit labels) and siege
(nav link). Smoke test: `/account` counts = in-game `/discoveries`; edit the Town rule and watch the preview; add/remove an
override; reset a discovery → "Discovery reset" in Recent Activity.

## Phase 5 — Adopt currency-payments ledger/idempotency and plugin auth

**Tasks**
- Replace the `AdjustBalancesAsync` call in `DiscoveryService` with the currency-payments mutation API, idempotency key
  `discovery:{userId}:{domainId}` (or per-call key if that design takes one key per call), keeping the same transaction.
- Apply the plugin-client auth policy to `POST api/users/{id}/discoveries` and the admin policy to rule/override/reset routes once
  either exists (DESIGN Q4); plugin sends credentials per `config.yml auth.type`.
- Reset route passes the acting staff user (CP7 `X-Acting-User-Id` once honoured).

**Tests:** ledger entry per discovery; replay with the same key → no second entry; unauthenticated grant → 401.
**Size:** S. **Depends on:** `specs/currency-payments/` implementation, inventory-menu CP7 server half.

---

### Phase 5 status — done 2026-09-26 (knk-web-api + knk-plugin `claude/domain-discovery`)

knk-web-api `616ef29` merges currency ledger `d5c1418` (snapshot conflict resolved; `has-pending-model-changes` clean, all
migrations kept), `dd43b2d` adds `IUserService.ApplyTitleProgressionAsync(userId, previousExperience, …)` (title at old vs.
current XP, pays crossed-bracket bonuses without re-adding XP, joins the caller's transaction), `1900b66` `DiscoveryService`
posts through `ICurrencyService`: **one posting per domain**, `DISCOVERY_REWARD`, key `discovery:{userId}:{domainId}`
(rediscovery after a reset uses `…:2`, `:3`), `SourceType "Domain"`/`SourceRef` = domain id, shared `CorrelationId` per
request, metadata with base amounts + multipliers; the reward's `BalanceAdjusted` audit row is dropped (ledger records it);
ledger refusals → 409. knk-plugin `45e80b6` merges `3630436` (service key never logged). API 828 pass / 14 skipped / 5
baseline; requires-mysql 14/14 ×3 on MySQL 8.0.46 (10 concurrent grants → one posting per domain, reconciler clean; reset +
rediscovery clean; ledger refusal rolls back the discovery rows; title crossing adds XP once, bonus once). Plugin CI green
https://github.com/PandiO/knk-plugin/actions/runs/36261765260. Plugin auth: nothing left (grant/known
`[RequirePluginService]`, progress/summary `[RequireServiceSelfOrPermission]`, reset `[RequireServiceOrPermission]`).
Known: until currency Phase 2 routes title bonuses through the ledger, a discovery that triggers a promotion shows a
reconciler chain mismatch (expected); at merge, switch `ApplyTitleProgressionAsync` to currency Phase 2's ledger-based
equivalent. Discovery rewards no longer appear as `BalanceAdjusted` in Recent Activity (they're in the discoveries panel
and, later, the ledger history views).

## Risks / notes for whoever picks this up
- `DomainService.SearchDomainRegionDecisionAsync` returns at most one Town/District/Structure and no GateStructures; discovery
  avoids it (server resolves raw region ids). Gate control in `SimpleRegionTransitionService` compares `domainType` to `"gate"`,
  which never matches `"GateStructure"`. Both are pre-existing, out of scope here — worth a separate fix.
- `Domain.WgRegionId` isn't unique; if two domains share a region id, `GetByWgRegionNameAsync` picks the first. Consider a
  unique index in a separate change.
- `SalaryService` doesn't read `TitleBracket.Salary` (its doc says it's a SalaryService input); discovery coins do read it
  (DESIGN Q1 option a). Flag to user-features if salary is meant to be title-scaled.
