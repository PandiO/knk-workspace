# Realtime channel inventory: how plugin, API and web app stay in sync today

**Status:** Report (research only, no code changed)
**Date:** 2026-10-25
**Issues:** [#66](https://github.com/PandiO/knk-workspace/issues/66) (KNG-57); read: #76 (KNG-170), #121 (KNG-262), #35 (KNG-176), #31 (KNG-202)
**Code basis:** knk-web-api `master` @ `6f08383`, knk-plugin `main` @ `ee35fb1`, knk-web-app `main` @ `0d61270` (all 2026-10-25)
**Used by:** [realtime-signalr/DESIGN.md](../specs/realtime-signalr/DESIGN.md), [plan handoff](../ai-agents/handoffs/2026-10-25-ux-dashboard-signalr-plan.md)

Path abbreviations:
- `P/` = `knk-plugin/knk-paper/src/main/java/net/knightsandkings/knk/paper/`
- `C/` = `knk-plugin/knk-core/src/main/java/net/knightsandkings/knk/core/`
- `AC/` = `knk-plugin/knk-api-client/src/main/java/net/knightsandkings/knk/api/`
- `cfg` = `knk-plugin/knk-paper/src/main/resources/config.yml`
- `API/` = `knk-web-api/`, `WEB/` = `knk-web-app/src/`


---

## 0. Headline findings

1. **There is no push from the API to the plugin except `RegionHttpServer`** (plugin-hosted HTTP, called synchronously by
   the API for region rename and containment questions). Everything else the plugin learns about web-app edits comes from
   one of four sources: (a) the 2 s `PlayerNotificationPoller`; (b) about 12 periodic re-syncs/timers; (c) cache TTLs
   (mostly the global 60 s); (d) pull-on-join. Many web-app edits have **no path at all** until a restart, an admin reload,
   or the player rejoining (gates, freeze, vanish/active mode, group/grant permission edits for online players, siege
   config while no lobby cycles).
2. **The "PlayerNotification" queue is not a table.** It is `InMemoryPlayerNotificationQueue`, a singleton
   (`API/DependencyInjection/ServiceCollectionExtensions.cs:70`, `API/Services/InMemoryPlayerNotificationQueue.cs:11-27`):
   24 h TTL, 1000 cap, **lost on API restart**, single consumer. This is the natural thing to replace with hub messages.
   Its 9 types are the existing event vocabulary (section 4.2).
3. **Online presence exists but is not reliable.** `User.IsOnline` / `User.LastSeenAt` (`API/Models/User.cs:152-170`) are
   set only by `PUT /api/users/{id}/presence` from the plugin's join/quit handlers (`P/listeners/PlayerListener.java:208-211,
   335-338, 355-366`). There is no reconcile on plugin start, crash or a failed quit call, and the join report is skipped
   if the user is not in the cache yet. A second, independent "online" truth exists in statistics sessions
   (`PlayerStatSession.LastHeartbeatAt`, closed after 5 min without a heartbeat). Hub connection state plus a roster
   snapshot on (re)connect would fix this.
4. **No SignalR/WebSocket/SSE anywhere** in the API (`API/knkwebapi_v2.csproj:26-45`, no `MapHub`/`UseWebSockets`) or the
   web app (`WEB/../package.json:5-15`, only `setInterval`/`setTimeout` polling). ASP.NET Core SignalR server is part of
   the shared framework on net8.0 (`API/knkwebapi_v2.csproj:4`), so no new package is needed on the API.
5. **The Java SignalR client fits the plugin.** `com.microsoft.signalr:signalr:10.0.14` (Maven Central POM) depends on
   `okhttp 4.12.0` (the plugin already ships exactly 4.12.0, `knk-plugin/knk-api-client/build.gradle.kts:4`), `rxjava 3.0.11`,
   `gson 2.8.9`, `slf4j-api 1.7.25`. 8.0.x uses okhttp 4.10.0. The client has `withHeader` (so `X-API-Key` works),
   `onWithResult` (client results, so the containment queries could move onto the hub), but **no automatic reconnect**
   (only `onClosed`; hand-write the backoff loop as #66 already says).
6. **Deployment:** the alpha nginx already forwards `Upgrade`/`Connection`, but only under `location /api/`
   (`knk-workspace/scripts/alpha-web/nginx.conf:16-26`). A hub mapped at `/hubs/...` would fall through to the SPA
   `location /`. Put the hub under `/api/hubs/...` or add a location. `production-installation.md` nginx (`:949-957`)
   does not forward `Upgrade` at all. The plugin reaches the API directly on the Docker network (`http://api:5000/api`),
   so nginx and Cloudflare are not in the plugin's path.

---

## 1. Plugin: polling loops, periodic re-syncs, TTLs and pull-on-join (API to plugin direction)

Intervals are the shipped `config.yml` defaults.

### 1.1 Timers that exist to pick up API-side changes

| Class (file:line) | Fetches | Interval / config key |
|---|---|---|
| `PlayerNotificationPoller` (`P/tasks/PlayerNotificationPoller.java:44,73,149-174`) | `GET /api/PlayerNotifications/pending`, then `POST .../acknowledge`. Skipped while nobody is online (`:157`). Self-rescheduling `runTaskLaterAsynchronously`. TODO for SignalR at `:40` | 2 s, `player-notifications.poll-interval-seconds` (`cfg:208-210`) |
| `HeadlessWorldTaskPoller` (`P/tasks/HeadlessWorldTaskPoller.java:27-28,43-44,85-86`) | `worldTasksApi.listByStatus("Pending")` for headless tasks (GateBlockScan, MinecraftCatalogScan; registered `P/KnKPlugin.java:605-610`). Another agent covers world tasks in depth | 5 s, backing off to 60 s idle: `world-tasks.headless-poll-interval-seconds`, `...-max-interval-seconds` (`cfg:163-170`) |
| `DomainAccessFlagSync` (`P/regions/access/DomainAccessFlagSync.java:41-49,74-86`) | every domain's AllowEntry/AllowExit (`DomainAccessRulesApi`) onto WorldGuard flags. Also run after a region finalize (`P/KnKPlugin.java:545-555`) and `/knk regions repair` | startup after `delay-ticks` 100, then every 5 min: `regions.access.sync.interval-minutes` (`cfg:827-832`) |
| `GameSettingsManager.refresh` (`P/settings/GameSettingsManager.java:133-145,170`) | `GameSettingsQueryApi.get()`: announcements, join spawn, respawn, time/weather, **hub settings** (`HubService` reads `gameSettingsManager.current()`, `P/KnKPlugin.java:2672-2680`) | 30 s, `game-settings.refresh-interval-seconds` (`cfg:215-217`) |
| `LootboxRuntime.refresh` (`P/lootbox/LootboxRuntime.java:59-63,94-`) | lootbox runtime config + active spawns | 60 s, `lootboxes.runtime-refresh-seconds` (`cfg:731`) |
| Grade catalog (`P/KnKPlugin.java:3598-3615`) | `gradesDataAccess.listAsync` into `GradeCatalog` (enchant-book caps) | 10 min, `enchant-books.grade-cap.grade-refresh-minutes` (`cfg:692`) |
| `TelemetryFlushTask.pollConfig` (`P/telemetry/TelemetryFlushTask.java:47-51,122`) | owner's telemetry choices (enhanced players, test runs) | 60 s, `telemetry.config-poll-seconds` (`cfg:382`) |
| `RoadNetworkCache` (`P/roads/RoadNetworkCache.java:57-58,105-106`) | road tiles (ETag) every 10 min; network meta (profiles, street names) every 60 s | constants, no config |
| `SpyService.refreshAll` (`P/user/SpyService.java:48-60`, started `P/KnKPlugin.java:1848`) | re-resolves `knk.socialspy` / `.exempt` through `KnkPermissible` (so it follows the permission cache) | 60 s, `private-messages.spy.refresh-seconds` (`cfg:187-189`) |
| Offline-security verifier (`P/KnKPlugin.java:2607-2629`, `C/offline/OfflineIdentityVerifier.java`) | re-checks accounts not confirmed for `verify-after-hours` via `usersQueryApi.getByUuid`; deletes erased accounts (today's only erasure path) | hourly; `offline-cache.verify-after-hours` 6 (`cfg:860-866`) |
| `SalaryPayoutScheduler` (`P/user/SalaryPayoutScheduler.java:47,94`) | checks online players each minute, pays hourly via API (writes, not reads) | 60 s check |
| `TempRegionRetentionTask` (`P/tasks/TempRegionRetentionTask.java:110-120`) | domain usage lookups before deleting temp regions | daily |

### 1.2 Cache TTLs (plugin re-reads on a stale hit; no timer)

| Cache (file:line) | TTL (effective) | Notes |
|---|---|---|
| `UserCache`, `TownCache`, `DistrictCache`, `StructureCache` (`P/cache/CacheManager.java:49-57`) | **global 60 s** `cache.ttl-seconds` (`cfg:871`) | `cache.entities.users.ttl-minutes: 15` etc. (`cfg:875-`) are ignored (#121) |
| Enchantment definitions, kits, menu templates, material refs, grades, tags, domain catalog (`P/KnKPlugin.java:628-701`) | global 60 s (`config.cache().ttl()`) | per-entity keys dead (#121, `P/dataaccess/DataAccessFactory.java:276-282`) |
| Item blueprints (`P/dataaccess/DataAccessFactory.java:155-166`, `P/KnKPlugin.java:636-639`) | **20 min** `cache.entities.itemBlueprints.ttl-minutes` (`cfg:931-936`) | KNG-262 already fixed for this entity (see stale list) |
| Permissions effective set (`P/dataaccess/DataAccessFactory.java:284-290`, `P/KnKPlugin.java:651-661`) | 30 s `cache.entities.permissions.ttl-seconds`; cache-only checks may use a set up to 90 s old `effective-set-stale-seconds` (`cfg:1018-1034`); preloaded at pre-login (`P/listeners/PlayerListener.java:130-153,176-192`), forgotten at quit (`:326-332`) | In-game changes invalidate at once (`P/KnKPlugin.java:752-757`); web-app changes wait for the TTL (comment `P/KnKPlugin.java:659-661`) |
| Offline security store (KNG-58) (`P/KnKPlugin.java:2564-2600`, `cfg:856-866`) | identity 30 d, permission answers 72 h, flushed every 10 s | `RankChanged` does not touch it (#76, confirmed: `P/user/UserAdminService.java:612-616` only refreshes the user) |
| Siege runtime config (`P/dataaccess/DataAccessFactory.java:312-326`) | 30 min `cache.entities.siege` (`cfg:990-996`) | refreshed at start (`P/siege/SiegeService.java:252-254`), on lobby cooldown (`RefreshConfigEffect`, `:390`, `C/siege/SiegeLobbyStateMachine.java:471`) and `/siege admin reload` (`:1541`) |
| Title brackets (`P/KnKPlugin.java:737-739`) | 10 min | siege also loads them once at start (`P/siege/SiegeService.java:253,1553`) |
| Permission groups list (`P/KnKPlugin.java:741-742`) | 2 min | |
| Teleport destinations / teleport group policy (`P/KnKPlugin.java:2506-2509, 2547-2551`) | 60 s `teleport.destinations.cache-seconds` (`cfg:261-262`) | |
| Navigation destinations, compass settings (`P/navigation/NavigationDestinations.java:49`, `P/navigation/CompassSettingsStore.java:21`) | 60 s, refresh started by the next stale read | |
| Region→domain resolver (`C/regions/RegionDomainResolver.java:45`) | 1 min | |
| Spawn destination (`C/teleport/SpawnPointResolver.java:37`) | 5 min | |
| Menus: item catalogue pages / categories (`P/menu/content/ItemsCatalogMenuFeature.java:53,76`), kits availability (`P/menu/content/KitsMenuFeature.java:63`), discoveries summary (`P/menu/content/DiscoveriesMenuFeature.java:57`), lootbox odds (`P/lootbox/LootboxOpening.java:70`) | 60 s / 10 min, 5 s, 30 s, 5 min | `MenuAutoRefreshTask` (`P/KnKPlugin.java:895`) is a per-tick UI redraw, not an API poll |

`/knk cache refresh` (`CacheManager.registerRefreshHook`, `P/cache/CacheManager.java:157`) is the manual "invalidate
everything" path. Its registered hooks are a ready-made list of push handlers: item blueprints (`P/KnKPlugin.java:639`),
permissions (`:661`), region domains (`:926`), navigation destinations/routes/compass (`:1613,1658,1667`), game settings
(`:2437`), spawn destination (`:2476`), teleport group settings (`:2523`), warp destinations (`:2551`).

### 1.3 Loaded once (startup / manual reload only, no TTL, no poll)

| What | Where | Refreshed by |
|---|---|---|
| **Gate structures/doors** | `gateManager.reloadGates()` at enable (`P/KnKPlugin.java:457-466`); per-district first entry `DistrictGateLoader.loadIfNotAlreadyLoaded` (`P/gates/DistrictGateLoader.java:51`, once per session) | `/gate ... reload` (`P/commands/GateCommand.java:529`, `GateCommandSupport.java:531-554`), siege stale restore (`P/siege/SiegeGateController.java:114`). **A web-app gate edit never reaches a running server by itself.** |
| Siege lobbies + title ranks at boot, crash-locked gate restore, unfinished-match abort | see #31 (KNG-202), confirmed current: `P/siege/SiegeService.java:252-254, 1553` | `/siege admin reload` or restart |
| Managed region repair, domain world backfill | `P/KnKPlugin.java:556-560` (`ManagedRegionsBootstrap`, `DomainWorldBackfillReporter`) | startup with retries |

### 1.4 Pull-on-join / pre-login

| What | Where |
|---|---|
| User record (`API_THEN_CACHE_REFRESH`), get-or-create, permission preload | `P/listeners/PlayerListener.java:116-192` |
| Admission (invite gate) | `P/KnKPlugin.java:2646-2660` (`AdmissionListener`, pre-login) |
| **Freeze state** (only read at join) | `P/user/AdminFreezeManager.java:59-80` `restoreOnJoin` |
| **Active mode / vanish** (persisted mode re-applied, permission re-checked) | `P/listeners/ModeListener.java:40-60` |
| Discovery known set | `P/discovery/DomainDiscoveryListener.java:162,206` |
| Undelivered lootbox tokens | `P/listeners/LootboxJoinListener.java:52-54` |
| Ignore list / PM session | `P/listeners/PrivateMessageSessionListener.java:45-49` |
| Salary offline gap, first-join kits | `P/user/SalaryPayoutScheduler.java`, `P/listeners/PlayerListener.java:290` |
| Pending notifications for that player | delivered by the next poll (left queued while offline, `PlayerNotificationPoller.java:35-38`) |

---

## 2. Inbound channels into the plugin (API calls the plugin)

| Listener | Bind / port / auth | Endpoints | Called by (API) |
|---|---|---|---|
| `RegionHttpServer` (`P/http/RegionHttpServer.java:20-61`, started `P/KnKPlugin.java:595-599`) | `com.sun.net.httpserver`; `region-http.bind-address` default `127.0.0.1`, port 8081 (`cfg:65-70`); `X-API-Key` required when `api.auth.api-key` is set (`P/http/RegionHttpAuthFilter.java`). Alpha: `0.0.0.0` inside the container, unpublished (`docs/guides/alpha-go-live.md:263-277`) | `POST /Regions/rename?oldRegionId&newRegionId[&domainType][&parentRegionId][&world][&replaceRegionId][&subRegionOf]` (`:90-117`); `GET /api/regions/{id}/contains-location?x&z&allowBoundary`; `GET /api/regions/{parent}/contains-region/{child}?requireFullContainment` (`:162-193`) | `API/Services/RegionService.cs:96-309` (`MinecraftPlugin:BaseUrl`, default `http://localhost:8081`, key from `Security:PluginApiKey`, `API/DependencyInjection/ServiceCollectionExtensions.cs:287-293`). Rename: `DomainRegionNameFinalizer.FinalizeAsync / FinalizeSubRegionAsync` (`API/Services/DomainRegionNameFinalizer.cs:114-134, 212, 275-337`) used by Town/District/Structure/Domain/GateStructure/DomainSubRegion services on create/update; manual `API/Controllers/RegionsController.cs:59`. Containment: form validation `API/Services/ValidationMethods/LocationInsideRegionValidator.cs:205`, `RegionContainmentValidator.cs:158` (synchronous request/response while a web user fills a form) |
| `MetricsHttpServer` (`P/metrics/MetricsHttpServer.java:17-36`) | port 9225, bearer token (`cfg:76-86`) | `GET /metrics` | Prometheus scraper, not the API |

No other inbound path exists (no webhook, no WebSocket client).

Note for the design: the containment checks are **synchronous queries from the API to the game server** that the web user
waits on. A hub can carry them only via SignalR client results (`ISingleClientProxy.InvokeAsync<T>` on the server,
`onWithResult` on the Java client, present in 10.0.14). Rename is a command with a boolean answer, same shape.

---

## 3. Plugin to API: game-side events reported today

| Report | Class (file:line) | Trigger / interval | API endpoint / store |
|---|---|---|---|
| **Presence** join/quit | `P/listeners/PlayerListener.java:208-211, 335-338, 355-366` | event | `PUT /api/users/{id}/presence` (`API/Controllers/UsersController.cs:709-740`, `[RequirePluginService]`) → `UserService.UpdatePresenceAsync` (`API/Services/UserService.cs:432-443`) → `UserRepository.cs:197` |
| Statistics (incl. session start/end, heartbeat) | `P/statistics/StatisticsFlushTask.java:21-34,69-72`, `StatisticsSessionListener.java:35,56` | flush 60 s `statistics.flush-interval-seconds`, spool replay 60 s (`cfg:328-335`) | `StatisticsIngestionService.IngestAsync` (`API/Services/Statistics/StatisticsIngestionService.cs:56,219,274`); sessions without heartbeat closed after `Statistics:SessionTimeoutMinutes` 5 (`API/Configuration/StatisticsOptions.cs:36`, `StatisticsProjectionService.cs:65`) |
| Discoveries | `P/discovery/DiscoveryFlushTask.java:71-72` | batch 20 ticks, replay 60 s (`cfg:288-301`) | discoveries API |
| Gate state (open/closed/destroyed/HP) | `P/gates/GateStateSyncTask.java:97-110` | 120 s `gates.state-sync-interval-seconds` (`cfg:541`) + shutdown | gate doors API |
| World list "runtime worlds" (server heartbeat-ish) | `P/settings/GameSettingsManager.java:142-144, 665` | checked every 30 s `game-settings.runtime-sync-interval-seconds`; sent on change or every 10 min (`cfg:218-222`) | `PUT /api/GameSettings/runtime-worlds` (`API/Controllers/GameSettingsController.cs:86-93`); stale after 30 min (`API/Services/GameSettingsService.cs:94-98`) |
| PM log | `C/messaging/PrivateMessageLogShipper.java:109` | 5 s `private-messages.log.flush-seconds` (`cfg:198`) | PM log API |
| Telemetry events | `P/telemetry/TelemetryFlushTask.java:50` | 10 s (`cfg:380`) | telemetry API |
| World analytics | `P/analytics/WorldAnalyticsFlushTask.java:59` | 300 s (`cfg:398`) | world analytics API |
| Siege matches, salary, teleport audit, lootbox spawns/claims, kit grants, active mode, `/freeze` | various command/service paths | event | respective controllers |

**Does the API know who is online right now?** Partly:
- `User.IsOnline` + `LastSeenAt` (`API/Models/User.cs:152-170`, column `KnKDbContext.cs:805`), exposed in user DTOs
  (`API/Mapping/UserMappingProfile.cs:49-50,157-158`) and the moderation "online only" filter
  (`API/Controllers/UsersController.cs:825`; web app `WEB/pages/admin/UserModerationPage.tsx`). Because accounts are
  merged on link (`UserService.LinkMinecraftAccountAsync`, `:1195`), a web user's linked player is the same `User` row.
- Gaps: no reconcile after a server crash/kill or a plugin reload (players stay `IsOnline=true`); a failed quit PUT is only
  logged (`PlayerListener.java:361-365`); join is skipped when the user is not cached yet (`:356-358`); not audited
  (`UserService.cs:438-441`). Only `PrivacyRepository.cs:169` resets it (erasure).
- `PlayerStatSession` (open session with `LastHeartbeatAt`, `API/Models/Statistics/PlayerStatSession.cs:9,22`) is a better
  liveness signal (60 s heartbeats, 5 min timeout) but is a statistics table, not a presence API.
- `ClientActivityMiddleware` (`API/Middleware/ClientActivityMiddleware.cs:89-99`) keys on `X-Knk-Client-*` headers that
  neither the plugin nor the web app sends, so "is the game server connected" is not tracked anywhere either.

---

## 4. API side: publish points and existing event plumbing

### 4.1 Natural publish points (service methods)

| Area | Methods (file:line) | What the plugin hears today |
|---|---|---|
| Rank/group membership | `UserPermissionGroupService.UpsertAsync` (`API/Services/UserPermissionGroupService.cs:61`), `DeleteAsync` (`:216-237`), `AfterMembershipChangeAsync` (`:138-158`), `SweepExpiredRanksAsync` (`:198-212`, from `RankExpirySweepService`, every 30 s per `docs/architecture/api-connectivity.md:116`). Endpoints `UsersController.cs:111-151`, `UserPermissionGroupsController.cs:51,74` | `RankChanged` notification (`:193-196`), all paths. Plugin handler only redraws display (`P/KnKPlugin.java:773`, `P/user/UserAdminService.java:612-616`) |
| Permission groups (a group's nodes edited, group deleted) | `PermissionGroupService.CreateAsync/UpdateAsync/DeleteAsync` (`API/Services/PermissionGroupService.cs:40,60,104`) | **nothing**; 30 s TTL |
| Direct grants | `PermissionGrantService.CreateAsync/UpdateAsync/DeleteAsync/UpsertByNodeAsync/RevokeByNodeAsync` (`API/Services/PermissionGrantService.cs:52,58,106,137,206`), endpoint `UsersController.cs:181` | **nothing**; 30 s TTL |
| XP / title / balances | `UserService.AdjustBalancesAsync` (`API/Controllers/UsersController.cs:870-893`, notify at `API/Services/UserService.cs:941-947`), `ApplyTitleProgressionAsync` (`:972-984`), `MergeAccountsAsync` (`:1188`); `CurrencyService.GrantAsync/SpendAsync/AdminAdjustAsync/ReverseAsync` (`API/Services/Currency/CurrencyService.cs:134,148,162,255`); `CurrencyAdminService.ReverseAsync` (`:110,174`) | `TitleChanged` only when the title changed and `notifyPlayer`; pure balance changes: **nothing** (scoreboard shows the 60 s user cache) |
| Payments | `CurrencyController.cs:302` | `PaymentReceived` |
| Freeze | `UserService.SetFrozenAsync` (`:445-462`), `UsersController.cs:749-773` | **nothing** until rejoin |
| Active mode / vanish | `UserService.UpdateActiveModeAsync` (`:415`), web toggle `UsersController.cs:237-242` | **nothing** until rejoin |
| Personal multipliers, gate pass-through method | `UserService.cs:353, 406` | nothing (60 s user cache) |
| Account link / merge | `UserService.LinkMinecraftAccountAsync` (`:1195-1333`) | `AccountLinked` |
| Discovery reset | `DiscoveryService.cs:673` | `DiscoveryReset` |
| Statistics visibility | `StatisticsVisibilityService.UpdateAsync` (`API/Services/Statistics/StatisticsVisibilityService.cs:43`) | nothing (menus re-read) |
| Domains / towns / districts / structures / sub-regions | `DomainService` `:42,61,102`, `TownService` `:54,77,108`, `DistrictService` `:106,190,285`, `StructureService` `:61,94,147`, `DomainSubRegionService` | rename via `RegionHttpServer`; AllowEntry/AllowExit via 5 min sync; names via 60 s caches |
| Gates | `GateStructureService.Create/Update/Delete/UpdateOverridesAsync` (`API/Services/GateStructureService.cs:71,98,124,159`), `GateDoorService` (`:74-305`) | **nothing** (startup/manual reload) |
| Siege | `SiegeConfigurationService.UpdateAsync` (`:31`), `SiegeLobbyService` (`:49,59,68`), `SiegeScenarioService` (`:54-351`) | picked up at the next lobby cooldown or `/siege admin reload` |
| Game settings / hub | `GameSettingsService.UpdateAsync` (`API/Services/GameSettingsService.cs:44`), `HubSettingsService` | 30 s poll |
| Menus, items, enchantments, kits, grades, tags | `MenuTemplateService` `:46,79,117`; `ItemBlueprintService` `:55,101,160`; `EnchantmentDefinitionService` `:39,62,119`; `KitService` `:69,84,124`; `GradeService` `:33,44,73`; `TagService` `:33,43,57` | TTL only (60 s; item blueprints 20 min) |
| Teleport destinations / group policy, navigation compass/domain nav settings | `TeleportDestinationService`, `NavigationCompassSettingsService.UpdateAsync` (`:38`), `DomainNavigationSettingsService` (`:41`) | 60 s caches |
| Lootboxes | `LootboxConfigurationService` (`:29`), `LootboxTypeService` (`:36,49,73`), `LootboxSpawnAreaService` (`:60,76,106`; notify `:116`), `LootboxRuntimeService.Pickup.cs:184`, `LootboxTokenGrantService.cs:183` | `LootboxWorldChanged` (despawns, area deletes, revokes), `LootboxTokensIssued`; config via 60 s poll |
| Salary config, discovery config, road network | `SalaryConfigurationService` (`:25`), `DiscoveryConfigurationService`, `RoadNetworkService` | TTL / 60 s meta poll |
| World tasks | `WorldTaskService.CreateAsync/UpdateStatusAsync/ClaimAsync/CompleteAsync/FailAsync` (`API/Services/WorldTaskService.cs:31-278`) | plugin polls (5→60 s); web app polls 2 s |
| Privacy erasure | `PrivacyDeletionService.ExecuteAsync` (`API/Services/Privacy/PrivacyDeletionService.cs:311`), `PrivacyDeletionDueService` | plugin's hourly verifier only |

### 4.2 Existing event/notification mechanisms to hang events on

- **`IPlayerNotificationQueue`** (`API/Services/Interfaces/IPlayerNotificationQueue.cs:14-`), singleton in-memory
  implementation. Types (`PlayerNotificationTypes`): `TitleChanged`, `RankChanged`, `LootboxTokensIssued`,
  `PaymentReceived`, `CurrencyAlert`, `LootboxWorldChanged`, `DiscoveryReset`, `LocationOrphanDigest`, `AccountLinked`
  (API constants; plugin mirror `C/domain/users/PlayerNotification.java:56-103`). Consumer endpoint
  `API/Controllers/PlayerNotificationsController.cs:15-34` (`GET pending`, `POST acknowledge`, plugin key only). All 13
  enqueue call sites are listed in section 4.1. A hub-backed implementation of this interface is the smallest first step.
- **Audit log** `AuditLogService.RecordAsync(actor, targetUserId, AuditAction, details)` (`API/Services/AuditLogService.cs:21`).
  Called on group assign/remove, grant add/update/remove, title change, vanish, balance adjust, freeze/unfreeze, kit,
  discovery reset, currency policy, privacy. A single choke point for most user-targeted admin changes, but not for
  entity CRUD (gates, menus, items...).
- **Email outbox** (`EmailDispatcher : BackgroundService`, 5 s, `API/Services/Email/EmailDispatcher.cs:16-19`;
  `API/Controllers/EmailOutboxController.cs`): the only DB-backed outbox pattern in the API, a template if gap-free
  delivery ("erasures since event id X", #66) needs a persisted sequence.
- No domain events, MediatR, EF `SaveChangesInterceptor` or change log exist (searched).
- Hosted services that would publish: `RankExpirySweepService`, `CurrencyMonitorService`, `PrivacyDeletionDueService`,
  `LocationRetentionScheduler`, `LeaderboardSnapshotService`, `StatisticsProjectionService`, `CloudflareAccessSyncService`
  and others (`grep BackgroundService API/Services`).

### 4.3 Auth schemes

- Plugin: `X-API-Key` header compared constant-time to `Security:PluginApiKey`; optional `X-Acting-User-Id`
  (`API/Attributes/RequireServiceOrPermissionAttribute.cs:52-108`). Attributes `[RequirePluginService]`,
  `[RequireServiceOrPermission]`. Plugin side: `AC/auth/ApiKeyAuthProvider.java`, header `api.auth.api-key-header`
  default `X-API-Key` (`cfg:30-36`).
- Web users: JWT bearer (`Security:Jwt`, `API/Program.cs:80-121`) with a `TokenVersion` check in `OnTokenValidated`;
  refresh token in an HttpOnly cookie, path `/api/Auth` (`API/Configuration/RefreshTokenCookie.cs:8`). Web app sends
  `Authorization: Bearer` from local/session storage and `credentials: 'include'` (`WEB/services/serviceCall.ts:93-104`,
  `WEB/utils/tokenService.ts:6-43`). **For a browser hub connection, `JwtBearerEvents.OnMessageReceived` must read
  `access_token` from the query string for the hub path; it is not configured today.** Cloudflare Access also gates the
  whole `app.` host (cookie, same origin, so a WebSocket carries it).
- CORS: `Cors:AllowedOrigins` with credentials (`API/Program.cs:205-224`); production is same-origin. Rate limiting has
  only named policies, no global limiter (`API/Configuration/RateLimitingSetup.cs:26-43`).

---

## 5. Plugin API client stack

- HTTP: OkHttp 4.12.0 + Jackson 2.17.2 (`knk-plugin/knk-api-client/build.gradle.kts:1-8`); one `OkHttpClient`
  (`AC/client/KnkApiClient.java:575-588`), timeouts 10 s (`cfg:38-42`), shared executor (`:597-600`).
- Shading: Shadow 8.3.11, relocates `com.fasterxml.jackson`, `okhttp3`, `okio` to `net.knightsandkings.knk.libs.*`
  (`knk-plugin/knk-paper/build.gradle.kts:3-5, 74-81`). No Paper `libraries:` loader in `plugin.yml`.
- Java 25 toolchain (`knk-plugin/build.gradle.kts:14-19`), Paper API 26.3 (`knk-plugin/gradle.properties`).
- Connectivity: `ApiConnectivityMonitor` probes `GET /health/ready` every 10 s, DOWN after 3 failures, UP after 2
  (`P/connectivity/ApiConnectivityMonitor.java:60-94`, `cfg:44-62`), fires `ApiConnectivityChangedEvent` on the main
  thread (UNKNOWN to UP is not reported as recovery, see #31). `DataAccessExecutor` skips the API while DOWN
  (`C/dataaccess/DataAccessExecutor.java:18-28`, KNG-171); gateways outside it ignore DOWN (#35: teleport policy/
  destinations, title brackets, permission groups, ignore list). `HubOutageService.setOnRecovery` is a second recovery
  hook (#31).
- Offline security cache KNG-58: `offline-security.json` (identity, freeze, mode, permission answers), see 1.2.
- **SignalR fit:** add `com.microsoft.signalr:signalr` (10.0.x pulls okhttp 4.12.0, identical to today; rxjava3 3.0.11;
  gson 2.8.9; slf4j-api 1.7.25 runtime). Relocate `io.reactivex.rxjava3` and `com.google.gson` too (Paper ships its own
  Gson; relocating avoids a clash) and keep okhttp relocated. Paper provides an SLF4J binding. No auto-reconnect in the
  Java client: build the loop on `onClosed` with backoff, and do the full resync on every (re)connect, wired to the
  existing refresh paths (`DomainAccessFlagSync.syncNow`, `CacheManager` refresh hooks, `PermissionsDataAccess.invalidateAll/
  invalidateEffective`, `GameSettingsManager.refreshNow`, `LootboxRuntime.refresh`, `gateManager.reloadGates`).
  Alternative with no new dependency: OkHttp's own WebSocket plus a hand-rolled JSON protocol (loses SignalR's
  invocation/result semantics).

---

## 6. Web app

- Polls: world task status every 2 s while a world-bound field is active (`WEB/components/Workflow/WorldBoundFieldRenderer.tsx:427-525`,
  `worldTaskClient.getById`); Minecraft catalog scan every 3 s (`WEB/components/admin/minecraftCatalog/MinecraftCatalogScanCard.tsx:15-16,115-131`).
  Nothing else polls (other timers are UI debounce/toasts).
- Push candidates for the browser: world-task status changes (claimed/completed/failed), catalog-scan progress, the
  player's online state on profile/moderation pages, "your balance/rank changed", admin moderation list. Notifications to
  web users do not exist as a feature yet.
- Auth: see 4.3 (Bearer from storage + refresh cookie). API base `/api` in production (`WEB/config/appConfig.ts:7-24`),
  same origin behind nginx.

---

## 7. Deployment notes for WebSockets

- Alpha (NAS, stack `knk-alpha`): Cloudflare Tunnel → nginx `web:8080` → `location /api/ { proxy_pass http://api:5000; ...
  Upgrade/Connection forwarded }` (`knk-workspace/scripts/alpha-web/nginx.conf:16-26`; doc copy `docs/guides/alpha-go-live.md:349-370`,
  comment "ready for SignalR (KNG-57)"). Actions: map the hub under `/api/hubs/...` (or add `location /hubs/`); consider a
  `map $http_upgrade $connection_upgrade` and a `proxy_read_timeout` above the SignalR keep-alive (default 60 s is fine with
  the 15 s keep-alive). Cloudflare Tunnel passes WebSockets.
- Plugin and API share the Docker network: plugin `api.base-url: http://api:5000/api`, API `MinecraftPlugin__BaseUrl=http://minecraft:8081`
  (`docs/guides/alpha-go-live.md:30-35,138,263-271`; `scripts/alpha-api/compose.api-service.yaml:40`; runbook
  `docs/guides/closed-alpha-deployment-runbook.md:271-273,343-345`). The plugin's hub connection would go straight to
  `http://api:5000/...` (no nginx, no Cloudflare Access), with `X-API-Key`.
- Production guide (bare host): nginx `/api/` block lacks `Upgrade`/`Connection` (`docs/guides/production-installation.md:949-957`);
  needs those two headers (and the hub path) before a browser hub works there.
- One game server today; no backplane needed. Note `GameSettings` already models several servers by `server-id`
  (`cfg:221-222`), so a hub group per server id is cheap to add.

---

## 8. Summary table

Priority: **high** = admin-change latency the developer cares about (ranks, permissions, statistics, balances, entity CRUD
from the web app); medium = config the server follows; low = rare, diagnostics, or already fast enough.

| mechanism | direction | interval/trigger | class/file | candidate push event | priority |
|---|---|---|---|---|---|
| Player notification poll | plugin pulls API | 2 s (skipped with nobody online) | `P/tasks/PlayerNotificationPoller.java:44,153-174`; API `InMemoryPlayerNotificationQueue` | one hub message per existing type (`TitleChanged`, `RankChanged`, `PaymentReceived`, `CurrencyAlert`, `LootboxWorldChanged`, `LootboxTokensIssued`, `DiscoveryReset`, `LocationOrphanDigest`, `AccountLinked`); keep "pending for offline player" semantics | high |
| Rank/group membership change | API→plugin via `RankChanged` | on change, ≤2 s + display only | `API/Services/UserPermissionGroupService.cs:138-237`; `P/user/UserAdminService.java:612-616` | `UserPermissionsChanged {userId, uuid}`: drop effective set + offline answers, re-read user, redraw tab/chat, re-check mode (#76) | high |
| Permission group / grant edits | plugin TTL | 30 s (90 s cache-only; offline answer first) | `API/Services/PermissionGroupService.cs:40-104`, `PermissionGrantService.cs:52-206`; `cfg:1018-1034` | `PermissionGroupChanged {groupId}` (fan out to online members), `UserPermissionsChanged {userId}` | high |
| Balance / XP / multipliers | plugin TTL (user cache) | 60 s; `TitleChanged` only on title change | `API/Services/UserService.cs:353,906-984`; `Currency/CurrencyService.cs:134-255` | `UserBalancesChanged {userId, coins, gems, xp}` (redraw scoreboard), keep `TitleChanged` | high |
| Freeze (web) | pull-on-join only | rejoin | `API/Services/UserService.cs:445-462`; `P/user/AdminFreezeManager.java:59-80` | `UserFrozenChanged {userId, frozen, reason}` | high |
| Active mode / vanish (web toggle) | pull-on-join only | rejoin | `API/Services/UserService.cs:415`, `UsersController.cs:237-242`; `P/listeners/ModeListener.java:40-60` | `UserModeChanged {userId, mode}` | high |
| Users/towns/districts/structures caches | plugin TTL | 60 s (per-entity keys ignored, #121) | `P/cache/CacheManager.java:49-57` | `EntityChanged {type, id, op}` → invalidate key | high |
| Item blueprints | plugin TTL | 20 min | `P/dataaccess/DataAccessFactory.java:155-166` | `EntityChanged {ItemBlueprint, id}` | high |
| Enchantments, kits, menu templates, material refs, grades, tags, domain catalog | plugin TTL | 60 s | `P/KnKPlugin.java:628-701` | `EntityChanged {type, id}`; menus: refresh open menus | high |
| Gate structures/doors | load at startup / manual reload | never by itself | `P/KnKPlugin.java:457-466`; `API/Services/GateStructureService.cs:71-159`, `GateDoorService.cs:74-305` | `GateChanged {gateId, op}` → reload that gate (and world sync check) | high |
| Domain AllowEntry/AllowExit | plugin pulls | 5 min + after finalize + `/knk regions repair` | `P/regions/access/DomainAccessFlagSync.java:41-86` | `DomainAccessChanged {domainId, regionId, allowEntry, allowExit}` or just `syncNow()` | high |
| Region rename/finalize | API→plugin HTTP (synchronous) | on domain create/update | `P/http/RegionHttpServer.java:58-117`; `API/Services/DomainRegionNameFinalizer.cs:114-337` | hub invocation with result `RenameRegion(...) → bool` (optional; HTTP works) | medium |
| Region containment checks | API→plugin HTTP (synchronous query) | web form validation | `P/http/RegionHttpServer.java:162-193`; `API/Services/RegionService.cs:126-244` | hub client result `ContainsLocation/ContainsRegion → bool` (optional) | low |
| Headless world tasks | plugin pulls | 5 s → 60 s idle | `P/tasks/HeadlessWorldTaskPoller.java:27-86` | `WorldTaskCreated {id, type}` | medium |
| World task status in the web app | web pulls | 2 s | `WEB/components/Workflow/WorldBoundFieldRenderer.tsx:459-519` | browser `WorldTaskUpdated {id, status}` | medium |
| Catalog scan status in the web app | web pulls | 3 s | `WEB/components/admin/minecraftCatalog/MinecraftCatalogScanCard.tsx:16,115-131` | browser `CatalogScanUpdated` | low |
| Game settings + hub settings | plugin pulls | 30 s | `P/settings/GameSettingsManager.java:133-145` | `GameSettingsChanged` → `refreshNow()` | medium |
| Siege config/lobbies/scenarios, title brackets | load at start, lobby cooldown, admin reload | between matches / never (#31) | `P/siege/SiegeService.java:252-254,390,1541-1553` | `SiegeConfigChanged` (apply between matches) | medium |
| Lootbox runtime config + active boxes | plugin pulls + `LootboxWorldChanged` | 60 s | `P/lootbox/LootboxRuntime.java:59-63` | `LootboxConfigChanged`, keep world-changed | medium |
| Teleport destinations / group policy | plugin TTL | 60 s | `P/KnKPlugin.java:2506-2551` | `TeleportDestinationsChanged` | medium |
| Navigation destinations / compass settings / road meta / tiles | plugin TTL / pulls | 60 s / 60 s / 60 s / 10 min | `P/navigation/NavigationDestinations.java:49`, `CompassSettingsStore.java:21`, `P/roads/RoadNetworkCache.java:57-58` | `NavigationSettingsChanged`, `RoadNetworkChanged {world, tiles}` | low |
| Permission groups list, title brackets | plugin TTL | 2 min, 10 min | `P/KnKPlugin.java:737-742` | covered by `PermissionGroupChanged` / `TitleBracketsChanged` | low |
| Grade catalog | plugin pulls | 10 min | `P/KnKPlugin.java:3598-3615` | `EntityChanged {Grade}` | low |
| Telemetry config | plugin pulls | 60 s | `P/telemetry/TelemetryFlushTask.java:51,122` | `TelemetryConfigChanged` | low |
| Social spy audience | plugin re-check | 60 s | `P/user/SpyService.java:48-60` | follows `UserPermissionsChanged` | low |
| Offline-store identity verify / erasure | plugin pulls | hourly (accounts unconfirmed 6 h) | `P/KnKPlugin.java:2607-2629` | `AccountErased {userId, formerUuid}` + REST catch-up (#66) | high (GDPR) |
| Presence | plugin pushes (REST) | join/quit only, no reconcile | `P/listeners/PlayerListener.java:208-211,335-366`; `API/Controllers/UsersController.cs:725` | hub `PlayerJoined/PlayerLeft` + `OnlineRoster` snapshot on connect; server presence from connection state | high (web "is my player online") |
| Statistics batches (session heartbeats) | plugin pushes (REST) | 60 s + spool | `P/statistics/StatisticsFlushTask.java:69-72` | keep REST (spooled, idempotent); optional browser `StatisticsUpdated` after projection | medium |
| Gate state persistence | plugin pushes (REST) | 120 s + shutdown | `P/gates/GateStateSyncTask.java:97-110` | keep REST; optional browser gate status | low |
| Runtime worlds report | plugin pushes (REST) | on change / 10 min | `P/settings/GameSettingsManager.java:142-144,665` | replace with hub connect + `WorldsChanged` | low |
| Discoveries, PM log, telemetry, world analytics | plugin pushes (REST) | 1 s / 5 s / 10 s / 300 s | see section 3 | keep REST (batched/spooled) | low |
| Startup-only siege work (KNG-202) | plugin pulls once | startup | `P/siege/SiegeService.java:252-254`; `SiegeGateController.java:104-118` | run on hub (re)connect "resync" | medium |

---

## 9. Stale statements (docs and issues vs. code)

**#66 (KNG-57)**
- "WorldTask poller: currently believed to poll the web API or plugin": direction is **plugin pulls API** (`HeadlessWorldTaskPoller`,
  5→60 s) and **web app pulls API** (2 s). Player-driven tasks (Location, WgRegionId, ItemScan, KitScan) are claimed with a link
  code, not polled.
- "RegionHttpServer ... called when a Domain entity is created": also on updates (region step re-run, `replaceRegionId`),
  for sub-regions, from Town/District/Structure/GateStructure services, and **for synchronous containment queries during web
  form validation** (moving those needs SignalR client results).
- "permission changes are only seen when the plugin's 30 s cache expires": also a 90 s window for cache-only checks
  (`effective-set-stale-seconds`), and (per #76) the first check after expiry can answer from the offline store. Rank changes
  do arrive in ≤2 s, but only the display is refreshed.
- "user-changed (frozen, active mode)": today the plugin does not hear about either until the player rejoins.
- "the plugin reports server-side events (heartbeat/online ...)": no heartbeat endpoint exists; presence is join/quit only.
- Missing from the list: gate config (never refreshed), freeze/mode, balances, game/hub settings (30 s), teleport/navigation
  caches, telemetry config, road network, siege startup work, the in-memory nature of the notification queue.

**#76 (KNG-170)**: "whether the web app's group removal path queues RankChanged at all": it does on every membership path
(`UserPermissionGroupService.cs:158,212,237`). Group-permission and direct-grant edits queue nothing. Also note the queue is
in-memory (lost if the API restarts before the poll). The "RankChanged does not clear the permission cache" claim is confirmed.

**#121 (KNG-262)**: "Only `createPermissionsDataAccess` and `createSiegeDataAccess` use `entityConfig.ttl()`": item blueprints
now do too (`DataAccessFactory.java:155-166`, `KnKPlugin.java:636-639`, `config.yml:931-936`). Users/towns/districts/structures
go through `CacheManager` (global TTL), not only the factory.

**Docs**
- `docs/architecture/plugin-architecture.md` (`last_updated: 2026-09-21`): "Java 21 toolchain, Paper API 1.21.10" (now Java 25,
  Paper 26.3, `build.gradle.kts:14-19`, `gradle.properties`); "Caching itself is purely in-memory ... no disk persistence" and
  "found nothing beyond ... config.yml" (now `offline-security.json`, game-settings store, statistics/discovery/PM spools, road
  tiles); the "Sync/polling model" section lists only `HeadlessWorldTaskPoller`, `GateStateSyncTask` and `RegionHttpServer`
  (misses ~20 loops in section 8); `Health` "30s TTL, allow-stale: false" (still true, but the policy is now `API_ONLY`, `cfg:1001-1005`, KNG-115).
- `docs/architecture/web-api-architecture.md` section 6: plugin auth "statically-configured bearer token ... defaulting to
  type: none" (now `X-API-Key` / `Security:PluginApiKey`); "HealthController (api/Health) is what the plugin actually calls"
  (plugin probes `/health/ready`, `cfg:44-58`); rename "triggered from Town/District/Street" (Street is not a caller; Structure,
  Domain, GateStructure, DomainSubRegion are; `KnKPlugin.java:296-301` line ref is stale, now `:595-599`).
- `docs/architecture/web-app-architecture.md:266-268`: `Workflow/TaskStatusMonitor` no longer exists (`WEB/components/Workflow/`
  holds only `WorldBoundFieldRenderer.tsx`).
- `docs/guides/production-installation.md:78,167`: RegionHttpServer "none today (G6)", "listens on all interfaces, port 8081,
  without authentication (`RegionHttpServer.java:45`)": now loopback by default with `X-API-Key` (KNG-64 done). Its nginx block
  (`:949-957`) has no WebSocket upgrade headers.
- `docs/ai-agents/handoffs/2026-10-24-dashboard-crud-hub-proposal.md:16` links `2026-10-25-ux-dashboard-signalr-plan.md`,
  which was written later in the same session (now present).
- `docs/architecture/plugin-permission-checks.md:36` ("A change made in the web app applies within the TTL") is accurate but
  omits the 90 s stale window and the offline-store-first behaviour described in #76.
