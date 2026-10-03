# Player statistics chain — progress report

**Status:** running
**Last updated:** 2026-10-03 (link 3 done)
**Charter:** `docs/ai-agents/handoffs/PLAYER_STATISTICS_CHAIN.md` · **Linear:** [KNG-34](https://linear.app/kngpandi/issue/KNG-34)

## Summary for the developer

Branch in all four repos: `claude/kind-dijkstra-y9d279` (nothing merged to any trunk).

| Link | Phase | State | Heads | Details |
|---|---|---|---|---|
| 1 | Design completion + implementation plan | **done** | knk-workspace (see Link 1 block) | [audit](2026-10-03-player-statistics-source-audit.md), [DESIGN §F](../specs/player-statistics/DESIGN.md), [plan](../specs/player-statistics/IMPLEMENTATION_PLAN.md) |
| 2 | API foundation (+ Siege projection, moved from link 4) | **done** | knk-web-api `b13ff0c` | Link 2 block: ingestion, projections, visibility, reads, owner attribute; 179 new tests |
| 3 | Plugin foundation | **done** | knk-plugin `e75d9b7`, knk-web-api `c95572a` | Link 3 block: statistics sink/spool, sessions, AFK + `/afk`, distance, falls, privacy menu + seed; 95 new plugin tests, 6 API |
| 4 | Combat and minigames | pending | — | — |
| 5 | Read surfaces + leaderboards | pending | — | — |
| 6 | Diagnostic telemetry + privacy | pending | — | — |
| 7 | World analytics + final write-up | pending | — | — |

**Review first:** (ranked; each link appends)
1. **L1-18 GDPR scope** — deletion pseudonymizes the `users` row and auto-executes 3 days before the 30-day due date
   (DESIGN §F.14). Irreversible for the player once executed; ledger and Siege rows are kept.
2. **L1-1 AFK rule** — `/afk` + auto-AFK after 300 s, retroactive idle window, anti-pool signals, tab marker, no Siege
   removal (§F.2). **L1-2:** salary still pays AFK players (needs an API contract change if you want otherwise).
3. **L1-3 "everyone" visibility** — anonymous web visitors see only always-public fields (§F.4).
4. **L1-5/L1-6 economy buckets** — `/pay` transfers, admin adjustments, signup grant, merges and premium top-ups are
   neither earned nor spent; `xp_gained` uses earned XP only (§F.5).
5. **L1-17 owner nodes** — `knk.owner.*` require an exact grant (wildcards never unlock owner data); grant them to
   yourself with `POST api/users/{id}/grants` (§F.13).

6. **L2-12 title history backfill** — on first start the ledger projector projects the **whole existing ledger**
   (authoritative, D6): economy totals, `xp_gained` and title history appear for past activity, named with today's
   brackets and genders. Wanted? If not, set the `ledger` cursor before the first run (one SQL row).
7. **L2-5 hidden totals** — a contextual metric whose total is hidden (one context overridden to Nobody) is returned
   with `value: null` and only its visible contexts (API shape change vs. the plan, recorded there).
8. **L3-4 kill switch scope** — `statistics.enabled: false` registers no statistics listener or task, but the privacy
   menu (`/stats settings`, profile tile) still works and `/afk` stays declared in `plugin.yml`, answering "AFK is
   disabled".
9. **L3-3 API down at join** — a player whose user id is unknown is tracked in memory and released when the id is found
   (looked up every replay interval); if the server stops before that, that session's statistics are lost (not spooled).

**Test when you have time:** (filled in by link 7 — build/deploy steps and the combined live checklist.)

## Chain start — coordinator session (2026-10-03)

- The developer answered the open questions (DESIGN.md "Developer decisions 2026-10-03", D1-D13), handed KNG-34 over
  to Claude Code, asked for the whole feature on one feature branch with a chain of fresh sessions, one phase each,
  and said not to wait for their testing.
- Created `claude/kind-dijkstra-y9d279` from trunk in knk-plugin (`main` `27b4236`), knk-web-api (`master`
  `ae0b3ad`) and knk-web-app (`main` `fc66101`); in knk-workspace from `main` with the earlier draft branch
  `codex/kng-34-player-statistics-design` (`4f5618a`, draft [PandiO/knk-workspace#4](https://github.com/PandiO/knk-workspace/pull/4)) merged
  in, so the draft design continues on this branch. PR #4 was left open and untouched (the developer may close it).
- Recorded D1-D13 and the adopted leaderboard recommendation in DESIGN.md; wrote the charter and link 1's handoff.
- AFK: not answered by the developer; link 1 analyses V1 and takes a reversible default (charter, DESIGN.md).
- Overlap noted: a Codex session ("Sequential backlog fixes", tracker row on `main` 2026-10-03) is changing knk-plugin
  Siege combat, item lore and command completion and knk-web-app form-wizard code, pushing to trunk. Links merge trunk
  at start and end; link 4 builds its combat hooks around their changes.
- Link 1 started as a **new session** (`create_session`, option 1): `session_015g7iripYBsgLJUPKZivR5s`, source
  knk-workspace `claude/kind-dijkstra-y9d279`, tag `kng-34-player-statistics-chain`.

## Link 1 — Design completion + implementation plan (2026-10-03)

Session `session_015g7iripYBsgLJUPKZivR5s` (started by the coordinator via `create_session`). Docs only.

- **Commits (knk-workspace `claude/kind-dijkstra-y9d279`):** `4eb179b` source audit + finalized DESIGN §F, `b76ee7e`
  implementation plan + feature register + specs hub + charter re-cut, plus this report/handoff commit. Tracker on
  `main`: `6a08f18` (link 1 in progress) and the link-1-done update. Code repos untouched (read-only at knk-web-api
  `ae0b3ad`, knk-plugin `db474e4`, knk-web-app `fc66101`; legacy `knk-v1-archive` `4117e7e`, `knk-v2-archive` `400e5c8`).
- **Tests vs baseline:** n/a (no builds in link 1). Static counts for reference: API 1,299 test attributes; plugin
  `@Test` knk-core 880 / knk-api-client 141 / knk-paper 1030.
- **Delivered:** [source audit](2026-10-03-player-statistics-source-audit.md); DESIGN.md §F (catalogue, AFK, sessions,
  visibility, economy buckets, match rules, combat/gate/distance attribution, periods/rounding, leaderboards, event
  contract, owner nodes, GDPR, retention); [IMPLEMENTATION_PLAN.md](../specs/player-statistics/IMPLEMENTATION_PLAN.md);
  feature register rows (statistics, telemetry, XP provenance) and specs hub; Linear: KNG-34 set to *In Progress*,
  comments on KNG-34, KNG-14 and KNG-23 (reconciliation).
- **Flagged decisions:** L1-1 … L1-23, table in DESIGN §F.16 (top five in "Review first").
- **Re-cut (charter §0):** Siege match projection moved from link 4 to link 2 (API-only, pure logic; link 4 keeps the
  plugin leaver fix and reconciliation tests). Still 7 links; every charter item is placed.
- **Discrepancies with the design / snapshot:** plugin trunk moved to `db474e4` (KNG-28); Siege leavers' stats are lost
  today (plugin drops them — fixed in link 4); per-match killstreak already exists (D2 extended to open world);
  `HealthSystem` returns void (link 4 changes it to return the effective loss); `*`/`knk.*` grants match `knk.owner.*`
  (→ exact-grant attribute); `Telemetry` config section is taken by OpenTelemetry (→ `DiagnosticTelemetry`); permission
  check and several user GETs are anonymous on trunk (not changed by this chain); V1 stored users in MySQL, not flat files;
  no first-join field (derived per L1-15).
- **Live checklist:** none for link 1.
- **Risks:** see plan §9 (Siege/gate files under concurrent change, create-only menu seed, MySQL-only upserts).
- **What link 2 must wire:** plan §1.1, §2, §3.1, §4 (link-2 rows), §6 (`RequireOwnerPermission`), §8 Link 2 acceptance
  criteria 1-10.
- **How link 2 was started:** new session (charter §6 option 1, `create_session`): `session_01M59wGLFhAji7UwGaZuoAdR`,
  source knk-workspace `claude/kind-dijkstra-y9d279`, model `claude-opus-5-5`, tag `kng-34-player-statistics-chain`;
  `get_session` showed it connected and working.

## Link 2 — API foundation (2026-10-03)

Session `session_01M59wGLFhAji7UwGaZuoAdR` (started by link 1 via `create_session`). knk-web-api only.

- **Commits (knk-web-api `claude/kind-dijkstra-y9d279`, pushed):** `cb2c7fc` data model + additive migration
  `20261003023630_AddPlayerStatistics`, `ece2cf7` services/repository/controller/DI/config/meter, `552d4a4` tests,
  `b13ff0c` cursor row lock + concurrency test. Trunk `master` is still `ae0b3ad` (merged at start and before the final
  push — nothing new). knk-workspace: this report, plan status, link 3 handoff; tracker on `main`.
- **Branch:** `claude/kind-dijkstra-y9d279` did **not** exist in knk-web-api (the charter says it did); created it from
  `master` `ae0b3ad` (L2-1, reversible).
- **Tests vs baseline** (`dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`): baseline 1,660 total /
  1,607 passed / **5 failed** / 48 skipped → after 1,839 total / 1,777 passed / **the same 5 failed** / 57 skipped
  (the 9 new MySQL tests skip without `KNK_TEST_MYSQL`). The 5 pre-existing failures (red on trunk, not touched):
  `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_ValidatesRequired`,
  `FormSubmissionProgressRepositoryTests.DeleteCompletedOlderThanAsync_DeletesStaleRootAndDescendantsInOrder`,
  `PathResolutionServiceTests.ValidatePathAsync_AllowsValidV1Paths` ×2 (`Town.Name`, `Town.WgRegionId`),
  `ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`.
  **MySQL-gated suite** (local MySQL 8.0.46 installed with apt in the cloud container): baseline 48 / 43 passed /
  5 failed → after 57 / 52 passed / the same 5 failed (`TeleportChargeMySqlTests` ×5 — "You don't have enough gems",
  pre-existing on trunk, unrelated). All 9 new statistics MySQL tests pass (migration applies; upserts; concurrency).
- **Delivered (plan §1.1, §2, §3.1, §4 link-2 rows, §6):** 10 tables (`Properties/KnKDbContext.Statistics.cs`);
  `StatisticsCatalog`, `StatisticsPeriods`, `StatisticsFormatting`, `LedgerStatisticsClassifier`, `StatisticsDeltaSet`,
  `StatisticsVisibilityRules`; `StatisticsIngestionService` (`POST api/statistics/batches`, multi-row
  `INSERT … ON DUPLICATE KEY UPDATE` + InMemory fallback); `LedgerStatisticsProjector` (economy, `xp_gained`, title
  history), `SiegeStatisticsProjector`, `StatisticsProjectionService` (+ session timeout sweep),
  `StatisticsRetentionService`, `StatisticsRebuildService`, `StatisticsMetrics` (`Knk.Statistics`);
  `StatisticsVisibilityService`, `StatisticsQueryService`, `StatisticsViewerResolver`; `StatisticsController` (8 routes);
  `RequireOwnerPermissionAttribute` + `OwnerPermissions`; `StaffPermissions.ViewStatistics`; `Statistics` config
  section. Acceptance criteria 1-10 of plan §8 link 2 are covered by tests (criterion → test class in the plan status
  note). The D13 guard: `LedgerStatisticsClassifierTests.EveryCurrencyReasonCode_IsClassifiedExplicitly`.
- **Live smoke (local MySQL, fresh DB, every migration applied, API started):** catalog; batch without key → 401;
  batch → applied with `deaths@siege` rejected `NotPluginWritable`; replay → `duplicate: true`; anonymous / self /
  signed-in reads filtered as designed; visibility PUT by another player → 403, by self → 200, stale → 409; title
  history as another player → 403; `DateOnly` query parameters bind; `Statistics__Enabled=false` → POST 503 and both
  jobs log "disabled" with no statistics SQL.
- **Flagged decisions:**

| # | Decision (reversible default) | Why |
|---|---|---|
| L2-1 | Created the missing knk-web-api feature branch from `master` `ae0b3ad` | Charter: one branch per repo |
| L2-2 | Extra rejection codes `UnknownUser` (user/killer/victim id not in `users`) and `InvalidEntry` (bad session type/end reason, empty key, killer = victim) | The plan's list had no code for these |
| L2-3 | Entries up to `Statistics:FutureToleranceSeconds` (300) in the future are accepted; counters must be > 0, records ≥ 0; values kept to 4 decimals | Clock skew between servers |
| L2-4 | Ledger projector waits `Statistics:ProjectionSafetyLagSeconds` (10) and stops at the first younger leg; cursor row locked `FOR UPDATE` | A lower ledger id may commit after a higher one; multiple API instances |
| L2-5 | `PlayerStatisticMetricDto.value`/`rawValue` are **null** when the total is hidden but some contexts are visible | The total rule (§F.4) without dropping visible contexts |
| L2-6 | `profile.activePlaytimeSeconds`/`afkSeconds` are lifetime whatever the period (the period values are in `metrics`) | The profile is the always-public base |
| L2-7 | Catalogue public shape: `PluginInput` + `ProjectionOwnedContexts` instead of `PluginWritableContexts`; `first_joined`, the discovery list and title history are settings/profile fields, not metric rows; `deaths` is reported non-contextual to clients | "All contexts except Siege" isn't expressible as an allow-list; those three have no stored value |
| L2-8 | Discovery counts: gate structures count as structures; each domain counts once at its earliest discovery across merged identities (period counts use that date) | DTO has towns/districts/structures only |
| L2-9 | Visibility: `contexts[].isOverride` added; a context change's `expected` is the inherited metric-level value when there is no override; extra 400 codes `TooManyChanges`, `DuplicateChange`, `InvalidVisibility`; an empty change list is a 200 no-op | The menu shows the inherited value; atomic preview semantics |
| L2-10 | A duration after an API `Timeout` close reopens the session | Timeout is an API inference (API down ≠ player gone) |
| L2-11 | A plugin read without `X-Acting-User-Id` is anonymous; owner nodes must be granted **directly on the user** (a user-level `*` decides before group grants and is refused) | Fail closed |
| L2-12 | On first run the ledger projector projects the whole existing ledger (economy, `xp_gained`, title history), with current brackets and genders | Ledger is authoritative (D6); "Review first" item 6 |
| L2-13 | Several participant rows of one user in one match count once (stats summed, streak max); any early leave → loss | Matches L1-7 |
| L2-14 | DbContext configuration lives in a new partial `KnKDbContext.Statistics.cs` (implements the existing `OnModelCreatingPartial` hook) instead of editing `KnKDbContext.cs` | Smaller conflict surface on a 2,300-line file |
| L2-15 | An unparseable `date`/`from`/`to` query value is ignored (defaults apply) instead of a 400 | MVC binding default; harmless |

- **Discrepancies with the design/plan:** none in behaviour beyond L2-5/L2-7/L2-9 (shape additions, recorded in the
  plan status note). The solution file `knkwebapi_v2.sln` references `tests/…` (lower case), so `dotnet build` at the
  repo root fails on Linux — build `knkwebapi_v2.csproj` (pre-existing, not changed).
- **Live checklist (link 2):** (1) apply migration `AddPlayerStatistics` (additive; 10 tables); (2) start the API — log
  "Statistics projection started"; within a minute `GET api/statistics/users/{yourId}` (logged in) shows `xp_gained`,
  `economy` and `GET …/title-history` your past promotions; (3) a completed Siege match appears as wins/losses/kills
  under context `siege` within ~30 s; (4) another account sees only active/AFK time and XP until you set something to
  Everyone (`PUT …/visibility`); (5) `Statistics:Enabled=false` → `POST api/statistics/batches` 503, no projection.
- **Risks:** first-run projection of a large ledger takes several cycles (50 × 2,000 legs per 30 s cycle); deadlock on
  concurrent upserts surfaces as a 5xx the plugin retries (idempotent); the menu seed (`statistics.visibility`) is link 3.
- **What link 3 must wire:** plugin client for `POST api/statistics/batches` (DTO in `Dtos/StatisticsDtos.cs`; spool on
  5xx/503/401/403/408/429, final on 400; read `rejected[]` codes), `GET api/statistics/catalog`, `GET/PUT
  api/statistics/users/{id}/visibility` with `X-Acting-User-Id` (409 body `{ error, message, current }`); never send
  `pvp_kills`/`deaths`/`highest_killstreak` in context `siege` (rejected); durations must lie inside a known session of
  the same user, start ≥ session start, ≤ 86,400 s, ≤ 7 days old; plus the API menu seed `MenuTemplateSeed.Statistics.cs`.
- **How link 3 was started:** new session (charter §6 option 1, `create_session`): `session_013GjXWw1R62Nzv6Tjoodejy`,
  source knk-workspace `claude/kind-dijkstra-y9d279`, model `claude-opus-5-5`, tag `kng-34-player-statistics-chain`;
  `get_session` showed it pending in the working bucket right after creation.

## Link 3 — Plugin foundation (2026-10-03)

Session `session_013GjXWw1R62Nzv6Tjoodejy` (started by link 2 via `create_session`). knk-plugin + knk-web-api (seed).

- **Commits (pushed to `claude/kind-dijkstra-y9d279`):**
  - knk-plugin (branch created from `main` `ee7824c`, L3-1): `2064f64` knk-core statistics (buffer, sessions, AFK
    tracker, spool, recorder), `d6ce7fe` api-client `StatisticsApiImpl`, `a503f2a` knk-paper service/listeners/`/afk`/
    flush task/config/privacy menu/`/stats settings` + regenerated `content-seeds.json`, `60135f0` pressure plates are
    not AFK activity, `e75d9b7` record/PvP-kill hooks for link 4.
  - knk-web-api: `c95572a` `MenuTemplateSeed.Statistics.cs` (`statistics.visibility`) + `profile.main` header slot 6.
  - Trunks merged at start and before the final push: knk-plugin `main` `ee7824c` (the branch was cut from it; nothing
    newer), knk-web-api `master` `ae0b3ad` (unchanged), knk-workspace `main` merged into the feature branch.
- **Tests vs baseline** — first executed plugin baseline of the chain (`./gradlew build -x deployToDevServer`, all
  green): knk-core 1,189 → **1,242**; knk-api-client 144 (2 skipped) → **152** (2 skipped); knk-paper 977 (14
  skipped) → **1,011** (14 skipped). New test classes: `AfkTrackerTest`, `MovementAndFallRuleTest`,
  `StatisticsBufferTest`, `StatisticsSessionsTest`, `StatisticsSpoolTest`, `StatisticsRecorderTest`,
  `StatisticsApiImplTest`, `ConfigLoaderStatisticsTest`, `StatisticsVisibilityMenuFeatureTest` (validates the exported
  seed and `profile.main` against the registered features), `StatisticsListenersTest` (World mock in a field);
  `UserCommandTest` extended. API (`dotnet test`): 1,839 → **1,845** total, 1,783 passed, **the same 5 pre-existing
  failures**, 57 skipped (`MenuTemplateStatisticsSeedTests` ×5 + the new content-seed theory case).
- **Live smoke (cloud, local MySQL 8 + the API on the feature branch, every migration applied):** the plugin's own
  `StatisticsSessions` → `StatisticsBuffer` → `StatisticsRecorder` → `StatisticsApiImpl` pipeline against the real
  endpoints: a 17-entry batch (two sessions incl. one resolved late, active/AFK slices, swim + vehicle distance split
  over two entries, a fall record, PvE kills, two PvP kills) → 16 accepted, the Siege-context PvP kill rejected
  `NotPluginWritable` and logged; resend → `duplicate: true`; a spooled batch replayed and its file deleted;
  `GET api/statistics/users/5` as self showed active 200 s / AFK 500 s / logins 1 / distances / fall 23.5 exactly as
  sent; visibility GET, atomic PUT (metric + context override), stale PUT → 409 mapped to the conflict exception with
  `current`, another player's settings → 403. The Paper runtime itself (listeners, menu rendering) was not run.
- **Delivered (plan §5.1, §5.2 link-3 rows, §5.3, §8 link 3):** see the plan's "Link 3 status" note for the class list
  and the acceptance-criterion → test map.
- **Flagged decisions:**

| # | Decision (reversible default) | Why |
|---|---|---|
| L3-1 | Created the missing knk-plugin feature branch from `main` `ee7824c` | Charter: one branch per repo (like L2-1) |
| L3-2 | Distance is summed per session in primitive fields and timestamped at the flush (≤ 60 s after the movement) | No allocation per move event (§7 budget) |
| L3-3 | Unknown user id at join: the session, its time, distance and values are held in memory and released with the original join instant once the id is found (UUID lookup every replay interval); ended unresolved sessions kept up to 1,024 (oldest dropped); lost if the server stops first | Matches the discovery pattern without a second spool format; rare (API down at join) |
| L3-4 | `statistics.enabled: false`: no statistics listener/task; the privacy menu and `/stats settings` stay (they record nothing); `/afk` is declared in `plugin.yml` and answers "AFK is disabled" | Bukkit needs commands declared; the profile tile must not open a blocked menu |
| L3-5 | AFK: move signals throttled to one per second per player; `/afk` itself is not an activity signal; pressure plates/tripwires (`PHYSICAL` interact) are not activity; `afk.idle-seconds` ≥ 30 | Cheap move path; `/afk` must be able to leave AFK; anti-AFK-pool |
| L3-6 | The AFK tab marker is restored only if the tab name is still the marked one (the Siege scoreboard redraws names in a match and then wins) | Never clobber another feature's name |
| L3-7 | Riding: `VehicleMoveEvent` passengers count as vehicle distance; no `EntityMoveEvent` listener (it would fire for every mob) — whether horses/pigs/striders raise `VehicleMoveEvent` is a live check | Cost; flagged |
| L3-8 | Fall rule uses `getFinalDamage()` (absorption already taken off) against health only | Avoids counting fatal falls as survived |
| L3-9 | `StatisticsApi` read methods (`getUserStatistics`, `getTitleHistory`) are left to link 5 (first consumer); `getCatalog` is implemented and tested but the menu uses the visibility response's groups/labels | No unused DTO surface; one call per menu render |
| L3-10 | Shutdown: sessions end `ServerStop`, the last batches get up to 5 s on the main thread, anything unsent is spooled | Bounded like the teleport refund at disable |
| L3-11 | `/stats settings` (and `/user statistics settings`) open the menu; a player literally named "settings" can then only be looked up from the console | Plan's subcommand name |
| L3-12 | Batches carry `serverName` = `<server software> <port>` and the plugin version (diagnostics only) | No server-name config exists |
| L3-13 | Flush sends at most 5 batches (10,000 entries) per interval; a replay run sends at most `replay-interval-seconds` batches (≤ 1/s average) | §7 budgets |
| L3-14 | Counters are summed and records maxed per (user, metric, context, UTC minute); `occurredAt` = the latest contribution | Fewer entries; period allocation stays exact to the minute |
| L3-15 | The menu keeps a viewer's settings for 5 s to avoid a GET per repaint; a click's PUT answer (or the 409's `current`) replaces them | Responsive cycling without stale reads |

- **Discrepancies with the plan/design:** `MovementClassifier.classify` returns a nullable enum (`FOOT`/`SWIM`/`FLYING`/
  `VEHICLE`) instead of `Optional<MovementMode>` (allocation-free); a pure knk-core `StatisticsSessions` was added under
  `StatisticsService` (testable session logic); `StatisticsMetric` lists only plugin-sent metrics (no `logins`, wins,
  economy — the API derives/projects them); menu header layout: slots 0-4 group selectors, 5-7 group actions, 8 Back,
  row 1 an info item, Confirm/Cancel at 48/50 (Confirm's lore is the preview). Performance (§7) was not measured — no
  Paper server in the cloud; the move listeners do a hash lookup and arithmetic and allocate nothing per event after a
  player's first move.
- **Live checklist (link 3):** (1) deploy API + plugin; run the content-menu reset (`scripts/reset-content-menus.ps1`) so
  `statistics.visibility` and the profile's slot-6 "Statistics privacy" tile appear; startup log shows "Player
  statistics started" and no validation block for `statistics.visibility`; (2) join, wait a minute: `GET
  api/statistics/users/{id}` (logged in) shows logins +1 and growing active time; (3) idle 5 min → "You are now AFK" +
  `[AFK]` in the tab list; look around → back; `/afk` toggles; AFK time grows instead of active; standing on a pressure
  plate or in a water stream stays AFK; (4) walk, swim, fly with an elytra, ride a boat/minecart **and a horse** → foot/
  flying/vehicle distance (L3-7: does the horse count?); (5) survive a ~10-block fall → highest fall; (6) stop the API,
  play a minute, see files in `plugins/KnightsAndKings/statistics-spool/`; start the API → files replayed and deleted;
  (7) `/stats settings` and Profile → Statistics privacy: switch groups, click a setting (cycles), "Set all listed to
  Everyone" → preview in chat and on Confirm → Confirm applies; change a setting via `PUT …/visibility` meanwhile → the
  menu says it changed elsewhere and refreshes; (8) `statistics.enabled: false` → log "Player statistics disabled",
  `/afk` says disabled, nothing is sent; (9) server stop → the session rows end with `ServerStop`.
- **Risks:** the menu seed is create-only (reset needed); `PlayerInteractEvent`/`InventoryClickEvent` are listened to
  at MONITOR for every player (cheap, no I/O); the 5 s shutdown wait runs on the main thread when the API hangs.
- **What link 4 must wire:** `KnKPlugin#getStatisticsService()` (null when disabled) →
  `StatisticsService.addCounter(Player, StatisticsMetric, double)` (context via `StatisticsContextResolver`),
  `addRecord(Player, …)` (`highest_killstreak`), `pvpKill(Player killer, Player victim)` (skip running-match members,
  §F.6), `contextOf(Player)`; for credit to an offline player (fire igniter who logged off, §F.8) call
  `service.buffer().addCounter(userId, metric, context, value, at)` directly with the stored user id. Config:
  `statistics.combat|gates|siege` go into `KnkConfig.StatisticsConfig` (add records + `ConfigLoader.loadStatistics`).
- **How link 4 was started:** new session (charter §6 option 1, `create_session`): `session_01GiwQhoD6EA3m9WvVPmdU3d`,
  source knk-workspace `claude/kind-dijkstra-y9d279`, model `claude-opus-5-5`, tag `kng-34-player-statistics-chain`;
  `get_session` showed it pending in the working bucket right after creation.
