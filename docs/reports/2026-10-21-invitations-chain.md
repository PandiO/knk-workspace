# Invitations chain — progress report

**Status:** Links 1–3 done (2026-10-21), nothing merged. Link 4 is ready ([handoff](../ai-agents/handoffs/2026-10-21-invitations-link-4.md)).
**Last updated:** 2026-10-21 (link 3)
**Linear:** [KNG-205](https://linear.app/kngpandi/issue/KNG-205) and its children (see the [charter](../ai-agents/handoffs/INVITATIONS_CHAIN.md))
**Branch:** `claude/player-signup-invitation-flow-f4v7ul` in every repo. knk-plugin's is based on `claude/mc-26.2-upgrade` (KNG-182).

## Summary (updated in place by each link)

| Link | Issues | Status | Heads (api / app / plugin / workspace) | Tests vs baseline | Started how |
|---|---|---|---|---|---|
| 1 | KNG-211 (API), KNG-207, KNG-208 | **done** (not merged, not live-tested) | api `110451f` (E0) + `bb4b9ee` (L0) / app `2bf70ab` / plugin `30b10e6e` / workspace: see git log | API 2754 passed, 4 known-red, 75 skipped (baseline 2697 / 4 / 73; +59 tests, 2 new `[MySqlFact]` skipped); app 940 (baseline 938); plugin core 2168 / api-client 264 / paper 1870, 0 failures (unchanged) | `create_session` by the coordinator with the § 8 prompt; `add_repo` and the dry-run pushes succeeded |
| 2 | KNG-206 | **done** (not merged, not live-tested) | api `a8b42ca` / app `aecd811` / plugin unchanged (`30b10e6e`) / workspace: see git log | API 2787 passed, 4 known-red, 77 skipped (baseline 2754 / 4 / 75; +41 new, 8 removed with the old mail code, 2 new `[MySqlFact]` skipped); app 156 suites / 950 (baseline 154 / 940) | `create_session session_019NV1SRUVvMbtLXs5QtkCq4` by the coordinator with the § 8 prompt; `add_repo` and the dry-run pushes succeeded |
| 3 | KNG-212 | **done** (not merged, not live-tested) | api `8ca8507` / app `18f3c9f` / plugin unchanged (`30b10e6e`) / workspace: see git log | API 2864 passed, 4 known-red, 80 skipped (baseline 2787 / 4 / 77); app 160 suites / 970 (baseline 156 / 950) | `create_session session_01LbSWhTfxJd2rZ25bV5iRcY` by the coordinator with the § 8 prompt; `add_repo` and the dry-run pushes succeeded |
| 4 | KNG-214 (API + web app) | waiting | — | — | — |
| 5 | KNG-214 (plugin) | waiting | — | — | — |
| 6 | KNG-216 | waiting | — | — | — |
| 7 | KNG-218 (prep) + final write-up | waiting | — | — | — |

**Follow-ups found during the chain:**
- knk-web-api `knkwebapi_v2.sln` points at `tests/knkwebapi_v2.Tests/…` (lower case), so `dotnet build` of the solution fails on Linux; `dotnet build knkwebapi_v2.csproj` works. Noted in a KNG-208 comment (link 1); not fixed (out of scope).
- knk-web-app: `npm ci` with the bundled npm 10 rejects the lock file (`Missing: yaml@2.9.1`); `npx npm@11 ci` works, as `CLAUDE.md` says. Noted in the KNG-208 comment.
- knk-plugin `plugin.yml` still declares the `knk.account.create` permission node (no command uses it). Left in place (link 1); a one-line removal for whoever next touches `plugin.yml`.
- Privacy erasure (`PrivacyDeletionService`) doesn't touch `email_outbox`: a deleted player's address stays in the mail log's metadata until the 90-day retention removes it (link 2, L2-10). Noted in a KNG-206 comment; a small follow-up for the privacy flow.
- `/auth/reset-password` doesn't send `Referrer-Policy: no-referrer` (DESIGN § 3.3 asks it of invite, reset and link
  pages); link 3's `useNoReferrer` hook covers `/invite` and `/join`. Noted in a KNG-212 comment (link 3).
- The web app's audit label list doesn't know `UsernameReleased` (35); it shows the raw name. Noted in the KNG-212
  comment (link 3).
- The daily-cap "currency-alert-style" in-game staff notice needs a new `PlayerNotificationTypes` value and a plugin handler; link 2 logs an error once a day and shows the count on `/admin/email` instead (L2-2). Noted in a KNG-206 comment.

---

## Link 1 — KNG-211 (API half), KNG-207, KNG-208: E0 optional SMTP auth + L0 link hygiene and the linking rules

**Started:** 2026-10-21 by the coordinator with the § 8 prompt (`create_session`; `add_repo` for the three component
repos and `git push --dry-run` on `claude/player-signup-invitation-flow-f4v7ul` all succeeded; the branch did not yet
exist in knk-web-api and knk-web-app and was created from `master` `2d71155` / `main` `e30c815`).
**Toolchains:** .NET 8.0.132, Node 22.22 (npm 11 via `npx`), Gradle 8.14.3 on JDK 21 with a Temurin **JDK 25** toolchain
installed to `/opt/jdk-25` (`-Porg.gradle.java.installations.paths=/opt/jdk-25`). No MySQL: the `[MySqlFact]` tests
were written but skipped.

### Commits per repo (heads)

