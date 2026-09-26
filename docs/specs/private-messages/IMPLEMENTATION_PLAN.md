# Private Messages & Social Spy — Implementation Plan

**Status:** Draft — awaiting developer review (open questions in DESIGN.md §5)
**Last updated:** 2026-09-26
**Linear:** [KNG-18](https://linear.app/kngpandi/issue/KNG-18/private-messages-harden-msg-and-r-social-spy-toggle-ignore-list)
**Sources:** [DESIGN.md](DESIGN.md); `knk-plugin` `main` @ `f65ae2e`; `knk-web-api` `master` @ `a102eea`;
`docs/specs/inventory-menu/CONTENT_PORT_PLAN.md` §9 (CP7 plugin auth); `docs/ACTIVE_SESSIONS.md` (branch convention).

Path shorthands: `P:` = `knk-plugin:knk-paper/src/main/java/net/knightsandkings/knk/paper/`,
`PT:` = `knk-plugin:knk-paper/src/test/java/net/knightsandkings/knk/paper/`,
`C:` = `knk-plugin:knk-core/src/main/java/net/knightsandkings/knk/core/`,
`AC:` = `knk-plugin:knk-api-client/src/main/java/net/knightsandkings/knk/api/`, `A:` = `knk-web-api:`.

**Branch convention** (`docs/ACTIVE_SESSIONS.md`): one standing branch per feature per repo —
`claude/private-messages` in knk-plugin (from `main`), knk-web-api (from `master`) and knk-web-app (from `main`, Phase 4
only). Every phase lands on that branch; merge to trunk per phase after the developer's in-game check. Claim the
feature (not the repo) in `ACTIVE_SESSIONS.md` before starting.

**Phase overview**

| Phase | Repos | Size | Depends on | Independently shippable |
|---|---|---|---|---|
| 1 — Harden `/msg`/`/r`, social spy v2, local log, vanilla bypass | plugin | M | — | yes |
| 2 — Ignore list | web-api + plugin | M | Phase 1 (gate chain) | yes |
| 3 — Server-side PM log + retention | web-api + plugin | M | Phase 1; **plugin API auth (CP7 option 1)**; DESIGN §5 Q1 | yes |
| 4 — Web-app PM log viewer | web-app | S | Phase 3 | yes |
| F — Follow-ups outside this feature | plugin (siege branch) | S | Phase 1 | — |

---

## Phase 1 — Harden messaging and social spy (knk-plugin only)

**Goal:** everything in DESIGN §3.3 except ignore and the API log sink. No API or DB changes.

**knk-core (new, Bukkit-free):**
- `C:messaging/ParticipantId.java` — record: `UUID uuid` or `CONSOLE`.
- `C:messaging/ReplyTargets.java` — link map + rules from DESIGN §3.3.3 (`recordDelivered`, `resolve`, `forget`).
- `C:messaging/RateLimiter.java` — sliding window + duplicate window, injectable `Clock`.
- `C:messaging/PrivateMessageGate.java` — `Optional<Denial> check(SendAttempt)`; `Denial` = reason enum + player message.
- `C:messaging/SpyRules.java` — `boolean shouldSee(spy, sender, recipient)` given cached flags (participant, toggle,
  exempt).

**knk-paper (changed/new):**
- `P:user/MessagingService.java` — becomes the orchestrator: gate chain → length cap → deliver → `ReplyTargets` →
  `SpyService` → `PrivateMessageLogger`. Remove the Bukkit `knk.staffchat` spy loop; fix the Javadoc.
- `P:commands/MessageCommand.java`, `P:commands/ReplyCommand.java` — `TabExecutor`, `VisiblePlayers` resolution, console
  `/r`, messages from DESIGN §3.3.7.
- New `P:commands/support/VisiblePlayers.java` (`canSee`-aware lookup + completion).
- New `P:commands/SocialSpyCommand.java` (`/socialspy [on|off]`, alias `spy`).
- New `P:user/SpyService.java` — cached audience/exempt sets via `KnkPermissible.hasPermissionAsync`, PDC toggle
  (`knk:socialspy`), periodic refresh task.
- New `P:chat/PrivateMessageFormat.java` — Adventure lines, hover/click, rank colours via `TabListTeam.resolve`.
- New `P:user/PrivateMessageLogger.java` — interface + `LocalFilePrivateMessageLog` (single-thread executor, daily files,
  retention sweep).
- New `P:listeners/VanillaMessagingBlockListener.java` (rewrite `/minecraft:msg|tell|w`, cancel `/teammsg`, `/tm`, `/me`).
- New `P:listeners/PrivateMessageSessionListener.java` — join: spy audience refresh; quit (`MONITOR`): forget reply links,
  spy flags, rate-limit state.
- `P:listeners/AdminFreezeListener.java` — let `/msg`/`/r` (+aliases) through; `FrozenGate` in `MessagingService`
  limits targets to `knk.freeze` holders.
- `P:KnKPlugin.java` — `registerTabCommand("msg"|"reply"|"socialspy", …)` instead of `registerSimpleCommand`; wire services
  and listeners.
- `knk-paper/src/main/resources/plugin.yml` — aliases (`message, tell, whisper, w, m, pm`; `r`; `spy`), `socialspy`
  command, nodes from DESIGN §3.5 (`default: op`); reword `knk.staffchat` description (no longer drives spy).
- `knk-paper/src/main/resources/config.yml` + `P:config/KnkConfig.java` / `ConfigLoader.java` — `private-messages:` block
  (DESIGN §3.3.10), `PrivateMessagesConfig` record.

**Tests:**
- knk-core: `ReplyTargetsTest` (reciprocal link, blocked message sets no link, vanished partner only when
  `initiatedByPartner`, console partner, forget-on-own-quit keeps inbound links), `RateLimiterTest` (window, duplicate,
  bypass), `SpyRulesTest` (participants excluded, toggle off, exempt either side, exempt spy sees exempt PM).
- knk-paper: `PT:chat/PrivateMessageFormatTest` (plain-text serialisation of each line, click = `suggest_command
  "/msg Bob "`, user text not parsed — `&c<b>` stays literal), `PT:commands/MessageCommandsTest` (Mockito: unknown /
  offline / vanished target → identical message; self; usage; console send and console reply), `PT:listeners/
  VanillaMessagingBlockListenerTest` (rewrite and cancel cases, op bypass).

**Acceptance (in-game, 3 accounts A, B staff S, plus console):**
1. S in staff mode is invisible to A; `/msg S hi` from A → `No online player found named 'S'.`, same text as `/msg Nobody hi`;
   tab completion from A never offers S.
2. S messages A while vanished; A's `/r` reaches S. After A later messages B, then B logs out, A's `/r` → `B is no longer online.`
3. Console `/msg A hi` → A sees `[CONSOLE -> me] hi`, A `/r ok` appears in the console; console `/r` answers A.
4. S (granted `knk.socialspy`, non-op) sees `[Spy] A -> B: …`; `/socialspy off` stops it and survives a restart; a PM from
   an owner holding `knk.socialspy.exempt` is not shown to S.
5. Six PMs in 5 s → the sixth is refused with the wait time; S doesn't see the refused one.
6. `/minecraft:tell B hi` behaves like `/msg B hi`; `/tm hi` and `/me hi` are refused.
7. Frozen A can `/msg S` but not `/msg B`.
8. `plugins/KnightsAndKings/logs/private-messages-<today>.log` contains the delivered lines; files older than 30 days are
   removed on enable.
9. Hover/click: clicking a received PM fills `/msg <sender> ` in the chat box.

**Size:** M (≈ 2 evenings). **Dependencies:** none. Note for the siege branch: see Phase F.

---

### Phase 1 status — done 2026-09-26 (knk-plugin `claude/private-messages`)

Commits `97ccfc5` (knk-core `messaging/`: `ParticipantId`, `ReplyTargets`, `RateLimiter`, `PrivateMessageGate` chain with
`FrozenGate`/`RateLimitGate`, `PrivateMessageNodes`, `SpyRules`), `43fb9ac` (knk-paper: `commands/support/VisiblePlayers`,
`MessagingService`, Adventure formatting + click-to-reply, console both ways, `/socialspy`, local PM log, vanilla
`/minecraft:msg`/`/teammsg`/`/me` blocking, frozen players can message `knk.freeze` holders), `15d5f10` (test fix);
trunk (KNG-16) merged in `8476d6d`. CI green: https://github.com/PandiO/knk-plugin/actions/runs/36251319236 (81 new tests).

Deviations: gates live in knk-core with pre-resolved nodes; "started by partner" persists while replying to the same
partner (so `/r` to a vanished staff member keeps working); PDC key `knightsandkings:socialspy`; ops bypass the vanilla
rewrite (selectors keep working); over-long messages are truncated; refused messages are logged too; message text gray.

Developer to-do: grant `knk.socialspy` (staff + owner groups), `knk.socialspy.exempt` (owner group), optionally
`knk.msg.bypass.ratelimit` (staff); frozen players can only message `knk.freeze` holders. Run the 9 in-game acceptance
steps above. Known: non-op spies join the spy audience once their user summary is cached (join, +5 s, every 60 s);
Paper's command log still records PMs until Phase 3; the siege alias follow-up (Phase F) stands.

## Phase 2 — Ignore list (knk-web-api + knk-plugin)

**knk-web-api (`claude/private-messages`):**
- New `A:Models/UserIgnore.cs`; `A:Properties/KnKDbContext.cs` (`DbSet<UserIgnore>`, unique `(UserId, IgnoredUserId)`,
  two FKs to `User` cascade); migration `dotnet ef migrations add AddPrivateMessagesIgnoreList`.
- New `A:Dtos/UserIgnoreDtos.cs`, `A:Repositories/UserIgnoreRepository.cs` + `Interfaces/IUserIgnoreRepository.cs`,
  `A:Services/UserIgnoreService.cs` + `Interfaces/IUserIgnoreService.cs` (self, limit 100, `knk.msg.unignorable` via
  `IPermissionResolutionService.CheckAsync`), `A:Controllers/UserIgnoresController.cs` (`api/users/{id}/ignores`, GET/PUT/
  DELETE per DESIGN §3.2), DI in `A:DependencyInjection/ServiceCollectionExtensions.cs`.
- Tests `A:Tests/knkwebapi_v2.Tests/Services/UserIgnoreServiceTests.cs` (add idempotent, self → 400, limit → 409,
  unignorable → 400, delete idempotent, cascade on user delete) and a controller test for status codes.

**knk-plugin:**
- `C:ports/api/UserIgnoresApi.java` (list/add/remove), `C:domain/users/UserIgnore.java`.
- `AC:dto/UserIgnoreDto.java`, `AC:impl/UserIgnoresApiImpl.java`, mapper method, `AC:client/KnkApiClient.java` getter.
- New `P:user/IgnoreService.java` (per-player concurrent sets, async load on join, optimistic update + rollback).
- New `P:commands/IgnoreCommand.java` (`/ignore [player]`, `/unignore <player>`; offline targets via
  `UserAdminService.resolveTarget`); `plugin.yml` entries.
- `IgnoreGate` in `MessagingService` gate chain (silent drop, `[Spy][ignored]`, bypass `knk.msg.bypass.ignore`).
- `P:listeners/PlayerListener.java` `onChat` — `e.viewers().removeIf(...)` for ignoring viewers.
- Tests: `PT:user/IgnoreServiceTest` (load, toggle, rollback on API failure, fail-open before load),
  `PT:commands/IgnoreCommandTest`, gate test in `MessageCommandsTest`, `AC` impl test against a mock server (same style as
  existing `*ApiImplTest`s).

**Acceptance:** A `/ignore B` → B's PMs to A show B the normal echo but never reach A; S sees `[Spy][ignored]`; B's public
chat no longer shows for A; survives A relogging and a server restart; `/ignore S` (staff) → `You can't ignore staff.`;
`/ignore` lists names with dates; `/unignore B` restores both.

**Size:** M. **Dependencies:** Phase 1 (gate chain). Answer to DESIGN §5 Q6 (if (b), drop the API half: S).

---

## Phase 3 — Server-side PM log + retention (knk-web-api + knk-plugin)

**Blocked until** the plugin authenticates to the API (CP7 option 1: API-key scheme with a plugin principal —
`docs/specs/inventory-menu/CONTENT_PORT_PLAN.md` §9) and DESIGN §5 Q1 is answered (b)/(c). If the currency-payments
feature lands plugin auth first (its ledger/idempotency hardening needs the same thing), reuse it.

**knk-web-api:**
- New `A:Models/PrivateMessageLogEntry.cs`, `A:Enums/PrivateMessageOutcome.cs`; `KnKDbContext` (indexes per DESIGN §3.1,
  unique `ClientMessageId`); `A:Models/AuditLogRetentionConfiguration.cs` + DTOs: `PrivateMessageRetentionDays = 30`;
  `A:Enums/AuditAction.cs`: `PrivateMessagesViewed = 12`; migration `AddPrivateMessageLog`.
- New `A:Dtos/PrivateMessageLogDtos.cs`, repository + interface (`AddRangeIgnoringDuplicatesAsync`, `SearchAsync`,
  `DeleteOlderThanAsync`), `A:Services/PrivateMessageLogService.cs` + interface, `A:Controllers/PrivateMessageLogController.cs`
  (`POST batch` plugin-principal only; `GET` JWT + `knk.pmlog.read`, writes the `PrivateMessagesViewed` audit row).
- `A:Services/RetentionPolicyService.cs` — third isolated cleanup block for PM entries.
- Tests: service (batch dedupe on `ClientMessageId`, ≤ 200 per batch, search filters/paging/newest-first), controller auth
  (anonymous POST → 401, JWT without node → 403, with node → 200 + audit row), retention (old rows deleted, config re-read).

**knk-plugin:**
- `C:ports/api/PrivateMessageLogApi.java`, `AC:dto/PrivateMessageLogEntryDto.java`, `AC:impl/PrivateMessageLogApiImpl.java`.
- `P:user/PrivateMessageLogger.java` — `ApiPrivateMessageLog` sink: bounded queue (1000, drop-oldest WARN), flush every
  `flush-seconds` or 50 entries, retry with same ids; enabled by `private-messages.log.api-enabled`.
- `P:commands/HealthCommand.java` — show PM log queue depth.
- Tests: `PT:user/ApiPrivateMessageLogTest` (batching, overflow, retry keeps ids).

**Acceptance:** with `api-enabled: true`, PMs appear via `GET api/private-message-log?participantUserId=…` within ~5 s; API
restart during play loses nothing (queue drains after); anonymous `POST` is rejected; rows older than the configured days
disappear after the daily run.

**Size:** M. **Dependencies:** plugin API auth (CP7 / currency-payments), Phase 1.

---

## Phase 4 — Web-app PM log viewer (knk-web-app)

- New `src/apiClients/privateMessageLogClient.ts` (built on `objectManager.ts`/`serviceCall.ts`),
  `src/types/dtos/privateMessageLog.ts`.
- `src/pages/admin/PlayerProfilePage.tsx` — "Private messages" panel (hidden on 403), counterpart + date filters, paging,
  outcome badge.
- Retention form: add `privateMessageRetentionDays` wherever the audit-log retention configuration is edited.
- Tests: `src/pages/admin/__tests__/PlayerProfilePage.privateMessages.test.tsx` (renders rows, hides on 403, filters call the
  client with the right query), client test.

**Acceptance:** an account with `knk.pmlog.read` sees a player's PMs on their profile; one without doesn't see the panel;
each view creates a `PrivateMessagesViewed` audit entry shown in "Recent activity".

**Size:** S. **Dependencies:** Phase 3.

---

## Phase F — Follow-ups outside this feature's branch

- **Siege (`claude/siege-minigame`, knk-plugin):** resolve aliases in `SiegeCommandFilterListener` (Bukkit command map →
  primary label) before `SiegeCommandFilter.isAllowed`, so `/tell`, `/w`, `/whisper`, `/reply` behave like `/msg`/`/r`
  during a match (DESIGN §4 D9). S. Coordinate via `ACTIVE_SESSIONS.md` with the siege owner.
- **Staff chat:** move `StaffChatCommand` onto `KnkPermissible` (`knk.staffchat` via the in-house model) — S, flagged in
  DESIGN §4 D8.
- **Docs:** refresh `docs/specs/user-features/COMMAND_CATALOG_V3.md` (missing `/msg`, `/reply`, `/staffchat`, `/freeze`,
  KNG-9 commands) and the plugin/web-api `CLAUDE.md` auth lines.
- **Mute:** when the justice system is designed, implement it as one more `PrivateMessageGate` plus a public-chat check.
