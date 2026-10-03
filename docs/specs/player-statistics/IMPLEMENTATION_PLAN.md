# Player statistics — Implementation Plan

**Status:** Binding for chain links 6-7 (written by link 1, 2026-10-03). Links 2-5 done (knk-web-api `2dec32b`, knk-plugin `5481327`, knk-web-app `00d978e`); link 6 next. Nothing merged.
**Last updated:** 2026-10-03 (link 5 status note)
**Linear:** [KNG-34](https://linear.app/kngpandi/issue/KNG-34) (with [KNG-14](https://linear.app/kngpandi/issue/KNG-14), [KNG-23](https://linear.app/kngpandi/issue/KNG-23), [KNG-9](https://linear.app/kngpandi/issue/KNG-9), [KNG-21](https://linear.app/kngpandi/issue/KNG-21))
**Sources:** [DESIGN.md](DESIGN.md) (§F = "Finalized design (link 1)"), [source audit](../../reports/2026-10-03-player-statistics-source-audit.md),
chain charter [`PLAYER_STATISTICS_CHAIN.md`](../../ai-agents/handoffs/PLAYER_STATISTICS_CHAIN.md), progress report
[`2026-10-03-player-statistics-chain.md`](../../reports/2026-10-03-player-statistics-chain.md).

This plan fixes data shapes, routes, DTOs, class names, config keys, permission nodes and per-link acceptance criteria so
links 2-7 never re-decide them. A link may add private helpers, tests and fields that a later section obviously needs; a
change to a **public** name/shape listed here must be recorded in the progress report and in this file's status notes.

---

## 0. Conventions

- **Branch:** `claude/kind-dijkstra-y9d279` in every repo (charter §1). Trunks: knk-web-api `master`, knk-plugin `main`,
  knk-web-app `main`, knk-workspace `main`. Merge trunk at the start and before the final push of every link.
- **Builds:** API `dotnet build` + `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`; plugin
  `./gradlew build -x deployToDevServer`; app `npm ci`, `npm run test:ci`, `npm run build`. Record baselines before
  changing code.
- **API conventions** (audit §7): models in `Models/Statistics/` etc., tables via explicit `ToTable("snake_case")`,
  PascalCase columns, enums stored as `byte` (`HasConversion<byte>()`), timestamps `datetime(6)` UTC. DTO properties carry
  `[JsonPropertyName("camelCase")]`; enums serialise as strings. Errors `{ error, message }`. New routes use kebab-case
  literals (`api/statistics`, …). Options POCOs in `Configuration/` with `SectionName`. Migrations via
  `dotnet ef migrations add <Name>` (Designer + snapshot), **additive only**.
- **Plugin conventions:** pure logic in knk-core (`C/statistics`, `C/telemetry`, `C/analytics`), Bukkit glue in
  knk-paper (`P/statistics`, …), HTTP in knk-api-client (`A/impl/*ApiImpl extends BaseApiImpl`, `A/dto`, `A/mapper`,
  wired in `A/client/KnkApiClient`). `java.time.Clock` injected for anything time-based. Tests follow the World-mock rule
  (`knk-plugin/CLAUDE.md`). New config sections follow `DiscoveryConfig` (record + `defaults()` + `validate()`,
  `ConfigLoader.loadX`, both `KnkConfig` back-compat constructors updated).
- **App conventions:** singleton clients on `ObjectManager` (`src/apiClients/`), `Controllers` enum in
  `src/utils/enums.ts`, DTOs in `src/types/dtos/<feature>/`, Jest/RTL tests in `__tests__/`, no new npm dependencies
  (charts = Tailwind/SVG; heatmap = `<canvas>`).
- **Kill switches:** every hook below names its switch; `false` reproduces today's behaviour.

### 0.1 Link cut (after link 1's §0 re-cut)

| Link | Phase | Repos | Change vs. charter |
|---|---|---|---|
| 2 | API foundation — catalogue, data model, ingestion, periods, ledger projection (economy, XP gained, **title history**), **Siege match projection**, visibility settings + enforcement, read endpoints, owner-permission attribute | knk-web-api | Siege match projection moved here from link 4 (API-only); "XP into the ledger" is already complete on trunk (audit §6) → link 2 only adds a guard test |
| 3 | Plugin foundation — API client + sink/spool, sessions/logins, AFK (`/afk` + auto), distance, highest fall, visibility InventoryMenu (+ API menu seed) | knk-plugin, knk-web-api (seed) | — |
| 4 | Combat + gates + Siege reconciliation — kills/deaths/causes, damage, arrows, headshots, open-world killstreak, gate damage incl. fire attribution, Siege leaver fix | knk-plugin (+ API tests) | Projection itself is in link 2 |
| 5 | Read surfaces + leaderboards — leaderboard snapshots, public profile endpoint, in-game statistics/leaderboard menus and `/stats` lines, web own statistics + settings, public profile, leaderboards, staff panel | knk-web-api, knk-plugin, knk-web-app | — |
| 6 | Diagnostic telemetry + privacy — event store/ingestion, plugin emitter, owner timeline UI, retention, GDPR workflow | knk-web-api, knk-plugin, knk-web-app | — |
| 7 | World analytics + write-up — movement heatmaps, menu funnels, domain interactions (owner views); final checklist | all four | — |

---

## 1. Data model (knk-web-api)

All tables are new; no existing table is altered. `UserId` columns reference `users.Id` logically but carry **no FK**
(like the ledger), so statistics never block user maintenance and GDPR deletion is explicit.

### 1.1 Link 2 — migration `<ts>_AddPlayerStatistics`

**`player_stat_daily`** — model `PlayerStatDaily`

| Column | Type | Notes |
|---|---|---|
| UserId | int | PK part |
| Day | date | PK part; local day per §F.10 |
| MetricKey | varchar(48) | PK part; catalogue key |
| ContextKey | varchar(32) | PK part; `''` = non-contextual |
| Value | decimal(20,4) | sum or max per catalogue aggregation |
| UpdatedAt | datetime(6) | last change (tie-break "reached first") |

PK `(UserId, Day, MetricKey, ContextKey)`; index `IX_player_stat_daily_metric_day (MetricKey, ContextKey, Day)`.

**`player_stat_totals`** — model `PlayerStatTotal`: `UserId`, `MetricKey`, `ContextKey`, `Value decimal(20,4)`,
`ReachedAt datetime(6)` (time the current value was reached), `UpdatedAt`. PK `(UserId, MetricKey, ContextKey)`; index
`(MetricKey, ContextKey, Value)`.

**`player_stat_sessions`** — model `PlayerStatSession`

| Column | Type | Notes |
|---|---|---|
| Id | bigint auto | PK |
| SessionKey | char(36) | unique; plugin-generated UUID |
| UserId | int | index `(UserId, StartedAt)` |
| StartedAt / LastHeartbeatAt | datetime(6) | |
| EndedAt | datetime(6)? | |
| EndReason | byte? | `PlayerSessionEndReason` {Quit=0, ServerStop=1, Kick=2, Timeout=3} |
| ActiveSeconds / AfkSeconds | int | accumulated from duration entries |
| ServerName | varchar(64) | |

**`player_stat_batches`** — model `PlayerStatBatch`: `BatchId char(36)` PK, `ServerName varchar(64)`, `ReceivedAt`,
`EntryCount int`, `RejectedCount int`. Index `ReceivedAt` (retention).

**`player_stat_visibility`** — model `PlayerStatVisibility`: `UserId`, `SettingKey varchar(48)`, `ContextKey varchar(32)`
(`''` = metric level), `Visibility byte` (`StatisticVisibility` {Nobody=0, Friends=1, Everyone=2}), `UpdatedAt`.
PK `(UserId, SettingKey, ContextKey)`; index `(SettingKey, ContextKey, Visibility)` (leaderboard eligibility).

**`player_stat_profiles`** — model `PlayerStatProfile`: `UserId` PK, `FirstSessionAt datetime(6)?`,
`LeaderboardExcluded bool`, `LeaderboardExcludedReason varchar(200)?`, `LeaderboardExcludedByUserId int?`, `UpdatedAt`.
(Columns for link 5 exclusions are created now to avoid a second migration on the same table.)

**`player_title_changes`** — model `PlayerTitleChange`

| Column | Type | Notes |
|---|---|---|
| Id | bigint auto | PK |
| UserId | int | index `(UserId, ChangedAt)` |
| FromTitleBracketId / ToTitleBracketId | int? / int | bracket ids at projection time |
| FromTitleName / ToTitleName | varchar(64) | gendered name at projection time |
| Direction | byte | `TitleChangeDirection` {Promotion=0, Demotion=1} |
| ExperienceBefore / ExperienceAfter | bigint | from the ledger leg |
| CurrencyEntryId | bigint | **unique** — idempotent projection key |
| ChangedAt | datetime(6) | transaction `CreatedAt` |

**`player_pvp_kill_pairs_daily`** — model `PlayerPvpKillPairDaily`: `KillerUserId`, `VictimUserId`, `Day date`,
`ContextKey varchar(32)`, `Count int`. PK `(KillerUserId, VictimUserId, Day, ContextKey)`; index `(Day)`.

**`statistics_projection_cursors`** — model `StatisticsProjectionCursor`: `Name varchar(48)` PK (`ledger`),
`LastSourceId bigint`, `UpdatedAt`.

**`statistics_projected_sources`** — model `StatisticsProjectedSource`: `SourceType varchar(32)` (`siege_match`),
`SourceId bigint`, `ProjectedAt`. PK `(SourceType, SourceId)`.

### 1.2 Link 5 — migration `<ts>_AddLeaderboards`

**`leaderboard_snapshots`** — `Id bigint` PK, `BoardKey varchar(96)`, `Period byte` (`LeaderboardPeriod` {Weekly=0,
Monthly=1, Lifetime=2}), `PeriodStart date?` (null for lifetime), `GeneratedAt datetime(6)`, `IsCurrent bool`,
`EntryCount int`. Index `(BoardKey, Period, IsCurrent)`.
**`leaderboard_snapshot_entries`** — `SnapshotId bigint`, `Rank int`, `UserId int`, `Value decimal(20,4)`,
`ReachedAt datetime(6)`. PK `(SnapshotId, UserId)`; index `(SnapshotId, Rank)`. Max `Leaderboards:MaxEntriesPerBoard`
(default 5,000) entries per snapshot.

### 1.3 Link 6 — migration `<ts>_AddDiagnosticTelemetryAndPrivacy`

**`telemetry_events`** — `Id bigint` PK, `EventId char(36)` unique, `Name varchar(64)`, `SchemaVersion smallint`,
`Level byte` {Baseline=0, Enhanced=1}, `Source byte` {Plugin=0, Api=1}, `OccurredAt datetime(6)`, `ReceivedAt datetime(6)`,
`ServerName varchar(64)`, `ServerSeq bigint`, `AppVersion varchar(32)`, `UserId int?`, `SessionKey char(36)?`,
`TestRunId int?`, `MatchId int?`, `CorrelationId varchar(64)?`, `Feature varchar(32)`, `Action varchar(64)`,
`Outcome byte` {Succeeded=0, Denied=1, Failed=2, Info=3}, `ReasonCode varchar(64)?`, `ObjectType varchar(32)?`,
`ObjectId varchar(64)?`, `PayloadJson json?`. Indexes: `(UserId, OccurredAt)`, `(SessionKey)`, `(TestRunId, OccurredAt)`,
`(MatchId, OccurredAt)`, `(CorrelationId)`, `(Name, OccurredAt)`, `(OccurredAt)`.
**`telemetry_test_runs`** — `Id int` PK, `Name varchar(100)`, `Description varchar(500)?`, `StartedAt`, `EndedAt?`,
`CreatedByUserId int`.
**`telemetry_enhanced_targets`** — `Id int` PK, `UserId int?`, `TestRunId int?` (exactly one set; check constraint),
`ExpiresAt datetime(6)`, `CreatedByUserId int`, `CreatedAt`.
**`privacy_deletion_requests`** — `Id int` PK, `UserId int`, `RequestedAt`, `DueAt`, `Status byte`
(`PrivacyRequestStatus` {Pending=0, Completed=1, Cancelled=2}), `RequestedByUserId int`, `Note varchar(500)?`,
`ExecutedAt datetime(6)?`, `ExecutedByUserId int?` (null = automatic), `ResultJson json?` (counts only). Index `(Status, DueAt)`.

### 1.4 Link 7 — migration `<ts>_AddWorldAnalytics` (anonymous aggregates, no user ids)

**`world_movement_cells_daily`** — `Day date`, `World varchar(64)`, `CellSize smallint`, `CellX int`, `CellZ int`,
`Samples int`. PK all but `Samples`.
**`menu_funnel_daily`** — `Day`, `MenuKey varchar(191)`, `Step varchar(96)` (`opened`, `action:<actionTypeId>`,
`back`, `closed`), `Outcome byte` (Succeeded/Denied/Failed/Info), `Count int`. PK `(Day, MenuKey, Step, Outcome)`.
**`domain_interactions_daily`** — `Day`, `DomainId int`, `Kind varchar(32)` (`enter`, `leave`, `discover`),
`Count int`, `UniquePlayers int`. PK `(Day, DomainId, Kind)`.
**`world_analytics_batches`** — `BatchId char(36)` PK, `ReceivedAt` (dedupe, 30-day retention).

---

## 2. Catalogue and pure rules (knk-web-api, link 2)

- `Services/Statistics/StatisticsCatalog.cs` — static, immutable registry. `StatisticMetricDefinition(Key, SettingKey?,
  Aggregation (Sum|Max), Unit (Count|Seconds|Blocks|Points), Contextual, Visibility (AlwaysPublic|Configurable|Internal),
  Source (Plugin|Ledger|SiegeProjection|Derived), PluginWritableContexts, MaxPerEntry, Group, Label)`. Contains every
  row of DESIGN §F.1 with these keys. `StatisticsCatalog.SettingKeys`, `.Groups`, `.ContextualSettingKeys`,
  `.IsPluginWritable(metric, context)` (false for `pvp_kills|deaths|highest_killstreak|wins|losses|draws|objectives_captured`
  in context `siege`; false for ledger/derived metrics everywhere). Context key regex `^[a-z][a-z0-9_]{0,31}$`; known
  contexts `open_world`, `siege` (others accepted if they match the regex).
  `MaxPerEntry`: durations 86,400 s, distances 100,000 blocks, damage 100,000, counts 10,000, `highest_fall` 10,000.
- `StatisticsPeriods.cs` — `StatisticsPeriods.Resolve(DateTime utc, PeriodKind kind, TimeZoneInfo zone) → (DateOnly start,
  DateOnly endExclusive)`, `LocalDay(DateTime utc, zone)`, `SplitByDay(DateTime fromUtc, DateTime toUtc, zone) →
  IEnumerable<(DateOnly day, double seconds)>`. Week starts Monday. The only place that computes boundaries; signature
  takes the zone so a player zone can be passed later.
- `StatisticsFormatting.cs` — `Display(metric, decimal raw)`: points → round half away from zero to integer; blocks →
  floor; `highest_fall` → 1 decimal; seconds → integer.
- `LedgerStatisticsClassifier.cs` — `Classify(string reasonCode) → LedgerBucket {Earned, Spent, Excluded, Reversal}` per
  §F.5; unknown codes → Excluded.

---

## 3. API contracts

Auth legend: **plugin** = `[RequirePluginService]`; **viewer** = no attribute, viewer resolved by
`StatisticsViewerResolver` (JWT user, or plugin + `X-Acting-User-Id`, else anonymous); **self** = JWT user id ==
`{userId}` or plugin with `X-Acting-User-Id == {userId}`; **owner(node)** = `[RequireOwnerPermission(node)]` (exact
grant, §6).

### 3.1 Link 2 — `Controllers/StatisticsController.cs` (`[Route("api/statistics")]`)

| Method + route | Auth | Body / query → response |
|---|---|---|
| `POST batches` | plugin | `StatisticsBatchDto` → `StatisticsBatchResultDto` (200; 400 only for structural errors) |
| `GET catalog` | anonymous | → `StatisticsCatalogDto` |
| `GET users/{userId:int}` | viewer | `?period=lifetime|day|week|month&date=yyyy-MM-dd` → `PlayerStatisticsDto` (404 unknown/inactive user) |
| `GET users/{userId:int}/series` | viewer | `?metric=&context=&granularity=day|week|month&from=&to=` (≤ 366 points) → `StatisticSeriesDto` (403 when hidden) |
| `GET users/{userId:int}/title-history` | viewer (setting `title_history`) | `?page=1&pageSize=20` → `PagedResultDto<TitleChangeDto>` |
| `GET users/{userId:int}/discoveries` | viewer (setting `discoveries.list`) | `?page=&pageSize=` → `PagedResultDto<DiscoveryListItemDto>` (reuses `IDiscoveryService` data; merged ids aggregated) |
| `GET users/{userId:int}/visibility` | self, or staff `knk.admin.statistics.view` (read-only) | → `StatisticsVisibilityDto` |
| `PUT users/{userId:int}/visibility` | self | `StatisticsVisibilityUpdateDto` → `StatisticsVisibilityDto`; 409 `VisibilityConflict` (body carries current settings); 400 `UnknownSetting` / `NotContextual` |

**DTOs (`Dtos/StatisticsDtos.cs`)** — JSON names shown:

```
StatisticsBatchDto { batchId: Guid, serverName: string(≤64), pluginVersion: string(≤32), sentAt: DateTime,
  sessions:  [ { type: "start"|"end", sessionKey: Guid, userId: int, at: DateTime, endReason?: "Quit"|"ServerStop"|"Kick" } ],
  durations: [ { sessionKey: Guid, userId: int, metric: "active_playtime"|"afk_time", from: DateTime, to: DateTime } ],
  counters:  [ { userId: int, metric: string, context: string, value: decimal, occurredAt: DateTime } ],   // sum metrics
  records:   [ { userId: int, metric: string, context: string, value: decimal, occurredAt: DateTime } ],   // max metrics
  pvpKills:  [ { killerUserId: int, victimUserId: int, context: string, occurredAt: DateTime } ] }
  // ≤ Statistics:MaxBatchEntries (2,000) entries across all lists
StatisticsBatchResultDto { batchId, duplicate: bool, accepted: int, rejected: [ { section: string, index: int, code: string } ] }
  // codes: UnknownMetric, NotPluginWritable, InvalidContext, OutOfRange, TooOld, InFuture, UnknownSession, InvalidInterval
StatisticsCatalogDto { timeZone: string, metrics: [ { key, settingKey?, aggregation, unit, contextual, visibility, group, label } ],
  settings: [ { settingKey, group, label, contextual } ], groups: [ { key, label, settingKeys[] } ] }
PlayerStatisticsDto { userId, username, period, periodStart?: date, periodEndExclusive?: date, timeZone,
  viewer: "self"|"staff"|"signedIn"|"anonymous",
  profile: { titleName, titleBracketId, experience, coins, gems, firstJoinedAt?, activePlaytimeSeconds, afkSeconds },
  metrics: [ { key, settingKey, value: decimal /*display-rounded*/, rawValue: decimal, unit, aggregation,
               contexts?: [ { context, value, rawValue } ] } ],          // only visible metrics; internal never
  economy?: { coinsEarned, coinsSpent, gemsEarned, gemsSpent },          // when "economy" visible
  discoveries?: { total, towns, districts, structures } }                // when "discoveries.counts" visible
  // "deaths" is returned as a total only (no contexts) to non-staff viewers.
StatisticSeriesDto { metric, context, granularity, points: [ { periodStart: date, value: decimal } ] }
TitleChangeDto { changedAt, fromTitleName?, toTitleName, direction: "Promotion"|"Demotion" }
StatisticsVisibilityDto { userId, friendsAvailable: false,
  settings: [ { settingKey, group, label, contextual, visibility: "Nobody"|"Friends"|"Everyone",
                contexts: [ { context, visibility } ] } ] }               // contexts = existing overrides + contexts with data
StatisticsVisibilityUpdateDto { changes: [ { settingKey, context: string /*"" = metric level*/,
                                             expected: "Nobody"|"Friends"|"Everyone", visibility: … } ] }   // ≤ 64, atomic
```

**Ingestion semantics (`StatisticsIngestionService`):** one DB transaction per batch. Insert `player_stat_batches` row
first; a duplicate key → return `duplicate: true` without applying anything. Validate entries individually (invalid →
`rejected`, others still applied). `start` inserts the session if its key is new, sets `PlayerStatProfile.FirstSessionAt =
min(...)` and adds `logins += 1` on the start's local day; `end` sets `EndedAt`/`EndReason` (idempotent). Durations are
split with `StatisticsPeriods.SplitByDay` into `active_playtime` / `afk_time` daily rows and added to the session's
seconds; `LastHeartbeatAt = max(LastHeartbeatAt, to)`. Counters → daily (+) and totals (+); records → daily (max) and
totals (max, `ReachedAt` updated only when the value increases); `pvpKills` → `pvp_kills` counter for the killer plus the
pair row. Entries are pre-aggregated in memory per key and written with multi-row `INSERT … ON DUPLICATE KEY UPDATE`
(`Value = Value + VALUES(Value)` / `GREATEST(…)`); the repository falls back to tracked-entity updates when the provider
is not relational (EF InMemory), like `CurrencyRepository`. `Statistics:Enabled=false` → `POST batches` returns 503
`StatisticsDisabled` (the plugin keeps spooling) and projectors/retention stop.

### 3.2 Link 5

`Controllers/LeaderboardsController.cs` (`[Route("api/leaderboards")]`):

| Method + route | Auth | → |
|---|---|---|
| `GET /` | anonymous | `LeaderboardBoardDto[] { boardKey, metric, context?, label, unit, periods[] }` |
| `GET {boardKey}` | viewer | `?period=weekly|monthly|lifetime&top=10` (top ≤ 50) → `LeaderboardViewDto { boardKey, period, periodStart?, generatedAt, totalRanked, entries: [ { rank, userId, username, value, rawValue } ], viewer?: { rank, value, rawValue } }` |
| `GET exclusions` | owner(`knk.owner.leaderboard.manage`) | `LeaderboardExclusionDto[] { userId, username, reason, excludedByUserId, updatedAt }` |
| `PUT exclusions/{userId:int}` | owner(`knk.owner.leaderboard.manage`) | `{ reason }` → 204 |
| `DELETE exclusions/{userId:int}` | owner(`knk.owner.leaderboard.manage`) | 204 |

Board keys: `<metric>` or `<metric>@<context>` (e.g. `pvp_kills`, `pvp_kills@siege`, `wins@siege`). 

`Controllers/PlayersController.cs` (`[Route("api/players")]`): `GET by-name/{username}` (anonymous) →
`PublicPlayerProfileDto { userId, username, titleName, experience, coins, gems, firstJoinedAt?, activePlaytimeSeconds,
afkSeconds }` (case-insensitive username; 404 for unknown or inactive accounts; **no** online flag, email or UUID — vanish
must not leak).

### 3.3 Link 6

`Controllers/TelemetryController.cs` (`[Route("api/telemetry")]`):

| Method + route | Auth | → |
|---|---|---|
| `POST events/batch` | plugin | `TelemetryEventDto[]` (≤ 500) → `{ accepted, duplicates, rejected }` |
| `GET events` | owner(`knk.owner.telemetry.view`) | `?userId&from&to&sessionKey&testRunId&matchId&correlationId&name&outcome&limit=200&before={id}` → `TelemetryEventPageDto { items: TelemetryEventViewDto[], nextBefore? }`; each read writes `AuditAction.TelemetryViewed` (target = `userId` when given) |
| `GET events/{eventId}` | owner(view) | `TelemetryEventViewDto` + `related: TelemetryEventViewDto[]` (same correlation id) + `links: { ledgerTransactionPublicIds[], siegeMatchId? }` resolved at read time |
| `GET timeline/{userId:int}` | owner(view) | Merged, ordered timeline: events + that user's ledger transactions + Siege participations in the window (read-time join, nothing duplicated) |
| `GET/POST test-runs`, `PUT test-runs/{id}` (end) | owner(`knk.owner.telemetry.manage`) | `TelemetryTestRunDto { id, name, description, startedAt, endedAt? }` |
| `GET/POST enhanced-targets`, `DELETE enhanced-targets/{id}` | owner(manage) | `EnhancedTargetDto { id, userId?, testRunId?, expiresAt }` |
| `GET config` | plugin | `TelemetryClientConfigDto { enabled, enhancedUserIds[], activeTestRunIds[], baselineEventNames[], enhancedEventNames[] }` |
| `GET health` | owner(view) | `{ queueDepth, droppedSinceStart, lastWriteAt, eventsLast24h }` |

`TelemetryEventDto` = DESIGN §F.12 envelope (`eventId, name, schemaVersion, occurredAt, serverName, serverSeq,
appVersion, level, userId?, sessionKey?, testRunId?, matchId?, correlationId?, feature, action, outcome, reasonCode?,
objectType?, objectId?, payload: { [key]: string|number|bool }`). The API validates name against
`TelemetryEventCatalog` (allowlisted payload keys per name), truncates strings > 128, drops non-allowlisted keys.

`Controllers/PrivacyController.cs` (`[Route("api/privacy")]`), all owner(`knk.owner.privacy.manage`):
`GET deletion-requests?status=`, `POST deletion-requests { userId, note? }` (201, `DueAt = now + 30 d`),
`POST deletion-requests/{id}/execute`, `POST deletion-requests/{id}/cancel` → `PrivacyDeletionRequestDto { id, userId,
username?, requestedAt, dueAt, status, executedAt?, executedByUserId?, result? }`.

### 3.4 Link 7

`Controllers/WorldAnalyticsController.cs` (`[Route("api/world-analytics")]`): `POST batches` (plugin;
`WorldAnalyticsBatchDto { batchId, windowStart: DateTime, movementCells: [ { world, cellSize, cellX, cellZ, samples } ],
menuSteps: [ { menuKey, step, outcome, count } ], domainInteractions: [ { domainId, kind, count, uniquePlayers } ] }` — the
plugin aggregates per flush window (never across a local midnight: it flushes early at the window boundary it receives
from `GET api/statistics/catalog`'s `timeZone`) and the API maps `windowStart` to the local day with
`StatisticsPeriods.LocalDay`), `GET heatmap?world&from&to&cellSize` → `HeatmapDto { world, cellSize, cells: [ { x, z,
samples } ], maxSamples }`, `GET menu-funnels?menuKey&from&to` → steps with counts, `GET domains?from&to&kind` → per
domain counts — all reads owner(`knk.owner.analytics.view`).

---

## 4. API services, jobs and configuration

| Class (knk-web-api) | Link | Role |
|---|---|---|
| `Services/Statistics/StatisticsIngestionService` (+`IStatisticsIngestionService`) | 2 | §3.1 semantics |
| `Services/Statistics/StatisticsQueryService` (+I) | 2 | Period reads (daily for day/week/month, totals for lifetime), merged-id aggregation via `ICurrencyService.GetMergedAccountIdsAsync`, economy/discovery sections, first-join derivation (§F.3), visibility filtering |
| `Services/Statistics/StatisticsVisibilityService` (+I) | 2 | Effective visibility (§F.4), atomic update with expected values (single transaction; 409 on mismatch) |
| `Services/Statistics/StatisticsViewerResolver` | 2 | Viewer kind from `HttpContext.GetKnkCaller()` + `knk.admin.statistics.view` check |
| `Services/Statistics/LedgerStatisticsProjector` | 2 | Reads `currency_entries` (user legs) with `Id > cursor` in chunks of 2,000 ordered by Id, joins the transaction (reason, `CreatedAt`, `ReversesTransactionId`), writes `coins_*`/`gems_*`/`xp_gained` daily+totals and `player_title_changes` (XP legs whose `BalanceBefore`/`BalanceAfter` resolve to different brackets via `TitleService` bracket list + user gender), advances the cursor in the **same transaction** |
| `Services/Statistics/SiegeStatisticsProjector` | 2 | Picks `Completed`/`Aborted` matches not in `statistics_projected_sources`, applies §F.6, writes daily (match end day) + totals, inserts the source row in the same transaction |
| `Services/Statistics/StatisticsProjectionService : BackgroundService` | 2 | `PeriodicTimer(Statistics:ProjectionIntervalSeconds = 30)`; runs both projectors in their own scopes; also closes timed-out sessions (`EndReason=Timeout` at `LastHeartbeatAt`) |
| `Services/Statistics/StatisticsRetentionService : BackgroundService` | 2 | Daily: purge daily rows, sessions, batches, kill pairs per §F.15 |
| `Services/Statistics/StatisticsMetrics` | 2 | OTel meter `Knk.Statistics`: `knk.statistics.batches`, `.entries`, `.rejected{code}`, `.projection.lag_seconds{projector}` — no user ids (OBSERVABILITY.md) |
| `Services/Statistics/StatisticsRebuildService` (+I) | 2 | Owner-triggered rebuild of ledger/siege projections for one user or all (deletes projected rows for the source, resets cursor/sources) — exposed in link 6 as `POST api/statistics/rebuild` owner(`knk.owner.telemetry.manage`) |
| `Services/Leaderboards/LeaderboardSnapshotService : BackgroundService` + `LeaderboardQueryService` (+I) + `LeaderboardEligibility` (pure) | 5 | Every `Leaderboards:RefreshSeconds` (300) builds current snapshots for all boards × periods: sums/max from daily (weekly/monthly) or totals (lifetime), `pvp_kills` from kill pairs with the per-victim cap, discoveries from `user_domain_discoveries`, merges secondary ids into primaries, applies eligibility + exclusions + active users, competition ranks, flips `IsCurrent` atomically; keeps the final snapshot of each closed period for retention |
| `Services/Telemetry/TelemetryIngestionService`, `TelemetryWriteQueue` (bounded `Channel`, `DiagnosticTelemetry:QueueCapacity` 10,000, drop-newest + counter), `TelemetryWriterService : BackgroundService` (batch insert every 2 s), `TelemetryQueryService`, `TelemetryEventCatalog`, `TelemetryRetentionService`, `ApiFailureTelemetryMiddleware` (5xx → `api.request_failed` with route template + correlation id) | 6 | §3.3 |
| `Services/Privacy/PrivacyDeletionService` (+I), `PrivacyDeletionDueService : BackgroundService` (daily) | 6 | §F.14 |
| `Services/WorldAnalytics/WorldAnalyticsIngestionService`, `WorldAnalyticsQueryService`, retention | 7 | §3.4 |

**appsettings.json sections** (options classes in `Configuration/`):

```json
"Statistics":         { "Enabled": true, "TimeZone": "Europe/Amsterdam", "MaxBatchEntries": 2000, "LateEventToleranceDays": 7,
                        "ProjectionIntervalSeconds": 30, "SessionTimeoutMinutes": 5, "DailyRetentionDays": 730,
                        "SessionRetentionDays": 365, "BatchRetentionDays": 30, "KillPairRetentionDays": 62 },
"Leaderboards":       { "Enabled": true, "RefreshSeconds": 300, "MaxEntriesPerBoard": 5000, "RepeatVictimDailyCap": 3,
                        "SnapshotRetentionDays": 400 },
"DiagnosticTelemetry": { "Enabled": true, "QueueCapacity": 10000, "MaxBatchSize": 500, "BaselineRetentionDays": 90,
                        "EnhancedRetentionDays": 14 },
"Privacy":            { "DeletionDueDays": 30, "AutoExecuteEnabled": true, "AutoExecuteBeforeDueDays": 3 },
"WorldAnalytics":     { "Enabled": true, "RetentionDays": 180 }
```

(`Telemetry` is already taken by the OpenTelemetry exporter config — do not reuse it.)

---

## 5. Plugin components (knk-plugin)

### 5.1 Config (`config.yml`, `KnkConfig.StatisticsConfig` etc.)

```yaml
statistics:
  enabled: true                       # false = no listeners, no /afk, no flush (today's behaviour)
  flush-interval-seconds: 60
  max-batch-entries: 2000
  spool-directory: statistics-spool
  replay-interval-seconds: 60
  excluded-game-modes: [CREATIVE, SPECTATOR]   # combat/distance/fall not recorded; playtime still is
  afk:
    enabled: true
    idle-seconds: 300
    command-enabled: true
    tab-list-marker: true
    marker-text: "&7[AFK]"
  movement:
    enabled: true
    max-segment-blocks: 10.0
  fall:
    enabled: true
  combat:                              # link 4
    enabled: true
    count-custom-damage: false
    pve-excluded-spawn-reasons: [SPAWNER, SPAWNER_EGG, BREEDING, EGG, DISPENSE_EGG]
  gates:                               # link 4
    enabled: true
    fire-attribution: true
  siege:                               # link 4
    report-departed-members: true      # false = today's completion payload
telemetry:                             # link 6
  enabled: true
  max-buffer-events: 5000
  flush-interval-seconds: 10
  config-poll-seconds: 60
  enhanced-movement-sample-seconds: 5
world-analytics:                       # link 7
  enabled: true
  movement-sample-seconds: 10
  cell-size: 16
  flush-interval-seconds: 300
```

### 5.2 Classes

| Class | Link | Role |
|---|---|---|
| `C/statistics/StatisticsMetric` (enum with API key strings), `C/statistics/StatisticsContext` (value type: `OPEN_WORLD`, `SIEGE`) | 3 | Keys shared with the API catalogue |
| `C/statistics/StatisticsBuffer` | 3 | Thread-safe accumulator: counters/records keyed `(userId, metric, context, minuteBucket)`, pending session events, durations, pvp kills; `drain(maxEntries) → StatisticsBatch`; primitive maps, no allocation per move event beyond the first per key |
| `C/domain/statistics/StatisticsBatch` (+ entry records) | 3 | Domain mirror of `StatisticsBatchDto` |
| `C/statistics/StatisticsSpool` | 3 | One JSON file per batch `<dir>/<batchId>.json`, atomic temp+move, versioned `version: 1` |
| `C/statistics/StatisticsRecorder` | 3 | Send with `RetryPolicy.defaultPolicy()`; spool on transient failure (network, 5xx, 401/403 key mismatch, 408/429, 503 disabled); final on structural 400 (logged, dropped); replay oldest-first |
| `C/statistics/AfkTracker` | 3 | Pure per-player state machine (§F.2): `activity(now)`, `toggleManual(now)`, `accrue(now) → DurationSlices(active, afk)` with pending-idle handling; `quit(now)` |
| `C/statistics/MovementClassifier` | 3 | Pure: `(MovementInput{inVehicle, gliding, flying, swimming}, segmentLength) → Optional<MovementMode>` with max-segment rule |
| `C/statistics/FallRule` | 3 | Pure: `(fallDistance, healthBefore, finalDamage, absorption) → Optional<Double>` |
| `C/ports/api/StatisticsApi` + `A/impl/StatisticsApiImpl`, `A/dto/StatisticsDtos`, `A/mapper/StatisticsMapper` | 3 | `postBatch`, `getCatalog`, `getUserStatistics(target, acting, period, date)`, `getTitleHistory`, `getVisibility(userId, acting)`, `updateVisibility(userId, acting, changes)` (sends `X-Acting-User-Id`); `getUserStatistics` etc. used from link 5 |
| `P/statistics/StatisticsService` | 3 | Owns buffer, trackers, user-id resolution (`UserCache.getStale`, unresolved-UUID queue like discovery), context resolution, lifecycle |
| `P/statistics/StatisticsContextResolver` | 3 | `contextOf(Player)`: `siege` when `SiegeService.runningMatchOf(uuid)` is present, else `open_world` (siege service looked up lazily; null-safe when siege is disabled) |
| `P/statistics/StatisticsSessionListener` | 3 | `UserDataLoadedEvent` (MONITOR) → session start; `PlayerQuitEvent` (MONITOR) → accrue + end; plugin disable → end all with `ServerStop` |
| `P/statistics/AfkActivityListener` | 3 | MONITOR/ignoreCancelled: move (look delta / eligible horizontal movement), chat (`AsyncChatEvent` → main-thread hop), `PlayerCommandPreprocessEvent`, interact, `InventoryClickEvent`, block break/place, sneak/sprint toggle, `EntityDamageByEntityEvent` as attacker |
| `P/statistics/AfkPresentation` | 3 | Messages + player-list marker (stores and restores the previous `playerListName`) |
| `P/commands/AfkCommand` (`/afk`, plugin.yml) | 3 | Toggle; disabled → "AFK is disabled" |
| `P/statistics/MovementStatisticsListener` | 3 | `PlayerMoveEvent` MONITOR/ignoreCancelled with cheap early-outs (same position, excluded mode, AFK) + `VehicleMoveEvent` for passengers; teleports ignored |
| `P/statistics/FallStatisticsListener` | 3 | `EntityDamageEvent` cause FALL, MONITOR/ignoreCancelled |
| `P/statistics/StatisticsFlushTask` | 3 | Main-thread timer every `flush-interval-seconds`: accrue durations for online players, drain buffer, hand off to recorder async; replay timer; `stop()` + `spoolEverything()` on disable |
| `P/menu/content/StatisticsVisibilityMenuFeature` (+ `StatisticsVisibilityView`) | 3 | Menu `statistics.visibility` (§5.3) |
| `P/commands/UserCommand` — new subcommand `/stats settings` (opens the menu) | 3 | Small additive edit |
| `C/statistics/KillstreakTracker`, `C/statistics/DeathCauseClassifier`, `C/statistics/CombatStatisticsRules` (damage cap, spawn-reason filter, arrow filter) | 4 | Pure |
| `P/statistics/CombatStatisticsListener` | 4 | `EntityDamageByEntityEvent` MONITOR/ignoreCancelled (damage dealt/received, headshot recompute via `SiegeCombatRules.isHeadshot` when the siege lobby's headshot multiplier > 1), `PlayerDeathEvent` MONITOR (deaths, causes, pvp kills — skipped for running-match members per §F.6), `EntityDeathEvent` MONITOR (pve kills), `EntityShootBowEvent` MONITOR/ignoreCancelled (arrows) |
| `C/gates/GateFireAttribution` (pure: burning block → igniter, split of a tick's loss) + `P/statistics/GateDamageStatisticsSink` (interface `GateDamageSink` in `P/gates`, default no-op) | 4 | Gate damage |
| Edits: `P/gates/HealthSystem.applyDamage` / `applyContinuousDamage` return `double` effective loss; `P/listeners/GateDamageConsequenceListener` passes `(attacker, gate, loss)` to the sink; `P/gates/GateFireSystem` keeps `Map<gateId, Map<Vector, Igniter>>` and reports per-igniter loss to the sink; `P/siege/SiegeService.removeMember` keeps the removed `MemberView` (when `statistics.siege.report-departed-members`) and `completion()` appends departed members' results | 4 | Minimal edits; outcomes unchanged |
| `P/menu/content/StatisticsMenuFeature`, `P/menu/content/LeaderboardsMenuFeature`, `C/ports/api/LeaderboardsApi` + impl, `P/commands/LeaderboardCommand` (`/leaderboard`, alias `/lb`) | 5 | Read surfaces (§5.3) |
| `UserCommand.statisticsLines` / `ProfileView.getStatisticsLines()` | 5 | Visible statistics lines (viewer-filtered by the API) |
| `C/telemetry/TelemetryEvent`, `C/telemetry/TelemetryBuffer` (bounded, drop-oldest, drop counter), `C/telemetry/TelemetrySequence`, `C/ports/api/TelemetryApi` + impl, `P/telemetry/TelemetryEmitter`, `P/telemetry/TelemetryFlushTask`, `P/telemetry/TelemetryConfigPoller`; hook interfaces `P/menu/MenuObserver` (called from `MenuService.openMenu`/`goBack`/close and `ActionRegistry.execute` result; default no-op) and new default-no-op methods on `SiegeMatchObserver` for lobby join/vote/team events; `BaseApiImpl` sends `X-Correlation-Id` when a correlation is active | 6 | Telemetry |
| `C/analytics/MovementCellGrid`, `C/analytics/DomainInteractionCounter`, `P/analytics/MovementSampler`, `P/analytics/MenuFunnelRecorder` (a `MenuObserver`), `P/analytics/DomainInteractionRecorder` (`OnRegionEnterEvent`/`OnRegionLeaveEvent` + discovery grants), `P/analytics/WorldAnalyticsFlushTask`, `C/ports/api/WorldAnalyticsApi` + impl | 7 | Analytics |

### 5.3 Menus (seeded by knk-web-api `Models/Menu/MenuTemplateSeed.Statistics.cs`, chained into `CanonicalTemplates()`; test mirror `content-seeds.json` regenerated)

| Key | Link | Layout / behaviour |
|---|---|---|
| `statistics.visibility` | 3 | Header: five group selector items (Activity, Combat, Minigames, Exploration, Progression; action `statistics.visibility.select-group`), three group actions "Set all listed to Nobody/Friends/Everyone" (action `statistics.visibility.group` → `MenuSession.PendingConfirmation("statistics.visibility.apply-group", {group, value}, prompt)` whose lore lists every affected setting `current → proposed`), confirm/cancel via the existing generic confirmation handlers, back. Content grid (row source `statistics.visibility.rows`): one row per setting of the selected group, plus one row per existing context override / context with data (`PvP kills — Siege`); click cycles Nobody → Friends → Everyone (action `statistics.visibility.cycle`, one-change PUT with expected value). Friends rows carry lore "Friends-only shows nothing until the friends system exists". Variable root `statsvis` |
| `profile.main` header slot 6 | 3 | Tile "Statistics privacy" → opens `statistics.visibility` (seed edit; existing databases need the content-menu reset — live checklist) |
| `statistics.main` | 5 | Own or another player's statistics (`target` param): header period cycle (lifetime/day/week/month), group items with visible metric lines from `GET api/statistics/users/{id}` (acting user = viewer), title-history row source |
| `statistics.leaderboards` / `statistics.leaderboard` | 5 | Board list → board view (top 10 + viewer row, period cycle) |
| `profile.main` header slot 5 | 5 | Tile "Statistics" → `statistics.main` |

---

## 6. Permission nodes

| Node | Kind | Enforced by | Seeded? |
|---|---|---|---|
| `knk.admin.statistics.view` | staff | `StatisticsViewerResolver` (normal wildcard resolution) | no |
| `knk.owner.telemetry.view` | owner | `[RequireOwnerPermission]` | **never** |
| `knk.owner.telemetry.manage` | owner | `[RequireOwnerPermission]` | **never** |
| `knk.owner.privacy.manage` | owner | `[RequireOwnerPermission]` | **never** |
| `knk.owner.analytics.view` | owner | `[RequireOwnerPermission]` | **never** |
| `knk.owner.leaderboard.manage` | owner | `[RequireOwnerPermission]` | **never** |

`Attributes/RequireOwnerPermissionAttribute(node)` (link 2): caller = JWT web user, or plugin service with
`X-Acting-User-Id`; anonymous → 401. Calls `IPermissionResolutionService.CheckAsync(userId, node)` and requires
`Result == Granted` **and** `MatchedNode == node` (exact grant on the user or one of their groups) — wildcard grants (`*`,
`knk.*`, `knk.owner.*`) → 403. Constants in `Attributes/OwnerPermissions.cs`; `StaffPermissions.ViewStatistics`. The
developer grants owner nodes with `POST api/users/{id}/grants`. Plugin-side owner commands (link 6 `/knk telemetry
testrun …`) call API endpoints with the acting user, so the API decides. Web UI gates owner pages with `usePermission`
for display only; a wildcard holder who sees a page gets 403 from the API and an "Owner only" notice.

---

## 7. Performance budgets (verify per link; measured numbers go into the progress report)

| Budget | Target |
|---|---|
| Plugin listener cost | ≤ 2 µs average per `PlayerMoveEvent` for the statistics listener after early-outs; no allocation per event in the steady state; no I/O on the main thread |
| Plugin flush | One batch per `flush-interval-seconds` (60 s) per server; ≤ 2,000 entries; serialisation + HTTP off the main thread |
| Spool | Bounded by disk only; replay ≤ 1 batch per second |
| API ingestion | p95 ≤ 150 ms for a 2,000-entry batch; one transaction; ≤ 6 multi-row upserts per batch |
| Projection | Ledger/siege projection lag ≤ 60 s at steady state; chunk 2,000 legs |
| Reads | `GET api/statistics/users/{id}` p95 ≤ 100 ms (lifetime from totals; month ≤ 31 days × metrics rows); series ≤ 366 points |
| Leaderboards | Full refresh ≤ 10 s for 10k active players; menu/page reads served from snapshots only |
| Telemetry | Plugin buffer ≤ 5,000 events; API queue ≤ 10,000; writer batch every 2 s; timeline query p95 ≤ 300 ms for a 24 h window |
| Analytics | Movement sampling ≤ 1 sample / player / 10 s in memory; one aggregate batch / 5 min |

---

## 8. Per-link scope, files, acceptance criteria and tests

### Link 2 — API foundation (knk-web-api)

**Files (new unless noted):** `Enums/StatisticVisibility.cs`, `Enums/StatisticAggregation.cs`, `Enums/StatisticUnit.cs`,
`Enums/PlayerSessionEndReason.cs`, `Enums/TitleChangeDirection.cs`; `Models/Statistics/PlayerStatDaily.cs`,
`PlayerStatTotal.cs`, `PlayerStatSession.cs`, `PlayerStatBatch.cs`, `PlayerStatVisibility.cs`, `PlayerStatProfile.cs`,
`PlayerTitleChange.cs`, `PlayerPvpKillPairDaily.cs`, `StatisticsProjectionCursor.cs`, `StatisticsProjectedSource.cs`;
`Properties/KnKDbContext.cs` (edit: DbSets + `ConfigureStatistics`); `Migrations/<ts>_AddPlayerStatistics.cs` (+Designer,
snapshot); `Configuration/StatisticsOptions.cs`; `Services/Statistics/*` (§2, §4 link-2 rows); `Services/Interfaces/
IStatistics*.cs`; `Repositories/StatisticsRepository.cs` + `Repositories/Interfaces/IStatisticsRepository.cs`;
`Controllers/StatisticsController.cs`; `Dtos/StatisticsDtos.cs`; `Attributes/RequireOwnerPermissionAttribute.cs`,
`Attributes/OwnerPermissions.cs`, `Attributes/RequirePermissionAttribute.cs` (edit: `StaffPermissions.ViewStatistics`);
`DependencyInjection/ServiceCollectionExtensions.cs` (edit: options, projectors, hosted services); `Program.cs` (edit:
`AddMeter("Knk.Statistics")`); `appsettings.json` (edit: `Statistics` section).

**Acceptance criteria**
1. Migration is additive; `dotnet build` and the full test suite pass with no new failures vs. baseline.
2. `POST api/statistics/batches` applies a mixed batch (sessions, durations across midnight, counters, records, pvp kills),
   replaying the same `batchId` changes nothing (`duplicate: true`), invalid entries are rejected per entry with codes,
   projection-owned Siege metrics are rejected (`NotPluginWritable`).
3. Period function: Monday week start, month boundaries, DST change days in `Europe/Amsterdam`, durations split at local
   midnight.
4. Ledger projector: earned/spent/excluded/reversal buckets per §F.5 incl. `PLAYER_TRANSFER` legs; `xp_gained`; title
   changes for promotions and demotions (incl. merge forfeit/carry-over); re-running is idempotent (cursor) and a rebuild
   reproduces identical rows.
5. Siege projector: win/loss/draw/left-early/aborted/deleted-team cases (§F.6), kills/deaths/streak/captures to the end
   day; idempotent per match.
6. Visibility: defaults nobody; friends treated as nobody; context precedence; totals rule; atomic multi-change update with
   409 on any expected mismatch and nothing written.
7. Reads: anonymous sees only `profile`; signed-in sees *everyone* metrics only; self and staff see all; `deaths` total
   only for non-staff; internal metrics never returned; merged identities aggregated; first join per §F.3.
8. `RequireOwnerPermission`: exact grant passes; `*`, `knk.*`, `knk.owner.*` grants get 403; anonymous 401.
9. `Statistics:Enabled=false`: ingestion 503, projectors and retention idle.
10. `CurrencyWriteGuardTests` still green; a new test asserts every `CurrencyReasons` code is classified explicitly by
    `LedgerStatisticsClassifier` (fails when a new reason code is added without a decision) — the D13 coverage guard.

**Tests:** `Tests/knkwebapi_v2.Tests/Services/Statistics/StatisticsPeriodsTests.cs`, `StatisticsCatalogTests.cs`,
`StatisticsFormattingTests.cs`, `LedgerStatisticsClassifierTests.cs`, `StatisticsIngestionServiceTests.cs`,
`LedgerStatisticsProjectorTests.cs`, `SiegeStatisticsProjectorTests.cs`, `StatisticsVisibilityServiceTests.cs`,
`StatisticsQueryServiceTests.cs` (visibility matrix × viewer kinds); `Tests/.../Api/StatisticsControllerAuthTests.cs`,
`RequireOwnerPermissionAttributeTests.cs`; a MySQL-gated upsert test under `MySql/` (skipped without `KNK_TEST_MYSQL`).

### Link 3 — Plugin foundation (knk-plugin + knk-web-api seed)

**Files:** plugin §5.2 link-3 rows; `P/config/KnkConfig.java` + `P/config/ConfigLoader.java` (edit: `StatisticsConfig`);
`knk-paper/src/main/resources/config.yml` (edit: `statistics:` block); `plugin.yml` (edit: `/afk`); `P/KnKPlugin.java`
(edit: `startStatistics()`, menu feature registration in the `List.of(...)` before validation, `onDisable` flush/spool);
`P/commands/UserCommand.java` (edit: `settings` subcommand); `knk-paper/src/test/resources/menu/content-seeds.json`
(regenerated). API: `Models/Menu/MenuTemplateSeed.Statistics.cs` (new), `Models/Menu/MenuTemplateSeed.cs` (edit: chain),
`Models/Menu/MenuTemplateSeed.Content.cs` (edit: `profile.main` slot 6), any small API fixes found while wiring.

**Acceptance criteria**
1. With `statistics.enabled: false` no statistics listener, task or command is registered.
2. A session produces a start, duration slices (active/AFK) and an end; reconnects produce new sessions and logins; unknown
   user ids are queued and resolved; server stop ends sessions with `ServerStop` after a final flush.
3. AFK: auto after `idle-seconds`; retroactive idle window; `/afk` toggles; listed activity signals end AFK; vehicle/water
   movement and damage do not; tab marker applied and restored.
4. Distance per mode with the max-segment rule; teleports/world changes/AFK/creative/spectator excluded; highest survived
   fall only.
5. Flush every interval off the main thread; transient failure spools; replay succeeds after recovery; a duplicate reply
   deletes the spool file.
6. `statistics.visibility` menu validates at startup (`MenuDefinitionValidationRunner`), shows the five groups, cycles a
   setting, previews and applies a group action atomically, handles a 409 by refreshing and telling the player.
7. Gradle build green; new tests pass; baseline counts recorded (first executed plugin baseline of the chain).

**Tests:** `AfkTrackerTest`, `MovementClassifierTest`, `FallRuleTest`, `StatisticsBufferTest`, `StatisticsSpoolTest`,
`StatisticsRecorderTest`, `StatisticsApiImplTest` (pattern of the existing `*ApiImplTest`), `ConfigLoaderStatisticsTest`,
`StatisticsVisibilityMenuFeatureTest` (with `ContentSeedFixture`), `MovementStatisticsListenerTest`/
`AfkActivityListenerTest` (World mock held in a field), API `MenuTemplateContentSeedTests` still green.

### Link 4 — Combat, gates, Siege reconciliation (knk-plugin; API tests)

**Files:** plugin §5.2 link-4 rows and edits; config `statistics.combat|gates|siege`. API: tests only unless a gap appears
(`Tests/.../Services/SiegeMatchServiceTests` — a reported leaver keeps `LeftAt`, gets stats, no reward;
`SiegeStatisticsProjectorTests` — reconciliation: projected `pvp_kills@siege` equals participant kills incl. leavers).

**Acceptance criteria**
1. Damage dealt/received split player/mob, capped, `CUSTOM` excluded by default; contexts set; deaths with causes; PvE kills
   respect spawn-reason exclusions; arrows counted on shoot; headshots only where a multiplier applies.
2. Running-match members' PvP kills/deaths/streaks are not sent by the plugin (projection owns them).
3. Open-world killstreak: increments on PvP kills, resets on death and quit, recorded as max.
4. Gate damage = effective loss, credited to attacker / projectile shooter / TNT source; fire split per igniter; gate HP
   outcomes byte-for-byte identical to before (tests compare HP sequences with the sink on and off).
5. Departed Siege members are included in the completion payload with their stats; rewards unchanged; switch off restores
   today's payload.
6. Edits inside Siege/gate files are minimal and isolated; trunk merged first; build green.

**Tests:** `KillstreakTrackerTest`, `DeathCauseClassifierTest`, `CombatStatisticsRulesTest`, `GateFireAttributionTest`,
`HealthSystemEffectiveLossTest`, `GateFireSystemAttributionTest`, `SiegeServiceDepartedMembersTest`,
`CombatStatisticsListenerTest`.

### Link 5 — Read surfaces + leaderboards (knk-web-api, knk-plugin, knk-web-app)

**Files.** API: migration `AddLeaderboards`, `Models/Leaderboards/LeaderboardSnapshot.cs`, `LeaderboardSnapshotEntry.cs`,
`Enums/LeaderboardPeriod.cs`, `Services/Leaderboards/*`, `Controllers/LeaderboardsController.cs`,
`Controllers/PlayersController.cs`, `Dtos/LeaderboardDtos.cs`, `Dtos/PlayerProfileDtos.cs`, `Configuration/LeaderboardsOptions.cs`,
seeds for `statistics.main`, `statistics.leaderboards`, `statistics.leaderboard`, `profile.main` slot 5. Plugin: §5.2
link-5 rows, `plugin.yml` (`/leaderboard`), content-seeds regenerated. App: `src/types/dtos/statistics/StatisticsDtos.ts`,
`src/types/dtos/leaderboards/LeaderboardDtos.ts`, `src/apiClients/statisticsClient.ts`, `leaderboardClient.ts`,
`playerClient.ts`, `src/utils/enums.ts` (edit: `Statistics`, `Leaderboards`, `Players`), `src/components/statistics/
StatisticsOverview.tsx`, `StatisticBars.tsx`, `StatisticsVisibilitySettings.tsx`, `TitleHistoryList.tsx`,
`src/pages/statistics/MyStatisticsSection.tsx` (in `AccountManagementPage` when linked),
`src/pages/players/PublicPlayerProfilePage.tsx` (public route `/players/:username`),
`src/pages/leaderboards/LeaderboardsPage.tsx` (public route `/leaderboards`), `src/components/admin/
PlayerStatisticsPanel.tsx` (in `PlayerProfilePage`, self-gated by `knk.admin.statistics.view`), `src/App.tsx` and
`src/components/Navigation.tsx` (edits: routes, "Leaderboards" link).

**Acceptance criteria**
1. Snapshots refresh on the interval; eligibility (always-public, *everyone*, per-context, totals rule), exclusions,
   merged ids, repeat-victim cap, competition ranks with `reachedAt` tie order; reads never touch raw history.
2. Public profile endpoint exposes only the listed fields; no online/vanish leak.
3. In-game: `/stats [player]` and `statistics.main` show only what the API returns for that viewer; leaderboards menu shows
   top 10 + own rank; `/leaderboard`.
4. Web: own statistics with period tabs and bars; visibility settings incl. group action preview and conflict handling;
   public profile and leaderboards work signed-out (always-public only) and signed-in; staff panel hides on 403.
5. All three repos build; tests green vs. baseline.

**Tests:** API `LeaderboardEligibilityTests`, `LeaderboardSnapshotServiceTests`, `LeaderboardsControllerTests`,
`PlayersControllerTests`; plugin `StatisticsMenuFeatureTest`, `LeaderboardsMenuFeatureTest`, `UserCommandStatisticsTest`;
app `statisticsClient.test.ts`, `leaderboardClient.test.ts`, `MyStatisticsSection.test.tsx`,
`StatisticsVisibilitySettings.test.tsx`, `PublicPlayerProfilePage.test.tsx`, `LeaderboardsPage.test.tsx`,
`PlayerStatisticsPanel.test.tsx`.

### Link 6 — Diagnostic telemetry + privacy (knk-web-api, knk-plugin, knk-web-app)

**Files.** API: migration `AddDiagnosticTelemetryAndPrivacy`, `Models/Telemetry/*`, `Models/Privacy/PrivacyDeletionRequest.cs`,
`Enums/TelemetryOutcome.cs`, `Enums/PrivacyRequestStatus.cs`, `Enums/AuditAction.cs` (edit: `TelemetryViewed`,
`PrivacyDeletionRequested`, `PrivacyDeletionExecuted` — appended values), `Services/Telemetry/*`, `Services/Privacy/*`,
`Controllers/TelemetryController.cs`, `Controllers/PrivacyController.cs`, `Dtos/TelemetryDtos.cs`, `Dtos/PrivacyDtos.cs`,
`Configuration/DiagnosticTelemetryOptions.cs`, `Configuration/PrivacyOptions.cs`, `Middleware/ApiFailureTelemetryMiddleware.cs`,
`StatisticsController` (edit: `POST rebuild`). Plugin: §5.2 link-6 rows, config `telemetry:`. App: `src/components/OwnerRoute.tsx`,
`src/pages/owner/OwnerTelemetryPage.tsx` (`/owner/telemetry`: filters by player/time/session/test run/match, ordered
timeline, linked failures and ledger/match links, event detail drawer), `src/pages/owner/OwnerPrivacyPage.tsx`
(`/owner/privacy`), `src/apiClients/telemetryClient.ts`, `privacyClient.ts`, DTOs, nav entries gated by the owner nodes.

**Acceptance criteria**
1. Envelope validation and payload allowlists; no forbidden data (tests assert command arguments/chat never appear);
   dedupe by `eventId`; bounded queue drops with a metric and a `telemetry.dropped` record.
2. Plugin emitter covers every baseline family in §F.12 that has a hook; enhanced events only for configured users/test
   runs; telemetry I/O never on the main thread; `telemetry.enabled: false` = no emitter.
3. Owner endpoints: exact grant only; every timeline read audited.
4. GDPR: request → due date; execute deletes/pseudonymizes exactly the §F.14 scope (test per table) and is idempotent;
   auto-execution job respects its switch and lead days.
5. Retention jobs for telemetry; Siege first vertical slice (DESIGN "First vertical slice") reproducible in the live
   checklist.

**Tests:** API `TelemetryEventCatalogTests`, `TelemetryIngestionServiceTests`, `TelemetryWriteQueueTests`,
`TelemetryQueryServiceTests`, `PrivacyDeletionServiceTests`, `PrivacyDeletionDueServiceTests`, controller auth tests;
plugin `TelemetryBufferTest`, `TelemetryEmitterTest`, `MenuObserverTest`; app `OwnerTelemetryPage.test.tsx`,
`OwnerPrivacyPage.test.tsx`, client tests.

### Link 7 — World analytics + final write-up (all four)

**Files.** API: migration `AddWorldAnalytics`, `Models/WorldAnalytics/*`, `Services/WorldAnalytics/*`,
`Controllers/WorldAnalyticsController.cs`, `Dtos/WorldAnalyticsDtos.cs`, `Configuration/WorldAnalyticsOptions.cs`.
Plugin: §5.2 link-7 rows, config `world-analytics:`. App: `src/pages/owner/OwnerAnalyticsPage.tsx` (`/owner/analytics`:
heatmap canvas per world/date range, menu funnel table, domain interaction table), `src/components/owner/HeatmapCanvas.tsx`,
`src/apiClients/worldAnalyticsClient.ts`. Workspace: progress-report final summary, `docs/FEATURE_REGISTER.md`,
`docs/CHANGELOG.md` entry (unmerged branch noted), tracker to "Recently completed".

**Acceptance criteria**
1. Movement sampling excludes AFK/spectator; cells aggregated in memory and flushed every 5 min; no user ids stored.
2. Menu funnels from `MenuObserver`; domain interactions with unique players per day; owner-only reads.
3. Final write-up per charter §5 (decisions ranked, combined live checklist, merge order API → plugin → app, migrations
   first).

**Tests:** API `WorldAnalyticsIngestionServiceTests`, `WorldAnalyticsQueryServiceTests`; plugin `MovementCellGridTest`,
`DomainInteractionCounterTest`, `MenuFunnelRecorderTest`; app `OwnerAnalyticsPage.test.tsx`.

---

## 9. Risks

- **Siege/gate files under concurrent change** (Codex session, 2026-10-03): link 4 merges trunk first and keeps edits to
  `SiegeService`, `HealthSystem`, `GateFireSystem`, `GateDamageConsequenceListener` minimal; headshots are recomputed in a
  new listener rather than edited into `SiegeCombatListener`.
- **Menu seed is create-only:** new tiles on `profile.main` and new templates appear on an existing database only after the
  content-menu reset script (`scripts/reset-content-menus.ps1`) or a CRUD edit — in every live checklist.
- **MySQL-specific upserts** are only exercised by the MySQL-gated tests; InMemory covers logic.
- **Projection lag** means statistics from the ledger/Siege appear up to ~30-60 s later than the event.
- **Merged identity overlap** (L1-16) may slightly overstate playtime if two merged identities were online simultaneously.
- **Link 5 spans three repos** — if it cannot finish, the staff panel and leaderboard web page move to link 6 (charter §0),
  recorded in the report.

---

## Phase status

| Link | State | Notes |
|---|---|---|
| 1 | done 2026-10-03 | This plan, finalized DESIGN §F, source audit. Docs only. |
| 2 | done 2026-10-03 | knk-web-api `claude/kind-dijkstra-y9d279` `b13ff0c`; see "Link 2 status" below. |
| 3 | done 2026-10-03 | knk-plugin `claude/kind-dijkstra-y9d279` `e75d9b7`, knk-web-api `c95572a`; see "Link 3 status" below. |
| 4 | done 2026-10-03 | knk-plugin `claude/kind-dijkstra-y9d279` `65a0e7d`, knk-web-api `12ae516`; see "Link 4 status" below. |
| 5 | done 2026-10-03 | knk-web-api `2dec32b`, knk-plugin `5481327`, knk-web-app `00d978e`; see "Link 5 status" below. |
| 6 | pending | |
| 7 | pending | |

### Link 2 status (2026-10-03)

Delivered as §1.1, §2, §3.1, §4 (link-2 rows) and §6 describe; migration `20261003023630_AddPlayerStatistics`.
Tests: 179 new (1,839 total; the same 5 pre-existing failures as trunk); 9 of them MySQL-gated and green on MySQL 8.

**Acceptance criterion → tests:** 1 `Migrations/AddPlayerStatisticsTests`, full suite; 2
`StatisticsIngestionServiceTests`, `MySql/StatisticsUpsertMySqlTests`; 3 `StatisticsPeriodsTests`; 4
`LedgerStatisticsProjectorTests`; 5 `SiegeStatisticsProjectorTests`; 6 `StatisticsVisibilityServiceTests`; 7
`StatisticsQueryServiceTests`, `Api/StatisticsControllerAuthTests`; 8 `Api/RequireOwnerPermissionAttributeTests`; 9
`Api/StatisticsControllerAuthTests` (503) + live smoke (jobs idle); 10 `LedgerStatisticsClassifierTests`
(`CurrencyWriteGuardTests` unchanged and green).

**Public shape changes vs. this plan** (progress report L2-n):
- `StatisticMetricDefinition`: `PluginInput` (`None|Counter|Record|Duration|PvpKill` — which batch list may carry the
  metric) and `ProjectionOwnedContexts` replace `PluginWritableContexts` (L2-7). `first_joined`, the discovery list and
  title history are not metric rows (profile field / settings `discoveries.list`, `title_history`).
- Rejection codes add `UnknownUser` and `InvalidEntry` (L2-2).
- `PlayerStatisticMetricDto.value`/`rawValue` are nullable: null when the total is hidden but some contexts are visible
  (L2-5). `profile` playtime is lifetime (L2-6). `StatisticsCatalogDto` adds `contexts` (known context keys).
- `StatisticsVisibilityContextDto.isOverride`; extra 400 codes `TooManyChanges`, `DuplicateChange`,
  `InvalidVisibility`; the 409 body is `{ error: "VisibilityConflict", message, current: StatisticsVisibilityDto }` (L2-9).
- Config adds `Statistics:FutureToleranceSeconds` (300) and `Statistics:ProjectionSafetyLagSeconds` (10).
- `IStatisticsRebuildService.RebuildAsync(projection: "ledger"|"siege"|"all", userId?)` is ready for link 6's
  `POST api/statistics/rebuild`.

### Link 3 status (2026-10-03)

Delivered as §5.1, §5.2 (link-3 rows) and §5.3 describe. knk-plugin: knk-core `statistics/` (`StatisticsMetric`,
`StatisticsContext`, `StatisticsBuffer`, `StatisticsSessions`, `AfkTracker`, `MovementClassifier`, `FallRule`,
`StatisticsSpool`, `StatisticsRecorder`), `domain/statistics/` (`StatisticsBatch`, `StatisticsBatchResult`,
`StatisticsCatalog`, `StatisticsVisibilitySettings`, `StatisticVisibility`, `StatisticsVisibilityConflictException`),
`ports/api/StatisticsApi`; knk-api-client `StatisticsApiImpl`, `StatisticsDtos`, `StatisticsMapper`
(`KnkApiClient.getStatisticsApi()`); knk-paper `statistics/` (`StatisticsService`, `StatisticsContextResolver`,
`StatisticsSessionListener`, `AfkActivityListener`, `AfkPresentation`, `MovementStatisticsListener`,
`FallStatisticsListener`, `StatisticsFlushTask`), `commands/AfkCommand`, `menu/content/StatisticsVisibilityMenuFeature`
(+ `StatisticsVisibilityView`, `StatisticsVisibilityRow`), `UserCommand` `/stats settings`, `KnkConfig.StatisticsConfig`
+ `ConfigLoader.loadStatistics`, `config.yml` `statistics:`, `plugin.yml` `/afk`, `KnKPlugin.startStatistics()`.
knk-web-api: `Models/Menu/MenuTemplateSeed.Statistics.cs`, `profile.main` header slot 6.

**Acceptance criterion → tests:** 1 `KnKPlugin.startStatistics` returns before any registration (code review; no Paper
runtime in the cloud) + `ConfigLoaderStatisticsTest`; 2 `StatisticsSessionsTest`, `StatisticsListenersTest` (kick, server
stop, unresolved ids); 3 `AfkTrackerTest`, `StatisticsListenersTest` (signals, throttle, vehicle/water, pressure plates,
`/afk`); 4 `MovementAndFallRuleTest`, `StatisticsListenersTest` (modes, max segment, world change, creative, AFK, falls);
5 `StatisticsBufferTest`, `StatisticsRecorderTest`, `StatisticsSpoolTest` + live smoke against the API (duplicate
reply, replay); 6 `StatisticsVisibilityMenuFeatureTest` (seed validation via `ContentSeedFixture`, groups, cycle, group
preview/confirm/apply, 409), API `MenuTemplateStatisticsSeedTests`; 7 Gradle build green, counts in the progress report.

**Public shape changes vs. this plan** (progress report L3-n):
- `MovementClassifier.classify(inVehicle, gliding, flying, swimming, length, max)` returns a nullable `Mode`
  (`FOOT`/`SWIM`/`FLYING`/`VEHICLE`) instead of `Optional<MovementMode>`; `FallRule.survivedFall` returns `OptionalDouble`.
- New pure `C/statistics/StatisticsSessions` holds the per-player session/AFK/movement state under
  `P/statistics/StatisticsService`.
- `StatisticsApi` has `postBatch`, `getCatalog`, `getVisibility`, `updateVisibility`; `getUserStatistics` and
  `getTitleHistory` are added by link 5 (first consumer).
- `StatisticsService` hooks for link 4: `addCounter(Player, metric, value)`, `addRecord(Player, metric, value)`,
  `pvpKill(killer, victim)`, `contextOf(Player)`, `buffer()`; `KnKPlugin#getStatisticsService()` (null when disabled).
- `statistics.visibility` actions/condition: `statistics.visibility.select-group|cycle|group|apply-group`,
  `statistics.visibility.pending`; root `statsvis`; Confirm/Cancel at slots 48/50.
- Config adds nothing beyond §5.1; `statistics.combat|gates|siege` are link 4's to add to `StatisticsConfig`.

### Link 4 status (2026-10-03)

Delivered as §5.1 (`statistics.combat|gates|siege`), §5.2 (link-4 rows and edits) and §8 link 4 describe. knk-plugin:
knk-core `statistics/KillstreakTracker`, `DeathCauseClassifier`, `CombatStatisticsRules`, `gates/GateFireAttribution`,
`siege/SiegeDepartedMembers`, `ParticipantResult.leftAt` (+ result spool, api-client DTO/mapper); knk-paper
`statistics/CombatStatisticsListener`, `statistics/GateDamageStatisticsSink`, `gates/GateDamageSink` (default no-op),
`StatisticsService.addCounter(UUID, metric, context, value)` + `userIdOf(UUID)`, minimal edits in `HealthSystem`
(returns the effective loss), `GateFireSystem` (igniter per burning block, `setDamageSink`, 3-arg `igniteBlock`),
`GateDamageConsequenceListener` (sink constructor), `SiegeService` (`setReportDepartedMembers`, departed members kept per
match and appended in `completion()`), `KnkConfig`/`ConfigLoader`/`config.yml`, `KnKPlugin` wiring. knk-web-api:
`SiegeMatchParticipantResultDto.leftAt` + `SiegeMatchService.CompleteAsync` (first left marker wins, kept before the end).

**Acceptance criterion → tests:** 1 `CombatStatisticsRulesTest`, `DeathCauseClassifierTest`, `CombatStatisticsListenerTest`
(damage split/cap/CUSTOM/excluded modes/contexts, headshots, causes, PvE filter, arrows); 2 `CombatStatisticsListenerTest`
(running-match members); 3 `KillstreakTrackerTest`, `CombatStatisticsListenerTest` (streak, death, quit); 4
`GateFireAttributionTest`, `HealthSystemEffectiveLossTest`, `GateFireSystemAttributionTest` (HP sequences identical with the
sink on and off), `GateDamageConsequenceListenerTest`, `CombatStatisticsListenerTest` (sink: attacker/shooter/TNT source,
gate context, offline igniter); 5 `SiegeDepartedMembersTest`, `SiegeResultSpoolTest`, `SiegeMatchesCommandApiImplTest`
(`leftAt` omitted for present members), API `SiegeMatchServiceTests` (reported leaver keeps `LeftAt`, gets stats, no reward;
lost left call; clock skew; complete → projection reconciliation incl. leavers); 6 Gradle build green, trunks unchanged.

**Public shape changes vs. this plan** (progress report L4-n):
- API `SiegeMatchParticipantResultDto` gains optional `leftAt` (L4-2) — the plan said "tests only unless a gap appears";
  without it a departed member whose `left` call was lost would have been rewarded as present.
- `ParticipantResult` (knk-core) gains `leftAt` with a 6-argument constructor for present members.
- The departed-member logic is the pure `C/siege/SiegeDepartedMembers` tested by `SiegeDepartedMembersTest`; there is no
  `SiegeServiceDepartedMembersTest` (SiegeService can't be constructed in a unit test; its edit is 18 lines).
- `GateDamageSink` methods: `directDamage(gate, causingEntity, loss)`, `tracksFire()`, `igniterOf(entity)`,
  `fireDamage(gate, igniter, loss)` (attacker resolution lives in the statistics sink, not in the gate listener).

### Link 5 status (2026-10-03)

Delivered as §1.2, §3.2, §4 (link-5 row), §5.2 (link-5 rows), §5.3 and §8 link 5 describe; migration
`20261003040910_AddLeaderboards`. knk-web-api: `Models/Leaderboards/*`, `Enums/LeaderboardPeriod`,
`Configuration/LeaderboardsOptions`, `Properties/KnKDbContext.Leaderboards.cs`, `Services/Leaderboards/`
(`LeaderboardCatalog`, `LeaderboardEligibility`, `LeaderboardSnapshotBuilder`, `LeaderboardSnapshotService`,
`LeaderboardQueryService`), `Repositories/LeaderboardRepository`, `LeaderboardsController`, `PlayersController`,
`Dtos/LeaderboardDtos.cs`, `Dtos/PlayerProfileDtos.cs`, menu seeds in `MenuTemplateSeed.Statistics.cs` + `profile.main`
slot 5. knk-plugin: knk-core `domain/statistics/PlayerStatistics`, `TitleChange`, `domain/leaderboards/*`,
`ports/api/LeaderboardsApi`, `statistics/StatisticsLines`; api-client `LeaderboardsApiImpl` + DTOs/mappers, statistics
reads; knk-paper `StatisticsMenuFeature`, `LeaderboardsMenuFeature` (+ views/rows), `LeaderboardCommand`, `UserCommand`
lines. knk-web-app: clients, DTOs, `components/statistics/*`, `MyStatisticsSection`, `PublicPlayerProfilePage`,
`LeaderboardsPage`, `PlayerStatisticsPanel`, routes and nav.

**Acceptance criterion → tests:** 1 `LeaderboardEligibilityTests` (eligibility per board kind, merges, values, ranks),
`LeaderboardSnapshotServiceTests` (periods, lifetime, exclusions, inactive/merged, replacement + closed period +
retention, cap end to end), `MySql/LeaderboardMySqlTests`; 2 `PlayersControllerTests` (+ live smoke); 3
`StatisticsMenuFeatureTest`, `LeaderboardsMenuFeatureTest`, `UserCommandStatisticsTest`, `LeaderboardCommandTest`,
`MenuTemplateStatisticsSeedTests`; 4 `MyStatisticsSection.test`, `StatisticsVisibilitySettings.test`,
`PublicPlayerProfilePage.test`, `LeaderboardsPage.test`, `PlayerStatisticsPanel.test`, client tests,
`LeaderboardsControllerTests` (anonymous vs signed-in); 5 all three repos build, tests green vs baseline.

**Public shape changes vs. this plan** (progress report L5-n):
- Internal metric `pvp_kills.ranked` (contextual, `PluginInput.None`, never returned) maintained by ingestion — the
  repeat-victim cap input for every period (L5-2); `StatisticsIngestionService` takes optional `LeaderboardsOptions`.
- `LeaderboardBoardDto.alwaysPublic`; `LeaderboardViewDto.label`, `.unit`; `generatedAt` nullable (no snapshot yet);
  anonymous reads of configurable boards → 401 `SignInRequired` (L5-4). `LeaderboardExclusionRequestDto { reason }`.
- `IStatisticsQueryService.GetPublicProfileAsync(username)` backs `PlayersController`; `IStatisticsRepository` adds
  `GetUserByUsernameAsync`, `GetKillPairCountsAsync`.
- Plugin: no `ProfileView.getStatisticsLines()` — knk-core `StatisticsLines` (L5-13); `StatisticsApi.getUserStatistics(
  userId, Integer actingUserId, period, LocalDate date)`, `getTitleHistory(userId, Integer actingUserId, page, pageSize)`;
  menu context keys `ctx.target`/`ctx.name` (`statistics.main`) and `ctx.board` (`statistics.leaderboard`); row sources
  `statistics.main.title-history`, `statistics.leaderboards.boards`, `statistics.leaderboard.entries`; roots `stats`, `lb`;
  actions `statistics.main.period`, `statistics.leaderboard.period`.
- Web: `PublicPlayerProfileDto` lives in `types/dtos/statistics/StatisticsDtos.ts` (no separate players DTO file).