| Repo | Commits | Head |
|---|---|---|
| knk-web-api | `110451f` **E0 (KNG-211) — cherry-pickable to `master`:** `Services/SmtpPasswordResetDeliveryService.cs`, `Services/Privacy/PrivacyEmailService.cs`, new `Tests/…/Services/SmtpOptionalAuthTests.cs` only. `bb4b9ee` **L0 (KNG-207, KNG-208)** | `bb4b9ee` (`master` `2d71155` merged, no changes) |
| knk-web-app | `2bf70ab` KNG-207: `authService.linkMinecraftAccount` stores the merged account's token; `authClient` return type; `AccountManagementPage`; `AuthDtos` | `2bf70ab` |
| knk-plugin | `30b10e6e` KNG-208: usage text, dead merge flow, warning line (on the KNG-182 branch `88497649`; `KnKPlugin.java` untouched) | `30b10e6e` |
| knk-workspace | `7fa7930` merge of `main`; the link 1 docs commit: plan status + § 4 as-built, DESIGN § 5.4 as-built, player guide, SPEC Part F, CHANGELOG, this report, link 2 handoff; tracker row on `main` `bb60574` (+ this link's update) | see git log |

### What was built

**E0 API half (KNG-211, `110451f`).** `SmtpCredentials.Resolve(EmailSettings)`: with `Email:SmtpUsername` empty the
`SmtpClient` gets no `Credentials`; with a username and no password it still throws. Both SMTP services got a
`protected virtual DeliverAsync(SmtpClient, MailMessage)` seam (`SmtpPrivacyEmailService` is no longer `sealed`), used
by six tests that inspect the client without sending. Nothing else in that commit.

**L0, knk-web-api (`bb4b9ee`).**
- Migration `20261021082846_LinkCodePurpose`: `linkcodes.Purpose int not null default 0`, `MinecraftUuid varchar(36)`,
  `MinecraftName varchar(16)`, index `IX_linkcodes_Purpose_Status_ExpiresAt`, and `UPDATE linkcodes SET Purpose = 1
  WHERE CHAR_LENGTH(Code) = 64` **after** the column is added. Additive; `Down` drops only what it added.
- `LinkCodePurpose` enum (Link 0, PasswordReset 1, Claim 2); `LinkCodeRepository` filters reset tokens by `Purpose`;
  `AuthService` stamps new reset tokens `PasswordReset`; `GetActiveClaimCodeByUuidAsync`, `DeleteFinishedBeforeAsync`.
- `LinkCodeService`: `GenerateCode(alphabet)` with `RandomNumberGenerator.GetInt32`; `ClaimChars` (Crockford base32),
  `CreateClaimCodeAsync(uuid, name, ttl)` (reuses the UUID's active code), `NormalizeClaimCode` (O→0, I/L→1, no
  hyphens/spaces), `FormatClaimCode` (XXXX-XXXX), `DeleteFinishedCodesAsync`. The 52^8 comment is now 36^8.
- `LinkCodeCleanupService` (hourly `BackgroundService`, `RunOnceAsync` for tests): marks lapsed codes Expired, deletes
  codes used/expired more than 7 days ago. Registered in `ServiceCollectionExtensions` next to `AccountMailSender`.
- `ILinkAttemptLimiter` / `LinkAttemptLimiter` (`Security:LinkAttempts`, defaults 5 / 15 min / 15 min, same shape as
  `Security:Lockout`), `LinkAttemptsExceededException` (429 `TooManyAttempts` + `Retry-After`), `LinkConflictException`
  (409 `AlreadyRegistered` / `AlreadyLinked`).
- `UserService.LinkMinecraftAccountAsync` → `LinkMinecraftAccountResult(User, Merged)`: limiter check → validate the
  code (non-consuming) → resolve the Minecraft identity (link code: its owner's UUID; claim code: `MinecraftUuid`;
  reset-token hash or a web-only owner: invalid, counts as a failure) → caller already linked to another UUID: 409
  `AlreadyLinked`; same UUID: spend the code, no change → target account has a `PasswordHash`: 409 `AlreadyRegistered`
  → spend the code → case A sets `Uuid` (+ verified name, releasing a squatter) → case B
  `FoldWebAccountIntoMinecraftAccountAsync` under `RunWithUsersLockedAsync([mc, web])`: `MergeWithForfeitAsync(mc, web)`
  (ledger postings, soft delete, the shell's sessions revoked), shell saved with `Email`/`PasswordHash` cleared, then
  the Minecraft account gets `Email`, `PasswordHash`, `LastPasswordChangeAt`, `LastEmailChangeAt`, `EmailVerified`.
- `UsersController.LinkMinecraftAccount`: after a fold, `IAuthService.StartSessionAsync(survivorId)` (new; the same
  `IssueSessionAsync` Register uses) and the refresh cookie through the new shared `Configuration/RefreshTokenCookie`
  (AuthController's private cookie helpers moved there). Response `{user, merged, accessToken, expiresIn, message}`.
  The three new constructor dependencies (`IAuthService`, `IWebHostEnvironment`, `IOptions<SecuritySettings>`) are
  optional parameters so the existing test constructions stand; DI fills them.
- No new endpoints, so `EndpointAccessRulesTests` and `ProtectedRoutes` are unchanged.

**knk-web-app (`2bf70ab`).** `LinkMinecraftAccountResponseDto`; `authClient.linkMinecraftAccount` typed to it;
`authService.linkMinecraftAccount` stores `accessToken` with `tokenService.isRemembered()`; `AccountManagementPage`
calls the service, then `refresh()`, and says when the login moved onto the Minecraft account. Two tests.

**knk-plugin (`30b10e6e`).** `/account [link|status]` in `AccountCommandRegistry` and `plugin.yml`; `/user statistics`
says "Minecraft only (/account link to add a web login)"; `AccountLinkCommand.startMergeFlow`, `mergeAccounts`,
`updateCachedUser`, `safeInt` and four imports removed (the `ChatCaptureManager` constructor parameter stays, since
`KnKPlugin` wiring is claimed by KNG-182); `LinkCodeMessage.DEFAULT_TEMPLATE` and `config.yml`
`messages.link-code-generated` end with "&cNever give this code to anyone; staff never ask for it.";
`LinkCodeMessageTest` and `AccountLinkCommandTest` updated.

**Docs.** Plan status line and § 4 as-built block; DESIGN § 5.4 as-built paragraph; player guide v1.1 (no `/account
create`, no web → game linking, the fold explained, the warning line); SPEC Part F: password reset built (KNG-64);
CHANGELOG entry.

### Tests vs baseline

| Repo | Baseline (before any change) | After link 1 |
|---|---|---|
| knk-web-api | 2697 passed, 4 failed, 73 skipped (2774) | **2754 passed, 4 failed, 75 skipped (2833)**. The 4 failures are the same known-red as `master` (`PathResolutionServiceTests` ×2, `FieldValidationServiceTests`, `ClientActivityStoreTests`). +59 tests; the 2 extra skips are the new `[MySqlFact]`s. |
| knk-web-app | 154 suites, 938 tests | **154 suites, 940 tests**; `npm run build` compiles with the same pre-existing warnings as `main` (none in the changed files; `CI=true` fails on those warnings on `main` too) |
| knk-plugin | core 2168 / api-client 264 (2 skipped) / paper 1870 (18 skipped), 0 failures | **unchanged counts, 0 failures** (tests were updated, not added) |

One existing test needed a fixture change: `AuthSessionTests.ResetPassword_EndsEverySession` inserted a 64-character
code without a `Purpose`; it now sets `PasswordReset`, as `AuthService` writes and the backfill sets.

### Flagged decisions (reversible defaults; review)

- **L1-1** The fold clears the shell's `PasswordHash` as well as its `Email` (plan: email only). Reason: a soft-deleted
  row with a live bcrypt hash of the player's password has no use, and no two rows should hold the same login.
- **L1-2** `InvitedVia*` and the invite's group membership are **not** copied: the columns and the group don't exist
  until I1 (KNG-212). Link 3 must extend `FoldWebAccountIntoMinecraftAccountAsync`; recorded in the plan § 4 block.
- **L1-3** The code is spent before the fold, not after (plan step 4 said "after all validation", which it still is),
  so two requests with one code can't both fold; a fold that then fails burns the code (the player gets a new one).
- **L1-4** The fold response is `{user, merged: true, accessToken, expiresIn, message}`; without a fold `{user,
  message}` as before. If `IAuthService` can't issue a session (inactive survivor), `{user, merged: true, message}`
  asks the player to log in again. The web app stores the token with the existing remember-me choice.
- **L1-5** Case A takes the verified name through `ReleaseUsernameFromWebOnlyAccountAsync` (renames a web-only
  squatter to `unclaimed-<id>`, audited) before setting `Username`. Only claim codes reach case A (link 4).
- **L1-6** `Security:LinkAttempts` reuses the `LockoutSettings` shape rather than a new class, so it is configured
  exactly like `Security:Lockout`. Not added to `appsettings.json`: the defaults are the plan's numbers.
- **L1-7** `UsersController`'s new dependencies are optional constructor parameters (null-safe), to keep the eight
  existing `new UsersController(...)` test constructions compiling. Cosmetic; a later cleanup could make them required.

### Discrepancies with the plan / design

- Plan § 4.1 says the cleanup goes "through the existing `CleanupExpiredCodesAsync`"; that method only flips Active →
  Expired and never deleted anything, so deletion is a new `DeleteFinishedCodesAsync` and the hosted service calls both.
- DESIGN § 5.4 row 3 ("UUID already linked to an account with credentials → refuse") is implemented as "the target
  account has a `PasswordHash`", which is what "has a web login" means today; `Email` alone doesn't count.
- The web → game `/account link <code>` text in the player guide (KNG-208) was already dead in the plugin since KNG-67;
  only the guide changed.

### Live checklist (dev API + web app; not run)

1. `dotnet ef database update` on a dev DB with a pending reset token (64 chars): after the migration its `Purpose`
   is 1 and the reset link still works; a link code from `/account link` has `Purpose` 0.
2. E0: `Email__Provider=Smtp`, `Email__SmtpHost=<relay>`, `Email__SmtpUsername=` (empty), `Email__UseStartTls=false`
   → forgot-password mail arrives; set a username without a password → the API logs the "Email:SmtpPassword" error
   and still answers the generic message.
3. Case B: web-only account (registered before KNG-67 or made with `generate-link-code`) enters a code from a
   Minecraft-only account on the Account page → the page says the login moved, the header shows the Minecraft name,
   a reload keeps the session, the old account is gone from the user list (soft-deleted), `/account` in game shows
   "web account linked", and balances are the higher of each.
4. Case B refusal: the same with a Minecraft account that already has a web login → "This Minecraft account already
   has a web account…" and nothing changes.
5. Five wrong codes on the Account page → the sixth answers "Too many attempts. Try again in 15 minutes." even with
   a valid code; the per-IP `lookup` limit (20/min) is not hit first.
6. Plugin: `/account` with a wrong subcommand shows `/account [link|status]`; `/account link` ends with the red
   "Never give this code to anyone" line; `/user statistics` on a Minecraft-only account shows the `/account link` hint.
7. Cleanup: after an hour the API log shows "Link code cleanup" only when it changed something; a used code older than
   7 days is gone from `linkcodes`.

### Deploy notes (a deploy of this API state)

- Migration `LinkCodePurpose` runs on start-up (additive). No new required settings; `Security:LinkAttempts` is optional.
- The alpha's E0 relay settings are the developer's NAS half (KNG-211, plan § 2); `110451f` alone is enough for it.
- Behaviour-neutral for today's alpha: `/account link` → register is unchanged (all `RegistrationAndLoginTests` pass
  unchanged); the fold only triggers for a logged-in web-only account entering another account's code.

### Risks

- The fold is a one-way data change on two `users` rows (soft delete + credential move) that is only undone by hand.
  It is reachable today only for legacy web-only accounts, and refused whenever the target has a login.
- EF InMemory doesn't enforce the unique indexes; the MySQL test for the email move exists but **was not run here**
  (no MySQL). Run `KNK_TEST_MYSQL=… dotnet test --filter Category=requires-mysql` before merging.
- `HasDefaultValue(LinkCodePurpose.Link)` means EF never writes `Purpose = 0` explicitly; it relies on the column
  default, which the migration sets. Fine for MySQL; worth knowing if the column is ever recreated.

### What the next link must know

- Reset tokens, link codes and claim codes share `linkcodes` and are told apart by `Purpose`; `LinkCodeService`
  normalises link codes (hyphens, upper case) but **not** Crockford look-alikes, so link 4 calls
  `LinkCodeService.NormalizeClaimCode` before validating a claim code.
- `FoldWebAccountIntoMinecraftAccountAsync` is where I1 adds the invite fields and group copy (L1-2).
- E1 (link 2) replaces `AccountMailQueue`/`AccountMailSender` and the delivery services; `SmtpCredentials.Resolve` and
  the `DeliverAsync` seam live in files E1 removes, so carry the optional-auth rule into the MailKit transport and
  keep its tests' intent (no username → no auth; username without password → refuse).
- `dotnet build` of the `.sln` fails on Linux (case of `tests/`); build the csproj. Web app: `npx npm@11 ci`.

---

## Link 2 — KNG-206: E1 email engine

**Started:** 2026-10-21 by the coordinator with the § 8 prompt (`create_session session_019NV1SRUVvMbtLXs5QtkCq4`);
`add_repo` (push) for knk-web-api, knk-web-app and knk-plugin, clones under `/home/user/<repo>`, branch checked out in
all four repos, and `git push --dry-run` succeeded in knk-workspace, knk-web-api and knk-web-app (the repos this link
changes). Base merges: `master` `2d71155` and `main` `e30c815` were already in; workspace merged `main` `7c80c85`.
**Toolchains:** .NET 8 and Node 22 present; `dotnet-ef` 9.0.10 from `~/.dotnet/tools`. No MySQL: the new
`[MySqlFact]`s were written and skipped.

### Commits per repo (heads)

| Repo | Commit | What |
|---|---|---|
| knk-web-api | `0d7ec4a`, `a8b42ca` | The engine, the call sites, the removals and the tests (one commit: the DI switch ties them together); then the Log transport keeps logging links with `AllowLogTransport` (L2-12) |
| knk-web-app | `aecd811` | `/admin/email`, client, DTOs, nav entry, tests |
| knk-workspace | this link's docs commit(s) | `docs/guides/email.md`, go-live § 4, production-installation, DESIGN § 4 as-built, plan status, CHANGELOG, this block, link 3 handoff |
| knk-plugin | — | not changed (`30b10e6e`) |

### What was built

**knk-web-api.**
- **Package:** MailKit `4.18.1` (pinned). `System.Net.Mail` is gone from the code.
- **Model and migration:** `Models/EmailOutboxMessage.cs`, table `email_outbox` (`AddEmailOutbox`, additive):
  the plan's columns, `Status` as a string, unique `DedupeKey`, indexes `(Status, NextAttemptAt)`,
  `(ToAddress, CreatedAt)` and `CreatedAt`.
- **`Services/Email/`:**
  - `EmailKind` + `EmailKinds` (template, subject, throttle class and footer reason per kind; `Test` added, L2-4);
  - `EmailTemplateRenderer` with 22 embedded templates (`_layout.html|txt` + 10 kinds), `{{name}}` filled
    case-insensitively, HTML-encoded in `.html`, dates as `yyyy-MM-dd HH:mm UTC`; unknown placeholder throws when strict
    (tests, Development) and renders empty with a warning otherwise;
  - `EmailComposer` (`QueueAsync`: dedupe → render → throttle → add to the caller's `KnKDbContext` → save → signal);
  - `EmailThrottle` (3/h per recipient and class, 6/h per recipient, `DailyCap` per 24 h);
  - `EmailDispatcher` (`PeriodicTimer` 5 s on `TimeProvider` + `EmailDispatchSignal`, scope per pass,
    `ConnectivityAwareFailureLogger`, 20 rows, backoff 1/5/15/60/240 min, Failed after `MaxAttempts`);
  - transports `SmtpEmailTransport` (MailKit, `StartTlsWhenAvailable`/`None`, 465 → TLS on connect; authenticates only
    with a username, refuses a username without a password naming `Email:SmtpPassword` — E0's rule, carried over),
    `LogEmailTransport` (body and links in Development or with `AllowLogTransport=true`, L2-12), `PickupEmailTransport` (`.eml`);
    `EmailMessageFactory` sets From, Reply-To, `Auto-Submitted`, a `Message-ID` on the sender's domain;
  - `EmailOutboxAdminService` + `Controllers/EmailOutboxController.cs` (`api/EmailOutbox`: `GET`, `POST test`,
    `POST {id}/retry`, each `[RequirePermission(ServerConfig)]`).
- **Configuration:** `EmailSettings` gains `Transport` (with `Provider` as fallback, `EffectiveTransport()`),
  `AllowLogTransport`, `PickupDirectory`, `ReplyToAddress`, `DailyCap` = 300, `MaxAttempts` = 6. New
  `Configuration/AppSettings.cs` (`App:PublicBaseUrl`, fallbacks kept). `StartupSecurity.EmailTransportProblem`:
  outside Development, Log without `AllowLogTransport=true` stops start-up (L2-3).
- **Call sites:** `AuthService` reset (`reset:{tokenId}`, `ExpiresAt` = token expiry) and email-change notice
  (`email-changed:{userId}:{ticks}`, shared `QueueEmailChangedNoticeAsync`); `PrivacyEmailService` (one class, interface
  unchanged, keys are hashes of the link / address, never the token); staff `PUT api/Users/{id}/update-email` notifies
  the old address (optional `IEmailComposer?` and `ILogger?` constructor parameters, like L1-7). `PrivacyDeletionService`
  and `AuthService` prefer `App:PublicBaseUrl`.
- **Removed:** `AccountMailQueue`/`AccountMailSender`, `IPasswordResetDeliveryService`,
  `PasswordResetDeliveryService`, `SmtpPasswordResetDeliveryService` (with `SmtpCredentials`, now in
  `Services/Email/EmailTransports.cs`), `LogPrivacyEmailService`/`SmtpPrivacyEmailService`, both DI switches.
- **Retention:** `RetentionPolicyService` deletes `email_outbox` rows older than 90 days.
- **Settings files:** `appsettings.json` lists the new keys with `Transport` **empty** (L2-9); `.gitignore` gets
  `mail-pickup/`; `CLAUDE.md`'s user-secrets line updated.

**knk-web-app.** `src/apiClients/emailOutboxClient.ts`, `src/types/dtos/email/EmailOutboxDtos.ts`,
`Controllers.EmailOutbox`, `src/pages/admin/EmailLogPage.tsx` at `/admin/email` behind
`StaffRoute node="knk.admin.config"` (status pills, kind, masked recipient, attempts, last error, filters, paging,
transport and 24-hour count, Retry on retryable Failed rows, "Send test mail to me" with a `FeedbackModal`), nav entry
**Mail** after Siege Settings, shown to holders of the node.

**Docs.** New living guide [email.md](../guides/email.md) (how it works, settings, transports, the relay, provider DNS,
the admin page, smoke steps, troubleshooting) and its row in the guides index; [go-live § 4](../guides/alpha-go-live.md)
(`Email__AllowLogTransport=true` required while the alpha runs Log, and the relay block for later);
[production-installation § 4.3](../guides/production-installation.md); DESIGN § 4 as-built; plan status line; CHANGELOG.

### Tests vs baseline

| Repo | Baseline (before any change) | After link 2 |
|---|---|---|
| knk-web-api | 2754 passed, 4 failed, 75 skipped (2833) | **2787 passed, 4 failed, 77 skipped (2868)**. Same 4 known-red as `master`. +41 new tests (`Services/Email/EmailEngineTests.cs`: renderer, dispatcher, composer/throttle, transports, startup guard, admin service and controller, privacy and staff call sites; `MySql/EmailOutboxMySqlTests.cs` ×2 skipped). **8 removed** with the code they tested: `AccountMailQueueTests.Enqueue_WhenFull_ReportsTheDrop`, the six `SmtpOptionalAuthTests`, `AccountSecurityTests.MailSender_LogsSmtpFailures_InsteadOfThrowing` — their intent lives on in `EmailTransportTests` (no username → no auth; username without password → refused) and the dispatcher's failure tests. |
| knk-web-app | 154 suites, 940 tests | **156 suites, 950 tests**; `npm run build` compiles with `main`'s pre-existing warnings, none in the changed files (ESLint clean on them) |
| knk-plugin | — | not touched |

Adjusted existing tests: `AuthTestHarness` captures mails through a strict-rendering `CapturingEmailComposer` instead of
the queue mock (the auth suites are otherwise unchanged); two assertions in `AccountSecurityTests` read the new record
(and the reset test now also checks the dedupe key, expiry and link); `DeploymentSettingsTests.Production_StartsWithAGoodSecret`
sets `Email:Transport=Smtp` (L2-3); `RequireServiceOrPermissionAttributeTests.ProtectedRoutes_CarryTheirGate` also reads
`[RequirePermission]` nodes so the three `EmailOutbox` routes could be added to `ProtectedRoutes`.

### Flagged decisions (reversible defaults; review)

- **L2-1** A **Failed** row keeps its bodies when it has no `ExpiresAt` (no token), so `POST {id}/retry` can resend it;
  a Failed row with an expiry (reset, privacy confirm, later invites) loses them and answers 409 on Retry. The plan
  said Failed rows always lose their bodies, which would make Retry impossible.
- **L2-2** The daily cap logs an **error once a day** (memory-cached) and `/admin/email` shows the 24-hour count against
  the cap. The plan's "currency-alert-style server notice" needs a new player-notification type and a plugin handler,
  outside this link's repos; follow-up recorded.
- **L2-3** The Log guard applies **outside Development** (like the other `StartupSecurity` checks and DESIGN § 4.2),
  not only in `Production`. With no `Email` section the transport is Log, so such a host refuses to start;
  `appsettings.json` has `Provider=Smtp`, so a normal deploy isn't affected.
- **L2-4** `EmailKind.Test` (throttle class `test`) for the admin test mail; not in the plan's list.
- **L2-5** `QueueAsync` adds the row **and saves** the caller's `DbContext`. Inside an explicit transaction it commits or
  rolls back with it (MySQL test written); without one it is its own save right after the caller's. Today's callers
  save their change first, as before. Link 3 should queue invitation mails inside `RunInTransactionAsync`.
- **L2-6** The throttle counts rows that weren't themselves suppressed, per lower-cased address; classes: `password-reset`,
  `account-notice` (email changed), `verification`, `privacy` (both privacy kinds), `invitation`, `onboarding`
  (welcome, linked, finish linking), `test`.
- **L2-7** Queue failures in forgot-password and the email-change notice are caught and logged, so the answer stays the
  same (SEC-13). The privacy confirm still answers `EmailFailed` if queueing throws, as it did for a send failure.
- **L2-8** Port 465 uses TLS on connect; the plan only named `StartTlsWhenAvailable` / `None`.
- **L2-9** `Email:Transport` is empty in `appsettings.json`, so the alpha's `Email__Provider=Log` override still decides
  (a non-empty `Transport` would win over it).
- **L2-10** `email_outbox.UserId` has no foreign key, and privacy erasure doesn't remove outbox rows (metadata with the
  address stays up to 90 days). Follow-up recorded.
- **L2-12** `LogEmailTransport` logs the text body (with links) in Development **and** whenever
  `Email:AllowLogTransport=true`; otherwise only kind, masked recipient and subject. The plan said "links only in
  Development", but that would end the alpha's current workflow (staff copy a tester's reset link from the API log while
  there is no relay) and break the charter's "keeps working with today's `Email:*` settings"; DESIGN § 4.2 describes
  `AllowLogTransport` as exactly that opt-in. Outside Development without it the API doesn't start, so the two agree.
- **L2-11** The layout's logo is `{PublicBaseUrl}/brand/knk-shield.png` (the web app's `public/brand`); mail clients
  that block images show the "Knights & Kings" wordmark under it.

### Discrepancies with the plan / design

- Plan § 3.1 "Sent, Expired and Failed rows get bodies null" vs "`POST {id}/retry` (Failed → Pending)": resolved by L2-1.
- Plan § 3.1 "in Production": implemented as outside Development (L2-3).
- `ProtectedRoutes_CarryTheirGate` only knew `RequireServiceOrPermission`; extended (see Tests) rather than giving a
  staff-only controller a plugin bypass.
- DESIGN § 4.2 shows `IEmailComposer.Queue(kind, to, model, expiresAt?)`; the code has the plan's `QueueAsync(kind, to,
  model, dedupeKey, expiresAt?, userId?)`.

### Live checklist (dev; not run)

The smoke steps are in [email.md § 6](../guides/email.md). In short, on a dev API with the migration applied:
1. Start with `ASPNETCORE_ENVIRONMENT=Production` and `Email__Provider=Log` → the API refuses to start naming
   `AllowLogTransport`; add `Email__AllowLogTransport=true` → it starts.
2. `/admin/email` → *Send test mail to me* → row Sent (Smtp/Pickup: the mail or `.eml` exists).
3. Forgot-password → mail with a working link; the row is Sent with no content left.
4. Email change on the account page and via staff `update-email` → the old address gets the notice both times.
5. Data deletion request → confirm mail.
6. Relay/SMTP down → row Pending with attempts and last error → back up → Sent; a reset older than 30 min → Expired.
7. Four resets in an hour (60 s apart) → the 4th is Suppressed.
8. A non-config staff member gets the "needs knk.admin.config" screen on `/admin/email` and no **Mail** nav entry.
9. Run `KNK_TEST_MYSQL=… dotnet test --filter Category=requires-mysql` (transaction rollback + unique key).

### Deploy notes (a deploy of this API state)

- **Precondition for deploying this API version to the alpha:** the alpha runs `Email__Provider=Log` until E0's relay
  works, so its env **must** have `Email__AllowLogTransport=true`, or the API refuses to start. Written into
  [go-live § 4](../guides/alpha-go-live.md). Once the relay works: `Email__Transport=Smtp`, `Email__SmtpHost=mailrelay`,
  `Email__UseStartTls=false`, `Email__SmtpUsername=` (empty), then drop `AllowLogTransport`.
- Migration `AddEmailOutbox` runs on start-up (additive, one new table).
- Recommended: `App__PublicBaseUrl=https://<web-host>` (otherwise `Security__PasswordResetFrontendBaseUrl` is used,
  as today).
