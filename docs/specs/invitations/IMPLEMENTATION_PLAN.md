# Invite-only sign-up, email engine and web-first Minecraft linking — Implementation plan

**Status:** In implementation through the [invitations chain](../../ai-agents/handoffs/INVITATIONS_CHAIN.md) (7 links, charter 2026-10-21). **Link 1 done on the feature branch (2026-10-21):** E0's API half (§ 2, knk-web-api `110451f`, cherry-pickable) and L0 (§ 4; api `bb4b9ee`, web-app `2bf70ab`, plugin `30b10e6e`), not merged, not live-tested; deviations flagged L1-1…L1-5 in the [progress report](../../reports/2026-10-21-invitations-chain.md). **Link 2 done (2026-10-21):** E1 (§ 3; api `0d7ec4a` + `a8b42ca`, web-app `aecd811`, [email guide](../../guides/email.md)), not merged, not live-tested; flags L2-1…L2-12. **Link 3 done (2026-10-21):** I1 (§ 5; api `77042fd` + `8ca8507`, web-app `dfa5cdd` + `18f3c9f`), not merged, not live-tested; flags L3-1…L3-12, as-built note at the end of § 5. Next: link 4 (I2 server side, § 6.1 and § 6.3). The decisions are in [DESIGN.md](DESIGN.md) § 8 (2026-10-21).
**Last updated:** 2026-10-21 (link 3)
**Linear:** [KNG-205](https://linear.app/kngpandi/issue/KNG-205) (parent). Each work package's issue is listed in § 1.
**Sources:** [DESIGN.md](DESIGN.md), plus code read on 2026-10-21 at knk-web-api `master` `2d71155`, knk-web-app `main` `e30c815`, and knk-plugin `claude/mc-26.2-upgrade` `88497649` (Paper 26.3, Java 25).

**Branches:** one standing branch per repo for the whole feature, `claude/player-signup-invitation-flow-f4v7ul`:

| Repo | Based on | Notes |
|---|---|---|
| knk-web-api | `master` `2d71155` | Merge `master` in (no rebase) when it moves. |
| knk-web-app | `main` `e30c815` | Same. |
| knk-plugin | **`claude/mc-26.2-upgrade` `88497649`** ([KNG-182](https://linear.app/kngpandi/issue/KNG-182): Paper 26.3, Java 25, WorldGuard 7.0.20 / WorldEdit 7.4.6; the branch kept its 26.2 name) | Pushed 2026-10-21. Build with **JDK 25**. Until KNG-182 merges, merge `claude/mc-26.2-upgrade` in whenever it moves; afterwards, merge `main`. This branch merges into `main` only **after** KNG-182 (§ 9). Write to Paper 26.3 APIs and Adventure 5 (e.g. no `ClickEvent#value()`, KNG-192). |
| knk-workspace | `main` | This plan, guides, tracker. |

E0 is the exception: its small API change goes to `master` on its own (§ 2). E1 merges on its own once smoke-tested, and the branch continues afterwards (§ 9).

**Build and test commands**
- API: `dotnet build`, then `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`. Add migrations with `dotnet ef migrations add <Name>`. Stage `Tests/` with a capital `T`.
- Web app: `npm run test:ci` and `npm run build` (ESLint runs in the build). Use npm 11 for dependency changes (`npx npm@11 …`).
- Plugin: `./gradlew build -x deployToDevServer` on JDK 25. Never build a `Location` around an inline `mock(World.class)`.

---

## 1. Work packages and issues

| # | Package | Repos | Issue | Blocked by |
|---|---|---|---|---|
| E0 | Real mail on the alpha now: SMTP relay container + Gmail | api (tiny), NAS, workspace | [KNG-211](https://linear.app/kngpandi/issue/KNG-211) | — |
| E1 | Email engine | api, web-app, workspace | [KNG-206](https://linear.app/kngpandi/issue/KNG-206) | E0 (order only) |
| L0 | Link hygiene + KNG-207 linking rules | api, plugin, workspace | [KNG-207](https://linear.app/kngpandi/issue/KNG-207), [KNG-208](https://linear.app/kngpandi/issue/KNG-208) | — |
| I1 | Invitations + invite-based registration (web-first accounts) | api, web-app | [KNG-212](https://linear.app/kngpandi/issue/KNG-212) | L0; E1 for the mails |
| I2 | Admission gate, claim codes, Minecraft linking | api, plugin, web-app | [KNG-214](https://linear.app/kngpandi/issue/KNG-214) | L0, I1 |
| A1 | Cloudflare Access sync + sign-up bypass | api, web-app, NAS, Cloudflare | [KNG-216](https://linear.app/kngpandi/issue/KNG-216) | I1 |
| I3 | Rollout: seeds, smoke test, docs, switch-over | workspace, api, NAS | [KNG-218](https://linear.app/kngpandi/issue/KNG-218) | I1, I2, A1, KNG-182 merged |

**Session chain** (global instructions, "Session chains"):
1. E0 is done with the developer at the NAS.
2. Then one link each: L0 + E1, I1, I2, then A1 + I3 (docs and smoke guide).

Each link runs `git push --dry-run` on the branches it will change before it changes anything, and updates its issue, this plan's status line and the tracker row when it stops.

---

## 2. E0 — Real mail on the alpha now (KNG-211)

**Goal:** password-reset and email-change mails reach the inbox on the alpha this week, without the engine.

**knk-web-api** (small fix, straight to `master`; no schema or contract change)
- `Services/SmtpPasswordResetDeliveryService.cs` (l.49) and `Services/Privacy/PrivacyEmailService.cs` (~l.89): make SMTP authentication optional.
  - With `Email:SmtpUsername` empty, send without `Credentials`.
  - When a username is set, keep today's "password required" check.
- Test: no credentials → the message is built and handed to the client without auth. Use a seam or pickup-directory delivery.

**NAS (with the developer)**
1. Add a `mailrelay` service to the alpha compose file:
   - image `boky/postfix` at a pinned tag;
   - networks `backend` and a new `mail-egress`; no published ports;
   - `RELAYHOST=[smtp.gmail.com]:587`, `RELAYHOST_USERNAME=knightsandkingsmc@gmail.com`, and `RELAYHOST_PASSWORD` from a secret file (the Gmail app password);
   - `ALLOWED_SENDER_DOMAINS=gmail.com`, and `MYNETWORKS` set to the backend subnet.
2. API env:
   - `Email__Provider=Smtp`, `Email__SmtpHost=mailrelay`, `Email__SmtpPort=587`;
   - `Email__UseStartTls=false` (an internal hop);
   - `Email__SmtpUsername=` (empty), `Email__FromAddress=knightsandkingsmc@gmail.com`;
   - remove `Email__SmtpPassword` from the API env.
3. Test:
   1. forgot-password for a tester account → the mail arrives (check spam) → reset → the old sessions end;
   2. an email change → the notice reaches the old address;
   3. stop the relay → forgot-password still answers the generic message, and the API log shows the send failure.

**Docs:** update [alpha-go-live](../../guides/alpha-go-live.md) § 4 (mail block and comment) and § 2 diagram, the [closed-alpha runbook](../../guides/closed-alpha-deployment-runbook.md), and [production-installation](../../guides/production-installation.md) (relay option next to direct SMTP).

**Done when:** a real reset mail is received on the alpha and the docs say how.

---

## 3. E1 — Email engine (KNG-206)

**Branch:** the standing branch, merged on its own after its smoke steps (§ 9). Follows DESIGN § 4.

### 3.1 knk-web-api

**Package and model**
- **Package:** MailKit, the current stable version, pinned. `System.Net.Mail` is no longer used.
- **Model** `Models/EmailOutboxMessage.cs`, table `email_outbox`:
  - `Id` (bigint), `Kind` (string ≤ 40), `ToAddress` (≤ 256), `ToName?`, `Subject` (≤ 200);
  - `TextBody?` and `HtmlBody?` (longtext);
  - `Status` (Pending / Sent / Failed / Expired / Suppressed), `Attempts`, `NextAttemptAt`, `ExpiresAt?`;
  - `LastError?` (≤ 1000), `CreatedAt`, `SentAt?`, `ProviderMessageId?`, `UserId?`;
  - `DedupeKey` (unique, ≤ 120).
  - Indexes: `(Status, NextAttemptAt)` and `(ToAddress, CreatedAt)`.
  - Config in `Properties/KnKDbContext.cs`; migration `AddEmailOutbox`.

**`Services/Email/`**
- `IEmailComposer` / `EmailComposer`: `QueueAsync(EmailKind kind, string to, object model, string dedupeKey, DateTime? expiresAt = null, int? userId = null)`.
  - Renders the template and adds the row to the **current** `DbContext`, so the row commits with the caller's transaction.
  - Then signals the dispatcher.
- `EmailKind` holds Invitation, Welcome, MinecraftLinked, FinishLinking, PasswordReset, EmailChanged, EmailVerification, PrivacyDeletionConfirm and PrivacyDeletionScheduled, each with its template name and throttle class.
- `EmailTemplateRenderer`:
  - embedded resources `Services/Email/Templates/_layout.html`, `_layout.txt` and `<kind>.html|.txt` (add `<EmbeddedResource>` to `knkwebapi_v2.csproj`);
  - `{{name}}` placeholders, HTML-encoded in the `.html` files;
  - an unknown placeholder throws in tests and stays empty in production.
- `EmailDispatcher : BackgroundService`: a `PeriodicTimer` every 5 s plus a `Channel<bool>` wake-up signal; it uses a scope per tick and `ConnectivityAwareFailureLogger` (the `RankExpirySweepService` pattern).
  - It takes at most 20 Pending rows with `NextAttemptAt <= now`.
  - Expired rows become `Expired`.
  - Otherwise it sends. On failure: `Attempts++`, then backoff 1 min / 5 min / 15 min / 1 h / 4 h; `Failed` after 6 attempts.
  - Sent, Expired and Failed rows get `TextBody`/`HtmlBody` set to null.
  - It uses `TimeProvider`, so tests control the clock.
- `IEmailTransport`:
  - `SmtpEmailTransport` (MailKit `SmtpClient`): `SecureSocketOptions.StartTlsWhenAvailable` / `None` from config; authenticates only when a username is set.
  - `LogEmailTransport`: logs kind, masked recipient and subject; logs links only in Development.
  - `PickupEmailTransport`: writes `.eml` files to `Email:PickupDirectory`, for dev and tests.
- `EmailThrottle`: before queueing, counts `email_outbox` rows per recipient in the last hour:
  - ≤ 3 per kind class, ≤ 6 in total;
  - `Email:DailyCap` (300) across all rows.
  - Over the limit, the row is stored as `Suppressed`, a warning is logged, and the daily cap queues a `CurrencyAlert`-style server notice.

**Configuration**
- `Configuration/EmailSettings.cs` gains:
  - `Transport` (Smtp / Log / Pickup; `Provider` stays read as a fallback);
  - `AllowLogTransport` (default false), `PickupDirectory`, `ReplyToAddress`, `DailyCap` = 300, `MaxAttempts` = 6.
- New `Configuration/AppSettings.cs` with `PublicBaseUrl`. `Security:PasswordResetFrontendBaseUrl` and `Privacy:FrontendBaseUrl` stay as fallbacks.
- **Startup:** in Production, `Transport=Log` without `AllowLogTransport=true` stops startup with a clear message. Add this to `Configuration/StartupSecurity.cs`.

**Wiring and call sites**
- **Remove** `AccountMailQueue`, `AccountMailSender`, `IPasswordResetDeliveryService` and its two implementations.
  - `AuthService.RequestPasswordResetAsync`: `ExpiresAt` = token expiry, dedupe key `reset:{tokenId}`.
  - Email-change notice: dedupe key `email-changed:{userId}:{ticks}`.
- `Services/Privacy/PrivacyEmailService.cs` keeps its interface and queues through the composer. Delete its SMTP and Log code paths.
- **Staff email change** (`UsersController` `PUT {id}/update-email`) now notifies the old address too (finding L101 in the 2026-10-08 verification report).
- **Retention:** `RetentionPolicyService` deletes `email_outbox` rows older than 90 days.
- **Controller** `Controllers/EmailOutboxController.cs` (`api/EmailOutbox`), all `[RequirePermission(StaffPermissions.ServerConfig)]`:
  - `GET` (paged; filter by status and kind; masked recipient; never bodies);
  - `POST test` (sends to the caller's own email; 400 if they have none);
  - `POST {id}/retry` (Failed → Pending).
  - Add these to `RequireServiceOrPermissionAttributeTests.ProtectedRoutes`.
- Delete `DependencyInjection/ServiceCollectionExtensions.cs` l.42-43 and l.57-65 (the account mail queue and delivery switch) and the privacy switch at l.276-283. Register the composer, renderer, dispatcher, throttle and the transport chosen by config.

**Templates** (text and HTML, one layout with the logo, a footer with "You get this mail because…" and the support Reply-To):
- `PasswordReset` and `EmailChanged`, ported from today's texts;
- `PrivacyDeletionConfirm` and `PrivacyDeletionScheduled`, from `PrivacyEmailTexts`;
- `Invitation`, `Welcome`, `MinecraftLinked` and `FinishLinking`. These are written now and used by I1/I2.

**Tests** (`Tests/knkwebapi_v2.Tests/Services/Email/`):
- **Renderer:** HTML encoding, both parts, unknown placeholder.
- **Dispatcher:** with a fake transport and `FakeTimeProvider`:
  - send → Sent and bodies null;
  - failure → backoff schedule → Failed after 6;
  - expiry → Expired without a send.
- **Throttle:** per kind, total, daily cap.
- **Composer:** the row is rolled back with the caller's transaction (InMemory; MySql integration if available).
- **Auth/privacy flows** still queue the right kinds, with no token in the logs outside Development.
- **Startup guard and access rules.**

### 3.2 knk-web-app
- `src/apiClients/emailOutboxClient.ts` (`ObjectManager` singleton, `Controllers.EmailOutbox`), DTOs in `src/types/dtos/email/EmailOutboxDtos.ts`.
- `src/pages/admin/EmailLogPage.tsx` at `/admin/email`, behind `StaffRoute node="knk.admin.config"`:
  - a table with status pills, kind, masked recipient, attempts and last error;
  - a Retry button on Failed rows;
  - a "Send test mail to me" button with a `FeedbackModal` result.
- Add a nav entry next to the other config pages.

### 3.3 Docs and done
- **Docs:**
  - a new living guide `docs/guides/email.md`: transports, settings, relay, DNS for the provider, the admin page, troubleshooting;
  - go-live § 4 (`AllowLogTransport` only for an emergency);
  - production-installation mail section;
  - DESIGN § 4 if anything deviates.
- **Smoke steps** (in the new guide): reset mail; email-change notice; privacy confirm; relay stopped → retries → relay started → sent; throttle (4 resets in an hour → the 4th is Suppressed); test mail from `/admin/email`.
- **Done when:** the tests pass, the developer has run the smoke steps on dev, the branch is merged, and the alpha is updated.

**As built (link 2, 2026-10-21; knk-web-api `0d7ec4a` + `a8b42ca`, knk-web-app `aecd811`):** as above, with these
deviations (details in the [report](../../reports/2026-10-21-invitations-chain.md), "Link 2"):
- Failed rows keep their bodies when they carry no token (no `ExpiresAt`), so Retry works (L2-1).
- The daily cap logs an error once a day and shows on `/admin/email`; no in-game staff notice yet (L2-2, follow-up).
- The Log guard applies outside Development, not only in Production (L2-3); the Log transport logs links in Development
  or with `AllowLogTransport=true`, which keeps the alpha's manual reset-link relay working (L2-12).
- `EmailKind.Test` for the admin test mail (L2-4); `QueueAsync` saves the caller's `DbContext` (L2-5).
- **Deploy precondition:** the alpha (`Email__Provider=Log`) needs `Email__AllowLogTransport=true` for this API build
  ([go-live § 4](../../guides/alpha-go-live.md)).

**Provider switch (E1 tail, optional before the beta):**
1. Open a Resend or Postmark account.
2. Add the SPF, DKIM and DMARC records for `knightsandkings.net`.
3. Move the relay's `RELAYHOST` and credentials to the provider.
4. `From: Knights & Kings <no-reply@knightsandkings.net>`, `Reply-To: support@knightsandkings.net` (decision E3). Set up the `support@` mailbox or forwarding first.

---

## 4. L0 — Link hygiene and the linking rules (KNG-207, KNG-208)

**Status (link 1, 2026-10-21): built on the feature branch** (api `bb4b9ee`, web-app `2bf70ab`, plugin `30b10e6e`). As built, with the deviations:
- The fold also clears the shell's `PasswordHash` (not only `Email`), so no two rows ever hold the same login (L1-1).
- The `InvitedVia*` fields and the invite group don't exist until I1; the fold copies `Email`, `PasswordHash`, `LastPasswordChangeAt`, `LastEmailChangeAt` and `EmailVerified`. **I1 must extend `UserService.FoldWebAccountIntoMinecraftAccountAsync`** with the invite fields and group membership (L1-2).
- The code is consumed **before** the fold (the conditional `TryMarkUsedAsync`), not after, so two requests with one code can't both fold (L1-3).
- The response is `{user, merged, accessToken, expiresIn, message}` after a fold and `{user, message}` otherwise; the web app stores `accessToken` with the current remember-me choice (L1-4).
- Case A also takes the verified name through `ReleaseUsernameFromWebOnlyAccountAsync` when a web-only account squats it (L1-5).
- Deleting finished codes is a new `ILinkCodeService.DeleteFinishedCodesAsync`, next to the existing `CleanupExpiredCodesAsync`, which only marks codes `Expired`.

### 4.1 knk-web-api

**Link codes**
- **Migration `LinkCodePurpose`:** on `linkcodes`, add:
  - `Purpose` (int: 0 Link, 1 PasswordReset, 2 Claim; backfill `1` where `CHAR_LENGTH(Code) = 64`);
  - `MinecraftUuid` (varchar 36, null) and `MinecraftName` (varchar 16, null);
  - index `(Purpose, Status, ExpiresAt)`.
- `Models/LinkCode.cs`: the fields and a `LinkCodePurpose` enum. Fix the 52^8 comment.
- `Repositories/LinkCodeRepository.cs`: replace the `Code.Length == 64` checks (l.342-382) with `Purpose`.
- `Services/LinkCodeService.cs`:
  - use `RandomNumberGenerator.GetInt32(alphabet.Length)`;
  - add `CreateClaimCodeAsync(uuid, name, ttl)`, which reuses an active claim code for that UUID if there is one. It uses the Crockford alphabet `0123456789ABCDEFGHJKMNPQRSTVWXYZ` and accepts input with `O`→`0` and `I`/`L`→`1`.
- **New `LinkCodeCleanupService : BackgroundService`**, hourly: deletes codes expired or used more than 7 days ago through the existing `CleanupExpiredCodesAsync`.
- **New `ILinkAttemptLimiter`**, modelled on `Services/LoginAttemptLimiter.cs`: 5 failed link or claim codes per account in 15 min → 15 min block → 429 `TooManyAttempts`. It replaces DESIGN § 6's `FailedAttempts` column, which isn't needed.

**Linking rules (DESIGN § 5.4)**
- Rewrite `UserService.LinkMinecraftAccountAsync(int userId, string code)` around one decision:
  - **Case A**, no account has this UUID (only reachable through claim codes, I2): set `Uuid` and `Username` on the web account.
  - **Case B**, a Minecraft account has this UUID: fold the web account into it. In `RunWithUsersLockedAsync`:
    1. `MergeWithForfeitAsync(primary: mc, secondary: web)`, so balances follow the existing rules;
    2. clear `Email` on the shell and save, because of the unique index;
    3. copy `Email`, `PasswordHash`, `LastPasswordChangeAt`, `EmailVerified`/`EmailVerifiedAt`, `InvitedVia*` and the invite's group membership to the Minecraft account;
    4. soft-delete the shell (already done by the merge);
    5. revoke the shell's sessions.
  - **Refuse:** if the UUID's account already has a `PasswordHash` (409 `AlreadyRegistered`), or if the web account already has a different UUID (409 `AlreadyLinked`).
  - The method returns the surviving user id.
- `UsersController.LinkMinecraftAccount` (l.1390): when the surviving account differs from the caller, issue a session for it through the same helper `AuthController.Register` uses, set the refresh cookie and return `{user, accessToken}`. Map the new errors to 409/429.
- **Tests:**
  - case B keeps the Minecraft account's id, groups and stats, moves the credentials, revokes the shell's sessions and returns a new session;
  - a refusal for each conflict;
  - the limiter;
  - `Purpose` backfill and the cleanup service;
  - the generator: each character has an equal share over a large sample, within tolerance.
  - EF InMemory doesn't enforce unique indexes, so add a **MySql integration test** (`Tests/.../MySql/`) for the email/UUID unique-index order in case B.

### 4.2 knk-plugin
- `commands/AccountCommandRegistry.java` l.78, `plugin.yml` `account.usage` and `commands/UserCommand.java` l.216: drop `create`.
- `commands/AccountLinkCommand.java`: delete the unused `startMergeFlow` and `mergeAccounts`.
- `commands/LinkCodeMessage.java`: add "Never give this code to anyone; staff never ask for it." to `DEFAULT_TEMPLATE`, and update `LinkCodeMessageTest`.

### 4.3 knk-web-app
- `authClient.linkMinecraftAccount` accepts the new response. When an `accessToken` is returned, store it through `tokenService` and refresh `AuthContext`.

### 4.4 Docs
- `docs/guides/users/PLAYER_GUIDE_ACCOUNT_MANAGEMENT.md`: remove `/account create` and the web → game text. The I3 update replaces the whole section.
- `docs/specs/users/SPEC_USER_ACCOUNT_MANAGEMENT.md` Part F: mark password reset as built (KNG-64) and point to this feature.

---

## 5. I1 — Invitations and invite-based registration (KNG-212)

### 5.1 knk-web-api

**Model**
- `Models/Invitation.cs`, table `invitations`:
  - `Id`, `Kind` (enum `InvitationKind`: Personal = 0, Shared = 1), `CodeHash` (char 64, unique), `CodeHint` (char 4);
  - `Email?` (≤ 256), `Label?` (≤ 120), `Note?` (≤ 500), `GrantGroupId?` (FK `permission_groups`, Restrict);
  - `MaxUses`, `UseCount`;
  - `CreatedAt`, `CreatedByUserId`, `ExpiresAt`, `PausedAt?`, `RevokedAt?`, `RevokedByUserId?`;
  - `SendCount`, `LastSentAt?`.
  - Indexes: `(Kind, ExpiresAt)` and `Email`.
- `Models/InvitationRedemption.cs`, table `invitation_redemptions`: `Id`, `InvitationId` (FK), `UserId`, `RedeemedAt`; index `InvitationId`.
- `Models/User.cs` gains `InvitedViaInvitationId?`, `InvitedByUserId?`, `AdmittedAt?` and `EmailVerifiedAt?`. Keep the `EmailVerified` bool in step until KNG-159 retires it.
- `Properties/KnKDbContext.cs`: configuration for all of the above.

**Migration `AddInvitations`**
- Creates the tables and columns.
- Backfills `AdmittedAt = CreatedAt` for every active, non-deleted user (grandfathering, decision I3).
- Backfills `EmailVerifiedAt = NULL`.

**Permissions and settings**
- `StaffPermissions.ManageInvites = "knk.admin.invites"` (`Attributes/RequirePermissionAttribute.cs`).
- Data migration `SeedInvitationStaffNode` grants it to `Admin`, using the `20261010170000_SeedStatisticsStaffNodes` pattern.
- `Configuration/InvitationSettings.cs` (section `Invitations`): `DefaultExpiryDays` = 7, `MaxExpiryDays` = 30, `SharedDefaultMaxUses` = 5, `SharedMaxUsesCap` = 50, `InvitableGroups` = ["Alpha Tester"], `ResendPerDay` = 3.
- `Configuration/SecuritySettings.cs`: `Registration.Mode` (LinkCode / Invite / Open). It defaults to `LinkCode` when `AllowWebFirst` is false, so nothing changes until the setting is switched.

**Codes:** `Services/Invitations/InvitationCodes.cs`
- personal tokens: 32 bytes, base64url;
- shared codes: `KNK-` + 10 Crockford characters, shown as `KNK-XXXXX-XXXXX`, case-insensitive, `-` ignored;
- `Hash(raw)` = SHA-256 hex of the normalised code.

**`Services/Invitations/InvitationService.cs`** (+ interface; `Repositories/InvitationRepository.cs`)
- **`CreatePersonalAsync(actorId, emails[], expiryDays, groupId?, note?, sendEmail)`**:
  - clamps expiry to 1..Max;
  - an email already used by an account → skipped, with reason `EmailInUse`;
  - a duplicate active invite for the same email → revoke the old one and create a new one;
  - the group must be in `InvitableGroups`, and it passes `PermissionEscalationGuard` for the actor;
  - queues `Invitation` mails (dedupe key `invite:{id}:{sendCount}`, `ExpiresAt` = the invite's expiry);
  - returns the raw links once.
- **`CreateSharedAsync(actorId, label, maxUses, expiryDays, groupId?)`**: label required, `maxUses` clamped to 1..Cap.
- **`ResendAsync`** (personal only, ≤ `ResendPerDay`): rotates the token and restarts the expiry.
- **`RotateAsync`** (shared): a new code, the same counters.
- **`PauseAsync` / `ResumeAsync` / `RevokeAsync`.**
- **`CheckAsync(raw)`** → `{valid, kind, emailHint?, expiresAt}`. Every failure is `InvalidInvite`.
- **`TryTakeUseAsync(invitationId)`**: `ExecuteUpdate … SET UseCount = UseCount + 1 WHERE Id = @id AND UseCount < MaxUses AND RevokedAt IS NULL AND PausedAt IS NULL AND ExpiresAt > @now` → bool.

**Registration** (`Services/AuthService.cs`, `RegisterAsync`; DTO `AuthRegisterRequestDto` gains `inviteToken?`, `inviteCode?`, `claimCode?`)
- **`Mode=Invite` with an invite:** in one transaction:
  1. check the invite;
  2. **personal:** the request's email must equal the invite's (case-insensitive) → `EmailVerifiedAt` = now. **Shared:** validate the typed email;
  3. password policy, duplicate email;
  4. `TryTakeUseAsync` (false → `InvalidInvite`);
  5. create the shell user:
     - `Username = "web-" + 10 random Crockford characters`, `AccountCreatedVia = WebApp`;
     - **no SIGNUP_GRANT** (it is posted at link time in case A, see I2);
     - the Default group, plus the invite's group;
     - `AdmittedAt` = now, `InvitedVia*`;
  6. write a redemption row and an audit entry;
  7. queue the `Welcome` mail;
  8. issue a session.
- `claimCode` is accepted from I2 onwards. In I1 it answers 400 `NotSupportedYet`.
- **`Mode=Invite` with only `linkCode`:** today's flow, but only if the code's account has `AdmittedAt` (grandfathered). Otherwise 403 `InviteRequired`.
- **`Mode=LinkCode`:** today's behaviour, and the invite fields are refused.
- `UserService.CreateAsync` from the plugin (`POST /api/Users`) sets `AdmittedAt` = now while the mode isn't `Invite`, so players who join through the whitelist before the switch are admitted.

**`Controllers/InvitationsController.cs`** (`api/Invitations`)

| Endpoint | Rule |
|---|---|
| `GET` (paged; filter by status and kind) | `knk.admin.invites` |
| `POST personal` | `knk.admin.invites` |
| `POST shared` | `knk.admin.invites` |
| `POST {id}/resend`, `{id}/rotate`, `{id}/pause`, `{id}/resume`, `{id}/revoke` | `knk.admin.invites` |
| `GET {id}/redemptions` (user id, name or email-masked, redeemed at, linked yes/no) | `knk.admin.invites` |
| `POST check` | `[AllowAnonymous]`, `[EnableRateLimiting("auth")]` |

**DTOs, audit, tests**
- **DTOs** `Dtos/InvitationDtos.cs`; `UserDto` and `AuthUserDto` gain `minecraftLinked` and `emailVerified` (from `EmailVerifiedAt`).
- **Audit:** `Enums/AuditAction.cs` gets InvitationCreated = 37, InvitationRevoked = 38, InvitationRedeemed = 39, MinecraftLinked = 40, MinecraftUnlinked = 41, PlayerAdmitted = 42, plus a range comment. Invitation create and revoke target the actor (DESIGN § 6).
- **Tests:**
  - `InvitationServiceTests`: clamps, caps, label required, the group allow-list and escalation guard, duplicate personal invite, resend limit and rotation, pause/revoke, hash-only storage, `CheckAsync` uniformity.
  - Register: personal (email mismatch → 400; verified set), shared, exhausted / expired / paused / revoked, duplicate email, `linkCode` only with and without `AdmittedAt`, `Mode=LinkCode` refuses invites.
  - A MySql integration test: two concurrent redemptions of the last use → exactly one wins.
  - `EndpointAccessRulesTests` allow-list: add `InvitationsController.Check`. Add `ProtectedRoutes` rows.

### 5.2 knk-web-app

**Plumbing**
- `src/utils/enums.ts`: `Controllers.Invitations`.
- `src/apiClients/invitationClient.ts`.
- `src/types/dtos/invitations/InvitationDtos.ts` with `INVITATION_NODES = { manage: 'knk.admin.invites' }`.
- `authClient.register` takes the new fields.

**Pages**
- **`src/pages/auth/InvitePage.tsx`, `/invite/:token`:**
  - reads the token, calls `history.replaceState` to drop it from the URL, then calls `check`;
  - shows "You're invited to the Knights & Kings closed alpha", the email filled in and locked, password plus confirmation with the strength meter, and acceptance of the alpha rules;
  - on success → `/account/link` (I2; until then `/account`).
- **`src/pages/auth/JoinPage.tsx`, `/join?code=`:** the same for shared codes, with a typed email. A shared `InviteSignupForm` component serves both pages.
- **`src/pages/admin/InvitationsPage.tsx`, `/admin/invitations`** (`StaffRoute node=INVITATION_NODES.manage`):
  - tabs: Personal, Shared;
  - a create card for each (bulk email textarea, expiry, group select limited to the API's invitable list, note, Send-email toggle / label, max uses, expiry, group);
  - a result panel with Copy buttons, shown once;
  - the list with status pills and row actions (Resend, Rotate, Pause/Resume, Revoke, with `FeedbackModal` confirms);
  - a redemptions drawer.
  - Patterns: `LocationRetentionPage.tsx` and `RoadProfilesCard.tsx`.
  - Link it from the `UserModerationPage` header and add a nav entry.

**Changed screens**
- `RegisterPage` / `RegisterForm`: map `InviteRequired` to "You need an invitation to create an account" with a link to `/join`.
- `AccountManagementPage`: an "Email verified" badge.
- **Tests:** InvitePage (locked email, token removed from the URL, error states), JoinPage, InvitationsPage (create → copy panel, revoke confirm), the client.

### 5.2a As built (link 3, 2026-10-21)

Built as above, with these differences (flags in the [progress report](../../reports/2026-10-21-invitations-chain.md) "Link 3"):
- `Security:Registration:Mode` is an enum defaulting to `LinkCode` whatever `AllowWebFirst` says; `AllowWebFirst` only
  words the refusal. `Open` is accepted but behaves like `Invite` (web-first sign-up without an invite isn't built) (L3-1).
- Under `Mode=LinkCode` an invite answers 403 `InvitesDisabled`; under `Invite` no invite and no code answers 403
  `InviteRequired`; an invite together with a `linkCode` is 400 `InvalidRequest` (L3-2).
- `POST api/Invitations/check` always answers 200; a personal invite's answer carries the full `email` as well as
  `emailHint`, so `/invite` can show the address locked (L3-3).
- Extra staff route `GET api/Invitations/options` (invitable groups, defaults, caps, the registration mode) (L3-4).
- Two extra `invitations` columns, `ResendWindowStartedAt` and `ResendsInWindow`, count resends in a rolling 24 hours
  (L3-5). Resend restarts the expiry with `DefaultExpiryDays`, and may resend an expired (not used, not revoked) invite (L3-6).
- Pause/resume are for shared codes only, as in DESIGN § 3.4 (409 `WrongKind` for personal invites) (L3-7).
- The Welcome mail greets "there" (the `web-…` name means nothing to the player) and links `/account/link`, which the
  web app redirects to `/account` until KNG-214 builds the page (L3-8).
- The fold (`FoldWebAccountIntoMinecraftAccountAsync`) now carries `EmailVerifiedAt`, `InvitedVia*`, the shell's
  `AdmittedAt` (when the Minecraft account has none) and the invite's group (L1-2 closed).
- The grandfathering backfill admits active, non-deleted accounts only (as planned): a deactivated account that is
  reactivated later needs staff Admit (KNG-214) (L3-9).
- Invite pages add `<meta name="referrer" content="no-referrer">` while open (`useNoReferrer`) (L3-10).

### 5.3 Done
- **Done when:**
  - with `Registration:Mode=Invite` on dev, an admin creates a personal invite (mail in the pickup folder or relay) and a shared code;
  - both sign up;
  - the redemptions show;
  - exhausted, expired and revoked codes are refused.
- Linking is I2.

---

## 6. I2 — Admission gate, claim codes and Minecraft linking (KNG-214)

### 6.1 knk-web-api

**`Services/AdmissionService.cs`: `CheckAsync(uuid, name)`**
- `Registration:Mode != Invite` → admitted. The plugin then keeps today's create-on-join.
- An active user with this `Uuid` and `AdmittedAt` set → admitted. Their `Username` is updated to `name` when it changed, as on join today.
- A deactivated or deleted user → `{admitted: false, reason: "Deactivated"}`, with no code.
- Otherwise → `LinkCodeService.CreateClaimCodeAsync(uuid, name, Admission:ClaimCodeMinutes = 15)` → `{admitted: false, reason: "NotAdmitted", code, expiresAt}`.

**`Controllers/AdmissionController.cs`** (`api/Admission`)
- `GET {uuid}?name=`: `[RequirePluginService]`.
- `POST claim/check {code}` → `{valid, minecraftName}`: `[AllowAnonymous]`, `[EnableRateLimiting("lookup")]`. It counts against the limiter by IP; there is no account yet.

**Linking (L0's `LinkMinecraftAccountAsync`)**
- It takes claim codes (`Purpose=Claim`). The web account must have `AdmittedAt` (invited or grandfathered), otherwise 403 `InviteRequired`.
- **Case A:**
  - set `Uuid = code.MinecraftUuid` and `Username = code.MinecraftName`;
  - post SIGNUP_GRANT (the existing `UserService.CreateAsync` ledger call, extracted into a helper);
  - consume the code;
  - audit `MinecraftLinked`;
  - queue the `MinecraftLinked` mail;
  - enqueue a `PlayerNotification` of new type `AccountLinked` with the masked email.
- **Case B** (a Minecraft account was created before invite mode): the fold from L0.
- Ordinary game → web link codes (`/account link`) keep working for grandfathered Minecraft-only accounts.

**Registration with `claimCode`** (game-first): the I1 transaction plus the case-A link in the same transaction. The response says `{linked: true, minecraftName}`.

**`POST /api/Users` from the plugin in `Mode=Invite`:** a UUID without an admitted account → 403 `NotAdmitted`. This is defense in depth; the plugin no longer calls it for strangers.

**Staff (`UsersController`, `[RequirePermission(ManageUsers)]`)**
- `POST {id}/admit`: sets `AdmittedAt`; audit `PlayerAdmitted`.
- `POST {id}/detach-web-login`: clears `Email`, `PasswordHash`, `EmailVerifiedAt` and `LastPasswordChangeAt`, and revokes the sessions. The Minecraft account and its data stay; the owner can register again with `/account link`. Audit `MinecraftUnlinked`. This is the remedy for a code given away under social engineering (DESIGN § 5.5).

**Notifications:** `PlayerNotificationTypes.AccountLinked` is added on both sides; see the plugin.

**Mail:** `FinishLinking` reminder (optional): a daily sweep in `LinkCodeCleanupService`, or a small sweep service. It finds users with `InvitedViaInvitationId`, `Uuid IS NULL` and `CreatedAt` older than 2 days, and sends one reminder (dedupe key `finish-linking:{userId}`).

**Tests:**
- Admission: each branch, claim code reuse per UUID, TTL.
- Claim link: case A sets the identity, grants SIGNUP_GRANT once and queues the notification and mail; a non-admitted web account is refused; a claim code for a UUID linked in the meantime → case B or a refusal.
- Register with `claimCode`; detach-web-login; plugin create refused in invite mode.
- Access-rule lists: `AdmissionController.CheckClaim` on the anonymous allow-list; plugin and staff routes in `ProtectedRoutes`.

### 6.2 knk-plugin (branch from `claude/mc-26.2-upgrade`)

**Ports and decision logic**
- knk-core:
  - `ports/api/AdmissionApi.java` with `CompletableFuture<AdmissionResult> check(UUID, String)`;
  - `domain/admission/AdmissionResult` (admitted, reason, code, expiresAt);
  - **`admission/AdmissionPolicy.java`**, Bukkit-free:
    - inputs: mode, isOp, API result or failure, and whether `OfflineSecurityStore` holds a fresh identity for the UUID;
    - output: `Allow` or `Deny(messageKey, placeholders)`.
- **Rules:**
  - mode `whitelist` or `open` → allow; vanilla handles the whitelist.
  - mode `invite`:
    - an operator → allow;
    - API admitted → allow;
    - API not admitted with a code → deny `admission.kick`;
    - API says deactivated → deny `admission.deactivated`;
    - API unreachable → allow if the `OfflineSecurityStore` identity is fresh (an account exists, so it was admitted), else deny `admission.unavailable`.
- knk-api-client: `api/impl/AdmissionApiImpl.java` (`GET Admission/{uuid}?name=`) and its DTO, wired into `KnkApiClient`.

**Listener and existing pre-login code**
- **`paper/admission/AdmissionListener.java`:** `@EventHandler(priority = EventPriority.LOWEST)` on `AsyncPlayerPreLoginEvent`, so it runs before `KnkWorldsListener` (LOW), `PlayerListener` (NORMAL) and `HubAdmissionListener` (HIGH).
  - It blocks on the API with a 3 s timeout; the event is async.
  - It applies the policy, and on Deny calls `event.disallow(Result.KICK_WHITELIST, component)`.
  - Register it in `KnKPlugin` next to the hub listener.
- **`listeners/PlayerListener.onValidateLogin`** (l.115): return early when `e.getLoginResult() != ALLOWED`, so no account is created for a denied player.
- `HubAdmissionListener` and `KnkWorldsListener` already run after the gate and need no change. Check that they also skip disallowed logins.

**Config, notifications and tests**
- **`config.yml`:**
  - `admission.mode: whitelist`. This is the default, so deploying the plugin changes nothing until the switch (§ 9).
  - `admission.api-timeout-ms: 3000`.
  - `admission.link-url: ""` (empty → `{web.public-url}/link`).
  - Messages, in the same format as `messages.*`:
    - `admission.kick`, e.g. *"Knights & Kings is invite-only.\nGo to {url} and enter\n{code}\n(valid {minutes} minutes). Never give this code to anyone."*;
    - `admission.unavailable` and `admission.deactivated`.
- **Notifications:** `PlayerNotification.AccountLinked` in knk-core plus a handler in `tasks/PlayerNotificationPoller`. On delivery: *"Your Minecraft account is now linked to the web account {maskedEmail}. Not you? Tell staff right away."*
- **Tests:**
  - `AdmissionPolicyTest`: every branch;
  - `AdmissionListenerTest`: the disallow result and message, the operator bypass, a timeout → the offline path;
  - `PlayerListener` creates nothing when disallowed;
  - the `AccountLinked` handler.
- **Check on Paper 26.3 during the dev test** (DESIGN § 5.2):
  - `AsyncPlayerPreLoginEvent` fires after Mojang authentication and before the whitelist check;
  - a multi-line component disconnect message shows as written.

  If Paper has moved the authoritative check to `PlayerConnectionValidateLoginEvent`, gate there instead. The policy stays the same.

### 6.3 knk-web-app

**`src/pages/auth/LinkPage.tsx`, `/link`** (works logged out):
1. Enter the claim code → `claim/check` → "Minecraft account **Steve** verified".
2. Then:
   - logged in and unlinked → link now;
   - logged out → "Log in" (returns here with the code kept in `sessionStorage` for its 15 min) or "Create an account with an invitation" (an invite code field, or "use the link in your invitation mail"), which goes to `/join` with the claim code carried along.
3. Without an invite: "The alpha is invite-only".

**Other pages**
- **`src/pages/account/AccountLinkPage.tsx`, `/account/link`** (`ProtectedRoute`): onboarding steps (join `play.knightsandkings.net` with Java 26.3; the code on the disconnect screen; enter it here); a code input that accepts both claim codes and `/account link` codes; success → `/account`, handling a new token in case B.
- **Unlinked banner:** in the layout, for logged-in users with `minecraftLinked=false`: "Link your Minecraft account to play →".
- **`AccountManagementPage`:** replace the old link section with a pointer to `/account/link`.
- **`PlayerProfilePage`** (admin): "Admit" and "Detach web login" buttons (`knk.admin.user.manage`) with confirms.
- **`LandingPage`:** `JOIN_STEPS` → "Get an invitation → Create your account → Join the server → Enter the code".
- **Tests:** the LinkPage flows (logged in/out, invalid code, kept code), the AccountLinkPage token switch, the banner.

### 6.4 Done
On dev, with `Registration:Mode=Invite` and `admission.mode: invite`:
- **Web-first:** invite → account → join → disconnect with a code → link → rejoin → first-join welcome and kits once.
- **Game-first:** join → code → `/link` → invite → account → rejoin.
- **Grandfathered player:** joins normally.
- **Operator:** bypasses.
- **API stopped:** a known player gets in; a stranger gets "unavailable".
- **Staff "Detach web login":** works.

---

## 7. A1 — Cloudflare Access sync and the sign-up bypass (KNG-216)

**First, verify (record the results in DESIGN § 5.8):**
- whether an Access policy can include a Zero Trust email list on the free plan, and the selector's name in the API;
- otherwise use an Access group: `GET`/`PUT accounts/{account}/access/groups/{group}`;
- the token permissions needed;
- the list's entry limit.

### 7.1 knk-web-api

**Settings and client**
- `Configuration/CloudflareAccessSettings.cs` (section `CloudflareAccess`): `SyncEnabled` (false), `AccountId`, `ListId` or `GroupId`, `ApiToken` (secret, env only), `ProxyUrl`, `ReconcileMinutes` = 5, `InlineAddTimeoutSeconds` = 5.
- Named `HttpClient` `"cloudflare"`:
  - `BaseAddress https://api.cloudflare.com/client/v4/`, a bearer token;
  - `HttpClientHandler { Proxy = new WebProxy(ProxyUrl), UseProxy = true }` when `ProxyUrl` is set;
  - a 10 s timeout.
- `Services/CloudflareAccess/ICloudflareAccessList.cs`: `GetEmailsAsync`, `AddAsync(emails)`, `RemoveAsync(emails)`. One implementation for the verified mechanism: `ZeroTrustEmailList` (`gateway/lists/{id}/items` + `PATCH append/remove`) or `AccessGroupEmailList` (read-modify-`PUT`, serialised).

**Sync service**
- `Services/CloudflareAccess/CloudflareAccessSyncService : BackgroundService`: every `ReconcileMinutes`, plus a wake-up `Channel` signalled by registration, invite create/revoke, email change, deactivation and merge.
- **Desired set:**
  - lower-cased emails of personal invites that are not revoked, not exhausted and `ExpiresAt > now`;
  - plus active, non-deleted users with an `Email` and (`AdmittedAt` or `InvitedViaInvitationId`).
- **Diff** against the API-owned list; add what's missing, remove what's extra. Removal only happens in that list.
- **Status** is kept in a singleton (`LastSuccessAt`, `LastError`, `PendingAdds`, `PendingRemoves`).
- **Inline add:** `AuthService` calls `TryAddNowAsync(email, timeout)` after the registration commits, swallowing any failure (the reconcile catches it).
- **Endpoint:** `GET api/Invitations/access-sync` → status (`knk.admin.invites`).
- **Tests:** a fake `HttpMessageHandler` for both implementations; the desired-set query; diffing never touches entries outside the owned list (group mode: only the owned include rule); inline add with a timeout; disabled → no calls.

### 7.2 knk-web-app
- `InvitationsPage`: a status line "Access sync: last OK 12:04 · 0 pending", red with the last error.
- `InviteSignupForm` done step: "Next, Cloudflare emails you a one-time PIN to open the site. Use the same address." Show it only when the API's `/api/Auth/register` response carries `accessGate: true`, which the API sets when `SyncEnabled`.

### 7.3 NAS and Cloudflare (with the developer)

**Forward proxy:** a `cfproxy` container (tinyproxy, pinned tag), networks `backend` and `mail-egress`. Config:
- `Allow <backend subnet>`, `ConnectPort 443`;
- `FilterDefaultDeny Yes`, filter `^api\.cloudflare\.com$`.

API env: `CloudflareAccess__ProxyUrl=http://cfproxy:8888`.

**Cloudflare dashboard**
1. Create the Zero Trust email list (or Access group) **"knk-api-testers"**.
2. Edit the policy *Allow testers*: include that list. Keep the existing hand-made emails as a separate include, for staff.
3. Set the session duration to 30 days.
4. Create the API token: Account → the Zero Trust/Access edit permission found in step "verify", for this account only. Put it in `/etc/knk/api.env` as `CloudflareAccess__ApiToken`.
5. Create the **bypass application** on the same hostname for the paths:
   - `/invite/*`, `/join*`, `/link*`;
   - `/static/*`, `/favicon.ico`, `/manifest.json`, `/logo*.png`;
   - `/api/Invitations/check`, `/api/Admission/claim/check`, `/api/Auth/register`;

   with one *Bypass — Everyone* policy.
6. Check from a private window: `/invite/x` loads without Access, `/account` shows the Access login, and `/api/Users/1` gets the Access login.

### 7.4 Done
With sync enabled on the alpha:
- a new personal invite's email appears in the list within seconds;
- a revoke removes it;
- a shared-code sign-up is added during registration;
- deactivating an account removes it;
- staff entries are untouched;
- the status line is green.

---

## 8. I3 — Rollout (KNG-218)

**Preconditions:** E0 live, E1 merged, KNG-182 merged into plugin `main` and plugin `main` merged into this branch, and I1/I2/A1 green on dev.

**knk-web-api**
- Data migration `SeedAlphaTesterGroup`: a group `Alpha Tester` (low Weight, parent `Default`, no extra nodes unless the developer adds some).
- `Invitations:InvitableGroups` defaults to it.

**Smoke test:** `docs/guides/invitations-smoke-test.md` in the style of the other smoke guides. It covers:
- every "Done when" of E1, I1, I2 and A1;
- these extra checks:
  - a guess flood on `/api/Invitations/check` → 429;
  - claim code guesses → per-account block;
  - a mail-bomb attempt (5 resends) → resend limit and Suppressed;
  - a revoked invite clicked from the mail → generic error;
  - an expired claim code → "join again for a new code";
  - an operator joining during an API outage;
  - the kill switches.

**Switch-over on the alpha (runbook order: back up → migrator → API → web → plugin)**
1. Deploy everything with `Registration:Mode=LinkCode`, `admission.mode: whitelist` and `CloudflareAccess:SyncEnabled=false`. Nothing changes; the migration has admitted everyone.
2. Enable the sync and check that the list fills with the current testers. Create the bypass application.
3. `Registration:Mode=Invite`; the developer creates a test invite and runs the web-first flow with a second Minecraft account.
4. `admission.mode: invite` (`/knk reload` or a restart), then `white-list=false` in `server.properties`.
5. Run the smoke-test sections marked "alpha".

**Kill switches:**
- `admission.mode: whitelist` plus `white-list=true`;
- `Registration:Mode=LinkCode`;
- `CloudflareAccess:SyncEnabled=false`;
- delete the bypass application.

**Docs** (living documents updated in place; dated reports untouched):
- [alpha-go-live](../../guides/alpha-go-live.md):
  - § 4 env: Registration mode, Invitations, CloudflareAccess, Email;
  - § 5 (whitelist → admission mode);
  - § 7 Cloudflare (list, bypass app, session, token);
  - § 9 checklist F (invite flow);
  - § 10: the tester invite template is now the system mail; keep a short text for shared codes;
  - § 12.
- [closed-alpha runbook](../../guides/closed-alpha-deployment-runbook.md) and [production-installation](../../guides/production-installation.md): the same keys, the relay and proxy containers.
- `docs/guides/users/PLAYER_GUIDE_ACCOUNT_MANAGEMENT.md`: rewrite "Getting an account" (invitation, account, join, code); keep `/account link` for existing players.
- A new living architecture doc, `docs/architecture/account-identity-and-admission.md`. It covers the identity anchor, the code kinds and purposes, admission, the linking cases, the Access sync and the mail flow, and links to DESIGN.
- [FEATURE_REGISTER](../../FEATURE_REGISTER.md) "Accounts" row, CHANGELOG entry at merge, specs README, this plan's status, tracker row → Recently completed.

**Done when:** the alpha runs invite-only with the whitelist off, the smoke test has passed, and KNG-205 and its children are closed.

---

## 9. Merge and deploy order

1. **E0:** the API fix goes to `master` (small change, its own commit/PR), then the NAS change.
2. **E1:** merge the standing branch into `master` / `main` after its smoke steps. Merge `master` / `main` back into the branch and continue there.
3. **L0, I1, I2, A1** merge **together** (one PR per repo) after the dev run of the I3 smoke test. Shipping I1 without I2 creates web accounts that can't join without a typed name on the whitelist.
4. **knk-plugin:** after KNG-182 has merged into `main` and `main` has been merged into this branch. Deploying the plugin with `admission.mode: whitelist` is behaviour-neutral, so it can go out with the next plugin release before the switch.
5. Then the I3 switch-over.

## 10. Open items to verify while implementing (not decisions)

- Cloudflare: email-list selector or Access group; token permission names; list size limit (§ 7).
- Paper 26.3: pre-login event order and the disconnect message rendering (§ 6.2).
- `boky/postfix` env names at the pinned tag (§ 2).
- MailKit version and TLS mode against the relay (§ 3).
