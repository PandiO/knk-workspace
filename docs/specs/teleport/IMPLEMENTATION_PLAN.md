# Teleportation Commands — Implementation Plan

**Status:** Draft — awaiting developer review (open questions in [DESIGN.md §5](DESIGN.md#5-open-questions-for-the-developer))
**Last updated:** 2026-09-26
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

## Phase 7 — `/back` (optional, Q5)

**knk-paper:** `teleport/BackLocationBook.java` (death location, expiry `teleport.back.expire-seconds`, cleared on use),
`listeners/BackDeathListener.java` (skip deaths while `SiegeService.activeLobbyOf` / via a restriction), `commands/
BackCommand.java` (`knk.teleport.back`), `plugin.yml`, `config.yml` `teleport.back.enabled`.
**Tests:** stored on death, expired after 5 min, not stored for siege deaths, uses warmup + guards + safe-location.
**Acceptance:** Dragon Blood player dies, `/back` within 5 min returns them near the death spot after the warmup.

---

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
