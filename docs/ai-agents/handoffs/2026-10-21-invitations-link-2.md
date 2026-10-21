# Invitations chain — link 2: E1 email engine (KNG-206)

**Written:** 2026-10-21 by link 1 (KNG-211 API half, KNG-207, KNG-208), after it finished.
**Charter:** [INVITATIONS_CHAIN.md](INVITATIONS_CHAIN.md). Read it first; it overrides this file.
**Plan:** [IMPLEMENTATION_PLAN.md](../../specs/invitations/IMPLEMENTATION_PLAN.md) § 3; [DESIGN.md](../../specs/invitations/DESIGN.md) § 4.
**Previous link's report block:** [2026-10-21-invitations-chain.md](../../reports/2026-10-21-invitations-chain.md) "Link 1".

## State at hand-over

| Repo | Branch `claude/player-signup-invitation-flow-f4v7ul` | Base | Tests at hand-over |
|---|---|---|---|
| knk-workspace | link 1 docs commit on top of `7fa7930` (merge of `main` `e54ec81`) | `main` | — |
| knk-web-api | `bb4b9ee` (`110451f` E0 optional SMTP auth, `bb4b9ee` L0) | `master` `2d71155` (merged, unchanged) | 2754 passed, **4 known-red** (`PathResolutionServiceTests` ×2, `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_ValidatesRequired`, `ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`; red on `master` too), 75 skipped (MySql) |
| knk-web-app | `2bf70ab` | `main` `e30c815` | 154 suites / 940 tests; `npm run build` compiles with `main`'s pre-existing warnings |
| knk-plugin | `30b10e6e` | `claude/mc-26.2-upgrade` `88497649` (KNG-182, unmerged) | core 2168 / api-client 264 (2 skipped) / paper 1870 (18 skipped), 0 failures |

- **Link 1's exit criteria are met**: all five steps pushed, builds green, counts ≥ baseline (+59 API tests, +2 web
  tests), E0 hash `110451f` recorded in the report and in a KNG-211 comment.
- **Tracker:** the chain's row is on workspace `main` (`bb60574` + link 1's update). Update it there (charter § 1.2).
- **Toolchains on a fresh container:** .NET 8 and Node 22 are present. Use `dotnet build knkwebapi_v2.csproj` (the
  `.sln` names `tests/` in lower case and fails on Linux) and `npx npm@11 ci` for the web app. This link doesn't change
  the plugin, so no JDK 25 is needed.
- **EF tooling:** `~/.dotnet/tools/dotnet-ef` (9.0.10) is installed on the image but not on `PATH`. Generate migrations
  with `ASPNETCORE_ENVIRONMENT=Development Database__MySqlServerVersion=8.0.36 ConnectionStrings__MySqlDbConnection="Server=localhost;Database=x;User=x;Password=x" ~/.dotnet/tools/dotnet-ef migrations add <Name> --project knkwebapi_v2.csproj`
  (the version setting stops it from connecting). Then edit the generated file for any SQL the plan wants.
- No MySQL in the container: write `[MySqlFact]`s where the plan asks and say they were skipped.

## Your work (plan § 3), in this order

1. **Claim** (charter § 5.1): tracker row on `main`, KNG-206 → *In Progress*.
2. **Setup** (charter § 1): fetch, merge `origin/master` / `origin/main` into the feature branches, dry-run pushes,
   record the baselines (expect the numbers above).
3. **knk-web-api** (§ 3.1): MailKit (pinned), `EmailOutboxMessage` + migration `AddEmailOutbox`, `Services/Email/`
   (composer, kinds, renderer with embedded templates, dispatcher with `TimeProvider`, transports, throttle),
   `EmailSettings` additions, `AppSettings.PublicBaseUrl`, the startup guard, `api/EmailOutbox`
   (`RequirePermission(ServerConfig)`; add to `RequireServiceOrPermissionAttributeTests.ProtectedRoutes`), retention,
   staff email-change notice to the old address, and the removal of `AccountMailQueue`, `AccountMailSender`,
   `IPasswordResetDeliveryService` and both implementations plus the SMTP/Log paths in `PrivacyEmailService`.
4. **knk-web-app** (§ 3.2): `emailOutboxClient`, DTOs, `/admin/email` page behind `StaffRoute node="knk.admin.config"`,
   nav entry. Tests next to the existing ones.
