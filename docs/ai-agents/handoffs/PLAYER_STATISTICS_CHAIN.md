# Player statistics chain — charter

**Status:** Running (started 2026-10-03)
**Last updated:** 2026-10-03 (link 1: §0 re-cut recorded in the table — Siege projection moved to link 2)
**Linear:** [KNG-34](https://linear.app/kngpandi/issue/KNG-34) (design + implement), with [KNG-14](https://linear.app/kngpandi/issue/KNG-14), [KNG-23](https://linear.app/kngpandi/issue/KNG-23), [KNG-9](https://linear.app/kngpandi/issue/KNG-9), [KNG-21](https://linear.app/kngpandi/issue/KNG-21)

A chain of **seven** Claude Code sessions ("links"). Each link implements **one phase**, tests it, documents it, pushes
it, writes the handoff for the next link and hands over to a **fresh context**. The developer's instruction (2026-10-03):
implement the **entire** KNG-34 feature on **one feature branch**, don't wait for them to test — they test once
everything is implemented. **Live testing is never a reason to stop**: write the checklist and go on. Do nothing the
developer can't easily review or undo.

| Link | Phase | Repo(s) |
|---|---|---|
| 1 | **Design completion + implementation plan** — V1/V2/V3 source audit (incl. V1 AFK mode), finalize `DESIGN.md`, write `IMPLEMENTATION_PLAN.md` (data model, API contracts, event contract, permission nodes, per-link file lists, acceptance criteria). May refine links 2-7 within §0. | knk-workspace (code repos and legacy archives read-only) |
| 2 | **API foundation** — XP into the existing ledger (D13), statistics data model + migrations, batched idempotent ingestion endpoints, period aggregation (D5), visibility settings (per metric, per context, group bulk update) and enforcement on every read, title history from XP, **Siege match projection (moved from link 4 by link 1, §0)**, tests | knk-web-api |
| 3 | **Plugin foundation** — api-client endpoints + buffered/spooled statistics sink, sessions (first join, logins incl. reconnects, active/AFK playtime, AFK detection), distance (foot/flying/vehicle), highest survived fall, visibility-settings InventoryMenu with group action + confirmation | knk-plugin (+ small knk-web-api fixes) |
| 4 | **Combat and minigames** — PvP/PvE kills per context, deaths by cause (only total shown), damage dealt/received, arrows/headshots, killstreak mechanic, gate-door damage incl. fire attribution, wins/losses/draws/leave-as-loss, objectives; reconcile Siege match facts (plugin leaver fix + reconciliation tests; the API projection itself is built in link 2) | knk-plugin, knk-web-api |
| 5 | **Read surfaces + leaderboards** — leaderboard snapshots (API), in-game statistics/profile menus and `/user statistics`, web-app own statistics + settings, public player profile, leaderboard pages | knk-web-api, knk-plugin, knk-web-app |
| 6 | **Diagnostic telemetry + privacy** — event contract, bounded async ingestion, plugin emitter (baseline + enhanced mode), owner-only nodes and timeline UI, retention, GDPR deletion workflow | knk-web-api, knk-plugin, knk-web-app |
| 7 | **World analytics + final write-up** — movement sampling/heatmaps, menu funnels, domain interaction analytics (owner-only views); combined live checklist, merge order, feature register + changelog | all four |

**Not in this chain:** merging into any trunk, deploying, touching the developer's servers or databases, Linear
issues other than KNG-34/KNG-14/KNG-23 comments, the friends system (KNG-35; friends-only visibility fails closed).

- **Design (binding):** `docs/specs/player-statistics/DESIGN.md` — the "Developer decisions 2026-10-03" table (D1-D13)
  and every "Agreed" paragraph are the developer's. After link 1: `docs/specs/player-statistics/IMPLEMENTATION_PLAN.md`
  is binding for links 2-7.
- **Progress report (append per link):** `docs/reports/2026-10-03-player-statistics-chain.md`.
- **Handoff prompts:** this folder, `docs/ai-agents/handoffs/2026-10-03-player-statistics-link-<n>.md`.

## 0. Rules for changing the plan

Link 1 may re-cut links 2-7 (move items between links, split one) when the source audit shows the cut is wrong, but:
the chain stays at **≤ 7 links in total** (session nesting is limited to 8 levels), every item in the table above stays
somewhere in the chain, and the change is recorded in this charter's table and in the progress report. Later links may
move a leftover item to the next link (record it); the last link may only leave items over as a written follow-up list.

## 1. Setup (every link, before anything else)

1. **Repos.** `github.com/PandiO/knk-workspace`, `knk-web-api`, `knk-plugin`, `knk-web-app`. They may be checked out
   already (`/home/user/<repo>`); if missing, add with `add_repo` (access `push`) and clone. Legacy archives
   `knk-v1-archive` / `knk-v2-archive` are read-only sources (link 1 needs them; `add_repo` with `read`).
2. **Branch — developer's instruction: ONE feature branch `claude/kind-dijkstra-y9d279` in every repo, including
   knk-workspace**, even if your environment suggests another name. It already exists in all four repos (created
   2026-10-03 from trunk). Check it out and pull. Trunks: knk-plugin `main`, knk-web-app `main`, knk-web-api `master`,
   knk-workspace `main`.
   - **Every link, at the start and again before the final push:** `git fetch` and merge `origin/<trunk>` into the
     feature branch in every repo you change. Other sessions merge to trunk while this chain runs (a Codex session was
     fixing Siege combat and command completion on 2026-10-03). A conflict that isn't mechanical is an absolute
     blocker (§4).
   - **Only `docs/ACTIVE_SESSIONS.md` is updated on workspace `main`** (the coordination board must be on the default
     branch): `git fetch`, commit the tracker change alone on top of `origin/main`, push `HEAD:main`. Everything else —
     design, plan, handoffs, report — goes on the feature branch.
   - Never push to another branch, never merge into a trunk, never force-push or rewrite pushed history, never delete
     branches.
3. **Push check** before changing anything: `git push --dry-run origin claude/kind-dijkstra-y9d279` per repo you'll
   change. Failure = absolute blocker.
4. **Toolchains.**
   - Plugin: Java 21 is installed. Create `~/.gradle/gradle.properties` with `org.gradle.workers.max=2`,
     `systemProp.org.gradle.internal.repository.max.tentatives=6`,
     `systemProp.org.gradle.internal.repository.initial.backoff=1500`; use `--offline` after the first build. Check
     `https://repo.papermc.io/repository/maven-public/` and `https://maven.enginehub.org/repo/` with curl; if they fail,
     mark knk-paper code "**not compiled**" — not a blocker.
   - API: .NET 8 is not preinstalled and `dotnet-install.sh` is blocked by the proxy; `sudo apt-get install -y
     dotnet-sdk-8.0` (Ubuntu archive) works. If .NET can't be installed, API code is "**not compiled**" — record it,
     but a link whose main deliverable is API code (2) must then stop (§4.2).
   - Web app: Node 22 is installed; `npm ci` then `npm run test:ci` and `npm run build`.
5. **Builds/tests.** Plugin `./gradlew build -x deployToDevServer` (plain `build` copies the jar to the developer's
   Windows dev-server path). API `dotnet build` + `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`.
   App `npm run test:ci`, `npm run build`. **Record test counts before changing anything** (baseline) and compare at the
   end. Keep build output short (tail/grep) — it costs context.

## 2. Read first (targeted — don't re-explore the codebase)

1. `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`, and `AGENTS.md`/`CLAUDE.md` of each repo you change.
2. `docs/ACTIVE_SESSIONS.md` on `origin/main` — does another "In progress" row claim files you must change? (§4.5)
3. `DESIGN.md` (all of it, every link), `IMPLEMENTATION_PLAN.md` (links 2-7), your handoff file.
4. The progress report so far.

## 3. Hard rules

- **Scope:** only your link. Reuse existing sources of truth: the currency ledger (KNG-21), Siege match persistence,
  discoveries (KNG-20), the audit log, `MenuFeature`/`profile.main`, the discovery spool pattern, `usePermission`. Never
  build a second independent counter for something already stored authoritatively (DESIGN.md).
- **Performance:** no database write per tick or per move event; plugin side buffers and flushes in batches off the
  main thread; ingestion is idempotent (batch/event ids) so spool replays never double count; gameplay never waits on
  statistics or telemetry I/O.
- **Privacy:** visibility is enforced in the API on every read path (Minecraft and web); friends-only fails closed
  until KNG-35; diagnostic data is owner-only via dedicated nodes (D12); no chat text, IPs, tokens or raw bodies in
  telemetry.
- **Siege behaviour must not change** except where KNG-34 needs a hook (event emission, attribution bookkeeping); gate
  HP/fire mechanics keep their exact outcome. Every hook has a config kill switch (`statistics.enabled`,
  `telemetry.enabled`, …) whose `false` reproduces today's behaviour.
- **Migrations:** additive only (new tables/columns, nullable or defaulted); never drop or rewrite existing data.
- **Files:** write sources with your file tools, not shell heredocs. **Commits** in logical chunks with the attribution
  trailer from your environment, **push after each chunk**. Tests for all pure logic; plugin tests follow the
  `CLAUDE.md` World-mock rule.
- **`ACTIVE_SESSIONS.md`:** others push to workspace `main` too — `git fetch` + rebase/merge before every push; on
  conflict keep both sides' rows; no conflict markers may survive.

## 4. Absolute blockers (stop the chain)

Stop, write why in the progress report and the tracker row, push, start no further link when:

1. You can't clone or push a repo your link must change.
2. A module you changed doesn't build or its tests fail and you can't fix it; or a baseline test you didn't touch starts
   failing and you can't explain it. (knk-paper not compilable because of the network is **not** this case; a
   baseline failure that is also red on trunk is recorded, not a blocker.)
