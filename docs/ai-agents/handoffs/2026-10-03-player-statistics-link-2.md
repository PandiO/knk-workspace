# Player statistics chain — link 2 handoff

**Date:** 2026-10-03 · **Written by:** link 1 (`session_015g7iripYBsgLJUPKZivR5s`) · **Linear:** [KNG-34](https://linear.app/kngpandi/issue/KNG-34)

Read docs/ai-agents/handoffs/PLAYER_STATISTICS_CHAIN.md first (branch claude/kind-dijkstra-y9d279) and follow it;
it overrides anything below.

Implement **link 2 — API foundation** end to end (code, tests, commits, push to claude/kind-dijkstra-y9d279, progress
report, handoff) as link 2 of the chain.

**State you start from.**
- knk-workspace `claude/kind-dijkstra-y9d279`: link 1 delivered the binding docs — `docs/specs/player-statistics/DESIGN.md`
  §F "Finalized design (link 1)" and `docs/specs/player-statistics/IMPLEMENTATION_PLAN.md`, plus the dated source audit
  `docs/reports/2026-10-03-player-statistics-source-audit.md`.
- knk-web-api `claude/kind-dijkstra-y9d279` = trunk `master` `ae0b3ad` at chain start (no chain commits yet). Merge
  `origin/master` first.
- knk-plugin trunk moved to `db474e4` (KNG-28) since the chain start; not your repo this link.
- No executed test baselines yet: you record the API baseline (`dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`;
  earlier sessions saw 5-8 known pre-existing failures on trunk — record the exact failing tests before changing code).
  .NET 8: `sudo apt-get install -y dotnet-sdk-8.0` (charter §1.4). `dotnet ef` may need `dotnet tool install --global
  dotnet-ef --version 9.0.10` for the migration; if tools can't be installed, hand-write the migration + Designer +
  snapshot changes carefully and say so.

**What link 2 must build** (plan §8 "Link 2", with §1.1, §2, §3.1, §4 link-2 rows, §6):
- Data model + additive migration `<ts>_AddPlayerStatistics` (10 tables, plan §1.1).
- `StatisticsCatalog`, `StatisticsPeriods`, `StatisticsFormatting`, `LedgerStatisticsClassifier` (pure, fully tested).
- `POST api/statistics/batches` ingestion (idempotent per batch id, per-entry rejection codes, MySQL multi-row upserts with
  an InMemory fallback like `CurrencyRepository.AddTransactionAsync`).
- Ledger projector (economy, `xp_gained`, **title history from XP legs**) and **Siege match projector** (moved here from
  link 4) run by `StatisticsProjectionService`; retention job; OTel meter `Knk.Statistics`.
- Visibility service (atomic multi-change PUT with expected values) and read endpoints with viewer resolution.
- `RequireOwnerPermissionAttribute` (exact grant: `MatchedNode == node`; the resolver already returns `MatchedNode`,
  `Services/PermissionResolutionService.cs:140`) + `StaffPermissions.ViewStatistics`.
- The D13 guard test: every `CurrencyReasons` code explicitly classified.

**Wiring facts (verified by link 1's audit — still check before relying on them):**
- DbContext `Properties/KnKDbContext.cs` (partial; ledger config helper `ConfigureCurrencyLedger` ~l.2149 is the model to
  follow); hosted services registered in `DependencyInjection/ServiceCollectionExtensions.cs:188-203`; convention scan
  registers `*Service`/`*Repository` with matching `I*` interfaces (l.213-226) — register projectors explicitly.
- Ledger tables: `currency_transactions` (`ReasonCode`, `CreatedAt`, `ReversesTransactionId`) and `currency_entries`
  (`UserId`, `Currency`, `Amount`, `BalanceBefore`, `BalanceAfter`, index `(UserId, Currency, Id)`). Reason table with
  directions: `Services/Currency/CurrencyReasons.cs:132-154`. Merged ids: `ICurrencyService.GetMergedAccountIdsAsync`.
- Title brackets: `TitleBracket` (`MinExperience`, `NameFor(gender)`), resolution rule in `Services/TitleService.cs:19-54`.
- Siege: `siege_matches.Status/EndedAt/WinningAllianceGroup`, `siege_match_participants.LeftAt/Kills/Deaths/
  HighestKillStreak/Captures/SiegeTeamId`, `SiegeTeam.AllianceGroup`; leaver = `LeftAt < EndedAt`; unreported rows get
  `LeftAt == EndedAt` (`Services/SiegeMatchService.cs:157-356`).
- Discoveries: `user_domain_discoveries` (unique user+domain, `DiscoveredAt`), domain type for the Town/District/Structure
  breakdown via the existing discovery summary code (`Services/DiscoveryService.cs:420-441`).
- Caller: `HttpContext.GetKnkCaller()` (`IsPluginService`, `WebUserId`, `ActingUserId`) in
  `Attributes/RequireServiceOrPermissionAttribute.cs:14-112`.
- Config: `Telemetry` is the OpenTelemetry section — use `Statistics` for this link.
- Tests: EF InMemory with hand-wired services (`Tests/.../Services/DiscoveryServiceTests.cs:37-75`); InMemory can't run
  raw SQL upserts or triggers.

**Open flags that affect this link.** L1-3 (anonymous sees only always-public), L1-4 (context precedence), L1-5/L1-6
(economy buckets), L1-7/L1-8 (Siege rules), L1-14 (time zone), L1-15 (first join), L1-16 (merged sums), L1-17 (exact
owner grant) — implement as written in DESIGN §F; record any deviation as `L2-n`.

**Known risks.** MySQL-only upsert SQL is exercised only by `KNK_TEST_MYSQL` tests — keep the SQL small and mirrored by
the InMemory path. Projection must advance its cursor in the same transaction as its writes. Do not edit currency or
Siege services (projections read their tables). Keep `Statistics:Enabled=false` a true no-op.

**Next after you:** link 3 — plugin foundation (needs your `POST api/statistics/batches`, visibility GET/PUT and
catalogue endpoints, and adds the `statistics.visibility` menu seed to knk-web-api).