- Behaviour for today's alpha: with `Email__AllowLogTransport=true` the reset link still appears in the API log, so
  the manual relay keeps working (L2-12). The mail now also shows on `/admin/email` as Sent (by the Log transport).

### Risks

- Forgetting `Email__AllowLogTransport=true` on the alpha stops the API at start-up (by design, with a clear message).
  Deploy E1 after E0's relay (plan § 9 order), or add the setting.
- EF InMemory has no transactions or unique indexes; the rollback and dedupe MySQL tests **were not run here**.
- A queued mail's `ToAddress` is lower-cased; a provider that treats the local part case-sensitively would still
  deliver (practically all do), but the log shows the lower-cased form.
- MailKit is a new dependency in the API image (MIT; MimeKit with it).

### What the next link must know

- Queue mails with `IEmailComposer.QueueAsync(kind, to, model, dedupeKey, expiresAt, userId)`; it saves the caller's
  `DbContext`, so call it inside the service's transaction. Suggested keys: `invite:{invitationId}:{sendNo}` (expires
  with the invite), `welcome:{userId}`.
- Template models (placeholders must all be present; tests render strictly): `Invitation` {`inviterName`, `inviteUrl`,
  `expiresAt`}; `Welcome` {`username`, `linkUrl`}; `MinecraftLinked` {`username`, `minecraftName`}; `FinishLinking`
  {`username`, `linkUrl`}; `EmailVerification` {`username`, `verifyUrl`, `expiresAt`}. Change a template's text in
  `Services/Email/Templates/` (embedded resource) if I1 needs different wording.