5. **Docs** (§ 3.3): new `docs/guides/email.md` (with the smoke steps), alpha-go-live § 4, production-installation,
   DESIGN § 4 deviations, plan status line, CHANGELOG, the report's Link 2 block.
6. **Linear:** KNG-206 → *In Review* with the commits, tests vs baseline, checklist and flags. KNG-211 stays open.
7. **Hand over:** `2026-10-21-invitations-link-3.md` (I1, KNG-212), committed and pushed.

## What link 1 leaves you (read before touching mail code)

- **E0's optional SMTP auth lives in the files you remove.** `SmtpCredentials.Resolve(EmailSettings)` in
  `Services/SmtpPasswordResetDeliveryService.cs` and the `DeliverAsync` seams in both SMTP services exist only for E0
  (`110451f`, which the developer may cherry-pick to `master` on its own). When `SmtpEmailTransport` (MailKit) replaces
  them, keep the rule and its tests' intent: **no username → connect without `Authenticate`; a username without a
  password → refuse with a message naming `Email:SmtpPassword`**. `Tests/…/Services/SmtpOptionalAuthTests.cs` goes
  with the old services; write the equivalent for the transport.
- `AuthService.RequestPasswordResetAsync` creates the reset token with `Purpose = LinkCodePurpose.PasswordReset`
  (KNG-208). When you switch it to `IEmailComposer.QueueAsync`, the dedupe key `reset:{tokenId}` needs the created
  `LinkCode.Id` (`CreateAsync` returns the entity).
- `AuthTestHarness` (`Tests/…/Security/AuthTestHarness.cs`) wires `IAccountMailQueue` into `AuthService` and captures
  mails in `Mail`; `AccountSecurityTests`, `AuthSessionTests`, `RegistrationAndLoginTests`, `LinkMinecraftAccountTests`
  and the password-reset tests build on it. Replace the queue in the harness with a capturing `IEmailComposer` (or a
  fake transport) and keep those suites green unchanged.
- `UsersController` now takes three optional constructor parameters at the end (`IAuthService?`,
  `IWebHostEnvironment?`, `IOptions<SecuritySettings>?`) for link-minecraft-account case B. If § 3.1's staff
  email-change notice needs a dependency there, add it the same way so the eight existing test constructions stand.
- `Configuration/RefreshTokenCookie.cs` is the shared refresh-cookie helper (moved out of `AuthController` by link 1).
- `LinkCodeCleanupService` is registered right after `AccountMailSender` in `ServiceCollectionExtensions` (l.43-46);
  when you delete the queue and sender lines, keep the `ILinkAttemptLimiter` and `LinkCodeCleanupService` lines.
- The alpha runs `Email__Provider=Log` until E0's NAS half is done: the startup guard must not break it. Set
  `AllowLogTransport` in alpha-go-live § 4 **and** call it out in the report's deploy notes (charter, link 2 specifics).

## Open flags from link 1 (for context; none block you)

L1-1 shell `PasswordHash` cleared in the fold; L1-2 invite fields copy deferred to I1 (link 3, not you); L1-3 code
spent before the fold; L1-4 fold response shape; L1-5 case A releases a squatted name; L1-6 `Security:LinkAttempts`
uses the `LockoutSettings` shape; L1-7 optional controller dependencies. Details in the report.

## Risks to keep in mind

- Removing `IPasswordResetDeliveryService` touches `ServiceCollectionExtensions` l.57-65 and the privacy switch
  l.276-283 as the plan says, but also `AuthTestHarness` and `AccountSecurityTests.MailSender_LogsSmtpFailures_InsteadOfThrowing`
  (which tests the sender you delete; replace it with the dispatcher's failure test).
- `email_outbox` rows must commit with the caller's transaction (composer adds to the current `DbContext`); the
  `UserRepository.RunWithUsersLockedAsync` / `RunInTransactionAsync` helpers are the transaction boundary the services
  already use.

## Exit criteria

- § 3 built and pushed; builds green; counts ≥ the numbers above apart from removed tests (name what was removed);
  the 4 known-red API tests unchanged.
- `docs/guides/email.md` written with the smoke steps; `AllowLogTransport` precondition in go-live § 4 and the report.
- The handoff file for link 3 (`2026-10-21-invitations-link-3.md`, I1 / KNG-212) written and pushed.
