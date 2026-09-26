Read docs/ai-agents/handoffs/SIEGE_OVERNIGHT_CHAIN.md first and follow it; it overrides anything below.

Implement siege **Phase 6 — Match persistence and rewards** from docs/specs/siege-minigame/IMPLEMENTATION_PLAN.md,
end to end (code, tests, commits, push, docs, morning report, handoff), as **link 1** of the overnight chain.
You also create the morning report file (docs/reports/2026-09-26-siege-overnight-chain.md already has a skeleton;
fill it in).

## State you start from
- knk-web-api `claude/siege-minigame` at `a25b8f8`; knk-plugin `claude/siege-minigame` at `1a8704c`; web-app not needed.
- Baselines: see the charter §9 (plugin 694 / 38 / 259; web-api 633 with 5 known failures). Re-measure.
- **The match tables already exist** (Phase 2, migration `AddSiegePhase2Schema`): `SiegeMatch`,
  `SiegeMatchParticipant`, `SiegeMatchObjectiveResult`, `SiegeMatchGateSnapshot` (Phase 7), enums `SiegeMatchStatus`,
  `SiegeMatchEndReason`, and `GateStructure.CurrentSiegeId` → `SiegeMatch.Id`. Read the models before designing;
  add a migration only if something is genuinely missing (and then check the fresh-DB workflow on your push).
- **Plugin side:** `LoggingSiegeMatchesCommandApi` (knk-paper `paper/siege/`) is the placeholder behind the core port
  `SiegeMatchesCommandApi` (knk-core `core/ports/api/`) with provisional records `KnkSiegeMatchRecords`
  (`Participant`, `ParticipantResult`, `ObjectiveResult`, `Completion`, `ParticipantReward`, `RewardSummary`). Phase 4
  said Phase 6 may reshape them.

## What Phase 5 says Phase 6 must wire (plan, Phase 5 status block)
- Build the HTTP `SiegeMatchesCommandApiImpl` in knk-api-client (DTOs + mapper, Kits/Siege Phase 4 style, register in
  `KnkApiClient`) and pass it instead of `LoggingSiegeMatchesCommandApi` in `KnKPlugin.initializeSiege()`.
  Keep the logging class (or delete it) - your call, flag it.
- Call sites already exist in `SiegeService`: `createMatch` in `onDraw` (future kept as
  `SiegeLobbyRuntime.matchIdFuture`), `startMatch` in `onStartMatch` (userId + team id per roster member),
  `participantLeft` in `removeMember` (leave/quit/kick during a match), `completeMatch` (built by `completion(...)`:
  `WinResolver.Result`, roster stats, one `ObjectiveResult` per capture with capturer userId and time, or the final
  holder when never captured) or `abortMatch` in `onEndMatch`; `abortMatch` in `onCancel` when a row exists and via
  `stop(SERVER_RESTART)` on disable.
- `printRewardSummary` already prints a non-empty `RewardSummary`; then remove the provisional line (`rewardLine`'s
  "provisional" wording) - keep the per-member stats line.
- Still Phase 6: retry `complete`/`abort` with the existing `RetryPolicy`; spool failures to
  `siege-vault/pending-results/<matchId>.json` and replay them on the next enable (idempotency makes replay safe);
  startup recovery of rows left `InProgress`/`Created` (abort them as `ServerRestart`); decide what happens when
  `createMatch` fails (today later calls for that round are skipped) - e.g. retry once, else continue the round
  unrecorded and log loudly. Never block the main thread; hop back with `runTask` for anything touching Bukkit.

## Web-api scope (DESIGN §3.10, §7.5–7.6, §11.2)
- `SiegeMatchService` + `SiegeMatchesController` (`api/siege-matches`, the route style the siege controllers already
  use - check `SiegeLobbiesController`): `POST` create (Created), `POST {id}/start` (participants + teams),
  `POST {id}/participants/{userId}/left`, `POST {id}/complete` (compute + grant rewards **in one transaction**,
  mark Completed, return the per-player breakdown; a repeat call returns the stored result without granting again),
  `POST {id}/abort` (no rewards), `GET ?userId=&lobbyId=` history. Leave `GET {id}/gate-snapshots` to Phase 7.
- Rewards exactly per DESIGN §7.6: win (coins/exp/gems), holding (objectives the participant's team holds at the end
  and did not hold at the start), capture (once per participant per objective); only participants still in the match
  at the end; XP through the existing user XP path so title brackets advance (find how `TitleService`/user XP updates
  work today); amounts stored on `SiegeMatchParticipant`. Not written to the admin AuditLog.
- **Auth:** DESIGN says match write endpoints accept only the plugin's service client. Today most controllers are
  unauthenticated; `KitsController` has one bare `[Authorize]` endpoint; `Program.cs` has a `RequireAdmin` policy and
  there is an `AdminClientsController`. Find what the plugin's bearer token actually satisfies (knk-plugin
  `config.yml` → `api.auth`, `BearerAuthProvider`) and protect the write endpoints with the strictest mechanism the
  plugin already passes. If that would lock the plugin out, fall back to the existing pattern and **flag it prominently**.
- Tests (plan Phase 6): reward matrix (winner/loser/left-early/captures/holding for 2- and 3-team scenarios),
  idempotent double-complete, abort grants nothing, XP increments move the player's `TitleBracket`. Follow the
  existing web-api test style (see `ClanServiceTests`, `KitServiceTests`).

## Phase-specific reading
- Plan: Phase 6 section, Phase 2 status (schema decisions), Phase 4 status (decision 14: records provisional),
  Phase 5 status ("What Phase 6 must wire").
- DESIGN §3.10, §5.1, §7.5, §7.6, §11.2.
- knk-web-api: `Models/Siege/SiegeMatch*.cs`, the siege services/controllers from Phase 2, `KitService` (a recent
  service with transactional grants), the user XP/coins update path.
- knk-plugin: `SiegeService`, `KnkSiegeMatchRecords`, `SiegeMatchesCommandApi`, `SiegeLobbiesQueryApiImpl`
  (client style), `RetryPolicy`/`DataAccessExecutor` (knk-core), `SiegePlayerVault` (file-writing style).

## Open flags that affect this phase
- Phase 5 decision 3: each round has a UUID match token (PDC tags, vault) separate from the match id. Keep it.
- Phase 5 decision 20: cancels after the draw abort with `NOT_ENOUGH_PLAYERS`.
- Participants without a cached userId are skipped in `start`/`complete` today - keep or improve, and flag.

## Known risks
- Reward idempotency under concurrent calls (retry + replay): use the match status + a transaction/row lock.
- The fresh-DB migration workflow if you add a migration.

## Next in the chain after you
Phase **7a** (gate integration + area lockdown, not 7b). Write `docs/ai-agents/handoffs/<date>-siege-phase-7a.md`
from the charter template, then start the next session or continue yourself (charter §6).
