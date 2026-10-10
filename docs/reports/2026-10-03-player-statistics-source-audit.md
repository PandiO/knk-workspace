# Player statistics — V1/V2/V3 source audit (KNG-34 link 1)

**Status:** Final (dated audit — not updated in place; a new scan gets a new dated file)
**Last updated:** 2026-10-03
**Linear:** [KNG-34](https://linear.app/kngpandi/issue/KNG-34), [KNG-14](https://linear.app/kngpandi/issue/KNG-14), [KNG-23](https://linear.app/kngpandi/issue/KNG-23)
**Feeds:** [`specs/player-statistics/DESIGN.md`](../specs/player-statistics/DESIGN.md) (finalized design) and
[`specs/player-statistics/IMPLEMENTATION_PLAN.md`](../specs/player-statistics/IMPLEMENTATION_PLAN.md)

Read-only scan of these revisions:

| Repo | Revision | Notes |
|---|---|---|
| knk-web-api | `master` `ae0b3ad` | Same as the chain start |
| knk-plugin | `main` `db474e4` | Trunk moved since the chain start (`27b4236`): KNG-28 siege safe-zone combat tests (Codex session) |
| knk-web-app | `main` `fc66101` | Same as the chain start |
| knk-v1-archive | `master` `4117e7e` | Bukkit 1.8 plugin, MySQL over JDBC (**not** flat files, unlike older notes) |
| knk-v2-archive | `main` `400e5c8` | Spigot 1.16, Hibernate |

Path shorthands. Plugin: **P** = `knk-paper/src/main/java/net/knightsandkings/knk/paper`, **C** = `knk-core/src/main/java/net/knightsandkings/knk/core`,
**A** = `knk-api-client/src/main/java/net/knightsandkings/knk/api`. API paths are relative to the repo root.
`v1:` paths are relative to `knk-v1-archive`; `v2:` paths are relative to `knk-v2-archive/src/main/java/net/knightsandkings/` unless they start with `src/`.

## 1. Corrections to the chain-start snapshot (charter §9)

| Snapshot claim | Actual | Evidence |
|---|---|---|
| PM batch route `POST api/PrivateMessageLog/batch` | `POST api/private-message-log/batch` | `Controllers/PrivateMessageLogController.cs:15,31` |
| snake_case tables via `ToTable` | Only **table** names are snake_case, set by hand per entity; columns stay PascalCase | `Properties/KnKDbContext.cs:201,2163,485` |
| Title changes reachable from one XP hook | No central post-XP hook; each XP path runs title progression itself (siege `SiegeMatchService.cs:299`, discovery `DiscoveryService.cs:342`, staff adjust `UserService.cs:827`, reversal `CurrencyAdminService.cs:145`, merge `UserService.cs:1101`). The ledger write itself is at `Services/Currency/CurrencyService.cs:486` (`afterPost` hook at :487-491) | as cited |
| `HighestKillStreak` — "check what the plugin fills in" | The plugin **already computes** a per-match streak: `SiegeMatchRoster.recordDeath` resets the victim's streak, credits same-roster killers, `highestKillStreak = max(...)` | `C/siege/SiegeMatchRoster.java:153-172` |
| (not in snapshot) | **A player who leaves a Siege mid-match loses their match stats**: `removeMember` drops them from the roster (the returned `MemberView` is discarded) and `completion()` is built from the remaining roster; `participantLeft` only sends `leftAt` | `P/siege/SiegeService.java:796-800, 627-632` |
| (not in snapshot) | The Siege match id is not public to other plugin code (`SiegeLobbyRuntime.matchIdFuture()` / `userIds()` package-private); `matchToken()` and `SiegeService.runningMatchOf(uuid)` are public; no `SiegeMatchObserver` callback carries the match id or the result | `P/siege/SiegeLobbyRuntime.java:90,100,109`; `P/siege/SiegeService.java:1530-1535`; `P/siege/SiegeMatchObserver.java` |
| `HealthSystem.applyDamage` effective loss | Both `applyDamage` and `applyContinuousDamage` return `void`; effective loss is `old - max(0, old - amount)` and never exposed | `P/gates/HealthSystem.java:61-94, 109-123` |
| No `navigation.walk` mentioned as kill-switch pattern | (Charter didn't claim it; the plugin audit brief did.) The kill-switch pattern to copy is `discovery.enabled` (`DiscoveryConfig` + `ConfigLoader.loadDiscovery`) | `P/config/KnkConfig.java:409-490`; `P/config/ConfigLoader.java:161-200`; `src/main/resources/config.yml:164-199` |
| Owner node prefix | Confirmed: in `PermissionResolutionService.TryMatch` a bare `*` grant matches **every** node and `knk.*` matches `knk.owner.x`; matching is ordinal/case-sensitive; there is **no** op/owner bypass. No migration or seed grants `*` today. `ActiveMode.Owner` only affects vanish | `Services/PermissionResolutionService.cs:66-95`; `Models/User.cs:121,293-309` |
| Web-app permission check | `GET api/Users/{id}/permissions/check` (and `/permissions/effective`, `GET api/Users`, `GET api/Users/{id}`, the Siege match GETs) carry **no auth attribute** and there is no global fallback policy → anonymous | `Controllers/UsersController.cs:190-247`; `Program.cs:151-160` |
| `Telemetry` config section is free | `appsettings.json` already has a `Telemetry` section (OpenTelemetry exporter). KNG-34 diagnostics need a different name | `appsettings.json:44` |

## 2. V2 `UserStatistics` / `UserStatisticsDaily`

**Storage.** `user_statistics` (`v2:model/user/UserStatistics.java:36-39`), PK = the user's UUID shared with `User`
via `@MapsId` (:56-64). `UserStatisticsDaily` (`user_statistics_daily`) *extends* it (`v2:model/user/UserStatisticsDaily.java:21-26`),
so it inherits the same PK: **at most one daily row per user, no per-day history**. The parent's `dailyStatistics` link is
`@Transient` (`UserStatistics.java:66-69`) and nothing saves the daily entity → **daily stats were memory-only and lost on
restart**. The day boundary was checked only inside `User.login()` with `ZoneId.systemDefault()`
(`UserStatisticsDaily.java:41-49`, `User.java:513-520`): a player online past midnight kept adding to yesterday. Lifetime
stats were saved on quit (`v2:listeners/PlayerListener.java:144-156`); the shutdown `saveAll()` is scheduled inside
`onDisable` (`v2:KNK.java:339-349`) and most likely never ran.

| Field | Written at | What it actually measured |
|---|---|---|
| `logins` | `v2:model/user/User.java:521` (async `PlayerLoginEvent`) | Every login **attempt**, including later-refused ones |
| `cashEarned` | `v2:model/minigame/siege/Siege.java:959` | Siege end reward only |
| `cashSpent` | — | **Never written** |
| `kills` | `v2:listeners/PlayerListener.java:309` | Every PvP kill anywhere (superset of `minigameKills`) |
| `minigameKills` / `siegeKills` | `v2:model/minigame/MGMember.java:236,238` | Identical in practice (Siege was the only minigame) |
| `deaths` | `v2:listeners/PlayerListener.java:313` | **Bug:** `killer.getName()` without null check at :282 → only deaths **by a player** were counted |
| `minigameDeaths` / `siegeDeaths` | `v2:model/minigame/MGMember.java:309,311` | Siege deaths |
| `minigameWins`, `siegeWins`, `minigameLosses`, `siegeLosses`, `objectivesCaptured`, `gateDamage` | — | **Never written** (gate hits existed but never fed the stat: `v2:listeners/ProjectileListener.java:64-72`) |
| `arrowsFired` | `v2:listeners/ProjectileListener.java:60` | Counted on **hit** (`ProjectileHitEvent`), not on shoot |
| `headshots` | `v2:listeners/EntityListener.java:131` | Projectile Y > victim feet + 1.33 (:66-72, 174-179) |
| `damageDealt` | `v2:listeners/EntityListener.java:150` | Raw pre-armour **PvP** damage only |
| `damageReceived` | `v2:listeners/EntityListener.java:148` | Post-armour damage from any entity (mobs included), no environment |
| `distanceTraveled` | `v2:listeners/PlayerListener.java:392-406` | **+1 per block-coordinate change**, teleports included, vehicles excluded — not a distance |
| `highestFall` | `v2:listeners/EntityListener.java:156-170` | `getFallDistance()` in blocks when fall damage fired; **lethal falls included** |
| `highestKillstreak` | `v2:model/minigame/MGMember.java:273` | Recorded only on the member's death; a streak running at match end was never recorded |

**Display:** only `/user statistics|stats <uuid>` (perm `k&k.user.statistics`), a raw `toString()` line
(`v2:spigot/command/user/UserCommand.java:103-115`). Players could not see their own stats.

## 3. V1 statistics

All on MySQL table `Player` (load `v1:src/Users/User.java:258-333`, save :373-420).

| Counter | State |
|---|---|
| Kills (PvP), Deaths | Work (`v1:src/Listeners/PlayerListener.java:1018-1038`) |
| Bandit kills, blocks broken (overall/wood/wheat/stone/ore, + today each) | **Dead** — no live callers (`v1:src/Minigames/BanditKill.java:127` commented; `User.addblocksBroken` :2123-2147 uncalled) |
| Fish caught | Half-broken: only the "today" column grows (`v1:src/Minigames/FishGame.java:56-69`) |
| Playtime / playtime today | **Broken**: overall and today are swapped on every quit (`v1:src/Listeners/PlayerListener.java:298-306`; getter/setter flag mismatch `User.java:1222-1231` vs :2467-2476) |
| Join date | Works (`v1:src/Main/Main.java:926-931`) — V1's "first joined" |
| Last login | Date only (`User.java:412`); used to evict room renters after 7 days |
| Daily reset | 00:01 Europe/Amsterdam ticker (`v1:src/Main/Main.java:1115-1122, 1426-1429`), DB-only (online players wrote yesterday back), and zeroed lifetime wheat instead of today's (`v1:src/Users/Users.java:308`) |

`/stats [player]` (`v1:src/Users/StatsCommands.java:21-50`) had **no permission**: anyone could view anyone's
username, title, XP, first join, playtime, kills, deaths, coins, gems, friends.

## 4. AFK — V1 and V2

**V2 has no AFK code.** **V1** (all hard-coded, no config file exists in either repo):

| Aspect | V1 behaviour | Evidence |
|---|---|---|
| Command | `/afk` toggle, no permission, no alias | `v1:plugin.yml:167-168`; `v1:src/Afk/AfkCommand.java:22-53` |
| Auto AFK | After `afkTime = 300` s without activity; 1 s checker task | `v1:src/Main/Main.java:251, 1160-1166` |
| Activity that resets the timer / ends AFK | Any `PlayerMoveEvent` (including pure head rotation and being pushed by water/pistons), chat, **taking damage** | `v1:src/Listeners/PlayerListener.java:312-352, 981-990`; `v1:src/Listeners/EntityListener.java:432-441` |
| Not counted as activity | Commands, block/entity interaction, inventory clicks | (no hooks) |
| Effects | Private "You are now AFK" message; tab/name-tag prefix `§7§oAFK - ` (scoreboard team); floating "Z"/"Zz" armour stands; **removed from an active Siege / Hide-and-Seek**; shopkeeper NPCs opened a random product menu on AFK players | `v1:src/Afk/Afk.java:36-90`; `v1:src/Scoreboards/Scoreboard.java:95-97`; `v1:src/Users/User.java:782-794`; `v1:src/Traits/Shopkeeper.java:376-395` |
| Not present | Broadcast, invulnerability, kick, exclusion from salary or playtime, anti-AFK-pool logic, persistence | `v1:src/Currency/SalaryPayout.java:28-53` |
| Dead code | All `AfkEvents` handlers commented out; AFK spawn teleport and the "teleporting" flag dead | `v1:src/Afk/AfkEvents.java:28-195`; `v1:src/Afk/Afk.java:41-47` |
| "AFK/settings menu" | **No AFK menu exists.** The personal menu's "Settings" lever (slot 16) has no click handler, nor do Knowledge and Pets/Servants | `v1:src/Menu/Menu.java:105,219,223,236`; `v1:src/Menu/MenuClick.java:88-289` |

## 5. Killstreaks, headshots, playtime in legacy

- **Killstreaks (V2 only):** per Siege member; team broadcast above 3 (bug: printed total kills); milestones at 5/10/15
  kills; reset on own death; no rewards (`v2:model/minigame/MGMember.java:225-276, 352-358`).
- **Headshots (V2):** same 1.33-block rule as V3's `SiegeCombatRules.isHeadshot` (`C/siege/SiegeCombatRules.java:61-66`).
- **Playtime:** V1 broken (above); V2's `UserLogin` session record was cache-only and effectively never persisted
  (`v2:model/user/UserLogin.java:66-80`).

## 6. V3 — what exists per candidate metric

| Metric | Exists in V3 today | Missing / to build |
|---|---|---|
| First joined | No first-join field. Proxies: `User.CreatedAt` when `AccountCreatedVia == MinecraftServer` (account auto-created on first join, `Models/User.cs:42,104,282`; `Services/UserService.cs:172-174`), the `SIGNUP_GRANT` ledger row, the first-join kit claim | Web-first accounts' link time is not recorded; session store |
| Logins, sessions, active/AFK playtime | Only `IsOnline` + `LastSeenAt` overwritten by `PUT api/users/{id}/presence` (plugin-only, no audit, `Controllers/UsersController.cs:632-650`, `Repositories/UserRepository.cs:164-173`) | Everything: sessions, AFK detection, accrual |
| XP / coins / gems history | **Complete ledger**: `currency_transactions` + `currency_entries` (before/after, op, amount, reason code, initiator, idempotency, correlation), immutable via triggers, outside audit retention. No coin/gem/XP write bypasses it (EF ignores the balance columns, `Tests/.../Architecture/CurrencyWriteGuardTests.cs` guards assignments, `Repositories/CurrencyRepository.cs:66-101` is the only physical write) | Period aggregates; earned/spent classification; XP-gained aggregates |
| Coins/gems earned & spent | All 21 reason codes carry a direction (`Services/Currency/CurrencyReasons.cs:132-154`); `LOOTBOX_REWARD`, `LOOTBOX_PURCHASE`, `EVENT_REWARD`, `PREMIUM_TOPUP` are defined but never posted | Classification table (DESIGN §F.5) |
| Title history | Derived current title (`Services/TitleService.cs:19-54`); `AuditAction.TitleChanged` rows (`Services/Currency/TitleProgressionService.cs:97`) purged after 180 days | Durable title-change store (derivable from XP ledger legs: every XP leg has BalanceBefore/After) |
| Siege W/L/D, kills, deaths, streak, captures | `siege_matches` (`Status`, `WinningAllianceGroup` null = draw/abort), `siege_match_participants` (`Kills`, `Deaths`, `HighestKillStreak`, `Captures`, `LeftAt`), alliance via `SiegeTeamId → SiegeTeam.AllianceGroup` (`Models/Siege/*`; `Services/SiegeMatchService.cs:157-356`) | Leaver stats (plugin gap §1); per-period aggregation; no explicit leaver flag (leaver = `LeftAt < EndedAt`; unreported rows get `LeftAt == EndedAt`) |
| PvP/PvE kills, deaths outside Siege | `PlayerListener.onPlayerDeath` is a stub (`P/listeners/PlayerListener.java:346-351`); no `EntityDeathEvent` listener | Everything |
| Damage dealt/received | Observing pattern: `CombatTagListener.onDamage` MONITOR/ignoreCancelled (`P/listeners/CombatTagListener.java:29-51`). Chaos/FlashChaos enchants fire synthetic `CUSTOM` damage events (`P/enchantment/effects/impl/ChaosEffect.java:75-82`) | Everything |
| Arrows, headshots | Headshot rule only inside `SiegeCombatListener` (siege, multiplier > 1; `P/listeners/SiegeCombatListener.java:64-70`); no `EntityShootBowEvent`/`ProjectileLaunchEvent` listener | Everything (headshot can be recomputed from `SiegeCombatRules` in a separate listener) |
| Gate damage | `GateDoorDamageEvent` / `GateDoorIgniteEvent` with `causingEntity`; flat 10 per hit in `GateDamageConsequenceListener` (`P/listeners/GateDamageConsequenceListener.java:20-52`); fire stored as `Map<Vector, Long>` expiry only (`C/domain/gates/CachedGateDoor.java:163`; `P/gates/GateFireSystem.java:54-108`); explosions credited to the TNT/creeper entity | Effective-loss return value, igniter per burning block, TNT source resolution |
| Distance, highest fall | No `VehicleMoveEvent`, no fall handling, no distance counter. Move listeners: discovery (same-block early-out), WorldGuard tracker (no early-out) (`P/discovery/DomainDiscoveryListener.java:94-102`; `P/regions/WorldGuardRegionTracker.java:89-110`) | Everything |
| Discoveries | `user_domain_discoveries` (unique user+domain, `DiscoveredAt`); reads are plugin/self/staff only (`Controllers/DiscoveriesController.cs:96-166`); summary does **not** aggregate merged accounts (`Services/DiscoveryService.cs:420-441`) | Per-visibility read path for other players; merged-id aggregation |
| `/user statistics` (KNG-9) | `P/commands/UserCommand.java:151-171`, `/stats` shortcut; `ProfileView.getQuickStatsLines` (`P/menu/content/ProfileView.java:136-157`) — Javadoc flags gameplay counters as the KNG-14 gap (:42-45) | Lines for new statistics |
| Leaderboards | Only `/baltop`: `GET api/currency/leaderboard` (coins/gems, `knk.baltop`, 60 s in-memory cache, live query, ties get different ranks; `Controllers/CurrencyController.cs:94-121`; `Repositories/CurrencyRepository.cs:208-238`) | Snapshot store, boards, eligibility |
| Diagnostic telemetry | OTel meters (`Knk.Currency`, lootbox) via OTLP; **no Prometheus `/metrics`** (`Program.cs:100-127, 200`); `OBSERVABILITY.md:36-39` forbids player ids in labels | Event store, ingestion, owner UI |
| Owner permission | Only `ActiveMode.Owner` (vanish) and plugin node `knk.mode.owner` (`P/modes/ModeService.java:48`) | Dedicated nodes + exact-grant enforcement |
| GDPR | None. `DELETE api/users/{id}` hard-deletes but returns 409 whenever ledger history exists (every account has `SIGNUP_GRANT`) (`Services/UserService.cs:469-488`); nothing purges `ArchiveUntil` | Deletion workflow |
| Web read surfaces | `/account` with `MyDiscoveriesSection` (`src/pages/AccountManagementPage.tsx:217`), staff `/admin/users/:id`; no public player page, no username lookup endpoint, no chart library, no i18n | Pages, public profile endpoint |

## 7. Reusable patterns (verified)

- **Batch + spool:** plugin `DiscoverySpool` (one JSON file per player, atomic temp+move), `DiscoveryRecorder` (RetryPolicy,
  spool on transient failure, batches of 50), `DiscoveryFlushTask` (main-thread flush every 20 ticks, async I/O, replay every
  60 s, `spoolEverything()` on disable) (`C/discovery/*`, `P/discovery/DiscoveryFlushTask.java`). API batch ingest:
  `PrivateMessageLogService` (max 200, all-or-nothing validation, dedupe on client id with one retry on a unique-index race;
  `Services/PrivateMessageLogService.cs:13-89`, `Repositories/PrivateMessageLogRepository.cs:18-50`).
- **Background jobs:** `BackgroundService` + `PeriodicTimer` + scope per cycle (`Services/Currency/CurrencyMonitorService.cs:28-88`),
  registered in `DependencyInjection/ServiceCollectionExtensions.cs:188-203`; options POCOs with `SectionName`.
- **Merged accounts:** `ICurrencyService.GetMergedAccountIdsAsync` (BFS over `MERGE_FORFEIT`, `Services/Currency/CurrencyService.cs:365-382`).
- **Menus:** `MenuFeature` list (`P/KnKPlugin.java:653-680`, locked at :717); seed is create-only by key
  (`Models/Menu/MenuTemplateSeed.cs`), test mirror `knk-paper/src/test/resources/menu/content-seeds.json` regenerated by the API
  test `MenuTemplateContentSeedTests.ContentSeeds_ExportAsApiJson`; `profile.main` header slots 3, 5, 6, 7 are free;
  confirmation via `MenuSession.PendingConfirmation` (`C/menu/MenuSession.java:397-411`).
- **Plugin identity:** session start = `UserDataLoadedEvent` (main thread, `userId` may be null when the API was down;
  `P/listeners/UserAccountListener.java:150`); UUID → id via `UserCache.getStale` (`P/permissions/KnkPermissible.java:127-133`).
- **Salary:** `SalaryPayoutScheduler` pays "hours since last payout" server-side (`P/user/SalaryPayoutScheduler.java:31-36`),
  so skipping AFK checks plugin-side would only delay the money — an AFK salary rule needs an API contract change.
- **Tests:** API 1,299 `[Fact]/[Theory]` attributes in 116 files (EF InMemory, hand-wired services); plugin `@Test` counts
  knk-core 880, knk-api-client 141, knk-paper 1030 (static counts — executed baselines are recorded by links 2/3); plugin
  World-mock rule (`knk-plugin/CLAUDE.md`).

## 8. Conclusions carried into the design

1. Nothing in V1/V2 is backfillable: V2 daily stats were never persisted and V1 playtime is corrupted — consistent with D6.
2. V1 had an explicit `/afk` toggle → per the chain default, V3 gets `/afk` **and** automatic detection; V1's noisy
   signals (head rotation, passive pushes, damage) are not reused as-is (DESIGN §F.2).
3. The ledger already satisfies KNG-23 / D13 for XP; title history can be **derived from XP ledger legs** without touching
   currency code.
4. Siege match tables are authoritative for match outcome metrics; the plugin's leaver gap must be fixed (link 4) so
   "leaving counts as a loss" (D1) and the leaver's kills are not lost.
5. Owner-only data needs **exact-grant** enforcement because `*` / `knk.*` wildcards would otherwise match `knk.owner.*`.
6. Gate damage and fire attribution are new work around `HealthSystem` / `GateFireSystem`, keeping outcomes identical.
