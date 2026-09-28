# Teleportation Commands — Implementation Plan

**Status:** Phases 1–7 + siege integration done on `claude/teleport`, trunk merged in; smoke test round 1 done 2026-09-28, fixes pushed, round-2 re-test + two feature requests open (not merged to trunk)
**Last updated:** 2026-09-28
**Linear:** [KNG-17](https://linear.app/kngpandi/issue/KNG-17/teleportation-staff-tp-tpa-requests-spawn-domain-warps-v1-port)
**Sources:** [DESIGN.md](DESIGN.md); `docs/ACTIVE_SESSIONS.md` (branch convention); code read at knk-plugin `0fa6d06`
(`claude/siege-minigame` head), knk-web-api `cd95dd1`, knk-web-app `9a6f347`.

**Branches:** one standing branch per repo, `claude/teleport` in knk-plugin (from `main`), knk-web-api (from `master`)
and knk-web-app (from `main`), created only when a phase first touches that repo. Do not fork per phase
(`ACTIVE_SESSIONS.md` convention). Claim the feature in `ACTIVE_SESSIONS.md` before starting.

**Build notes:** `./gradlew build` in knk-plugin runs the `deployToDevServer` hook — use `./gradlew build -x
deployToDevServer` unless deploying on purpose. knk-web-api tests live in `Tests/knkwebapi_v2.Tests/` on disk (repo
`CLAUDE.md` says `tests/`); 5 pre-existing failures are the known baseline.

| Phase | Repos | Size | Depends on | Shippable alone |
|---|---|---|---|---|
| 1 — Engine + staff teleports | plugin | M | — | yes |
| 2 — Admin teleport audit | web-api, plugin, web-app | S | 1 | yes |
| 3 — Player requests (`/tpa`, `/tpahere`) | plugin | M | 1; Q2 | yes |
| 4 — `/spawn` | plugin | S | 1 | yes |
| 5 — Domain teleports (`/warp`) | web-api, plugin, web-app (authoring) | L | 1; Q3, Q4; currency-payments (soft) | yes |
| 6 — Teleport menu | web-api (seed), plugin | M | 5 | yes |
| 7 — `/back` (optional) | plugin | S | 1; Q5 | yes |

Siege integration (guards) is part of Phase 1 through a registration interface, so nothing waits for
`claude/siege-minigame` to reach plugin `main`; the siege branch registers its restriction when the two meet.

---

## Phase 1 — Engine + staff teleports (plugin only)

**knk-core** (Bukkit-free, new package `net/knightsandkings/knk/core/teleport/`):
- `TeleportKind.java` (STAFF, REQUEST, SPAWN, WARP, BACK), `TeleportDenial.java` (reason code + message).
- `WarmupPolicy.java` — seconds from (kind, hasShortWarmup, hasBypass) and config.
- `SafeLocationFinder.java` + `BlockProbe.java` port (passable/solid/hazard/world-height queries) — bounded ring search,
  radius from config (DESIGN §3.4.2).
- `CombatTagBook.java` — last-PvP timestamps, `isTagged(uuid, now)`.
- `TeleportCooldowns.java` — per (uuid, kind) expiry (or reuse `utils/CommandCooldownManager` from knk-paper if moving
  it to core is cheap — decide during implementation, don't duplicate).

**knk-paper** (new package `net/knightsandkings/knk/paper/teleport/`):
- `TeleportPlan.java`, `TeleportService.java` (warmup map, 5-tick runnable, commit, `teleportAsync(loc,
  TeleportCause.COMMAND)`, cooldown, messages), `TeleportGuards.java`, `TeleportRestriction.java` (interface:
  `Optional<String> deny(Player subject, Location from, Location to, TeleportKind kind)`),
  `FreezeTeleportRestriction.java`, `RegionTeleportRestriction.java` (wraps the `RegionTransitionService` decision used by
  `listeners/WorldGuardRegionListener.java`), `BukkitBlockProbe.java`, `VisibleTargetResolver.java` (vanish-aware name
  lookup + tab-complete using `modes/ModeService.isVanished`).
- `listeners/TeleportWarmupListener.java` — cancel on block move, damage, foreign teleport, death, quit.
- `listeners/CombatTagListener.java` — PvP tagging (direct + projectile).
- `commands/StaffTeleportCommand.java` — `/tp <player>`, `/tp <player> <target>`, `/tp <x> <y> <z> [world] [yaw pitch]`,
  `/tphere <player>`, `-s`/`silent`/`s` flag; rank checks via `commands/support/RankHierarchy`; tab completion.
- Changed: `commands/TeleportToPlayerCommand.java` → thin delegate to `StaffTeleportCommand` (keeps `/knk tp` +
  `knk.admin.tp`); fix its javadoc (v1's owner `/tpa <player>` was dead too).
- Changed: `listeners/WorldGuardRegionListener.java` — skip the deny when the player holds `knk.region.bypass`
  (`KnkPermissible.hasPermission`, sync cache-only is fine here).
- Changed: `KnKPlugin.java` — construct `TeleportService`, register listeners/commands, expose
  `registerTeleportRestriction(...)`.
- Changed: `src/main/resources/plugin.yml` — `tp`, `tphere` commands (no `permission:` key, per convention); declare
  the `knk.teleport.*` and `knk.region.bypass` nodes (`default: op`, documentation-only like `knk.kit.*`).
- Changed: `src/main/resources/config.yml` — `teleport:` block (DESIGN §3.11), read in `config/KnkConfig`.
- **Siege hook (on `claude/siege-minigame` or after it merges):** `siege/SiegeTeleportRestriction.java` implementing
  `TeleportRestriction` with `SiegeService.activeLobbyOf` (subject and, for requests, target) and
  `SiegeAreaLockdown.blockingEntry`; registered where `SiegeService` is built in `KnKPlugin`. If siege is already on
  `main` when this phase starts, include it here.

**Tests:**
- knk-core: `SafeLocationFinderTest` (exact safe spot, lava below, 1-high gap, search finds ring-2 spot, none within
  radius → empty, Y out of bounds), `WarmupPolicyTest`, `CombatTagBookTest`, `TeleportCooldownsTest`.
- knk-paper (MockBukkit or plain mocks, as existing `listeners/` tests do): warmup cancelled by block move but not by
  head rotation; cancelled by damage; guard re-check at commit (frozen mid-warmup); staff `/tp a b` refused when actor
  doesn't outrank either; vanished target reported as offline to a non-staff viewer; `/knk tp` delegates.

**Acceptance:**
- `/tp`, `/tp a b`, `/tp x y z`, `/tphere`, `-s` work for a holder of the nodes; refused (clean message) for a lower rank
  target, a siege member (when the hook is present), a destination in a locked siege area without bypass.
- `/tp` into a domain with `AllowEntry=false` works only with `knk.region.bypass`.
- Teleports fire with cause `COMMAND` (verify the siege lockdown listener now sees `/knk tp`).
- `./gradlew build -x deployToDevServer` green; test counts noted in `ACTIVE_SESSIONS.md`.

---

### Phase 1 status — done 2026-09-26 (knk-plugin `claude/teleport`)

Commits `f8597df` (knk-core `core/teleport/`: `WarmupBook`, `WarmupPolicy`, `TeleportCooldowns`, `CombatTagBook`,
`SafeLocationFinder`, `RegionTransitionService.previewAccess`), `1277b44` (knk-paper `teleport/TeleportService` +
restrictions, warmup/combat listeners, `knk.region.bypass`, `teleport:` config block), `b38e9f9` (`StaffTeleportCommand`:
`/tp <p>`, `/tp <a> <b>`, `/tp x y z [world] [yaw pitch]` with `~`, `/tphere`, `-s`; `/knk tp` delegates to it), `141be98`
(async hardening); trunk (KNG-16) merged in `7db6d66`. CI green: https://github.com/PandiO/knk-plugin/actions/runs/36251383587.

Deviations: restrictions take a `TeleportCheck` and return `Optional<TeleportDenial>`; a staff member's region bypass
carries to the player they move; frozen players can't escape via pearls/chorus/portals; `/knk tp` uses the shared rank
check; own `VisibleTargetResolver` (to be unified with private-messages' `VisiblePlayers` at merge); every teleport now
uses cause `COMMAND` (closes the siege-lockdown bypass). Siege guard hook: `KnKPlugin.registerTeleportRestriction(...)` —
the siege branch should add a `SiegeTeleportRestriction` (`activeLobbyOf` + `blockingEntry`, bypass `knk.siege.bypass.*`).

Developer to-do: grant `knk.teleport.staff`, `.staff.others`, `.staff.silent`, `knk.region.bypass` to staff groups and
`knk.teleport.warmup.short` to Noble; smoke-test `/tp` forms, `-s`, `AllowEntry=false` town with/without bypass,
`/minecraft:tp` still works. Known: `knk.region.bypass` read from cache only (first move after a cold cache fails
closed); with bypass the domain-entered callback doesn't fire for that move.

## Phase 2 — Admin teleport audit

**knk-web-api:**
- `Enums/AuditAction.cs` — `PlayerTeleported = 12`.
- `Dtos/TeleportDtos.cs` (new) — `TeleportAuditDto { actorUserId?, kind, subjectUserId, visitedUserId?, from, to,
  domainId?, silent }`.
- `Controllers/UsersController.cs` — `POST {id:int}/teleport-audit`, `[RequirePluginServiceKey]`, calls
  `IAuditLogService.RecordAsync(actorUserId, id, AuditAction.PlayerTeleported, json)`. No migration (enum stored as
  string/int per existing convention — verify how `AuditAction` is persisted in `KnKDbContext` before assuming).
- Tests: `Tests/knkwebapi_v2.Tests/Api/UsersTeleportAuditTests.cs` (201/204, 401 when the key is configured and
  missing, 404 unknown user).

**knk-plugin:** `knk-core:ports/api/UsersCommandApi.java` + `knk-api-client:impl/UsersCommandApiImpl.java` —
`recordTeleportAudit(...)`; `teleport/TeleportAuditor.java` — fire-and-forget with one retry, always logs locally;
`TeleportService` calls it for STAFF kinds. Test: auditor called once per staff teleport, never for player kinds.

**knk-web-app:** `src/types/dtos/userManagement/UserProfileSummaryDtos.ts` (+`'PlayerTeleported'`),
`src/pages/admin/PlayerProfilePage.tsx` label "Teleported by staff". Test: label renders (existing page test pattern).

**Acceptance:** a `/tp a b` produces one `PlayerTeleported` row visible on the player's profile page, with the actor
id filled in when the plugin runs with `api.auth.type: apikey`.

**Note:** actor trust has the same open issue as InventoryMenu CP7 (`ACTIVE_SESSIONS.md`); the service key is what makes
the body's `actorUserId` acceptable.

---

### Phase 2 status — done 2026-09-26 (all three repos, `claude/teleport`)

knk-web-api `3515d2f`: `AuditAction.PlayerTeleported = 12`, `Dtos/TeleportDtos.cs`, `UserService.RecordTeleportAuditAsync`,
`POST api/users/{id}/teleport-audit` (204/400/404; actor from `X-Acting-User-Id` via KNG-16's `GetActorUserId()`; strict
server validation: row user must be moved/visited player, known kind, existing users, finite coords within ±30M, length
limits; usernames resolved server-side). knk-plugin `6612ade`: `core/teleport/TeleportAudit`, `UsersCommandApi.recordTeleportAudit`,
`teleport/TeleportAuditor` (async, one retry after 5 s, never fails the teleport). knk-web-app `a494af5`: "Teleported by
staff" in Recent Activity with detail lines; `auditActionLabel` moved to `utils/auditDetails.ts`.
Tests: API 616 (611 pass, the 5 baseline failures); plugin CI green https://github.com/PandiO/knk-plugin/actions/runs/36252256858;
web-app 3 new tests, suite 16 failed / 243 passed (16 pre-existing). No migration (actions stored by name).
Endpoint needing KNG-22 service auth: `POST /api/users/{id}/teleport-audit`. Smoke test: `/tp A B`, `/tphere A` → A's
profile Recent Activity; `/tp B` → B's profile; `/tp -s …` shows "Silent".

## Phase 3 — Player requests

**knk-core:** `core/teleport/TeleportRequestBook.java` (expiry, one outgoing per requester, per-target cap, duplicate
check, remove-on-accept).

**knk-paper:** `commands/TeleportRequestCommand.java` (`/tpa`, `/tpa accept|deny`, `/tpahere`, `/tpaccept`,
`/tpdeny`, `/tpcancel`, aliases `/tpyes`, `/tpno`), clickable Adventure `[Accept] [Deny]` components, expiry sweep in
the Phase 1 runnable, quit/death cleanup in `TeleportWarmupListener`; `plugin.yml` command entries; coin price hook
(`teleport.request.price-coins`, default 0) via `UsersCommandApi.adjustBalancesById(id, -price, 0, 0,
"teleport.request", false)` only when > 0.

**Tests:** knk-core `TeleportRequestBookTest` (expiry at 30 s, replace outgoing, cap drops oldest, accept removes,
double accept no-op); knk-paper: accept re-runs guards for both players (target joined a siege → refused), destination
is the live location at commit, vanished requester can't request a non-staff target.

**Acceptance:** two-account live check — request, accept, warmup, arrival; deny; expiry; `/tpcancel`; moving during
warmup cancels; request to a siege member refused.

**Depends on:** Q2 (who gets `/tpahere`; price). Grant `knk.teleport.request` to the Default group and
`knk.teleport.request.here` per Q2 via the web-app PermissionGroup forms (data step, no code).

---

### Phase 3 status — done 2026-09-26 (knk-plugin `claude/teleport`)

Commits `0b81b56` (knk-core `TeleportRequestBook`: 30 s expiry, one outgoing request per requester, one pending per pair,
per-target cap, take-on-answer; `TeleportRequestSettings`), `3311a92` (`/tpa`, `/tpahere`, `/tpaccept`|`/tpyes`,
`/tpdeny`|`/tpno`, `/tpcancel`, v1 form `/tpa accept|deny [player]`; `TeleportRequestService`, `TeleportRequestCommand`,
clickable [Accept]/[Deny]; `TeleportService.check(plan)`; requests cleared on quit/death), `b559df7` (vanish re-check after
async checks). knk-core 563/563 locally (26 new); knk-paper 32 new tests; CI green
https://github.com/PandiO/knk-plugin/actions/runs/36253711523.
Nodes: `/tpa` = `knk.teleport.request`, `/tpahere` = `knk.teleport.request.here` (Dragon Blood). Warmup on whoever moves;
all guards re-run at accept and after warmup for both players; destination = the other player's position at warmup end.
Vanish-safe; pre-send refusal when the engine would refuse; 10 s send cooldown (`knk.teleport.bypass.cooldown`).
Deviations: only price 0 works (non-zero refuses "Paid teleport requests aren't available yet." — charging lands with
Phase 5's server-side charge path); reverse request refused with a `/tpaccept` pointer; `/tpahere` pre-check doesn't give
the reason; accepted requests start the 30 s REQUEST cooldown on whoever moved. `setIgnoreCheck(...)` is ready for
private-messages' `IgnoreService::ignores` (wire at merge). Developer to-do: grant `knk.teleport.request` (Default) and
`knk.teleport.request.here` (Dragon Blood); new `teleport.request.*` config keys default 30/10/5/0; two-account smoke test.
Known: players literally named "accept"/"deny" can't be `/tpa`'d; pending requests lost on restart.

## Phase 4 — `/spawn`

**knk-core:** `ports/api/GameSettingsQueryApi.java`, `domain/settings/KnkSpawnReference.java`.
**knk-api-client:** `impl/GameSettingsQueryApiImpl.java` + DTO on the existing `GET /api/GameSettings`.
**knk-paper:** `commands/SpawnCommand.java` (`/spawn`, `/spawn <player>`), `teleport/SpawnDestinationResolver.java`
(CustomReference → Location/Town/District/Structure via existing data-access gateways; else main world spawn), cached
5 min, invalidated by `/knk cache`.
**Tests:** resolver per `sourceType`, fallback on missing reference/location, `/spawn <player>` requires
`knk.teleport.staff.others`.
**Acceptance:** with a Town set as join spawn in the web-app Game Settings page, `/spawn` lands on that town's location
after the warmup; unset → world spawn.
**Out of scope here:** switching the join/respawn listeners to the same resolver (would be a natural follow-up; note it
in the handoff, don't do it silently).

---

### Phase 4 status — done 2026-09-26 (all three repos, `claude/teleport`)

KNG-22 merged (api `92f5558`, plugin `15613d6`, web-app `2ef9bfa`); `390c58a` puts `[RequirePluginService]` on
`POST api/users/{id}/teleport-audit` (tests: no/wrong key 401, key OK, web user 403, actor header ignored without key).
Plugin `6e29948` (knk-core `KnkGameSettings`, `KnkSpawnReference`, `GameSettingsQueryApi`, `SpawnPoint`/`SpawnPointResolver`;
api-client `GameSettingsQueryApiImpl`), `2e32d44` (`/spawn` with `knk.teleport.spawn` through the engine — warmup,
cooldown, combat tag, safe spot, guards; `/spawn <player> [-s]` for staff, instant + audited, console OK;
`SpawnDestinationResolver`; `/knk cache refresh` via new `CacheManager.registerRefreshHook`). Destination: GameSettings
`CustomReference` (Location, or a Town/District/Structure's Location) else main world spawn; cached 5 min.
API 706 (701 pass, 5 baseline); knk-core 584/584 (21 new), api-client 55/55; plugin CI green
https://github.com/PandiO/knk-plugin/actions/runs/36260886257; web-app 16 baseline failures only.
Deviations: no set-spawn command (plan names none; `PUT api/GameSettings` still anonymous — KNG-22 follow-up); fallback
chain reference → saved coordinates → world spawn, last-resolved spawn if settings can't be read (retry 30 s).
Developer to-do: grant `knk.teleport.spawn` to Default; smoke test (Town as join spawn → `/knk cache refresh` → `/spawn`
warmup, move cancels; WorldSpawn mode; `/spawn <player>` instant + Recent Activity; `-s`). Follow-up: point join/respawn
listeners at `SpawnDestinationResolver`.

## Phase 5 — Domain teleports (`/warp`)

**knk-web-api:**
- `Models/Domain.cs` — `TeleportEnabled`, `TeleportPriceGems`, `TeleportMinTitleBracketId`(+nav),
  `TeleportMinPremiumGroupId`(+nav), `TeleportRequiresDiscovery`; `Properties/KnKDbContext.cs` FKs `SetNull`, check
  constraint price ≥ 0.
- Migration `Migrations/<ts>_AddDomainTeleportSettings.cs` (defaults false/0/null; no backfill). Must pass the fresh-DB
  CI workflow (`.github/workflows/migrations.yml`).
- `Dtos/DomainDtos.cs` (+ the five fields on `DomainDto` and the Town/District/Structure DTOs as they inherit),
  `Mapping/` profile update.
- `Services/TeleportDestinationService.cs` + `Services/Interfaces/ITeleportDestinationService.cs`
  (`ListForUserAsync`, `EvaluateAsync`, `ChargeAsync`, `RefundAsync`; premium weight from the user's active
  `UserPermissionGroup` rows where `IsPremiumTier`; title via `TitleBracket.MinExperience`; discovery via an
  `IDomainDiscoveryLookup` interface with a no-op default until domain-discovery ships).
- `Controllers/TeleportDestinationsController.cs` — `GET api/teleport-destinations?userId=`, `POST {domainId}/charge`,
  `POST refund` (DESIGN §3.7.3), `[RequirePluginServiceKey]` on the POSTs; DI registration in `DependencyInjection/`.
- Tests: `Tests/knkwebapi_v2.Tests/Services/TeleportDestinationServiceTests.cs` (each lock reason, order of checks,
  bypass flags, charge deducts once and records `BalanceAdjusted` with `reason teleport.domain`, insufficient gems →
  409 and no mutation, refund restores), controller auth test for the key.

**knk-plugin:**
- knk-core: `domain/teleport/KnkTeleportDestination.java`, `ports/api/TeleportDestinationsQueryApi.java`,
  `ports/api/TeleportDestinationsCommandApi.java`, `dataaccess/TeleportDestinationsDataAccess.java` (per-user list,
  TTL 60 s); `DataAccessFactory` wiring + `entities.teleport-destinations` cache settings.
- knk-api-client: `dto/TeleportDestinationDto.java`, `impl/TeleportDestinationsQueryApiImpl.java`,
  `impl/TeleportDestinationsCommandApiImpl.java`, mapper.
- knk-paper: `commands/WarpCommand.java` (`/warp`, `/point` alias, `list`, `<domain>`, `<domain> <player>`, tab-complete
  from the cache, `type:name` disambiguation); charge-after-warmup + refund-on-failure in `TeleportService`.
- Tests: knk-core data-access cache/invalidate; knk-paper: no charge when warmup cancelled, refund when
  `teleportAsync` returns false, locked destination shows the server's reason, staff `<domain> <player>` free/instant.

**knk-web-app / dev DB (authoring, no code expected):** add the five fields to the Town, District and Structure
FormConfigurations (TitleBracket and PermissionGroup pickers already exist from siege/menu work; filter the premium
picker to `IsPremiumTier`). Document the steps in `docs/specs/teleport/` when done (like `kits/PHASE_3_FORMCONFIGS.md`).
Enable 1–2 towns with a price of 10 gems (v1 default) for the live test.

**Acceptance:** an enabled town appears in `/warp list` with price and lock state; a player below the required title
sees "Reach title X to unlock"; a paid warp deducts gems exactly once after the warmup and shows "You paid N gems and
your new balance is M"; moving during warmup charges nothing; `AllowEntry=false` domains never appear.

**Dependencies:**
- `docs/specs/currency-payments/` — when its ledger/idempotency API lands, switch `ChargeAsync`/`RefundAsync` onto it
  with the plugin's `idempotencyKey` (and make the plugin retry on timeout). Until then, no retries (DESIGN §3.7.3).
- `docs/specs/domain-discovery/` — provides the real `IDomainDiscoveryLookup`; until then `TeleportRequiresDiscovery`
  has no effect (document on the form field).
- Q3, Q4 answers.

---

### Phase 5 status — done 2026-09-26 (all three repos, `claude/teleport`)

Merges (commits, per merge order currency → discovery → teleport): API `829e409` (currency `d5c1418`), `bcaddf3` (discovery
`fb94564`; AuditAction 12 + 17 kept; snapshot clean); plugin `b892d91` (`3630436`), `bfd7678` (`54b29ec`).
knk-web-api `813c699`: five `Domain` fields + migration `AddDomainTeleportSettings` (`TeleportEnabled`, `TeleportPriceGems`,
`TeleportMinTitleBracketId`, `TeleportMinPremiumGroupId`, `TeleportRequiresDiscovery`), `TeleportDestinationService`,
`api/teleport-destinations` (GET list, POST `{domainId}/charge`, POST `request-fee`, POST `refund`; all
`[RequirePluginService]`); `18b7ea4` TitleBrackets fetch/search routes (copied verbatim from siege). knk-plugin `87e6085`
(core types, client, destination cache, retry-safe charger), `0c14238` (charge after warmup + guard re-check, refund when a
paid teleport doesn't arrive; `/warp`, `/point`, `/warps`, `/warp list`, `/warp <d> <player> [-s]`; paid `/tpa` works),
`eb8abfa`, `e47c73d`. knk-web-app `454ab70` (TitleBracket client, domain DTO fields).
Tests: API 915 (910 pass, 5 baseline) incl. real MySQL: 12 parallel same-key charges → one charge; 20 parallel own-key warps
never overdraw; charge racing refund → refunded or void, never charged without a teleport; 8 parallel refunds reverse once;
migration up/down/up. Live API: charge → replay → refund → re-charge refused. Plugin CI green
https://github.com/PandiO/knk-plugin/actions/runs/36264003007 (627 knk-paper tests); web-app 16 baseline failures only.
Deviations: every warp (free ones too) calls charge after warmup so title/premium/discovery are always checked server-side;
refund-before-charge voids the key in the API's **memory** for 30 min (single instance, lost on restart — to harden in
review); refunds are ledger reversals `reverse:{txId}`; warp list is service-key only, locked destinations include the
server's reason; bypass nodes applied plugin-side and sent with the charge; premium picker shows all groups (API refuses
non-premium); staff `/warp <d> <player>` audit lacks `domainId`.
Developer to-do: apply `20260926181358_AddDomainTeleportSettings`; grant `knk.teleport.warp` (Default),
`knk.teleport.bypass.requirements` + `.bypass.cost` (staff); add the five fields to the Town/District/Structure
FormConfigurations; enable 1–2 towns at 10 gems; smoke test `/warps`, move during warmup (no charge), paid warp message,
title-locked refusal, staff `/warp town:X Bob`, paid `/tpa` with `price-coins > 0`. Known: a charge in flight at plugin
shutdown isn't refunded; destination cache cleared only by `/knk cache refresh`.

## Phase 6 — Teleport menu

**knk-web-api:** `Models/Menu/MenuTemplateSeed.Content.cs` (or a new `MenuTemplateSeed.Teleport.cs` partial) —
create-only template `teleport.destinations` + hub tile in the `/menu` hub template; tests in the existing seed test
class pattern.
**knk-paper:** `menu/content/TeleportMenuFeature.java` — content source `teleport.destinations`, action
`teleport.warp` (delegates to `WarpCommand`'s path, closes the menu); registered in `KnKPlugin` with the other
`MenuFeature`s; `/warp` with no args opens it.
**Tests:** feature registers source/action; locked rows are not clickable; the action goes through the engine (siege
guard applies even though `/menu` passes the siege command filter).
**Acceptance:** `/menu` → COMPASS "Teleport to points on the map" → destination list with v1-style lore and the viewer's
real warmup in the info tile; clicking teleports via the Phase 5 path.

---

### Phase 6 status — done 2026-09-26 (knk-web-api + knk-plugin, `claude/teleport`)

knk-web-api `f074aaa`: `teleport.destinations` menu seed (`Models/Menu/MenuTemplateSeed.Teleport.cs`) + hub **Teleport tile in
slot 24** (v1 COMPASS texts; slot 20 stays Discoveries). knk-plugin `5e0b117`: warp menu — paged grid (36/page) from the
same cached list as `/warps` with the viewer's permissions/bypasses, per-domain-type icons, tooltip with type, gem price,
required title/tier, discovered state, "Available!/Locked! <reason>" (locked tiles unclickable); header: Spawn (0), pending
`/tpa` requests (2, re-sends clickable Accept/Deny in chat), info compass with the viewer's warmup (4), Back (8). Clicks run
the command code (`WarpCommand.warpTo`, `SpawnCommand.teleportSelf`), so warmup, post-warmup charge and every registered
restriction (siege hook) apply — test proves a registered restriction blocks a menu warp. Bare `/warp` opens the menu.
API 922 (902 pass, 15 skipped, 5 baseline); plugin CI green https://github.com/PandiO/knk-plugin/actions/runs/36265081028.
Deviations: `/warp list` stays the chat list; per-type icons (tier shown as a tooltip line); "discovered" shown as
"Must be discovered first" when an earlier requirement fails first (API reports only the first failing requirement); no
grid filters. Developer to-do: on an existing DB add the hub slot-24 tile via MenuTemplates or delete the `main` row to
re-seed (same step as discovery's slot 20), restart Paper; smoke test `/menu` → Teleport, locked vs open tiles, `/warp` opens
the menu, requests tile, Spawn tile. Siege branch must call `registerTeleportRestriction` at merge.

## Phase 7 — `/back` (optional, Q5)

**knk-paper:** `teleport/BackLocationBook.java` (death location, expiry `teleport.back.expire-seconds`, cleared on use),
`listeners/BackDeathListener.java` (skip deaths while `SiegeService.activeLobbyOf` / via a restriction), `commands/
BackCommand.java` (`knk.teleport.back`), `plugin.yml`, `config.yml` `teleport.back.enabled`.
**Tests:** stored on death, expired after 5 min, not stored for siege deaths, uses warmup + guards + safe-location.
**Acceptance:** Dragon Blood player dies, `/back` within 5 min returns them near the death spot after the warmup.

---

### Phase 7 status — done 2026-09-26 (knk-plugin + knk-web-api `claude/teleport`)

knk-plugin `a68ecc8`: `/back` (`knk.teleport.back`, Dragon Blood; config `teleport.back.enabled` true,
`teleport.back.expire-seconds` 300) — single use (consumed on arrival; cancelled warmup/guard refusal/unsafe spot gives it
back), expiry checked when `/back` starts, full engine (warmup, BACK cooldown, combat tag, freeze/region/siege guards,
safe-spot search: lava death → nearest safe ground, void death refused), knk-core `BackLocationBook`/`TeleportBackSettings`.
Siege hook: `KnKPlugin.registerBackDeathExclusion(BackDeathExclusion)` — siege branch registers
`p -> siegeService.activeLobbyOf(p.getUniqueId()).isPresent()` (checked at `PlayerDeathEvent` LOWEST; death recorded at
MONITOR if not cancelled; a siege death wipes older deaths). knk-web-api `7b4e2da`: **durable void keys** — a refund that
arrives before its charge writes a `teleport_fee_voids` row (keyed by idempotency key, inside the refund's user-lock
transaction); warp charge and request fee check it under the same lock, so a late duplicate charge is refused after a
restart or on another instance (in-memory cache removed). Tests: knk-core 635 pass, api-client 72; API 925 (904 pass, 16
skipped, 5 baseline); requires-mysql 16/16 (8 parallel pre-charge refunds → one row, late charge refused); migration
up/down/up. Plugin CI green https://github.com/PandiO/knk-plugin/actions/runs/36265661554.
Deviations: `teleport.back.enabled` defaults true (node still limits to Dragon Blood); a recorded death survives relog
within 5 min, lost on restart; void marker is its own table (ledger refuses empty transactions), kept permanently.
Developer to-do: apply `20260926192445_AddTeleportFeeVoids`; grant `knk.teleport.back` to Dragon Blood; smoke test (die →
`/back` within 5 min; second `/back` refused; after 5 min refused; lava death → safe ground; void death refused).

### Final review — 2026-09-26 (all phases)

Fixed (knk-plugin, HEAD `9b7efd1`, CI green https://github.com/PandiO/knk-plugin/actions/runs/36277325347):
(1) **Medium** — a warp/`/tpa` charge in flight at plugin disable left the player charged without a teleport; `TeleportService`
tracks open charges and `onDisable` abandons them (refund or void the key, never send an unsent charge), waiting ≤ 5 s
before `apiClient.shutdown()`; refund hook registered before the charge (`401dad8`). (2) **Low** — a refused retry after an
unanswered attempt could leave a charge; now refunded (`401dad8`). (3) **Low** — `Bukkit.getWorld` off the main thread in
`TeleportCharges`; resolved on the main thread (`401dad8`). (4) **Low** — per-player warp caches never released; quit
hooks (`c3f736d`). (5) **Low** — request expiry/cancel notices revealed vanished players; now only sent to viewers who can
see them (`9b7efd1`). No API/web-app defects. Checked sound: per-attempt keys, post-warmup charge, refund on any
non-arrival, durable void keys, row-lock serialisation, server-side title/tier/discovery checks, plugin-trusted bypass flags
only on `[RequirePluginService]` routes (per DESIGN D6), staff rank checks, guards on every path (staff, requests, spawn,
warp, menu, back), bounded safe-spot search, main-thread Bukkit use.
Left: `/tpa` bait-and-switch (a `/tpahere` holder can replace a request after 10 s and the target's old [Accept] accepts
the new direction — needs request ids in the click command; follow-up); cooldown per kind, not global (as planned); staff
`/warp` audit lacks domainId; pre-existing direct `player.teleport` calls in gates/region-tracker.

**Feature status: Phases 1–7 complete on `claude/teleport`; awaiting developer smoke test + merge.** Merge order:
currency-payments → domain-discovery → teleport. At merge also: unify `VisibleTargetResolver` with private-messages'
`VisiblePlayers`, wire `TeleportRequestService.setIgnoreCheck(IgnoreService::ignores)`, and siege must call
`registerTeleportRestriction(...)` + `registerBackDeathExclusion(...)`.

### Siege integration — done 2026-09-27 (all three repos, `claude/teleport`)

Plugin fast-forwarded to `940a87d` first (the `/tpa` request-id fix for the bait-and-switch, pushed from a separate session),
then trunk merged: plugin `863eda4` (main `716fb3c`), API `d4daef5` (master `67f451e`), web-app `c12b39b` (main `4fba7d0`).
Conflicts kept both sides (API `UserService` keeps this branch's capped/checked balance adjustment + trunk's `TitleProgression`
helper used only by `SiegeMatchService`; DbContext/menu seeds: discovery (hub 20), teleport (hub 24) and siege menus all
seeded; no AuditAction collisions; EF snapshot clean, full migration chain up/down/up on scratch MySQL; web-app enums/entity
mapping and `TitleBracketDto` superset). Wired (plugin `c954c30`): `siege/SiegeTeleportRestriction` registered in
`initializeSiege()` — a member's own `/tp`, `/spawn`, `/warp`, menu warp, `/tpa`, `/back` refused unless
`knk.siege.bypass.commands`; `/tpahere` pulling a member out refused; staff/console moving a member refused ("use /siege admin
kick first", D8); `/tpa` to a member refused; staff may `/tp` to a member to spectate. `registerBackDeathExclusion` — siege
deaths never grant `/back`. Siege's own four teleports now go through `SiegeBukkit.teleport` with `TeleportCause.PLUGIN`
(never through the engine). 13 tests; CI green https://github.com/PandiO/knk-plugin/actions/runs/36279721817.
Deviations: no destination check (`SiegeAreaLockdown.blockingEntry` no longer exists on trunk). Known: on this branch siege
rewards still bypass the ledger (fixed on `claude/currency-payments` `37bab02`; resolved by merge order); pre-existing on
trunk — `WorldGuardRegionListener` judges PLUGIN-cause teleports, so a siege hub/return spot inside an AllowEntry/AllowExit=false
domain could block siege's own teleports. In-game: members blocked from `/spawn`/`/warp`/`/tpa`/`/back`/menu warps in hub
and match; staff `/tphere <member>` refused, `/tp <member>` allowed; match death → no `/back`; siege's own teleports work.

### Trunk merge — done 2026-09-27 (all three repos, `claude/teleport`)

Merged trunk (private messages, currency ledger + payments incl. KNG-22 service key, domain discovery, lootboxes, nav rework)
into the branch with merge commits: API `d5dc808` (master `ccc8c02`) + `e31ffc6`, plugin `d42decc` (main `eb1d68c`) +
`60ea800`, web-app `a14b14b` (main `f56d421`). Tips: API `e31ffc6`, plugin `60ea800`, app `a14b14b`.
Where trunk and the branch carried the same code (ledger core `d5c1418`/`3630436`, discovery `fb94564`/`54b29ec`, KNG-22
commits), trunk's version is kept — the branch now differs from trunk only in teleport code. API: `UserService` = trunk's
ledger version + the teleport audit method re-added; `TeleportDestinationService` already posted `TELEPORT_FEE` spends and
`REVERSAL` refunds through `ICurrencyService` and builds unchanged against trunk's final ledger (nested
`RunWithUsersLockedAsync` joins the caller's transaction; void-fee keys unchanged); `TeleportRequiresDiscovery` reads
trunk's `IDiscoveryRepository.GetDiscoveredDomainIdsAsync`. `AuditAction.PlayerTeleported = 12` next to lootboxes 13–14,
PMs 15, discovery 17, currency 19–22 — no collision. Menu seeds: hub 20 = discoveries, 24 = teleport. EF: throwaway
`migrations add` produced an empty migration and an unchanged snapshot (deleted); `has-pending-model-changes`: none.
Plugin: `KnkConfig` carries privateMessages + teleport + discovery; `/knk tp` stays the `/tp` delegate; `/knk currency` and
`/lootbox` kept; `PlayerCommandSupport.whenAnyAllowed` moved onto trunk's `KnkPermissible.checkAsync` (API down → "can't be
checked", not "no permission"; new `PlayerCommandSupportTest`). Web app: `auditActionLabel` (in `utils/auditDetails.ts`)
carries trunk's lootbox/discovery/currency/PM labels too.
**Post-merge wiring:** `TeleportRequestService.setIgnoreCheck(IgnoreService::ignores)` (`60ea800`) — a `/tpa`/`/tpahere` from
a player the target `/ignore`s is swallowed (sender sees "Request sent", target sees nothing). Not done (follow-up): unify
the three vanish-safe lookups (`commands/support/VisiblePlayers`, `currency/VisiblePlayers`, `teleport/VisibleTargetResolver`).
Verification: API build OK; tests 1660 (1604 pass, 48 skipped) — the 5 baseline failures plus 3 currency tests that only
fail under this machine's nl-NL number format (`70.000` vs `70,000`; pass with invariant culture, pre-existing on trunk);
`requires-mysql` tests **not run** (no scratch MySQL: Docker Desktop can't start here — Hyper-V/VM Platform not enabled);
fresh-DB migrations CI green https://github.com/PandiO/knk-web-api/actions/runs/36343835020. Plugin: full local
`gradlew build -x deployToDevServer` — knk-core 1142, api-client 144 (2 skipped), knk-paper 966 (14 skipped), 0 failures;
CI green https://github.com/PandiO/knk-plugin/actions/runs/36343838547. Web app: build OK (trunk warnings), tests 16 failed
/ 387 passed in the known 10 trunk suites only.
Pending on the dev DB (checked 2026-09-27): `20260926181358_AddDomainTeleportSettings`, `20260926192445_AddTeleportFeeVoids`
(teleport) plus trunk's not-yet-applied `20260927173616_BackfillDefaultRankMembership`, `20260927174550_AddLootboxWorldPickup`.
Known, pre-existing on trunk: `WorldGuardRegionListener` judges PLUGIN-cause teleports (siege hub/return spots inside an
AllowEntry/AllowExit=false domain); `api/MenuTemplates` writes are anonymous.

### Smoke test round 1 — 2026-09-28 (developer, dev server)

Setup went cleanly (four migrations applied, all modules start). Passed: A1–A9, B1–B8, C1–C5, D1–D2, E1–E4 (menu), D9
(staff warp), F1/F2/F4/F5, G1–G4, H1–H4, I1/I3–I6, J1/J3, K2/K3/K5. Accepted without testing: D8 (refund via an unsafe
destination), F3 (void death), L (anti-exploit — **still to test**, list below). Not run: B9 (paid `/tpa`), D3 (move
during a paid warmup → no charge), J2 (premium picker refusing a non-premium group — "unsure"), J4 (ledger rows).

Findings and fixes (plugin `a2a319f`, `a8930a5`, `8fff139`, `51570c7`; CI green
https://github.com/PandiO/knk-plugin/actions/runs/36452143982; knk-core 1146, api-client 144, knk-paper 971, 0 failures):
- **E5/E6 (bug):** a new title or premium tier didn't unlock a warp until the 60 s per-player destination cache ran out or
  the player relogged (the API check was always live). `/warp`, `/warps` and the warp menu now take a list at most 5 s old;
  tab completion keeps the cache time. Also explains D1's first empty `/warps`.
- **`/knk cache reload` did nothing** — only `refresh` was a subcommand, `reload` just printed stats. The "works after cache
  reload" notes (A9, E5) and C5 (spawn mode change only after a restart) were cache times running out. `reload` is now
  `refresh`, and refresh also drops the permission cache (grants applied at once instead of within 30 s).
- **E7 (bug):** multi-word places (`/warp Residential District`): tab completion skipped them. Now completed word by word,
  spacing ignored, unknown names get "Did you mean: …?" (no auto-pick — warps can cost gems).
- **B4 (request):** "Request sent … [Cancel]" — clickable `/tpcancel` (also on the pending-request reminder).
- **I2 (bug):** `/tpahere` to a siege member now says "X is in a siege match." (other reasons about the target stay hidden).
- **K1 (bug):** API down → staff `/tp A` said "No player found named 'A'". Shared `UserAdminService.resolveTarget` now says
  "Can't look up 'A' right now (the KnK service is unreachable)". Staff `/tp` still needs the API for the rank check.
- Explained, no change: A8 — `/minecraft:tp` is vanilla (vanilla messages, no audit/rank/vanish handling) by design;
  K4 — `/spawn` with the API down refuses with "permissions can't be checked" when that player's `knk.teleport.spawn`
  answer isn't cached (fail closed); J1 — the five domain fields are FormConfiguration data, not seeded (the developer added
  them to Town, District, Structure and GateStructure).
- Noted, outside teleport: joining players ignore the Game Settings join spawn — the plugin side of Game Settings isn't
  built yet (developer has a stash of a first version); `/spawn` itself uses it.

**Round-2 re-test:** E5/E6 (promote → `/warps` within a few seconds), E7 (`/warp Residential District`, tab completion,
"Did you mean"), B4 [Cancel], I2, K1 message, `/knk cache reload` after a Game Settings change (C5) and after removing a
grant (A9); plus the untested B9, D3, D8, F3, J2, J4.

**Anti-exploit checks still to test (L, DESIGN §3.12):** frozen mid-warmup → refused, no charge; siege queue joined
mid-warmup → refused, no charge; double [Accept] → second finds nothing; request bait-and-switch (old [Accept] after a
`/tpahere` replaced the request must not pull the target); 6 requests to one target → only the newest 5 pending;
pearl/chorus while frozen blocked; `/tpa` to a player inside an AllowEntry=false domain → refused at commit.

**Feature requests (developer, 2026-09-28) — need design before building:**
1. **Per-permission-group teleport fees** for `/tpa`, `/warp` and `/spawn`: optional per group, with a default; each with
   a price, a currency (coins, gems, XP or a combination) and a cooldown. Open: configured on PermissionGroup (web app) or
   in config; does a group fee replace or add to a domain's warp price; which group wins when a player has several
   (highest weight?); does a group cooldown replace `teleport.cooldown-seconds`.
2. **`/back` variants by permission:** `knk.teleport.back` (death, today), `knk.teleport.back.warps` (before a `/warp`),
   `knk.teleport.back.teleport` (before other teleports), `knk.teleport.back.spawn` (before `/spawn`),
   `knk.teleport.staff.back.others` (staff `/back <player>`), `knk.teleport.back.all` / `*` (every variant). With several
   granted, `/back` returns to the origin of the latest recorded teleport. Open: does "teleport" include `/tpa`, `/tpahere`
   and being moved by staff; is a `/back` itself recorded (ping-pong); is `/back` after a paid warp free; expiry per variant;
   still never after a siege teleport/death.

## Cross-cutting

- **Docs to update when phases land** (not now): `user-features/COMMAND_CATALOG_V3.md` (already stale — see DESIGN §1.3
  discrepancy 3), `user-features/EVENT_CATALOG_V3.md` (new listeners), `ACTIVE_SESSIONS.md` rows, and the
  `knk-plugin/CLAUDE.md` menu/auth notes (discrepancy 5) if the developer agrees.
- **Linear:** one parent issue for the feature, one sub-issue per phase. No existing KNG issue covers teleport
  (KNG-5/6 enchant books/grades, KNG-7/8 rank display, KNG-9 player commands, KNG-11 combat safezones are related only
  by shared infrastructure); KNG-11's safezone check is not a combat tag and is not reused.
- **Permission grants** (data, via web-app PermissionGroup forms, after each phase): Default → `knk.teleport.request`,
  `.spawn`, `.warp`; Noble → `knk.teleport.warmup.short`; Dragon Blood → `.request.here`, `.back` (per Q2/Q5); staff
  groups → `knk.teleport.staff`, `.staff.others`, `.staff.silent`, `knk.teleport.bypass.*`, `knk.region.bypass`.
