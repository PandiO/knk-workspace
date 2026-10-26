# Realtime channel (SignalR) between knk-web-api, knk-plugin and knk-web-app

**Status:** Accepted design (developer decisions 2026-10-26, §12). **S1 (§4–§5) and S2 (§6.1) implemented on `claude/realtime-signalr`** (knk-web-api, knk-plugin; 2026-10-26, #178, #179), not merged, `realtime.enabled: false` until the live check; WT1, WT2 and S3–S5 not started.
**Last updated:** 2026-10-26 (S2 built: implementation notes in §6.7; S1 built: §4.6; decisions recorded; §8.3 delivery and busy flow, §8.7 tasks anchored to the draft, §4.3 publishing path)
**Issue:** [PandiO/knk-workspace#66](https://github.com/PandiO/knk-workspace/issues/66) (KNG-57, priority high); phase issues in
[IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md). Related: #76 (KNG-170, rank changes don't reach the server),
#121 (KNG-262, cache TTLs), #31 (KNG-202, startup-only siege work), #35 (KNG-176), #34 (KNG-246), #145 (KNG-249), #75.
**Code basis:** knk-web-api `master` @ `6f08383`, knk-plugin `main` @ `ee35fb1`, knk-web-app `main` @ `0d61270` (2026-10-25).
**Evidence:** [2026-10-25-realtime-sync-inventory.md](../../reports/2026-10-25-realtime-sync-inventory.md) (every poll, TTL,
inbound channel and publish point, with file:line) and [2026-10-25-world-tasks-as-is.md](../../reports/2026-10-25-world-tasks-as-is.md).

## 0. In one paragraph

Today the API cannot tell the game server anything except through `RegionHttpServer` (region rename and containment
queries). Everything else the server learns about a web-app change comes from a 2 s notification poll, about twelve
periodic re-syncs, cache TTLs (mostly 60 s) or the player rejoining; some changes (gates, freeze, active mode, group and
grant edits for online players) have no path at all until a restart or a manual reload. World tasks are claimed by
typing a code from the web app into the game, and the web app polls the task every 2 s. This design adds **one
SignalR hub for game servers and one for the web app, both inside the API process**. Messages are small **"this changed"
notifications**; REST stays the source of truth and the only write path, and every (re)connect triggers a full resync
through the refresh paths that already exist. The first users are the admin changes the developer cares most about
(ranks, permissions, balances, statistics, freeze, active mode, entity CRUD from the web app) and **world tasks**: the
API offers a task straight to the initiator's Minecraft player when they are online and the plugin claims it there;
the task code stays as the fallback and for handing a task to another admin.

## 1. Developer requirements (2026-10-25)

| # | Requirement (developer's words, condensed) |
|---|---|
| R1 | Changes to player ranks, permissions, statistics, balances etc. sync fast; initially admin changes matter most. |
| R2 | Changes to other entities through the web app form wizard or dashboard sync fast too. |
| R3 | World tasks use SignalR instead of polling. |
| R4 | When the initiator on the web app is online in Minecraft, the system sends them the world task right away and claims it — no code to copy. |
| R5 | Keep the claim-code flow as a fallback: it is tried and tested; and admin A doing CRUD may need admin B in game to perform the task. |

From #66 (2026-10-06, still valid): full resync on reconnect; periodic resync stays as safety net; two-way (the plugin
reports server events); erasure push with REST catch-up (GDPR, KNG-34 D14–D16, KNG-58).

## 2. Current state in brief (details in the inventory)

- **API → plugin:** only `RegionHttpServer` (`127.0.0.1:8081`, `X-API-Key`): rename after domain create/update, and
  synchronous containment checks during web form validation.
- **Plugin pulls:** `PlayerNotificationPoller` 2 s against `InMemoryPlayerNotificationQueue` (singleton, 24 h TTL, 1000
  cap, **lost on API restart**; 9 types: `TitleChanged`, `RankChanged`, `PaymentReceived`, `CurrencyAlert`,
  `LootboxWorldChanged`, `LootboxTokensIssued`, `DiscoveryReset`, `LocationOrphanDigest`, `AccountLinked`); domain
  access 5 min; game + hub settings 30 s; lootbox runtime 60 s; headless world tasks 5→60 s; grades 10 min; telemetry
  config 60 s; roads 60 s / 10 min; plus TTLs (global 60 s, permissions 30 s with a 90 s stale window, item blueprints
  20 min, title brackets 10 min, permission groups 2 min).
- **No path at all** for: gate structure/door edits, freeze and active mode set on the web, permission group node edits
  and direct grants (until TTL), balance-only changes (60 s user cache), siege config outside a lobby cooldown.
- **`RankChanged` only redraws** tab list and chat; it does not drop the permission cache or the offline-store answers
  (#76 confirmed in code: `P/user/UserAdminService.java:612-616`).
- **Presence:** `User.IsOnline`/`LastSeenAt` set by `PUT /api/users/{id}/presence` on join/quit only; no reconcile after
  a crash or reload; skipped when the user isn't cached at join. Not reliable enough to auto-claim on.
- **No SignalR/WebSocket/SSE anywhere.** API is net8.0 (SignalR server in the shared framework, no package needed). The
  Java client `com.microsoft.signalr:signalr` 10.0.x uses okhttp 4.12.0 — the version the plugin already ships.
- **World tasks:** web polls 2 s; plugin polls headless tasks only; player tasks only via `/knk task-claim <code|id>`.
  Codes are not unique, never expire, never clear and are **not checked** on claim; a second claim of an InProgress
  task returns 200 to anyone; no cancel/expiry/heartbeat, so tasks stay InProgress forever after an in-game cancel,
  quit or restart; the creator is taken from the request body; the server id is hard-coded `"localhost"`.

## 3. Principles

- **P1 — REST is the truth, the hub is a doorbell.** A hub message says *what* changed (type, ids, maybe the few
  fields a display needs). Receivers re-read through REST/their existing data access when they need more. No business
  write happens over the hub except what is explicitly listed (world-task offer results, presence).
- **P2 — At-most-once, so resync on every (re)connect.** Each side runs its existing refresh paths after (re)connect.
  Every message carries a per-connection sequence number; a gap triggers the same resync. The periodic re-syncs stay,
  with longer intervals while the hub is connected.
- **P3 — Reuse the existing refresh paths.** Plugin handlers call what `/knk cache refresh`, `/gate reload`,
  `DomainAccessFlagSync.syncNow()`, `GameSettingsManager.refreshNow()` and friends already do; no second code path.
- **P4 — Publish after commit, from the service layer.** Publishing happens after `SaveChangesAsync` succeeded, so a
  receiver that re-reads sees the new state.
- **P5 — Degrade, never block.** Hub down = today's behaviour (polls, TTLs, task codes). No player action or web
  request waits on the hub.
- **P6 — Main thread on the plugin.** Hub callbacks arrive on OkHttp/RxJava threads; every Bukkit-touching handler hops
  to the main thread (or an existing async executor for pure cache work).

## 4. Architecture

```
 web app (React)                knk-web-api (ASP.NET Core)                    knk-plugin (Paper)
 ───────────────                ─────────────────────────                    ──────────────────
 @microsoft/signalr  ──WS──►  /api/hubs/web   (JWT)          ◄──WS──  com.microsoft.signalr
   groups: user:{id},           /api/hubs/game  (X-API-Key)             one connection per server,
   task:{id}                    IRealtimePublisher                      header X-Knk-Server-Id
                                PresenceRegistry (in memory)            RealtimeClient (reconnect,
                                services publish after commit           resync, dispatch to handlers)
```

### 4.1 Hubs

| Hub | Path | Auth | Who connects | Groups |
|---|---|---|---|---|
| `GameServerHub` | `/api/hubs/game` | `X-API-Key` = `Security:PluginApiKey` (same check as `[RequirePluginService]`), plus `X-Knk-Server-Id` | each game server (one today) | `server:{serverId}`, `servers` |
| `WebHub` | `/api/hubs/web` | JWT bearer; `access_token` query string read in `JwtBearerEvents.OnMessageReceived` for this path only (not configured today) | logged-in web users | `user:{userId}`, `task:{taskId}`, later `staff` / `entity:{type}` |

- Both live in the API process (no backplane: one API instance, one game server; #66 open question answered "same
  process"). If a second API instance ever appears, add the Redis backplane then.
- Paths under `/api/` so the alpha nginx `location /api/` that already forwards `Upgrade`/`Connection`
  (`scripts/alpha-web/nginx.conf:16-26`) covers the browser hub. `production-installation.md`'s nginx block needs the two
  headers. The plugin connects straight to `http://api:5000/api/hubs/game` on the Docker network (no nginx, no
  Cloudflare Access).
- Keep-alive 15 s / client timeout 30 s (SignalR defaults); nginx `proxy_read_timeout` above 30 s.

### 4.2 Message envelope and versioning

Every server→client message is one hub method per event type with a single argument:

```json
{ "v": 1, "seq": 1042, "type": "UserPermissionsChanged", "at": "2026-10-25T21:03:11Z",
  "actor": { "userId": 7, "source": "web" },
  "payload": { "userId": 42, "uuid": "…", "reason": "GroupAssigned" } }
```

- `v` is the contract version of that type; a receiver ignores a type or a `v` it doesn't know and logs once
  (forward compatible). Breaking changes add a new type name.
- `seq` is per connection, monotonically increasing, assigned when sent. A receiver that sees a jump runs the resync
  (P2). Not persisted (not needed for P2); erasure has its own persisted catch-up (§7.4).
- Contract types live in `knk-web-api/Realtime/Contracts/` (C#) and `knk-api-client/.../realtime/` (Java); one
  catalogue table in this document (§6) is the human-readable source.

### 4.3 Publishing on the API

- New `IRealtimePublisher` (singleton) with typed methods (`UserPermissionsChanged(userId, reason)`,
  `EntityChanged(type, id, op)`, …) that wrap `IHubContext<GameServerHub>` / `IHubContext<WebHub>`. Fire-and-forget on a
  bounded channel (`System.Threading.Channels`, drop-oldest + log when full) so a slow socket never slows a request.
- **Explicit calls** from the service methods listed in the inventory §4.1 for user-state changes (they already have the
  right hooks: the 13 `IPlayerNotificationQueue` enqueue sites and `AuditLogService.RecordAsync` callers).
- **Generic `EntityChanged`** for entity CRUD through one EF Core `SaveChangesInterceptor` that, after a successful save,
  publishes `{type, id, op}` for an allow-list of entity types the plugin caches (§6.3). This covers every write path
  (form wizard, dashboard, import, seeders off) without touching ~30 services. **Decided (Q3, 2026-10-26): option A
  now** — the interceptor collects changes and sends them only after the save *and its transaction* committed (16
  services/repositories use explicit transactions); explicit calls for user-state events and for bulk paths the
  interceptor can't see (`CurrencyRepository` `ExecuteUpdateAsync` for balances, `UserRepository` raw SQL for presence,
  `MinecraftCatalogMaintenanceService` bulk updates). **Longer term option C** (the developer wants gameplay in the
  web app, which needs many detailed events and a robust feed): the same interceptor writes outbox rows inside the
  transaction and a dispatcher sends them (like `EmailDispatcher`), giving durable, ordered, replayable events. Build A
  so the switch is local: the interceptor produces typed event records and hands them to one `IRealtimeEventSink`;
  A's sink sends after commit, C's sink writes the outbox.
- `IPlayerNotificationQueue` gets a hub-backed implementation: online server → send at once over the hub; no server
  connected or player offline → keep it queued as today, and `PlayerNotificationPoller` keeps draining that queue
  only while the hub is down (and on reconnect). Same 9 types, same plugin handlers.

### 4.4 Plugin client

- New `knk-api-client` package `realtime/`: `RealtimeClient` built on `HubConnectionBuilder` with `withHeader("X-API-Key")`,
  `withHeader("X-Knk-Server-Id")`; Shadow relocates `io.reactivex.rxjava3` and `com.google.gson` (okhttp/okio are already
  relocated). The Java client has no automatic reconnect: `onClosed` → backoff 1 s, 2 s, 5 s, 10 s, 30 s (cap) with
  jitter; stop while `ApiConnectivityMonitor` says DOWN and reconnect on UP.
- `RealtimeDispatcher` in knk-paper maps type → handler; handlers are thin and call existing refresh paths (P3).
- **On every (re)connect:** (1) send the online roster (§5); (2) run `ResyncAll`: invalidate permission/user caches for
  online players, `DomainAccessFlagSync.syncNow()`, `GameSettingsManager.refreshNow()`, `LootboxRuntime.refresh()`,
  `CacheManager` refresh hooks, open world tasks resolution (§8.6), drain pending notifications once over REST; (3) run
  the startup-only work that never retries today (#31 KNG-202: lobbies, title ranks, crash-locked gates) if it has not
  succeeded yet. This also gives #31 and #144-style "API was down at start" bugs a natural retry point.
- Config (`config.yml`): `realtime.enabled` (default **false** until the phase is live-tested), `realtime.server-id`
  (replaces the hard-coded `"localhost"` used for world-task claims), `realtime.hub-path`, backoff values, and
  `realtime.fallback-poll-multiplier` (how much the periodic re-syncs slow down while connected).
- Metrics: connection state, reconnects, messages by type, resyncs, gaps (fits the KNG-232 `metrics:` section).

### 4.5 Web app client

- `@microsoft/signalr` npm package, one `RealtimeProvider` context at `App` level, connected only for logged-in users;
  `accessTokenFactory` returns the current access token (refresh on 401 through the existing token service).
- Built-in `withAutomaticReconnect`; after reconnect, components re-fetch what they show (P2).
- First consumer: world tasks (§8). Later consumers: the dashboard refreshes a type's table when an `EntityChanged` for
  that type arrives from another admin (nice-to-have, §9), the player profile shows live online state.

### 4.6 S1 as built (2026-10-26, #178)

- **API** (`knk-web-api/Realtime/`): `RealtimeSetup` (DI, hub mapping, `access_token` reader for `/api/hubs/web`),
  `Hubs/GameServerHub` (policy `KnkRealtimeGameServer` = the plugin key check of `[RequirePluginService]`; header
  `X-Knk-Server-Id`, 1–64 of `[A-Za-z0-9._-]`, else the connection is closed), `Hubs/WebHub` (default JWT policy,
  closes when the token expires), `RealtimePublisher` (bounded channel, drop-oldest) + `RealtimeDispatchService`
  (one reader; expands a group to its connections and numbers `seq` per connection, so SignalR's own groups are not
  used), `Presence/` (`PresenceRegistry`, `PresenceStore` on `User.IsOnline`/`LastSeenAt`, `PresenceSweepService`),
  meter `Knk.Realtime`. Settings section `Realtime` (`ChannelCapacity` 1000, `PresenceGraceSeconds` 60,
  `PresenceSweepSeconds` 10, `KeepAliveSeconds` 15, `ClientTimeoutSeconds` 30, `AllowedServerIds` empty = any).
- **Event in S1:** only `Welcome {serverId, presenceGraceSeconds}`, the first message (seq 1) on each game-server
  connection. Business events start with S2.
- **Plugin:** `knk-core/.../core/realtime/` (backoff, sequence tracker, resync hooks, stats), `knk-api-client/.../api/realtime/`
  (`RealtimeClient`, `SignalRHubTransport` on `com.microsoft.signalr` 10.0.13, `RealtimeEnvelope`),
  `knk-paper/.../paper/realtime/` (`RealtimeService`, `RealtimeDispatcher`, `RealtimeSettings`). Resync hooks in S1:
  the `/knk cache refresh` hooks, `DomainAccessFlagSync.syncNow()`, `LootboxRuntime.refresh()`. The startup-only
  siege work (#31) joins in S3 (#182, charter link 10); the notification drain and the slower re-syncs in S2.
- `/knk health` shows the channel; the KNG-232 `/metrics` endpoint exports `knk_realtime_*`.

## 5. Presence (needed for R4)

- `PresenceRegistry` (API singleton): `serverId → {connectionId, connectedAt, players: uuid → {userId, name, world,
  joinedAt}}`.
- The plugin sends `ReportRoster(players[])` on every (re)connect and `PlayerJoined` / `PlayerLeft(uuid, world)` as hub
  invocations (client → server). The registry updates `User.IsOnline`/`LastSeenAt` (the existing columns, so moderation
  filters and DTOs keep working) — the REST `PUT /presence` stays for the hub-down case.
- When a server connection drops and does not come back within a grace period (e.g. 60 s), its players are marked
  offline. On API start the registry is empty; the first roster fixes the columns (a reconcile, which today never
  happens).
- "Is the initiator online?" = registry lookup of `User.Uuid` → `serverId` (authoritative while the hub is up). The
  plugin still double-checks `Bukkit.getPlayer(uuid)` before claiming (§8).

## 6. Event catalogue (first versions)

### 6.1 API → game server, user state (R1)

| Type | Payload | Published from | Plugin handler |
|---|---|---|---|
| `UserPermissionsChanged` | userId, uuid, reason | `UserPermissionGroupService` Upsert/Delete/AfterMembershipChange/SweepExpiredRanks; `PermissionGrantService` all writes | drop effective set **and** offline-store answers for that uuid, re-read user, redraw tab/chat, re-check active mode, refresh social spy (fixes #76) |
| `PermissionGroupChanged` | groupId, op | `PermissionGroupService` Create/Update/Delete | invalidate group list; for each online member → as above |
| `UserBalancesChanged` | userId, uuid, coins, gems, xp | `UserService.AdjustBalancesAsync`, `CurrencyService` Grant/Spend/AdminAdjust/Reverse, `CurrencyAdminService.ReverseAsync` | update cached user, redraw scoreboard (no re-read needed: values in payload) |
| `UserTitleChanged` | (existing `TitleChanged` notification) | as today | as today |
| `UserFrozenChanged` | userId, uuid, frozen, reason, by | `UserService.SetFrozenAsync` | apply/lift freeze now (`AdminFreezeManager`) |
| `UserModeChanged` | userId, uuid, mode | `UserService.UpdateActiveModeAsync` | apply mode now (`ModeListener` logic) |
| `UserChanged` | userId, uuid, fields[] | multipliers, gate pass-through method, link/merge | invalidate user cache entry |
| `StatisticsVisibilityChanged` | userId | `StatisticsVisibilityService.UpdateAsync` | refresh open menus for that player |
| existing notification types | as today | `IPlayerNotificationQueue` (hub-backed) | as today |

### 6.2 API → game server, config the server follows (R2)

| Type | Published from | Plugin handler |
|---|---|---|
| `GateChanged {gateStructureId, op}` | `GateStructureService`, `GateDoorService` writes | reload that gate (`GateCommandSupport` reload path), skip during a running siege match → apply after the match |
| `DomainAccessChanged {domainId}` | Domain/Town/District/Structure/SubRegion writes that touch AllowEntry/AllowExit | `DomainAccessFlagSync.syncNow()` (or a single-domain variant) |
| `GameSettingsChanged` | `GameSettingsService.UpdateAsync`, `HubSettingsService` | `GameSettingsManager.refreshNow()` |
| `SiegeConfigChanged {scope}` | `SiegeConfigurationService`, `SiegeLobbyService`, `SiegeScenarioService` | refresh config; lobbies/scenarios apply between matches (as `RefreshConfigEffect` does) |
| `LootboxConfigChanged` | lootbox configuration/type/spawn-area services | `LootboxRuntime.refresh()` (keep `LootboxWorldChanged`) |
| `TeleportDestinationsChanged`, `NavigationSettingsChanged`, `RoadNetworkChanged {world}` | their services | existing cache refresh hooks |
| `TelemetryConfigChanged` | owner telemetry settings | `TelemetryFlushTask.pollConfig()` |

### 6.3 API → game server, generic entity CRUD (R2)

`EntityChanged {type, id, op}` for the allow-list: User, Town, District, Structure, DomainSubRegion, ItemBlueprint,
EnchantmentDefinition, Kit, MenuTemplate, MinecraftMaterialRef, Grade, Tag, TitleBracket, PermissionGroup (also
§6.1). Handler: invalidate that key in the matching cache (`CacheManager`, the data-access caches in
`DataAccessFactory`), refresh open menus that show it. With this in place, the per-entity TTLs (#121) matter only for the
hub-down case.

### 6.4 Game server → API (client → server invocations)

| Method | Purpose |
|---|---|
| `ReportRoster(players[])`, `PlayerJoined`, `PlayerLeft` | presence (§5) |
| `ReportWorlds(worlds[])` | replaces the 10-minute runtime-worlds REST report while connected (keep REST as fallback) |
| `WorldTaskOfferResult {taskId, result}` | §8 |
| `Heartbeat` | not needed: SignalR keep-alive + connection state are the server liveness |

Batched data (statistics, discoveries, PM logs, telemetry, analytics, gate state) **stays on REST**: it is spooled,
idempotent and already resilient.

### 6.5 API → web app

| Type | Group | Consumer |
|---|---|---|
| `WorldTaskUpdated {taskId, status, offer, claimedBy, output?, error?}` | `task:{id}`, `user:{creatorId}` | `WorldBoundFieldRenderer` (§8.5) |
| `CatalogScanUpdated {scanId, status, progress}` | `user:{starterId}` | `MinecraftCatalogScanCard` (replaces the 3 s poll) |
| `PresenceChanged {userId, online, serverId}` | `staff` | player profile / moderation list (later) |
| `EntityChanged {type, id, op, actorUserId}` | `staff` | dashboard live refresh (later, §9) |

### 6.6 Region rename and containment (later, optional)

`RegionHttpServer` stays for now: it works, it is authenticated and loopback-bound, and the containment
checks are synchronous queries a web user waits on. Moving them onto the hub needs SignalR client results
(`ISingleClientProxy.InvokeAsync<T>` / Java `onWithResult`); worth it only when the plugin no longer needs to expose a
port (e.g. API and game server on different hosts). #66's open question "Whether RegionHttpServer's inbound HTTP moves
onto the hub" → **later, phase S6**.

### 6.7 S2 as built (2026-10-26, #179)

- **API.** `Realtime/RealtimeEventSink.cs`: `IRealtimeEventSink` (scoped) is the one place services hand events to
  (option A of §4.3). `AfterCommitRealtimeEventSink` sends at once, or, while a transaction is open on the scope's
  `KnKDbContext`, holds the event until it commits: `RealtimeTransactionEvents` is an EF Core transaction interceptor
  (added next to the KNG-232 command interceptor in `Program.cs`) that sends a context's held events on commit and
  drops them on rollback, failure or a new transaction. The actor's source is taken from the request (plugin key =
  `plugin`, logged-in user = `web`, none = `system`). S3's entity interceptor and option C's outbox plug in behind the
  same interface. `Realtime/UserStateEvents.cs` builds the payloads; users without a Minecraft UUID get no event.
- **Publish points.** `UserPermissionGroupService` (upsert, delete, rank-expiry sweep; next to the `RankChanged`
  notification, which stays), `PermissionGrantService` (every write; a user holder → `UserPermissionsChanged`, a
  group holder → `PermissionGroupChanged {op: GrantsChanged}`, a grant moved between holders tells both),
  `PermissionGroupService` (create, update, delete), `CurrencyService.ExecuteAsync` (every posting that wasn't a
  replay → `UserBalancesChanged` per user with the balances after it; this covers Grant, Spend, AdminAdjust, Reverse,
  transfers and `UserService.AdjustBalancesAsync`, whose outer transaction holds the events until it commits),
  `UserService.SetFrozenAsync`, `UpdateActiveModeAsync` (only on a change), `SetPersonalMultipliersAsync`,
  `UpdateGatePassThroughMethodAsync`, the link and merge paths (`UserChanged` with `fields`).
  `StatisticsVisibilityChanged` (§6.1) was not built: the plugin's menus re-read it already.
- **Hub-backed notification queue.** `Realtime/HubPlayerNotificationQueue.cs` replaces the `IPlayerNotificationQueue`
  registration and decorates `InMemoryPlayerNotificationQueue`, which stays the store behind `GET pending` /
  `POST acknowledge`. A new notification is pushed at once (`PlayerNotification`, payload = the REST DTO) to the
  player's server when the presence registry has them online, to every server when it is server-wide (user 0);
  otherwise it waits as before. `PlayerJoined` over the hub pushes what waited for that player plus the server-wide
  ones. The plugin acknowledges over REST as before, so a lost push is still pending for the next drain.
- **Plugin.** `knk-api-client/.../realtime/UserStateEvents` (types and payload records), `knk-paper/.../realtime/
  UserStateSync` (handlers) with `BukkitUserStateDisplay` (tab list, visibility, "/" list, social spy, mode checks).
  `UserPermissionsChanged` drops the effective set and the offline-store answers (`OfflineSecurityStore.
  forgetPermissionAnswers`, #76), then for an online player reloads the set, re-reads the user and redraws, and drops
  a mode whose node is gone. `PermissionGroupChanged` fans out to online players whose cached effective groups
  (parents included) contain the group. `UserBalancesChanged` writes the values into the user cache and re-reads only
  when XP changed (title and prestige are computed by the API). Freeze and mode apply at once and are idempotent, so
  the echo of an in-game `/freeze` or mode toggle changes nothing.
- **Resync** (after the S1 steps): re-read every online player (redraw, freeze, mode, permission-dependent state;
  their offline answers dropped), then one drain of the notification queue. `PlayerNotificationPoller` makes no HTTP
  call while the hub is connected.
- **Slower re-syncs (Q4).** `realtime.fallback-poll-multiplier` (default 4) and `core/realtime/FallbackPolling`. In S2
  it applies to the re-sync whose changes S2 pushes: the social-spy re-check (60 s → 4 min). The other timers (domain
  access, game settings, lootbox runtime, grades, roads, telemetry config) keep their interval until their events
  land in S3 (#182); slowing them now would delay those changes with nothing pushed in their place.

## 7. Reliability

### 7.1 Ordering, gaps, duplicates

Per-connection `seq` (§4.2); handlers are idempotent (they invalidate and re-read), so duplicates are harmless and
order matters only within one entity, where "re-read latest" is correct regardless of order.

### 7.2 Hub down

Everything falls back to today's polls/TTLs/codes (P5). While connected, the plugin multiplies the periodic re-sync
intervals by `realtime.fallback-poll-multiplier` (default 4: domain access 20 min, game settings 2 min, …) instead of
stopping them.

### 7.3 Security

- Game hub: API key (constant-time compare as today), server id from a header but only accepted if it matches a
  configured allow-list once several servers exist; until then any id is accepted and logged.
- Web hub: JWT validated like REST (`TokenVersion` check); group joins are server-side only (a client can't join
  `user:{other}` or `task:{id}` it doesn't own: `task:{id}` join checks `CreatedByUserId` or `knk.admin.world`).
- Cloudflare Access already gates the `app.` host; WebSocket upgrade carries its cookie (same origin).
- Payloads never carry secrets; uuids and user ids only, to authenticated servers/staff.
- Rate limit: client→server invocations from the web hub are limited to group join/leave (no writes).

### 7.4 Erasure (GDPR, from #66)

`AccountErased {userId, formerUuid, erasureId}` pushed after `PrivacyDeletionService.ExecuteAsync`; the plugin kicks
the player with a neutral message if online and deletes local data (offline store, caches, spools, vault) as #66
lists. Because SignalR is at-most-once, erasures are also persisted (a small `privacy_erasure_events` table with a
sequence, or reuse the deletion request rows) and the plugin calls `GET /api/privacy/erasures?since={lastId}` on every
(re)connect and stores `lastId` on disk. The hourly verifier and KNG-58's max age stay as backstop. Separate phase (S5).

## 8. World tasks over SignalR (R3–R5)

### 8.1 Goals

- Initiator online in game → the task appears in game at once, already claimed; the web app sees "Claimed by you in
  game" within a second, and the result fills the form within a second of completion. No code to copy.
- Initiator not online, or wants someone else → task code as today, plus "send to an online admin" (admin B gets a
  clickable Accept/Decline in chat).
- No more stuck tasks: every task ends Completed, Failed, Cancelled or Expired.

### 8.2 REST hardening first (useful even without the hub)

Schema (`world_tasks`):
- `CreatedByUserId` (FK User, from the JWT on create; never from the body). `WorkflowSession.UserId` also from the JWT
  (same bug class as the drafts' `userId = '1'`).
- `TargetUserId` (null = code only), `OfferState` (`None`/`Offered`/`Accepted`/`Declined`/`TimedOut`), `OfferedAt`.
- `ClaimedByUserId`, `ClaimedByUuid` (next to the existing username), `ClaimedByServerId` from config.
- `ExpiresAt` (Pending TTL, default 30 min, configurable), `LeaseUntil` (InProgress lease, renewed by heartbeat,
  default 3 min), `RowVersion`.
- Task code: rename to **"task code"** in UI and docs (the invitations work owns "claim code" now, #57); keep the
  `LinkCode` column; generate with `RandomNumberGenerator`, unique among open tasks (filtered unique index or retry),
  cleared (or ignored) once the task is closed.

State machine (enforced in `WorldTaskService`, conditional updates on `Status` + `RowVersion`):

```
Pending ──claim──► InProgress ──complete──► Completed
   │                  │  ├──fail──────────► Failed
   │                  │  ├──release───────► Pending   (in-game cancel / quit / restart; offer to someone else)
   │                  │  └──lease expired─► Pending   (or Failed after N releases)
   ├──cancel──────────┴─────────────────► Cancelled  (web: Capture again / Try again / leave form)
   └──ExpiresAt passed──────────────────► Expired
```

- `claim` succeeds only from `Pending` (or is idempotent for the **same** `ClaimedByUuid`); otherwise 409.
  The claim body carries the task code when claimed by code, and the API checks it. Claiming by numeric id needs the
  separate node `knk.tasks.any` (owner/rescue only; Q11 decided 2026-10-26). In-game command: `/knk task <code>`,
  `/knk task-claim` kept as alias.
- `complete`/`fail` only from `InProgress` and only by the claiming server; otherwise 409. Gate-scan apply failures
  answer 409/422 instead of 500.
- New endpoints: `POST {id}/cancel` (web creator or `knk.admin.world`), `POST {id}/release` (plugin),
  `POST {id}/heartbeat` (plugin; also over the hub later), `GET open?serverId=` (plugin resync),
  `GET session/{id}/open` (web reattach after reload).
- `WorldTaskSweepService` (BackgroundService, 30 s): expire Pending past `ExpiresAt`, release InProgress past
  `LeaseUntil`, delete orphan `tempregion_worldtask_*` regions of expired/cancelled tasks via the plugin (ties into
  `TempRegionRetentionTask` and #34).
- Form builder: offer only task types that have a handler; default to `LocationSelection` instead of `VerifyLocation`;
  the plugin fails a claimed task whose type has no handler instead of leaving it InProgress.

Plugin hygiene in the same phase: handler state keyed by UUID in concurrent maps; chat-driven actions hop to the main
thread; in-game `cancel` → `release` (or `cancel` if the player says so), quit → release, plugin disable → release
all; heartbeat every 60 s for held tasks; `server-id` from config; headless poller claims before it runs a task.

Web hygiene: "Capture again"/"Try again"/leaving the form → `cancel` the old task; reattach through the draft (§8.7); stop polling when the task is closed;
show Expired/Cancelled with a "Start again" button; recover from a stuck InProgress with "Cancel task".

### 8.3 The offer (R4, R5)

Decided 2026-10-26 (Q6–Q8): the normal **"Send to Minecraft"** button means *auto*; a separate **"Hand off to…"**
action sends it to another player; the code stays as fallback. On `POST /WorldTasks` the web app sends
`deliver: "auto" | "code" | {"userId": n}`.

**Before sending (busy check, developer decision):** the web app calls `GET /api/WorldTasks/active-for-me` (the
caller's open task in game, if any, with its form/field label). If the player already holds a task, the web app does
not send blindly but asks: **Queue** (offered automatically when the current task ends), **Hand off** (pick an online
player, as 2. below), **Replace** (the current task is **released** back to Pending with its task code, so the other
form can still get it done — the dialog names that form — and the new one is offered), or **Cancel** (nothing sent). The plugin still re-checks on arrival (race: a task claimed
in between) and reports `busy`, which the web app shows with the same choices.

1. **auto** — the API looks up the creator's `User.Uuid` in the `PresenceRegistry`.
   - Online → `TargetUserId = creator`, `OfferState = Offered`, push `WorldTaskOffered {taskId, uuid, taskType,
     fieldName, label, entityType, mode: "auto-claim"}` to that server.
   - The plugin checks `Bukkit.getPlayer(uuid)` online, holds `knk.tasks`, no open task (KNG-174 rule). If yes:
     `POST {id}/claim` (by uuid, offer path, no code needed), start the handler, chat: "Task from the web app: {label}
     — {instructions}. Type `cancel` to hand it back." Reports `WorldTaskOfferResult {accepted}`.
   - Busy → handled before sending (busy check above); a late race reports `busy`. Offline after all, or no
     permission → `declined`, and the web app shows the code.
   - Not online (registry) → no offer; behaves as **code**.
2. **{userId}** (admin B, "Hand off to…") — the web app offers a picker listing online users who hold
   `knk.admin.world` / `knk.tasks` (new `GET /api/presence/online-staff?node=knk.tasks`). The plugin shows admin B a
   clickable `[Accept] [Decline]` chat line (not an auto-claim, since admin B didn't start it). Accept → claim.
   Decline/timeout (default 2 min) → `OfferState = Declined/TimedOut`, the web app expands the code.
3. **code** — today's flow, hardened (§8.2).

The code is **always generated** and available in the web UI: collapsed under "Sent to {player} in game… or use task
code ABC123" while an offer is pending, expanded when there is no offer or it was declined/timed out. So the
tried-and-tested path is always one click away (R5).

Optional later: **broadcast** an offer to every online staff member with `knk.tasks` as a clickable line, first claim
wins via the conditional claim **(not in the first version)**.

### 8.4 Plugin flow (hub up)

- `WorldTaskOffered` → handler as above (main thread).
- `WorldTaskCancelled {taskId}` (web cancelled, or the sweeper expired it) → stop the local handler, clean up its temp
  region/WorldEdit session, tell the player "The web app cancelled this task".
- Headless tasks: `WorldTaskCreated {taskId, type}` to the `servers` group → the plugin claims, then runs (stops double
  scans); `HeadlessWorldTaskPoller` stays as safety net at 60 s while connected.
- Queue: when a player's task ends (complete, fail, release, cancel), the API offers that player's next queued task
  (oldest first) with the same auto-claim.
- Resync on (re)connect: `GET open?serverId=` → tasks this server holds but has no local handler for (restart) →
  `release`; tasks offered to a player who is online here → re-offer; held and alive → heartbeat.

### 8.5 Web app flow

- `WorldBoundFieldRenderer` joins `task:{id}` and renders state from `WorldTaskUpdated` instead of the 2 s poll; after
  hub reconnect (or while disconnected, every 10 s) it re-fetches `GET {id}`.
- States shown: *Sending to {you} in game…* → *Claimed by {name} in game* (with "Cancel task") → *Completed* (fills the
  field as today via `extractTaskResult`) / *Failed {reason}* / *Expired* / *Cancelled* (each with "Start again").
- Buttons: **"Send to Minecraft"** (auto: offered to and claimed by you when you are online, `GET /api/presence/me`;
  otherwise it shows the task code), a secondary **"Hand off to…"** (online player picker, Accept/Decline in game), and
  the task code always visible as fallback. The busy check (§8.3) runs before either sends.

### 8.6 Fallback summary

| Situation | What happens |
|---|---|
| Hub down | No offers; code flow; web polls every 10 s; plugin heartbeats/releases over REST |
| Initiator offline | Code flow (or "send to an online admin") |
| Admin B in game | Targeted offer with Accept/Decline; code as fallback |
| Plugin restart mid-task | Resync releases the task to Pending; web shows "Released — sent again"/code |
| Player quits mid-task | Release; offer again on rejoin if `TargetUserId` is them |
| Web user leaves the form | Cancel |

### 8.7 Tasks anchored to the draft (developer decision 2026-10-26)

**Problem (verified on web app `0d61270`, API `6f08383`):** every time a form opens, including resuming a draft, the
web app creates a **new** `WorkflowSession` (`FormWizardPage.tsx:318`, `:449`); world tasks hang off that session; the
draft (`FormSubmissionProgress`) has no link to the session or its tasks; the task id lives only in the field's React
state (`WorldBoundFieldRenderer.tsx:411`). So reload, step change, closing a child form or resuming loses the task, a
task finished while the tab was closed never reaches the draft, and abandoned sessions pile up. A draft only exists
after Save Draft, Next or Submit.

**Design (option 2 of the 2026-10-26 analysis):**
- The first world task in a form saves the draft silently if none exists, so a task always has a draft.
- One workflow session per draft: `FormSubmissionProgress.WorkflowSessionId` (or the session gets
  `FormSubmissionProgressId`); resuming reuses it. Child forms (`ChildFormModal`) use their own child progress the same way.
- `WorldTask.FormSubmissionProgressId` next to `StepKey`/`FieldName`; plus `AppliedAt` (when the result was written into
  the draft).
- `GET /api/FormSubmissionProgress/{id}/world-tasks` returns the latest task per field. On mount the field panel
  reattaches: waiting / in game / **completed but not applied** → fills the field with `extractTaskResult`, saves the
  draft and calls `POST /WorldTasks/{id}/applied`.
- Replacing a field's task ("Capture again") cancels the previous one for that field.
- The #180 sweep also removes sessions with no draft and no activity (default 7 days) and their open tasks.
- Later, if needed: the API writes the result into the draft itself on completion (option 3), which needs the web
  app's field-mapping rules (location spread, region id, item/kit scan fan-out) on the server.

## 9. Web app: entity CRUD push (nice-to-have)

When admin A saves a Town in the dashboard, admin B's dashboard showing Towns refreshes its table (`EntityChanged`
to group `staff`, the dashboard bumps `refreshKey` for the matching type, debounced). Not needed for R1/R2 (they are
about the game server); small once the web hub exists. Phase S4 web part, low priority.

## 10. What changes for existing docs and issues

- #66 body: stale statements listed in the inventory §9 (world task direction, RegionHttpServer callers, freeze/mode
  not synced, no heartbeat endpoint); this design answers its three open questions (same process; `v`/new type names;
  RegionHttpServer later).
- #76: the push fixes the latency part; the display part ("rank shown wrong until rejoin") needs its own check in S2.
- `docs/specs/world-tasks/*`: several statements contradict the code (inventory table "Docs that contradict the code");
  update them when §8.2 lands, not before.
- Living docs to update when phases land: `architecture/plugin-architecture.md` (sync model, also stale Java/Paper
  versions), `architecture/web-api-architecture.md` §6 (plugin auth is `X-API-Key`, health probe `/health/ready`),
  `architecture/api-connectivity.md`, `architecture/web-app-architecture.md` (`TaskStatusMonitor` gone),
  `guides/production-installation.md` (RegionHttpServer now loopback + key; nginx upgrade headers),
  `guides/alpha-go-live.md` (hub path, config keys).

## 11. Out of scope

- Several API instances (backplane), several game servers beyond keeping a `serverId` everywhere.
- Moving batched REST reports (statistics, discoveries, PM logs, telemetry) onto the hub.
- Player-facing web notifications ("you were paid") — a feature of its own once the web hub exists.

## 12. Decisions (developer, 2026-10-26)

| # | Question | Decision |
|---|---|---|
| Q1 | Two hubs in the API process, no backplane | **Yes** |
| Q2 | Java client `com.microsoft.signalr` (shaded) | **Yes** |
| Q3 | Publishing entity CRUD | **Option A now** (interceptor + allow-list, sent after commit; explicit calls for user state and bulk paths), **option C (outbox) as the longer-term target** for gameplay in the web app; build A behind one event sink so the switch is local (§4.3) |
| Q4 | Periodic re-syncs while connected | **Keep, ×4 slower** |
| Q5 | Presence from the hub (roster, joined/left, 60 s grace) | **Yes** |
| Q6 | Auto-claim for the online initiator | **Yes, on the normal "Send to Minecraft" button**; a separate "Hand off to…" action for another player (§8.3, §8.5) |
| Q7 | Initiator already holds a task | **The web app checks before sending** and offers Queue / Hand off / Replace / Cancel (§8.3) |
| Q8 | Admin B | **Accept/Decline in chat, 2 min timeout** |
| Q9 | Broadcast offers in the first version | **No** (confirmed 2026-10-26) |
| Q10 | Pending expiry 30 min, lease 3 min, release on lease expiry | **Yes**; plus tasks anchored to the draft (§8.7) |
| Q11 | Naming and id claims | **Rename to "task code"**; id claims only with `knk.tasks.any` (owner/rescue) |
| Q12 | Gate edits during a running siege match | **Apply after the match** |
| Q13 | `RegionHttpServer` stays HTTP for now (S6 later) | **Yes** (confirmed 2026-10-26) |
| Q14 | Erasure catch-up in its own phase S5 | **Yes** (confirmed 2026-10-26) |
| Q15 | `realtime.enabled` default false until each phase is live-tested | **Yes** (confirmed 2026-10-26) |
| Q16 | The 2026-10-08 "SignalR recommendation comment" on KNG-57 (Linear) | **Closed:** superseded by this design (developer, 2026-10-26) |
| — | When S1 starts | **While #177 link 2 (A2) is built** |
| Q17 | Busy check "Replace": what happens to the held task | **Released** to Pending (its task code stays usable), not cancelled |
| Q18 | Sessions with no draft and no activity | **Removed after 7 days** with their open tasks |
| Q19 | First world task in a new form | **Saves the draft silently** (no modal) |
