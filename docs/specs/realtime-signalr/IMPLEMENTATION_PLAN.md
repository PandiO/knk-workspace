# Realtime channel (SignalR) — implementation plan

**Status:** Accepted (developer decisions 2026-10-26, [DESIGN.md](DESIGN.md) §12). **No code yet.** S1 starts while #177 link 2 is built.
**Last updated:** 2026-10-26
**Issue:** [PandiO/knk-workspace#66](https://github.com/PandiO/knk-workspace/issues/66) (KNG-57); phase issues are sub-issues of #66
(numbers in the table below).
**Order across features:** [2026-10-25-ux-dashboard-signalr-plan.md](../../ai-agents/handoffs/2026-10-25-ux-dashboard-signalr-plan.md)
(the dashboard/form wizard work goes first; S1 can start in parallel because it touches other repos).

## Branches

One standing branch per repo for the feature (global instructions): `claude/realtime-signalr` in knk-web-api,
knk-plugin, knk-web-app and knk-workspace, based on each repo's current default branch (`master` for knk-web-api,
`main` for the others). World-task hardening (WT1) is its own feature and branch (`claude/world-task-hardening`)
because it is useful without the hub and touches different files.

## Phases

| Phase | Issue | Repos | Content | Depends on | Size |
|---|---|---|---|---|---|
| **S1 Foundation** | #178 | API, plugin, workspace | Hubs (`/api/hubs/game` with API key + server id; `/api/hubs/web` with JWT query-string token), envelope + `seq`, `IRealtimePublisher` with a bounded channel, `PresenceRegistry` (roster/joined/left → `IsOnline`/`LastSeenAt`, grace on disconnect), plugin `RealtimeClient` (shaded SignalR client, backoff reconnect gated by `ApiConnectivityMonitor`, resync-on-connect hook list, `realtime.*` config, metrics), `realtime.server-id` used for world-task claims instead of `"localhost"`, nginx/production docs | design Q1, Q2, Q5, Q15 | M–L |
| **S2 User state push** (R1) | #179 | API, plugin | `UserPermissionsChanged` (also drops offline-store answers: #76), `PermissionGroupChanged`, `UserBalancesChanged`, `UserFrozenChanged`, `UserModeChanged`, `UserChanged`, hub-backed `IPlayerNotificationQueue` (poller only while hub down), slowed periodic re-syncs (Q4); re-check the #76 display symptom | S1 | M |
| **WT1 World-task hardening** (REST) | #180 | API, plugin, web app, workspace (world-tasks docs) | Schema (creator from JWT, claimer uuid/user id, `ExpiresAt`, `LeaseUntil`, `RowVersion`, target/offer columns unused yet), state machine with conditional updates + 409s, task code checked on claim, unique among open tasks, `RandomNumberGenerator`, renamed "task code" (`/knk task <code>`), id claims only with `knk.tasks.any`, **tasks anchored to the draft** (one session per draft, `WorldTask.FormSubmissionProgressId` + `AppliedAt`, silent draft save on the first task, reattach and apply on mount; DESIGN §8.7), `cancel`/`release`/`heartbeat`/`open` endpoints, `WorldTaskSweepService`, plugin hygiene (UUID keys, main thread, release on cancel/quit/disable, heartbeat, headless claim-before-run, fail unknown task types), web hygiene (cancel on Capture again/Try again/leave, reattach after reload, closed states with Start again), form builder task-type list, `WorkflowSession.UserId` from the JWT; correct `docs/specs/world-tasks/*` | #186 (drafts owned by the caller) | M–L |
| **WT2 World tasks over SignalR** (R3–R5) | #181 | API, plugin, web app | "Send to Minecraft" = auto (offer + claim for the online initiator), "Hand off to…" (Accept/Decline, 2 min), busy check before sending with Queue / Hand off / Replace / Cancel (`GET active-for-me`), queue delivery when a task ends, presence lookup, `WorldTaskOffered`/`Cancelled`/`Created` to the game hub, auto-claim for the initiator, Accept/Decline for admin B, queue when busy, `WorldTaskOfferResult`, `GET /api/presence/me` + `online-staff`, web `RealtimeProvider` + `@microsoft/signalr`, `WorldBoundFieldRenderer` on `WorldTaskUpdated` (10 s poll only while disconnected), catalog scan card on `CatalogScanUpdated` | S1, WT1 | M–L |
| **S3 Config and entity push** (R2) | #182 | API, plugin | `EntityChanged` (option A: interceptor + allow-list behind one event sink, sent after commit; outbox = option C later, DESIGN §4.3), `GateChanged` (after-match rule Q12), `DomainAccessChanged`, `GameSettingsChanged`, `SiegeConfigChanged`, `LootboxConfigChanged`, teleport/navigation/road/telemetry events, `ReportWorlds`; run startup-only siege work on (re)connect (#31) | S1 | M |
| **S4 Web live updates** (nice-to-have) | #183 | API, web app | `EntityChanged` to `staff` → dashboard refresh of the shown type; `PresenceChanged` on profile/moderation | S1, WT2 (web client), dashboard hub #177 | S |
| **S5 Erasure push** (GDPR) | #184 | API, plugin | `AccountErased` + persisted catch-up (`GET /api/privacy/erasures?since=`), plugin deletes local data, kick if online | S1; KNG-58 store | M |
| **S6 Region calls over the hub** (optional) | — (not filed; decide later, Q13) | API, plugin | rename + containment as hub invocations with client results; retire `RegionHttpServer` | S1 | M |

S2 and WT1 can run in parallel (different files: WT1 is world-task code, S2 is user/permission code). WT2 needs both
S1 and WT1. S3 after S2 (same dispatcher, more handlers).

## Per phase: verification

- **Unit/integration tests** in each repo as usual (API xUnit with an in-memory hub client via
  `Microsoft.AspNetCore.SignalR.Client` against `WebApplicationFactory`; plugin core tests for dispatcher, backoff and
  resync ordering; web app tests for the provider and `WorldBoundFieldRenderer` states).
- **Dev server smoke test** (a new `docs/guides/realtime-smoke-test.md` per phase section): kill the API mid-session
  and check the fallback; restart the API and check the resync; change a rank/grant/balance/freeze/mode in the web app
  with the player online and measure "visible in game" (target < 2 s); world tasks: initiator online → auto-claim;
  initiator offline → code; admin B → Accept/Decline; plugin restart mid-task → release; web "Capture again" →
  cancel; reload → reattach.
- `realtime.enabled: false` until the developer's live check of that phase passes; the alpha gets it after the dev
  server.

## Docs to update as phases land

See DESIGN §10. Each phase updates the living docs it touches and adds its CHANGELOG line on merge.