3. A trunk merge into the feature branch has non-mechanical conflicts.
4. The link needs an expensive-to-undo decision that the design doesn't settle and no reversible default exists.
5. Another "In progress" row claims files you must change **and** its branch has unmerged changes to them — coordinate
   by building around them (new files/hooks) first; stop only if that is impossible.
6. The previous link's status says its exit criteria aren't met.

**Never a blocker:** live testing, design details left open (take the most reversible default consistent with the
design, flag it as a numbered decision `L<k>-<n>` in the progress report), knk-paper not compilable in the cloud.

## 5. Per link

1. Claim: update the chain's "In progress" row in `ACTIVE_SESSIONS.md` on `main` (link number, repos/files); push.
   Linear (if the tools exist): link 1 sets KNG-34 to *In Progress*; every link adds a short comment on KNG-34.
2. Setup (§1): fetch, merge trunk, record baselines.
3. Implement the link exactly as `IMPLEMENTATION_PLAN.md` describes; unit tests for all pure logic.
4. Append a **"Link N"** block to the progress report (§7) and a short status note under the plan's phase table.
   Update the plan's Status/Last-updated.
5. Merge trunk once more, push every changed repo's feature branch, update the tracker row, push.
6. Hand over (§6).

### Link specifics

- **Link 1 (docs only):** Read the current code in all three code repos (default branches) and the legacy archives.
  Deliver: (a) a dated audit report `docs/reports/2026-10-03-player-statistics-source-audit.md` — V1/V2 `UserStatistics`
  /`UserStatisticsDaily` fields and call sites, V1 AFK mode (commands, detection, effects), V3 sources per candidate
  metric (what exists, what's missing); (b) `DESIGN.md` finalized: every metric with definition, source, context
  breakdown, periods, visibility default, leaderboard eligibility; AFK rule; event contract; owner-only node names;
  GDPR deletion scope (what is deleted vs pseudonymized, e.g. ledger rows — flag for review); retention defaults;
  (c) `IMPLEMENTATION_PLAN.md`: data model (tables, keys, indexes), API endpoints + DTOs + auth per endpoint, plugin
  components, web pages, config keys and kill switches, permission nodes, per-link file lists, acceptance criteria
  and the test plan per link, performance budgets; (d) update `docs/FEATURE_REGISTER.md` rows for KNG-34 and
  `docs/specs/README.md`. Reconcile KNG-14 and KNG-23 explicitly (comment on both in Linear if tools exist).
- **Links 2-7:** as the plan says. Each code link ends with every changed module building and its tests green.
- **Link 7 also writes the final summary** in the progress report: what was built, decisions to review (ranked),
  combined live checklist for the developer, how to merge (repo order: API → plugin → app; migrations first), and
  moves the tracker row to "Recently completed" (nothing merged).

## 6. Handoff — fresh context for every link

1. Write the next link's prompt to `docs/ai-agents/handoffs/2026-10-03-player-statistics-link-<n+1>.md` using §8: what
   you left (branch heads, test counts, wiring points, open flags), phase pointers, risks. Commit and push (feature
   branch).
2. **Start the next link in a fresh context**, first option that works:
   1. **New session** — Claude Code Remote `create_session`, same environment (omit `environment_id`), model
      `claude-opus-5-5`, `source_url` `https://github.com/PandiO/knk-workspace`, `source_revision`
      `claude/kind-dijkstra-y9d279`, `title` "KNG-34 player statistics — link <n+1>", prompt: *"Read and execute
      `docs/ai-agents/handoffs/2026-10-03-player-statistics-link-<n+1>.md` in the knk-workspace repository (branch
      claude/kind-dijkstra-y9d279). It starts with a pointer to the chain charter. Work autonomously; the developer is
      not available until the whole chain is done."* Then check with `get_session` that it is running.
   2. **Fresh subagent** — otherwise: one general-purpose subagent (Agent tool, foreground) with exactly that sentence;
      read only its summary and the progress report afterwards, then repeat for the next link. You are then a
      coordinator.
   3. **Same session** — if neither exists: re-read this charter and the handoff, then continue.
   Record in the progress report which option you used.
3. Start **at most one** next link, never one the report marks done or in progress. After link 7 (or at a blocker)
   stop.

## 7. Progress report

`docs/reports/2026-10-03-player-statistics-chain.md` (never overwritten, only appended; the Summary block at the top
is the one part each link updates in place).

```
## Link <N> — <title>
Commits per repo (heads); tests vs baseline; flagged decisions L<N>-<n>; discrepancies with the design; short live
checklist; risks; what the next link must wire; how the next link was started.
```

## 8. Handoff prompt template

```
Read docs/ai-agents/handoffs/PLAYER_STATISTICS_CHAIN.md first (branch claude/kind-dijkstra-y9d279) and follow it;
it overrides anything below.

Implement link <k> — <title> end to end (code, tests, commits, push to claude/kind-dijkstra-y9d279, progress report,
handoff) as link <k> of the chain.

State you start from: <branch heads per repo, test baselines/counts, what earlier links left>.
What earlier links say this link must wire: <class/method names>.
Phase-specific reading: <design/plan sections, files>.
Open flags that affect this link: <list>.
Known risks: <list>.
Next after you: link <k+1> (or: last link — stop after the write-up).
```

## 9. Facts at chain start (2026-10-03)

From read-only scans of the trunk heads (knk-web-api `ae0b3ad`, knk-plugin `27b4236`, knk-web-app `ba0c77d`/`fc66101`).
A snapshot — verify before relying on a detail.

**knk-web-api**
- **No statistics model exists.** `Models/User.cs` has `CreatedAt` (+ `AccountCreatedVia`), `IsOnline`, `LastSeenAt`
  (overwritten by plugin-only `PUT api/users/{id}/presence` on join/quit; no history). Nothing records first join,
  logins, sessions or playtime.
- **Ledger (KNG-21) already covers XP:** `Models/Currency/CurrencyTransaction` (`Kind`, `ReasonCode`, `SourceType`/
  `SourceRef`, `IdempotencyScope`+`IdempotencyKey`, `Initiator`, `CorrelationId`, `CreatedAt`, …) + `CurrencyEntry`
  (`Currency`, `Operation`, `Amount`, `BalanceBefore`/`After`). `Enums/Currency.cs`: `Coins, Gems, Experience`. Write
  API `ICurrencyService` (`Services/Currency/CurrencyService.cs`); reason codes `Services/Currency/CurrencyReasons.cs`;
  only `CurrencyRepository` writes balances; ledger rows are protected from delete by DB triggers. XP write paths:
  `SiegeMatchService.CompleteAsync`, `DiscoveryService`, `TitleProgressionService`, `UserService.AdjustBalancesAsync`,
  `MergeWithForfeitAsync`, `CurrencyAdminService.ReverseAsync`.
- **Titles** are derived (`TitleService.ResolveAsync`: highest `TitleBracket.MinExperience` ≤ XP);
  `TitleProgressionService` pays once-ever bracket bonuses. Title changes are only stored as `AuditAction.TitleChanged`
  audit rows (JSON from/to/direction) — and the audit log is purged after 180 days (`RetentionPolicyService`,
  `AuditLogRetentionConfiguration`), so **title history needs its own durable store**.
- **Audit log:** `Models/AuditLogEntry.cs`, `IAuditLogService.RecordAsync/SearchAsync`, `GET api/audit-log`
  (`knk.admin.user.manage`).
- **Siege:** `Models/Siege/SiegeMatch` (`Status` Created/InProgress/Completed/Aborted, `EndReason`,
  `WinningAllianceGroup?` — null = draw or aborted), `SiegeMatchParticipant` (`Kills`, `Deaths`, `HighestKillStreak`,
  `Captures`, `LeftAt?`, awards), `SiegeMatchObjectiveResult` (`CapturedByUserId`). Plugin-only writes in
  `SiegeMatchesController` (create/start/participants/{id}/left/complete/abort). No gate-damage or per-player damage
  data. Note `HighestKillStreak` already exists per participant — link 1 checks what the plugin fills in.
- **Discoveries:** `UserDomainDiscovery`; `DiscoveriesController` (summary/progress readable by plugin, self or
  `knk.admin.discovery`); `GET api/discoveries/stats` staff only.
- **Authorization:** in-house permission nodes, attributes `RequirePermission`, `RequireServiceOrPermission`,
  `RequirePluginService`, `RequireServiceSelfOrPermission` (`Attributes/`); constants in `StaffPermissions`; checks via
  `IPermissionResolutionService.CheckAsync` (trailing `*` wildcards — **an owner-only node must not be matched by a
  `knk.admin.*` grant**, so use a separate prefix such as `knk.owner.`). Plugin auth: `X-API-Key` (+ optional
  `X-Acting-User-Id`), `HttpContext.GetKnkCaller()`. **No owner role/node exists**; only `User.ActiveMode.Owner`
  (`/ownermode`) and plugin node `knk.mode.owner`. Only seeded group: "Default".
- **Identity/merge:** canonical `User.Id` (int), `User.Uuid` nullable unique. `UserService.MergeAccountsAsync` soft-deletes
  the secondary user (`IsActive=false`, `ArchiveUntil +90d`); **child rows are not re-pointed** (discoveries, siege
  participants stay on the old id); merged-into relation is only derivable from `MERGE_FORFEIT` ledger rows
  (`CurrencyRepository.GetUsersMergedIntoAsync`). Statistics reads must aggregate across merged ids the same way.
- **No GDPR/deletion feature.** `DELETE api/users/{id}` hard-deletes but refuses when ledger history exists; no job acts
  on `ArchiveUntil`.
- **Patterns to reuse:** `BackgroundService` + `PeriodicTimer` (`RetentionPolicyService`, `CurrencyMonitorService`,
  `RankExpirySweepService`, registered in `DependencyInjection/ServiceCollectionExtensions.cs`); batch ingest
  `POST api/PrivateMessageLog/batch` (plugin-only, max 200, dedupe on client id); OpenTelemetry meters
  (`Services/Currency/CurrencyMetrics.cs`; `OBSERVABILITY.md` forbids player ids in metric labels). There is **no**
  Prometheus `/metrics` endpoint despite `CLAUDE.md`.
- **Tests:** xUnit + Moq + FluentAssertions + EF InMemory, ~1,300 test attributes; MySQL tests skipped unless
  `KNK_TEST_MYSQL`. **Migrations:** `yyyyMMddHHmmss_Name.cs` + Designer + maintained `KnKDbContextModelSnapshot`; latest
  `20260927174550_AddLootboxWorldPickup`; snake_case tables via `ToTable`.

**knk-web-app**
- Own account page `/account` → `src/pages/AccountManagementPage.tsx` (sections incl. `MyDiscoveriesSection` when
  linked). Staff profile `/admin/users/:id` → `src/pages/admin/PlayerProfilePage.tsx` (stack of cards; panels such as
  `PlayerDiscoveriesPanel` self-gate with `usePermission(node)` and hide on 403). **No public profile page, no
  leaderboards, no chart library** (only Tailwind bars, `DiscoveryStatsCard` "Top explorers").
- API clients: singleton classes on `src/apiClients/objectManager.ts`; controllers enum in `src/utils/enums.ts`; DTOs in
  `src/types/dtos/<domain>/`. Permissions in the UI: `usePermission(node)` / `useStaffAccess()` in
  `src/hooks/useStaffAccess.ts` (GET `Users/{id}/permissions/check?node=`). Routes in `src/App.tsx` (`StaffRoute`,
  `ProtectedRoute`); nav in `src/components/Navigation.tsx`.
- Tests: Jest/RTL via `npm run test:ci`, `__tests__/` folders; examples `PlayerDiscoveriesPanel.test.tsx`,
  `MyDiscoveriesSection.test.tsx`, `discoveryClient.test.ts`.

**knk-plugin** (P = `knk-paper/src/main/java/net/knightsandkings/knk/paper`, C = `knk-core/.../knk/core`,
A = `knk-api-client/.../knk/api`)
- **No KNG-34 gameplay statistic exists outside a Siege match**: no AFK/idle detection, no playtime, no persistent
  kill/death/damage/distance/arrow/fall counters; no `EntityDeathEvent` (PvE), `ProjectileLaunchEvent`/
  `EntityShootBowEvent`, fall-damage or `VehicleMoveEvent` listeners.
- `/user statistics` (KNG-9): `P/commands/UserCommand.java` (`statisticsLines`, `/stats` shortcut), rendered via
  `P/menu/content/ProfileView.getQuickStatsLines` (title, XP, coins, gems, prestige, premium; Javadoc: "not tracked yet,
  KNG-14").
- Sessions: `P/listeners/PlayerListener` (`onJoin`/`onLeave` → `UsersCommandApi.setPresenceById`; `onPlayerDeath`
  reads `getKiller()` and does nothing); `P/listeners/UserAccountListener` fires `P/events/UserDataLoadedEvent` once the
  user id is known (best session-start hook). Per-player timer template: `P/user/SalaryPayoutScheduler` (injectable
  `Clock`). Salary currently pays regardless of activity (AFK interaction is a link-1 question).
- Combat: `P/listeners/SiegeCombatListener` (`resolveAttacker`, headshots via `SiegeCombatRules.isHeadshot`),
  `CombatTagListener.onDamage` (MONITOR, `attackerOf` — template for a damage-stats listener),
  `SiegeDeathRespawnListener` → `SiegeService.handleMemberDeath`. In-match kills/streaks: `C/siege/SiegeMatchRoster
  .recordDeath` → `KillCredit`; reported at match end via `SiegeService.completion()` → `ParticipantResult(kills,
  deaths, highestKillStreak, captures)` through `C/siege/SiegeMatchRecorder` (retry + spool). Outcome:
  `WinResolver.Result`. **Hook without editing `SiegeService`: `P/siege/SiegeMatchObserver`** (`matchStarted`,
  `objectiveCaptured`, `matchEnded`, `memberRemoved`). Capturer = closest attacker (`C/siege/ObjectiveState`).
- Gates: `GateDoorHitService` fires `GateDoorDamageEvent`/`GateDoorIgniteEvent` (carry `getCausingEntity()`; TNT
  source not resolved, `BlockExplodeEvent` → null); `P/listeners/GateDamageConsequenceListener` applies
  `HealthSystem.applyDamage`/`GateFireSystem.igniteBlock` without the attacker; effective loss = `before - newHealth`
  in `HealthSystem.applyDamage`/`applyContinuousDamage`; `CachedGateDoor.getBurningBlocks()` is `Map<Vector, Long>`
  (expiry only) — **fire attribution needs an igniter per burning block** (new work, keep damage outcome identical).
- Movement: `P/discovery/DomainDiscoveryListener.onMove`, `P/regions/WorldGuardRegionTracker` (fires
  `OnRegionEnterEvent`/`OnRegionLeaveEvent`) — reuse for domain interaction analytics.
- Menus: `P/menu/MenuFeature` + `MenuFeatureRegistries` (features listed in `KnKPlugin` ~l.653-682, must register before
  `MenuDefinitionValidationRunner`); `P/menu/content/ProfileMenuFeature` (`profile.main`); **menu templates are seeded by
  knk-web-api `MenuTemplateSeed.Content.cs`** with a test mirror `knk-paper/src/test/resources/menu/content-seeds.json`
  (`ContentSeedFixture`); confirmation pattern: `UserManagerMenuFeature` (`MenuSession.PendingConfirmation`) and
  `KitsMenuFeature`. Funnel points: `MenuService.openMenu`/`goBack`, `MenuClickListener.onClick`,
  `C/menu/ActionRegistry.execute`, `MenuLifecycleListener`.
- API client: port in `C/ports/api/`, `A/impl/XxxApiImpl extends BaseApiImpl` (see `DiscoveriesApiImpl`), DTOs `A/dto/`,
  mappers `A/mapper/`, wire in `A/client/KnkApiClient`. Spool/retry template: `C/discovery/DiscoverySpool` +
  `DiscoveryRecorder` + `P/discovery/DiscoveryFlushTask`; `C/siege/SiegeResultSpool`; `C/dataaccess/RetryPolicy`.
- Permissions: checks via `P/permissions/KnkPermissible.hasPermission` (cache-only, fails closed, ops bypass);
  `plugin.yml` declarations are documentation. Owner node today: `ModeService.OWNER_NODE` = `knk.mode.owner`.
- Currency from the plugin: `UsersCommandApi.adjustBalanceById` (staff), salary, `/pay`, teleport fees, kits; rewards
  for siege/discovery are granted server-side. The plugin never sends a `reasonCode`.
- Tests: JUnit 5 + Mockito; static annotation counts on trunk: knk-core 888, knk-api-client 142, knk-paper 1024 (methods,
  not executed cases — link 3 records the real baseline).
