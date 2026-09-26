Read docs/ai-agents/handoffs/SIEGE_OVERNIGHT_CHAIN.md first and follow it; it overrides anything below.

Implement siege **Phase 6b — plugin wiring of match persistence and rewards** from
docs/specs/siege-minigame/IMPLEMENTATION_PLAN.md (Phase 6; the web-api half, 6a, is done), end to end (code, tests,
commits, push, docs, morning report, handoff), as **link 2** of the overnight chain. After 6b the chain continues with
Phase **7a** (write `docs/ai-agents/handoffs/<date>-siege-phase-7a.md` from the charter template, then start the next
session or continue yourself, charter §6).

## Precondition - check this FIRST, before claiming anything

Link 1 stopped because **knk-plugin can't be built in the cloud container**: the environment's network policy denies
`repo.papermc.io` (paper-api) and `maven.enginehub.org` (WorldEdit/WorldGuard), so Gradle can't resolve
dependencies (`Received status code 403`, and the agent proxy status lists them as `connect_rejected`). Don't route
around the policy (no mirrors, no rebuilding Paper from source, no stub jars) - that was refused in link 1.

1. Clone knk-plugin, check out `claude/siege-minigame`, run `./gradlew build -x deployToDevServer`.
2. If dependency resolution still fails with 403 on those hosts: **stop** (charter §1.3/§4). Don't change any repo.
   Add one line to the morning report ("link 2 found the build still blocked, nothing done") and to the chain's row
   in `ACTIVE_SESSIONS.md`, push the workspace, and don't start another session.
3. If it builds, record the baselines (they have never been measured on the current head, see below) and go on.

The developer can unblock it by adding `repo.papermc.io` and `maven.enginehub.org` to the cloud environment's
allowed domains (environment settings → Network access), or by running this link locally.

## State you start from
- knk-web-api `claude/siege-minigame` at `7d4fd44` (Phase 6a: `b86d692`, `82b78a4`, `7d4fd44`). Test baseline
  **709 with 5 known failures** (ClientActivityStore, 2× PathResolution `Town.*`, FieldValidation
  ConditionalRequired, FormSubmissionProgressRepository) - compare by name. Build the csproj and test
  `Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` directly (the `.sln` has a `tests/` path that breaks on Linux).
  .NET 8: `dotnet-install.sh` is blocked, but `apt-get install -y dotnet-sdk-8.0` (Ubuntu archive) works.
- knk-plugin `claude/siege-minigame` at `d41be49` = Phase 5 (`1a8704c`) + a trunk merge of main
  (InventoryMenu content port / `claude/menu-content`). **That merge has not been built or tested in any session
  this chain knows of**; the charter's baselines (knk-core 694, api-client 38 with 2 skipped, knk-paper 259 with 14
  skipped) are for `1a8704c`. Measure the real baseline first; if the merge itself doesn't compile or fails tests,
  fixing it mechanically is in scope (flag it), anything bigger is a blocker.
- Title-bracket overlap (charter §9): already resolved in `d41be49` - one `TitleBracketsQueryApi` with `listAll()`
  (menu, `TitleBracket`) and a default `getAll()` → `KnkTitleBracket` (siege) on `GET /api/title-brackets`.
- web-app not needed.

## What Phase 6b must wire
Read the plan's **"Phase 6 status"** block first: its "Request shapes" list is the API contract, its decisions 1-11
say how the server behaves on retries/replays. Then:
- `SiegeMatchesCommandApiImpl` in knk-api-client (DTOs + mapper in the `SiegeLobbiesQueryApiImpl` style; register in
  `KnkApiClient`), calling `POST /siege-matches`, `POST /siege-matches/{id}/start`,
  `POST /siege-matches/{id}/participants/{userId}/left`, `POST /siege-matches/{id}/complete`,
  `POST /siege-matches/{id}/abort`, `POST /siege-matches/abort-unfinished` (relative to `api.base-url`, which ends in
  `/api`). Enums go over the wire as PascalCase names (`SiegeEndReason.apiName()`). Pass it instead of
  `LoggingSiegeMatchesCommandApi` in `KnKPlugin.initializeSiege()` (keep or delete the logging class - flag it).
- `KnkSiegeMatchRecords` (knk-core, provisional since Phase 4): reshape only what the breakdown needs, e.g.
  `ParticipantReward` gains `presentAtEnd`, `holdingCount`, `captureCount`; the port may gain
  `abortUnfinished(SiegeEndReason)` returning the ids.
- `SiegeService` call sites already exist (Phase 5 status, "What Phase 6 must wire"): `createMatch` in `onDraw`
  (future in `SiegeLobbyRuntime.matchIdFuture`), `startMatch` in `onStartMatch`, `participantLeft` in `removeMember`,
  `completeMatch`/`abortMatch` in `onEndMatch`, `abortMatch` in `onCancel` and via `stop(SERVER_RESTART)` on disable.
  `printRewardSummary`: print the server's breakdown; remove the provisional `rewardLine` wording (keep the per-member
  stats line). Don't announce a promotion from `titleChange` - the API already queues a `TitleChanged` notification
  for the plugin's poller (Phase 6 decision 2).
- Retry `complete`/`abort` with the existing `RetryPolicy`; on final failure spool the request to
  `siege-vault/pending-results/<matchId>.json` (see `SiegePlayerVault` for the file style) and replay the spool on the
  next enable, **then** call `abort-unfinished` with `ServerRestart` (so a spooled `complete` isn't aborted first).
  A 409 on replay means the server already has a final state - drop the file.
- Decide `createMatch` failure handling (today later calls for that round are skipped): e.g. retry once, else run the
  round unrecorded and log loudly - flag it.
- Never block the main thread; hop back with `runTask` for anything touching Bukkit.
- Participants without a cached userId are skipped in `start`/`complete` today - keep or improve, and flag.
- Tests: mapper/DTO round-trip (knk-api-client), spool/replay and retry decisions as pure logic (knk-core, no
  Bukkit imports in `core/siege/`), plus whatever knk-paper tests the existing style allows.

## Phase-specific reading
- Plan: Phase 6 section + "Phase 6 status"; Phase 5 status ("What Phase 6 must wire", decisions 3, 5, 20); Phase 4
  status decision 14.
- DESIGN §3.10, §5.1, §5.3, §7.6, §11.2.
- knk-plugin: `SiegeService`, `KnkSiegeMatchRecords`, `SiegeMatchesCommandApi`, `LoggingSiegeMatchesCommandApi`,
  `SiegeLobbiesQueryApiImpl`, `KnkApiClient`, `RetryPolicy`/`DataAccessExecutor` (knk-core), `SiegePlayerVault`.
- knk-web-api (read-only reference): `Dtos/SiegeMatchDtos.cs`, `Controllers/SiegeMatchesController.cs`.

## Open flags that affect this phase
- Phase 6 decision 1: the write endpoints are open until `Security:PluginServiceKey` is set; the plugin's existing
  `api.auth.type: apikey` sends the key. Nothing to wire, but don't hard-code an auth type.
- Phase 5 decision 3: each round has a UUID match token separate from the match id. Keep it.
- Phase 5 decision 20: cancels after the draw abort with `NOT_ENOUGH_PLAYERS`.

## Known risks
- The unverified `d41be49` trunk merge (see above).
- Replay ordering on enable (spool before abort-unfinished).
- Reward idempotency is server-side (row lock + status), so retries/replays are safe; don't add client-side dedupe
  that could drop a legitimate first call.

## Next in the chain after you
Phase **7a** (gate integration + area lockdown, not 7b).