- Tests: `AuthTestHarness.Email` / `.Mail` capture queued mails; `Tests/…/Services/Email/EmailTestDb` gives an InMemory
  outbox with the real composer, throttle and dispatcher; `CapturingEmailComposer` for service tests.
- Links in mails: `AppSettings.ResolveBaseUrl(app.PublicBaseUrl, …fallbacks)`.
- Staff-only routes with `[RequirePermission]` can now go in `ProtectedRoutes`.

---

## Link 3 — KNG-212: I1 invitations and invite-based registration

**Started:** 2026-10-21 by the coordinator with the § 8 prompt (`create_session session_01LbSWhTfxJd2rZ25bV5iRcY`);
`add_repo` (push) for knk-web-api, knk-web-app and knk-plugin, clones under `/home/user/<repo>`, branch checked out in
all four repos, `git push --dry-run` succeeded in knk-web-api, knk-web-app and knk-workspace (the repos this link
changes). Base merges: `master` `2d71155` and `main` `e30c815` were already in (no change); workspace merged `main`
(the tracker commits). The session's worker restarted once mid-link; the clones and state survived.
**Toolchains:** .NET 8.0.132 with `dotnet-ef` from `~/.dotnet/tools`, Node 22.22 (`npx npm@11 ci`). No MySQL: the new
`[MySqlFact]`s were written and skipped. No plugin change, so no JDK 25.

