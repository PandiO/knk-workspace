# Code knowledge graph over MCP: trial

**Status:** In progress — Steps 1–2 done (baseline, vetting); Steps 3–4 (install, measure) wait for the developer's
approval of the two tools · **Last updated:** 2026-11-22
**Branch:** knk-workspace `claude/relaxed-shannon-3t43yr` (not merged; time-boxed trial). Code repos read at
knk-web-app `31a6896`, knk-web-api `75b8434`, knk-plugin `2411d78` (`main`).

Goal: see whether an auto-generated code graph exposed over MCP lets agents answer "who calls this?", "what depends on
this?" and "which web-app call hits which API endpoint?" with fewer tokens than grep-and-read. Agent-first overview
written for this: [system overview](../architecture/system-overview.md).

## 1. Baseline (no graph tool)

Method: each task ran once in a fresh general-purpose subagent with the same neutral prompt (normal file tools only,
no workspace docs). Tokens are the subagent's total; an empty "reply ok" agent costs **72,996** (system prompt, tool
definitions, CLAUDE.md files), so the **net** column is what the task itself added. Correctness is checked against
ground truth I built by hand (§ 4).

| # | Task | Tokens (total / net) | Tool calls | Time | Correct |
|---|---|---|---|---|---|
| T1 | Who calls `RevokeAllSessionsAsync` (C#, through wrappers) | 78,777 / 5,781 | 5 | 30 s | Yes, 9/9 |
| T2 | `POST api/Towns/search`: handler chain + every web-app and plugin caller | 93,839 / 20,843 | 17 | 91 s | Yes, complete (found a caller my first ground truth missed) |
| T3 | What depends on the plugin port `TownsQueryApi` (Java impact) | 84,418 / 11,422 | 3 | 27 s | Yes, 11/11 |
| T4 | Town edit in the web app → realtime event → plugin cache invalidation | 103,976 / 30,980 | 16 | 98 s | Yes, every hop |
| T5 | `KitsController`: each endpoint × web-app client method × plugin client method | 84,331 / 11,335 | 5 | 28 s | Yes, 13/13 |
| | **Sum** | **445,341 / 80,361** | **46** | | **5/5** |

What this says before any tool is installed:

1. **The baseline is already good.** Consistent naming across repos (`TownsController` / `TownClient` /
   `TownsQueryApiImpl`) and literal path constants in the plugin make grep effective. A graph tool has to beat
   ~5–31k net tokens per question, not a struggling agent.
2. **Fixed overhead dominates.** 73k of every agent's tokens is context loaded before it does anything; a graph tool
   that adds a large tool schema or server instructions raises that floor for every session, used or not.
3. **The hard cases are cross-language and indirect:** T2 and T4 cost the most. T2's trap cases (a `towns::search`
   method reference, a commented-out caller, a generic `getSearchFunctionForEntity('town')` dispatch) are exactly what
   a graph should resolve, or get wrong.
4. **Web app → API links are not literal.** The web app builds URLs at run time from
   `invokeServiceCall(data, operation, Controllers.Towns, HttpMethod.Post)`, so no tool can link them by matching URL
   string literals. Any cross-language edge there will need the tool to resolve an enum value plus a string argument.

## 2. Candidate vetting

Checked 2026-11-22 from shallow clones of each default branch (read only; nothing built, installed or run).
"Commits" = commits since 2026-08-01.

| | colbymchenry/codegraph | sdsrss/code-graph-mcp | DeusData/codebase-memory-mcp | CodeGraphContext (Shashankss1205) |
|---|---|---|---|---|
| Last commit / activity | 2026-11-20 · 1,171 commits | 2026-11-20 · 1,091 | 2026-11-19 · 3,547 | 2026-11-21 · 351 |
| Version | 1.6.4 (npm) | 0.204.0 (npm-wrapped Rust binary) | C binary (install script, npm, PyPI, Homebrew) | 0.6.13 (PyPI) |
| License | MIT | MIT | MIT | MIT |
| Java / C# / TS | Yes / Yes / Yes | Yes / Yes / Yes | Yes / Yes / Yes | Yes / Yes / Yes |
| HTTP route ↔ caller links | No | Express, Go net/http, Flask/FastAPI, axum only — **not ASP.NET or Spring** | **Yes:** Route nodes, ASP.NET attribute routes incl. `[controller]` token, HTTP client patterns (OkHttp among them), cross-repo `CROSS_HTTP_CALLS` matching | No |
| Storage | `.codegraph/` in each project (SQLite) | `.code-graph/` in each project (SQLite) | `~/.cache/codebase-memory-mcp/` (outside the repos) | `~/.codegraphcontext/`, embedded KùzuDB/LadybugDB or Neo4j |
| Runs fully locally | Yes, but see network | Yes, but see network | Yes | Yes (Neo4j optional, needs Docker) |
| Telemetry / network | **Telemetry on by default** (anonymous daily rollups to `telemetry.getcodegraph.com`: tool names, counts, language names, file-count bucket, machine UUID) + daily GitHub version check. `DO_NOT_TRACK=1` disables both; `--no-telemetry` per server | No telemetry found. **Auto-update** downloads new binaries from GitHub releases (`CODE_GRAPH_NO_AUTO_UPDATE=1`); embedding model downloaded lazily (`CODE_GRAPH_DISABLE_MODEL_DOWNLOAD=1`) | **None:** README states no telemetry and no background requests; no update check | No telemetry; network only for the opt-in `registry`/bundle commands (Hugging Face) |
| Install script | `install.sh` curl-pipe; fetches the release tarball. npm provenance and signed/attested releases | Claude plugin with ~25 hook scripts (pre-Grep/Read/Edit guides, statusline, session init, `adopt.js` edits `CLAUDE.md`), auto-update via `curl` | `install.sh` HTTPS-only with redirects pinned to HTTPS; plain HTTP only to a loopback mirror; mandatory checksum (from the same release, so integrity not authenticity) | `pip install`; no install hooks |
| Something to watch | Installer offers a Claude Code `UserPromptSubmit` hook (opt-in) and wires agents automatically | Most invasive: changes how Grep/Read behave and rewrites `CLAUDE.md` | Very high churn (3.5k commits in 4 months): pin a version | Its own repo ships call-graph audit and inconsistency reports listing failures |

