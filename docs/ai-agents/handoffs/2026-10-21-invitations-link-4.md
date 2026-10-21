# Invitations chain — link 4: I2 server side — admission, claim codes, claim linking (KNG-214, API + web app)

**Written:** 2026-10-21 by link 3 (KNG-212), after it finished.
**Charter:** [INVITATIONS_CHAIN.md](INVITATIONS_CHAIN.md). Read it first; it overrides this file.
**Plan:** [IMPLEMENTATION_PLAN.md](../../specs/invitations/IMPLEMENTATION_PLAN.md) § 6.1 and § 6.3 (and § 5.2a, link 3's as-built note);
[DESIGN.md](../../specs/invitations/DESIGN.md) § 5 (5.2–5.5), § 6.
**Previous link's report block:** [2026-10-21-invitations-chain.md](../../reports/2026-10-21-invitations-chain.md) "Link 3".

## State at hand-over

| Repo | Branch `claude/player-signup-invitation-flow-f4v7ul` | Base | Tests at hand-over |
|---|---|---|---|
| knk-workspace | link 3 docs commit(s) on top of the merge of `main` | `main` | — |
| knk-web-api | `8ca8507` (`77042fd` model + migrations, `8ca8507` service/controller/registration) on link 2's `a8b42ca` | `master` `2d71155` (merged, unchanged) | **2864 passed, 4 failed, 80 skipped (2948)** (the 4 known-red: `PathResolutionServiceTests` ×2, `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_ValidatesRequired`, `ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`; red on `master` too) |
| knk-web-app | `18f3c9f` (`dfa5cdd` pages, `18f3c9f` audit labels) | `main` `e30c815` | **160 suites / 970 tests**; `npm run build` compiles with `main`'s pre-existing warnings |
| knk-plugin | `30b10e6e` (unchanged since link 1) | `claude/mc-26.2-upgrade` `88497649` (KNG-182, unmerged) | core 2168 / api-client 264 / paper 1870, 0 failures |

- **Link 3's exit criteria are met**: § 5 built and pushed in api and web-app, builds green, counts above the baseline,
  the 4 known-red unchanged, the existing auth suites unchanged under `Mode=LinkCode`, migration `AddInvitations` with
  the grandfathering backfill, 3 `[MySqlFact]`s written and skipped (no MySQL in the container).
- **Tracker:** the chain's row is on workspace `main`. Update it there (charter § 1.2).
- **Toolchains on a fresh container:** .NET 8 and Node 22 are present. Build `dotnet build knkwebapi_v2.csproj` (the
  `.sln` fails on Linux); web app `npx npm@11 ci`. Link 4 doesn't change the plugin (link 5 does), so no JDK 25.
- **EF tooling:** `ASPNETCORE_ENVIRONMENT=Development Database__MySqlServerVersion=8.0.36 ConnectionStrings__MySqlDbConnection="Server=localhost;Database=x;User=x;Password=x" ~/.dotnet/tools/dotnet-ef migrations add <Name> --project knkwebapi_v2.csproj`.
  Check that the snapshot diff only adds what you meant.

## Your work (plan § 6.1, § 6.3), in this order

1. **Claim** (charter § 5.1): tracker row on `main`; KNG-214 → *In Progress* (it stays *In Progress* after link 4:
   link 5 finishes it).
2. **Setup** (charter § 1): fetch, merge `origin/master` / `origin/main`, dry-run pushes in api, web-app and workspace,
   baselines (expect the numbers above).
3. **knk-web-api** (§ 6.1): `AdmissionService`; claim codes (`LinkCodeService.CreateClaimCodeAsync` exists since
   link 1); `api/Admission` (`claim/check` anonymous on the `lookup` limit → allow-list; `GET {uuid}?name=`
   `RequirePluginService` → `ProtectedRoutes`); claim linking (case A) in `UserService.LinkMinecraftAccountAsync`;
   register with `claimCode`; staff `POST api/Users/{id}/admit` and `/{id}/detach-web-login` (`ManageUsers`);
   `PlayerNotificationTypes.AccountLinked`; audit 40–42.
4. **knk-web-app** (§ 6.3): `/link`, `/account/link` (replace the redirect), the unlinked banner, staff Admit / Detach.
5. **Docs, report block "Link 4", plan status, CHANGELOG, Linear** (KNG-214 stays *In Progress*), **handoff for link 5**
   (`2026-10-21-invitations-link-5.md`, I2 plugin). **Record the exact `AccountLinked` type string and payload** in that
   handoff (charter "Link 4" specifics).

## What link 3 leaves you

- **Admission flag:** `User.AdmittedAt` (nullable). Set by: the `AddInvitations` backfill (active, non-deleted accounts
  as of `CreatedAt`), invite redemption, and `UserService.CreateAsync` while `Security:Registration:Mode` isn't
  `Invite`. Under `Mode=Invite` a plugin-created account has `AdmittedAt = NULL`: that is who the gate stops. Staff Admit
  and claim linking set it. Deactivated accounts were **not** admitted by the backfill (L3-9).
- **Registration:** `AuthService.RegisterAsync` refuses `claimCode` first, in every mode (`NotSupportedYet`, 400). Replace
  that branch. The invite path is `RegisterWithInviteAsync`: `IInvitationService.FindUsableAsync(token, code)` →
  checks → `RedeemAsync(new InviteSignup(invitation, email, passwordHash, emailVerified))`, which creates the admitted
  `web-…` shell in one transaction (Default + the invite's group, redemption, audit `InvitationRedeemed`, Welcome mail)
  and returns the `User`. **No SIGNUP_GRANT** is posted for shells: post it when the claim links (case A; DESIGN § 5.3).
  For "register with invite + claimCode" (game-first, DESIGN § 5.3) the claim must be validated before the use is
  taken, and the link applied in the same transaction, or a failed claim leaves a shell without Minecraft.
- **Fold (case B):** `FoldWebAccountIntoMinecraftAccountAsync` now also carries `EmailVerifiedAt`, `InvitedVia*`,
  `AdmittedAt` (when the Minecraft account has none) and the invite's group (L1-2 closed). Case A still goes through
  `ReleaseUsernameFromWebOnlyAccountAsync` (L1-5); a `web-…` shell's `Username` is replaced by the Mojang name there.
- **`UserDto.minecraftLinked`** (Uuid set) exists for the banner; `emailVerified` reads `EmailVerifiedAt` too.
- **Mail kinds for you:** `MinecraftLinked` {`username`, `minecraftName`}, `FinishLinking` {`username`, `linkUrl`};
  every placeholder must be in the model (strict rendering in tests). The Welcome mail links `{base}/account/link`.
- **Web app:** `/account/link` is `<Navigate to="/account" replace />` in `src/App.tsx`, and `InvitePage`/`JoinPage`
  navigate there after sign-up (`AFTER_SIGNUP_PATH`). `src/hooks/useNoReferrer.ts` is ready for `/link`. Audit labels
  (`src/utils/auditDetails.ts` + the `AuditAction` union in `UserProfileSummaryDtos.ts`) know 37–39; add 40–42.
- **Tests:** `Tests/…/Services/Invitations/InvitationTestDb` (InMemory, real repositories, real composer + throttle,
  `ManualClock`, an Admin user and the Default / Alpha Tester / Moderator groups); pass `AuthTestHarness.Db` to share
  the context (see `Security/InviteRegistrationTests`). `AuthTestHarness.CreateAuthService(invitations)`.
- **Access-rule tests:** `ProtectedRoutes` and the anonymous allow-list now include `InvitationsController`.

## Open flags (for context; none block you)

Link 1: L1-1…L1-7 (L1-2 closed by link 3). Link 2: L2-1…L2-12. Link 3: L3-1 `Mode` default and `Open` = `Invite`;
L3-2 refusal codes; L3-3 check returns the personal address; L3-4 `GET options`; L3-5 resend window columns; L3-6
resend restarts with the default expiry; L3-7 pause for shared only; L3-8 Welcome mail wording and `/account/link`
redirect; L3-9 backfill skips inactive accounts; L3-10 no-referrer meta; L3-11 one transaction per address; L3-12
direct membership insert for shells. Details in the report.

## Risks to keep in mind

- Do not let anyone switch `Mode=Invite` on the alpha before link 4 **and** link 5 are deployed: invited shells can't
  link Minecraft until then, and plugin-created accounts stop being admitted.
- Case A at sign-up touches the most rows of the chain (shell creation + claim + username release + SIGNUP_GRANT):
  keep it in one transaction and test the rollback (MySQL test).
- The backfill's MySQL test hasn't run anywhere yet; it is in the live checklist of link 3 and should be run before
  the switch-over.

## Exit criteria

- § 6.1 and § 6.3 built and pushed; builds green; counts ≥ the numbers above; the 4 known-red unchanged; existing
  auth tests unchanged with `Mode=LinkCode`.
- The `AccountLinked` notification type and payload recorded for link 5.
- The handoff file for link 5 (`2026-10-21-invitations-link-5.md`, I2 plugin / KNG-214) written and pushed.