### Commits per repo (heads)

| Repo | Commits | Head |
|---|---|---|
| knk-web-api | `77042fd` model + migrations (`AddInvitations` with the backfill, `SeedInvitationStaffNode`), node, audit range; `8ca8507` service, controller, registration, `UserService` admission and fold, DI, settings, tests | `8ca8507` |
| knk-web-app | `dfa5cdd` pages, client, DTOs, routes, nav, register form, Account badge, tests; `18f3c9f` audit labels | `18f3c9f` |
| knk-workspace | this block, plan status + § 5.2a, DESIGN § 3.3 note, CHANGELOG, link 4 handoff; tracker row on `main` | see git log |
| knk-plugin | — | not changed (`30b10e6e`) |

### What was built

**knk-web-api.**
- **Model:** `Models/Invitation.cs` (`Invitation`, `InvitationRedemption`, `InvitationKind`, derived `InvitationStatus`
  with `StatusAt(now)`: Revoked > Exhausted > Expired > Paused > Active); tables `invitations` (the plan's columns plus
  `ResendWindowStartedAt`, `ResendsInWindow`, L3-5; `CodeHash char(64)` unique, `CodeHint char(4)`, indexes
  `(Kind, ExpiresAt)` and `Email`, FK `GrantGroupId` → `permission_groups` Restrict) and `invitation_redemptions`
  (index `InvitationId`). `users` gains `InvitedViaInvitationId`, `InvitedByUserId`, `AdmittedAt`, `EmailVerifiedAt`.
