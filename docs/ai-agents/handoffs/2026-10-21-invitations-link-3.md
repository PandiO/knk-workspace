# Invitations chain — link 3: I1 invitations and invite-based registration (KNG-212)

**Written:** 2026-10-21 by link 2 (KNG-206), after it finished.
**Charter:** [INVITATIONS_CHAIN.md](INVITATIONS_CHAIN.md). Read it first; it overrides this file.
**Plan:** [IMPLEMENTATION_PLAN.md](../../specs/invitations/IMPLEMENTATION_PLAN.md) § 5; [DESIGN.md](../../specs/invitations/DESIGN.md) § 3, § 5.3–5.4, § 6.
**Previous link's report block:** [2026-10-21-invitations-chain.md](../../reports/2026-10-21-invitations-chain.md) "Link 2".

## State at hand-over

| Repo | Branch `claude/player-signup-invitation-flow-f4v7ul` | Base | Tests at hand-over |
|---|---|---|---|
| knk-workspace | link 2 docs commits on top of the merge of `main` `7c80c85` | `main` | — |
| knk-web-api | `a8b42ca` (`0d7ec4a` E1 engine, `a8b42ca` Log-transport fix) on link 1's `bb4b9ee` | `master` `2d71155` (merged, unchanged) | **2787 passed, 4 known-red** (`PathResolutionServiceTests` ×2, `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_ValidatesRequired`, `ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`; red on `master` too), **77 skipped** (MySql) |
| knk-web-app | `aecd811` | `main` `e30c815` | **156 suites / 950 tests**; `npm run build` compiles with `main`'s pre-existing warnings |
| knk-plugin | `30b10e6e` (unchanged by link 2) | `claude/mc-26.2-upgrade` `88497649` (KNG-182, unmerged) | core 2168 / api-client 264 / paper 1870, 0 failures |

- **Link 2's exit criteria are met**: § 3 built and pushed in api and web-app, builds green, counts ≥ the baseline
  apart from 8 removed tests (named in the report), the 4 known-red unchanged, `docs/guides/email.md` written with the
  smoke steps, the `AllowLogTransport` precondition in go-live § 4 and in the report's deploy notes.
- **Tracker:** the chain's row is on workspace `main`. Update it there (charter § 1.2).
- **Toolchains on a fresh container:** .NET 8 and Node 22 are present. Build `dotnet build knkwebapi_v2.csproj` (the
  `.sln` fails on Linux); web app `npx npm@11 ci`. No plugin change in link 3, so no JDK 25 needed.
- **EF tooling:** `ASPNETCORE_ENVIRONMENT=Development Database__MySqlServerVersion=8.0.36 ConnectionStrings__MySqlDbConnection="Server=localhost;Database=x;User=x;Password=x" ~/.dotnet/tools/dotnet-ef migrations add <Name> --project knkwebapi_v2.csproj`.
  Check that the snapshot diff only adds your tables/columns.
- No MySQL in the container: write the `[MySqlFact]`s the plan asks for and say they were skipped.

## Your work (plan § 5), in this order

1. **Claim** (charter § 5.1): tracker row on `main`, KNG-212 → *In Progress*.
2. **Setup** (charter § 1): fetch, merge `origin/master` / `origin/main`, dry-run pushes in api, web-app and workspace,
   baselines (expect the numbers above).
3. **knk-web-api** (§ 5.1): `invitations` / `invitation_redemptions` and the `User` columns in migration
   `AddInvitations` **with the grandfathering backfill**; `InvitationSettings`; `InvitationService`; register with
   `inviteCode` under `Security:Registration:Mode` (default **`LinkCode`**: every existing test must behave as before);
   `claimCode` answers `NotSupportedYet` until link 4; `api/Invitations` with explicit access rules, the anonymous
   check endpoint on the `EndpointAccessRulesTests` allow-list, staff routes in `ProtectedRoutes`.
4. **knk-web-app** (§ 5.2): `/invite`, `/join`, `/admin/invitations`, the Account page badge, tests.
5. **Docs, report block "Link 3", plan status, CHANGELOG, Linear** (KNG-212 → *In Review*), **handoff for link 4**
   (`2026-10-21-invitations-link-4.md`, I2 server side, KNG-214).

## What link 2 leaves you (read before sending mail)

- **Queue mails with `IEmailComposer.QueueAsync(kind, to, model, dedupeKey, expiresAt, userId)`**
  (`Services/Email/EmailComposer.cs`). It adds the outbox row to the caller's `KnKDbContext` **and saves**, so call it
  inside the transaction that creates the invite (`UserRepository.RunInTransactionAsync` / `RunWithUsersLockedAsync`);
  a rolled-back invite then never mails (L2-5).
