# Invitations chain — progress report

**Status:** Link 1 done (2026-10-21), nothing merged. Link 2 is ready ([handoff](../ai-agents/handoffs/2026-10-21-invitations-link-2.md)).
**Last updated:** 2026-10-21 (link 1)
**Linear:** [KNG-205](https://linear.app/kngpandi/issue/KNG-205) and its children (see the [charter](../ai-agents/handoffs/INVITATIONS_CHAIN.md))
**Branch:** `claude/player-signup-invitation-flow-f4v7ul` in every repo. knk-plugin's is based on `claude/mc-26.2-upgrade` (KNG-182).

## Summary (updated in place by each link)

| Link | Issues | Status | Heads (api / app / plugin / workspace) | Tests vs baseline | Started how |
|---|---|---|---|---|---|
| 1 | KNG-211 (API), KNG-207, KNG-208 | **done** (not merged, not live-tested) | api `110451f` (E0) + `bb4b9ee` (L0) / app `2bf70ab` / plugin `30b10e6e` / workspace: see git log | API 2754 passed, 4 known-red, 75 skipped (baseline 2697 / 4 / 73; +59 tests, 2 new `[MySqlFact]` skipped); app 940 (baseline 938); plugin core 2168 / api-client 264 / paper 1870, 0 failures (unchanged) | `create_session` by the coordinator with the § 8 prompt; `add_repo` and the dry-run pushes succeeded |
| 2 | KNG-206 | ready | — | — | — |
| 3 | KNG-212 | waiting | — | — | — |
| 4 | KNG-214 (API + web app) | waiting | — | — | — |
| 5 | KNG-214 (plugin) | waiting | — | — | — |
| 6 | KNG-216 | waiting | — | — | — |
| 7 | KNG-218 (prep) + final write-up | waiting | — | — | — |

**Follow-ups found during the chain:**
- knk-web-api `knkwebapi_v2.sln` points at `tests/knkwebapi_v2.Tests/…` (lower case), so `dotnet build` of the solution fails on Linux; `dotnet build knkwebapi_v2.csproj` works. Noted in a KNG-208 comment (link 1); not fixed (out of scope).
- knk-web-app: `npm ci` with the bundled npm 10 rejects the lock file (`Missing: yaml@2.9.1`); `npx npm@11 ci` works, as `CLAUDE.md` says. Noted in the KNG-208 comment.
- knk-plugin `plugin.yml` still declares the `knk.account.create` permission node (no command uses it). Left in place (link 1); a one-line removal for whoever next touches `plugin.yml`.

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