- **Migrations:** `20261021120136_AddInvitations` (generated; snapshot diff additive only) with
  `UPDATE users SET AdmittedAt = CreatedAt WHERE IsActive = 1 AND DeletedAt IS NULL AND AdmittedAt IS NULL` **after**
  the column is added; `EmailVerifiedAt` starts NULL. `20261021120500_SeedInvitationStaffNode` grants
  `knk.admin.invites` to Admin (idempotent, the `SeedStatisticsStaffNodes` pattern).
- **Permissions, audit, settings:** `StaffPermissions.ManageInvites`; `AuditAction` 37–42 with a range comment;
  `Configuration/InvitationSettings.cs` (`Invitations`: 7 / 30 / 5 / 50 / ["Alpha Tester"] / 3, plus
  `MaxEmailsPerRequest` = 100); `Security:Registration:Mode` (`LinkCode` default, `Invite`, `Open`), both in
  `appsettings.json`.
- **`Services/Invitations/`:** `InvitationCodes` (43-char base64url tokens, `KNK-XXXXX-XXXXX` Crockford codes read
  case-insensitively with `-`/spaces and O→0, I/L→1, SHA-256 hex, `web-` + 10 Crockford shell names);
  `InvitationService` (create personal/shared, resend, rotate, pause/resume, revoke, list, redemptions, options, check,
  `FindUsableAsync`, `RedeemAsync`) and `Repositories/InvitationRepository.cs` (`TryTakeUseAsync`: one
  `ExecuteUpdate … SET UseCount = UseCount + 1 WHERE … UseCount < MaxUses AND RevokedAt IS NULL AND PausedAt IS NULL
  AND ExpiresAt > @now`; `RunInTransactionAsync`). Mails through `IEmailComposer` inside the transaction:
  `Invitation` (`invite:{id}:{sendCount}`, expires with the invite, the returned row's status reported, so a throttled
  mail shows as `Suppressed`) and `Welcome` (`welcome:{userId}`). Create/revoke audit the actor, redemption the new
  account; Details never hold a code. No log line holds a code or link.