Nothing malicious found in any install path. The concerns are default-on telemetry (codegraph), self-updating binaries
and hook-heavy agent changes (code-graph-mcp), and churn (all four, codebase-memory-mcp most).

### Recommendation: trial two

1. **DeusData/codebase-memory-mcp** — the only candidate whose route linking matches this stack (ASP.NET attribute
   routes, OkHttp in the plugin); no telemetry or background network; index lives outside the repos.
2. **colbymchenry/codegraph** — the auto-syncing symbol graph, best-documented exclusions (`.gitignore` +
   `codegraph.json` `exclude`), signed releases. Run with `DO_NOT_TRACK=1` and `--no-telemetry`, without its prompt
   hook.

Not trialled: **code-graph-mcp** (its headline route tracing doesn't cover ASP.NET or Spring; auto-update and hooks
change agent behaviour beyond an MCP server), **CodeGraphContext** (no route linking, Python plus a graph DB for no
gain here; its own audit lists call-graph failures). If the two trialled tools fail on cross-language links,
CodeGraphContext's Neo4j backend is the "real graph database" escalation to weigh.

## 3. Trial

_Pending approval._

## 4. Ground truth

T1 — methods reaching `SessionRevocationService.RevokeAllSessionsAsync`: via `AuthService.RevokeAllSessionsAsync`
(delegating): `AuthController.LogoutAll`, `AuthService.UpdateUserAsync`, `AuthService.ResetPasswordAsync`; via the
private `UserService.RevokeSessionsAsync`: `UserService.UpdateAsync` (2 sites), `DeleteAsync`, `ChangePasswordAsync`,
`UpdateEmailAsync`, `MergeWithForfeitAsync`, `DetachWebLoginAsync`.

T2 — `TownsController.SearchTowns` → `TownService.SearchAsync` → `TownRepository.SearchAsync`. Web app:
`TownClient.searchPaged`, called by `RoadProfilesCard` and by `getSearchFunctionForEntity('town')`
(`entityApiMapping.ts`), which `PagedEntityTable`, `RelationPicker` and `ManyToManyRelationshipEditor` call. Plugin:
`TownsQueryApiImpl.search`, called by `GameSettingsManager`, `TownsDebugCommand` and `ManagedRegionSpecSource`
(`towns::search`). Decoy: the commented-out call in `RegionDomainResolver`.

T3 — 11 files: knk-core `TownsDataAccess`, `ManagedRegionSpecSource`, `RegionDomainResolver` (holds it, calls
commented out); knk-api-client `TownsQueryApiImpl`, `KnkApiClient`; knk-paper `KnKPlugin`, `DataAccessFactory`,
`ManagedRegionsBootstrap`, `GameSettingsManager`, `KnkAdminCommand`, `TownsDebugCommand`.

T4 — `TownClient.update` → `PUT api/Towns/{id}` → `TownsController.Update` → `TownService.UpdateAsync` → SaveChanges
→ `RealtimeEntityChangeInterceptor` → `RealtimeEntityChangeMap.Map` (Town allow-listed, key `WgRegionId`,
`EntityChanged`) → `AfterCommitRealtimeEventSink` → `RealtimePublisher` → `RealtimeDispatchService` /
`HubContextRealtimeTransport` → `GameServerHub` (`/api/hubs/game`) → plugin `SignalRHubTransport` / `RealtimeClient` →
`RealtimeService` → `RealtimeDispatcher` → `ConfigRealtimeSync.onEntityChanged` → `EntityChangeRouter.route` →
handlers from `KnKPlugin.entityChangeRouter`: `TownsDataAccess.invalidate`, `DomainCatalogDataAccess.invalidate`,
`RegionDomainResolver.clearRegionCache`.

T5 — 13 endpoints. Web `KitClient`: getAll, getById, create, update, delete, searchPaged, getAvailableForUser, give.
Plugin: `KitsQueryApiImpl` getById, search, getAvailableForUser; `KitsCommandApiImpl` claimAsync, purchaseAsync,
giveAsync, pendingDeliveriesAsync, markDeliveredAsync, grantFirstJoinKitsAsync. Web-only: GET all, POST, PUT, DELETE.
Plugin-only: claim, purchase, deliveries pending/delivered, grant-first-join. Both: GET by id, search, available, give.