- **Invitation mail:** `EmailKind.Invitation`, dedupe key `invite:{invitationId}:{sendCount}` (plan § 5.1),
  `expiresAt` = the invite's expiry, model `{ inviterName, inviteUrl, expiresAt }`. Throttle class `invitation`:
  3 per recipient per hour (the API's own limit on top of `ResendPerDay`); over it the row is **Suppressed** — surface
  that in the create/resend response (the returned `EmailOutboxMessage.Status`) rather than claiming "sent".
- **Welcome mail:** `EmailKind.Welcome`, model `{ username, linkUrl }`, key e.g. `welcome:{userId}`, no expiry.
  `MinecraftLinked` {`username`, `minecraftName`} and `FinishLinking` {`username`, `linkUrl`} exist for link 4.
- **Every placeholder must be in the model**: the tests render strictly and throw on an unknown placeholder; in
  production a missing one renders empty. Templates live in `knk-web-api/Services/Email/Templates/` (embedded); change
  the wording there if § 5 needs "closed alpha" phrasing (the invitation text says "a medieval Minecraft server").
- **Links:** build them with `AppSettings.ResolveBaseUrl(app?.Value.PublicBaseUrl, security.PasswordResetFrontendBaseUrl)`
  (`Configuration/AppSettings.cs`), e.g. `{base}/invite?code=…` and `{base}/join?code=…`.
- **Never log invite codes outside Development** (charter § 3). `LogEmailTransport` logs mail bodies (so the code) in
  Development or with `Email:AllowLogTransport=true` — that opt-in is the alpha's setting until its relay works, which
  matches today's reset-link practice (L2-12). Your own service logs must still not contain the code.
- **Tests:** `AuthTestHarness.Email` (a `CapturingEmailComposer`) and `.Mail` capture what `AuthService` queues; if
  registration with `inviteCode` lives in `AuthService`, assert the `Welcome` mail there. For an `InvitationService`
  with a real outbox use `Tests/…/Services/Email/EmailTestDb` (InMemory, real composer/throttle/dispatcher, a
  `ManualClock`).
- **Access-rule tests:** `RequireServiceOrPermissionAttributeTests.ProtectedRoutes_CarryTheirGate` now reads both
  `[RequireServiceOrPermission]` and `[RequirePermission]` nodes, so staff-only `knk.admin.invites` routes go straight
  into `ProtectedRoutes`.
- **`UsersController`** has optional constructor parameters at the end (L1-7 plus link 2's `IEmailComposer?`,
  `ILogger<UsersController>?`); add new ones the same way so the existing test constructions stand.
- `FoldWebAccountIntoMinecraftAccountAsync` (link 1, L1-2) is where the invite fields and group copy go.

## Open flags (for context; none block you)

Link 1: L1-1…L1-7. Link 2: L2-1 Failed rows keep bodies without a token (Retry); L2-2 daily cap → error log + admin
page, no in-game notice; L2-3 Log guard outside Development; L2-4 `EmailKind.Test`; L2-5 composer saves the caller's
context; L2-6 throttle classes; L2-7 queue errors caught in reset/email-change; L2-8 port 465 TLS; L2-9
`Email:Transport` empty in `appsettings.json`; L2-10 outbox rows not erased by privacy deletion (follow-up); L2-11 logo
URL; L2-12 Log transport logs links with `AllowLogTransport`. Details in the report.

## Risks to keep in mind

- The grandfathering backfill is the riskiest step of the chain: every existing account must come out admitted, or
  `admission.mode` later locks players out. Test it on a copy of real-shaped data (MySql test) and state it in the
  live checklist.
- With `Registration:Mode` left at `LinkCode`, nothing may change for today's alpha (charter § 3); run the auth suites
  unchanged.
- The deploy precondition from link 2 still holds for any deploy of this branch: the alpha's API env needs
  `Email__AllowLogTransport=true` while it runs `Email__Provider=Log` (go-live § 4).

## Exit criteria

- § 5 built and pushed; builds green; counts ≥ the numbers above; the 4 known-red unchanged; existing auth tests
  unchanged with `Mode=LinkCode`.
- Migration with the grandfathering backfill; MySql tests written (skipped if no MySQL, and said so).
- The handoff file for link 4 (`2026-10-21-invitations-link-4.md`, I2 server side / KNG-214) written and pushed.