- **Registration (`AuthService.RegisterAsync`):** `claimCode` → 400 `NotSupportedYet` (every mode). `Mode=LinkCode`:
  invite fields → 403 `InvitesDisabled`, everything else exactly as before. `Mode=Invite`: invite token/code → check →
  personal email must match (400 `InviteEmailMismatch`, then verified) / shared email validated → password → duplicate
  (409) → `RedeemAsync` in one transaction (take the use, create the admitted `web-…` shell with Default + the invite's
  group, redemption row, audit, Welcome mail; **no SIGNUP_GRANT**) → session. A failed take is 400 `InvalidInvite`. A
  link code alone works only for an admitted account (else 403 `InviteRequired`); no invite and no code → 403
  `InviteRequired`. `AuthController` maps the new codes. `IInvitationService` is an optional last constructor parameter.
- **`UserService`:** `CreateAsync` (the plugin's `POST api/Users`) sets `AdmittedAt = CreatedAt` unless the mode is
  `Invite`; the fold copies `EmailVerifiedAt`, `InvitedVia*`, `AdmittedAt` (if the Minecraft account has none) and the
  invite's group (L1-2). Both new dependencies are optional constructor parameters (L1-7 style).
- **`Controllers/InvitationsController.cs`** (`api/Invitations`): `GET`, `GET options`, `POST personal`, `POST shared`,
  `POST {id}/resend|rotate|pause|resume|revoke`, `GET {id}/redemptions`, each `[RequirePermission(knk.admin.invites)]`
  (in `ProtectedRoutes`); `POST check` `[AllowAnonymous]` + `auth` rate limit (on the `EndpointAccessRulesTests`
  allow-list). 404 / 403 (escalation) / 409 (wrong kind, not active) / 429 (resend limit) / 400.
- **DTOs:** `Dtos/InvitationDtos.cs`; `UserDto` gains `minecraftLinked`, and `emailVerified` is true for
  `EmailVerified` **or** `EmailVerifiedAt` (there is no separate `AuthUserDto`; login returns `UserDto`).

**knk-web-app.** `Controllers.Invitations`, `src/apiClients/invitationClient.ts`,
`src/types/dtos/invitations/InvitationDtos.ts` (`INVITATION_NODES`), `RegisterRequestDto` with the invite fields,
`UserDto.minecraftLinked`. `src/components/auth/InviteSignupForm.tsx` (email locked or typed, password + strength meter,
alpha-rules checkbox, error mapping); `src/pages/auth/InvitePage.tsx` (`/invite/:token`: reads the token once,
`history.replaceState` to `/invite`, then checks; one "invalid or has expired" message) and `JoinPage.tsx`
(`/join?code=` or typed); success → `/account/link`, which redirects to `/account` until KNG-214 (L3-8);
`src/hooks/useNoReferrer.ts` (L3-10). `src/pages/admin/InvitationsPage.tsx` (`/admin/invitations`, `StaffRoute
node=knk.admin.invites`): Personal/Shared tabs, create cards (bulk textarea, expiry, group from `options`, note,
send-email toggle / label, max uses, expiry, group), the once-only result panel with Copy buttons and mail status,
the list with status pills, row actions with `FeedbackModal` confirms, a redemptions drawer, and a warning while the
server's mode isn't `Invite`. Nav entry **Invitations**; link in the `UserModerationPage` header. `RegisterForm` maps
`InviteRequired` to "You need an invitation to create an account" with a link to `/join`. Account page "Email
verified" badge. Audit labels for 37–39.

### Tests vs baseline

| Repo | Baseline (before any change) | After link 3 |
|---|---|---|
| knk-web-api | 2787 passed, 4 failed, 77 skipped (2868) | **2864 passed, 4 failed, 80 skipped (2948)**. The 4 failures are the same known-red as `master`. New: `InvitationServiceTests` (31 incl. theories: clamps, caps, label, group allow-list, escalation guard, duplicate personal invite, throttle → Suppressed, resend rotation and limit, rotate, pause/resume/revoke, hash-only storage, uniform check, list filters, options, redemption), `InvitationCodesTests`, `InviteRegistrationTests` (12: personal incl. mismatch and single use, shared, exhausted/expired/paused/revoked, duplicate email, weak password, link code with and without `AdmittedAt`, invite + link code, claim code, `Mode=LinkCode` refuses invites), `AddInvitationsMigrationTests` (4), `UserServiceTests` admission (4), fold tests (2), a DI test; 3 new `[MySqlFact]`s skipped (concurrent last use ×10 rounds, paused/revoked/expired give no use, the backfill on real-shaped rows after migrating down to `AddEmailOutbox`). **No existing test changed behaviour**; `AuthTestHarness.CreateAuthService` got an optional parameter and the fold test class a memberships field. |
| knk-web-app | 156 suites, 950 tests | **160 suites, 970 tests** (`invitationClient`, `InvitePage`, `JoinPage`, `InvitationsPage`, a `RegisterForm` case, audit labels); `npm run build` compiles with `main`'s pre-existing warnings, none in the new files; `tsc` shows only the 3 errors `main` has (`sessionPinnedRows.test.ts`) |
| knk-plugin | — | not touched |

### Flagged decisions (reversible defaults; review)

- **L3-1** `Registration.Mode` defaults to `LinkCode` regardless of `AllowWebFirst` (the plan: "defaults to LinkCode
  when AllowWebFirst is false"); `AllowWebFirst=true` alone changes nothing but the refusal's wording, as today. `Open`
  is accepted and behaves like `Invite`: web-first sign-up without an invite isn't specified anywhere.
- **L3-2** Refusal codes: `InvitesDisabled` (403, invite under `LinkCode`), `InviteRequired` (403), `InvalidInvite`,
  `InviteEmailMismatch`, `NotSupportedYet` (400), `InvalidRequest` for an invite **and** a link code together.
- **L3-3** The check returns the personal invite's full address (plus `emailHint`) to the token holder, so `/invite` can
  show it locked as § 5.2 asks; DESIGN § 6 only named `emailHint`. The token is a 256-bit secret mailed to that address.
- **L3-4** `GET api/Invitations/options` added (invitable groups that exist, defaults, caps, mode) for the create
  forms' "group select limited to the API's invitable list".
- **L3-5** Resends per day are counted in two new `invitations` columns (rolling 24 h window) rather than derived.
- **L3-6** Resend restarts the expiry with `DefaultExpiryDays` (the original lifetime isn't stored) and works on an
  expired invite; it refuses used or revoked ones and addresses that meanwhile have an account. `sendEmail: false`
  rotates without mailing (copy-link only) and counts as a resend.
- **L3-7** Pause/resume only for shared codes (DESIGN § 3.4); the plan listed them generically.
- **L3-8** The Welcome mail says "Hi there" and links `{base}/account/link`; the web app redirects `/account/link` to
  `/account` until link 4 builds the page.
- **L3-9** The backfill admits only active, non-deleted accounts (as planned). A deactivated account reactivated later
  is not admitted; staff Admit (KNG-214) covers it. Worth a look before the switch-over.
- **L3-10** `useNoReferrer` adds `<meta name="referrer" content="no-referrer">` on `/invite` and `/join` (DESIGN § 3.3;
  the reset and link pages don't have it yet; follow-up below).
- **L3-11** A personal create runs one transaction per address (the old invite revoked, the new one and its mail
  together), so a failure part-way keeps the addresses before it. Bulk results report each address.
- **L3-12** Group memberships of a new shell are written directly (`InvitationRepository.AddMembershipAsync`), not
  through `UserPermissionGroupService`, because the escalation guard already ran when the invite was created; the
  fold uses `UserPermissionGroupService.UpsertAsync`.

### Discrepancies with the plan / design

- Plan § 5.1 "`UserDto` and `AuthUserDto` gain …": there is no `AuthUserDto` (login returns `UserDto`); `emailVerified`
  already existed and now also reads `EmailVerifiedAt`.
- DESIGN § 3.4's single statement omits `PausedAt IS NULL`; the plan's (and the code's) includes it.
- Plan § 5.1 link format `{base}/invite?code=…` in the link 3 handoff vs DESIGN `/invite/<token>`: the code follows DESIGN.

### Live checklist (dev API + web app; not run)

1. `dotnet ef database update` on a copy of the alpha DB: every active account has `AdmittedAt = CreatedAt`; deleted
   and inactive ones have NULL; Admin holds `knk.admin.invites` (`permission_grants`). Run
   `KNK_TEST_MYSQL=… dotnet test --filter Category=requires-mysql` (incl. the 3 new invitation tests).
2. With the default `Mode=LinkCode`: `/account link` → `/auth/register` works exactly as before; `POST
   api/Auth/register` with an `inviteCode` answers 403 `InvitesDisabled`; `/admin/invitations` shows the mode warning.
3. Admin → **Invitations** (nav and Moderation header): create a personal invite for your own address (send email on)
   → result panel with Copy link and "Mail pending"; `/admin/email` shows the Invitation row; the mail (pickup folder,
   relay or API log with `AllowLogTransport`) has the link.
4. Set `Security__Registration__Mode=Invite`, restart. Open the link: the address bar shows `/invite`, the email is
   locked; sign up → logged in, `/account` shows "Email verified"; the user is `web-…`, `AdmittedAt` and
   `InvitedVia*` set, Default (+ group) membership, **no** SIGNUP_GRANT ledger entry; a Welcome mail is queued.
   Open the same link again → "invalid or has expired".
5. Shared code with 2 uses → `/join?code=…` twice with two addresses → both work; the third → invalid; the drawer
   lists both as "Not linked yet" with masked emails.
6. Pause → sign-up refused; resume → works; rotate → the old code refused, the new one works, uses kept; revoke →
   refused. Expired (create with 1 day, wait or edit `ExpiresAt`) → refused with the same message.
7. Resend a personal invite four times in a day → the 4th answers 429; the old link stops working after each resend.
8. Under `Mode=Invite`: `/account link` code of a grandfathered player → registration works; of an account created
   after the switch (plugin, `AdmittedAt` NULL) → "You need an invitation" with the `/join` link.
9. A non-admin staff member without the node gets the "staff only" screen on `/admin/invitations` and no nav entry.

### Deploy notes (a deploy of this API state)

- Migrations `AddInvitations` (additive, with the backfill) and `SeedInvitationStaffNode` (data) run on start-up.
- **No setting needed**: `Security:Registration:Mode` defaults to `LinkCode`, so a deploy is behaviour-neutral for the
  alpha. Do **not** set `Mode=Invite` before I2 (KNG-214) is deployed too: invited web accounts can't link Minecraft yet.
- The link 2 precondition still holds: `Email__AllowLogTransport=true` while the alpha runs `Email__Provider=Log`.
- Optional: `Invitations__*` overrides; the "Alpha Tester" group is seeded in link 7 (until then the group select is
  empty unless the group exists).

### Risks

- The backfill is the step that decides whether existing players can join once the admission gate is on. It was not
  run against MySQL here; checklist item 1 must pass on a copy of the alpha DB before the switch-over.
- EF InMemory runs `TryTakeUseAsync` without `ExecuteUpdate`; the race is covered only by the skipped MySQL test.
- Under `Mode=Invite` the plugin's new accounts are not admitted. Until I2's gate exists that changes nothing in game,
  but `/account link` registration for them is refused — another reason not to switch before I2.
- A shell account can log in and see its account page, but has no Minecraft identity until KNG-214's linking.

### What the next link must know

- `IInvitationService.FindUsableAsync(token, code)` and `RedeemAsync(new InviteSignup(invitation, email, hash,
  verified))` are the building blocks for register-with-`claimCode` (case A at sign-up): RedeemAsync creates the shell
  and returns the `User`; link 4 then sets `Uuid`/`Username` from the claim code (or folds) in the same flow and posts
  SIGNUP_GRANT then. `AuthService.RegisterAsync` refuses `claimCode` first thing (`NotSupportedYet`): replace that.
- `User.AdmittedAt` is the admission flag the plugin gate reads (via the Admission API). Set it in staff Admit and in
  claim linking; `UserService.CreateAsync` leaves it NULL under `Mode=Invite`.
- `AuditAction.MinecraftLinked` (40), `MinecraftUnlinked` (41) and `PlayerAdmitted` (42) exist; labels in the web app
  (`src/utils/auditDetails.ts`) cover only 37–39.
- `/account/link` is a `<Navigate to="/account">` in `src/App.tsx`: replace it with the onboarding page. The Welcome
  mail already links there.
- Test fixtures: `Tests/…/Services/Invitations/InvitationTestDb` (InMemory + real composer + `ManualClock`; pass an
  existing `KnKDbContext` to share it with `AuthTestHarness`, as `InviteRegistrationTests` does).

### Follow-ups found (not fixed)

- `/auth/reset-password` (and link 4's `/link` pages) don't send `Referrer-Policy: no-referrer`; `useNoReferrer` can
  be reused. Noted in the KNG-212 comment.
- The web app's audit label list doesn't know `UsernameReleased` (35, from the alpha hardening); it shows the raw name.
