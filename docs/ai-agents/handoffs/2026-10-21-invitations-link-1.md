# Invitations chain — link 1: E0 API half (KNG-211) + L0 link hygiene and linking rules (KNG-207, KNG-208)

**Written:** 2026-10-21 by the planning session (KNG-205), before any link ran.
**Charter:** [INVITATIONS_CHAIN.md](INVITATIONS_CHAIN.md). Read it first; it overrides this file.
**Plan:** [IMPLEMENTATION_PLAN.md](../../specs/invitations/IMPLEMENTATION_PLAN.md) § 2 (API part only) and § 4.

## State at hand-over

| Repo | Branch `claude/player-signup-invitation-flow-f4v7ul` | Base |
|---|---|---|
| knk-workspace | `1c49082` + this handoff commit (design, plan, charter, report) | `main` `f3d1307` |
| knk-web-api | no commits yet (= `master` `2d71155`) | `master` |
| knk-web-app | no commits yet (= `main` `e30c815`) | `main` |
| knk-plugin | no commits yet (= `claude/mc-26.2-upgrade` `88497649`, Paper 26.3 / Java 25) | `claude/mc-26.2-upgrade` (KNG-182, unmerged) |

- **Baselines:** none recorded yet. Record them first (charter § 1.5).
- **Tracker:** the feature's row is only on the workspace feature branch so far: the planning session's rules let it
  push only that branch. Publish or update it on `main` as the charter says.

## Your work, in this order

1. **E0 API half (KNG-211), one self-contained commit** in knk-web-api:
   - `Services/SmtpPasswordResetDeliveryService.cs` (credential check at l.49) and `Services/Privacy/PrivacyEmailService.cs`
     (~l.89): with `Email:SmtpUsername` empty, send without `Credentials`; with a username set, keep requiring the
     password.
   - Add a test for each.
   - Touch nothing else in that commit, so the developer can cherry-pick it to `master`.
   - Put the hash in a KNG-211 comment ("API half ready to cherry-pick; NAS relay steps in plan § 2").
2. **L0 in knk-web-api** (plan § 4.1):
   - **Migration `LinkCodePurpose`:** `Purpose`, backfilled to `1` for 64-character codes; `MinecraftUuid` and
     `MinecraftName`; index `(Purpose, Status, ExpiresAt)`.
   - Model enum, and the repository switched from `Code.Length == 64` to `Purpose`. The reset-token paths in
     `AuthService` set `Purpose=PasswordReset`.
   - `LinkCodeService`:
     - `RandomNumberGenerator.GetInt32`;
     - fix the 52^8 comment;
     - `CreateClaimCodeAsync(uuid, name, ttl)`: Crockford alphabet, reuses the UUID's active claim code, input
       normalisation O→0 and I/L→1. It's used from link 4; test it now.
   - `LinkCodeCleanupService` (hourly; deletes codes used or expired more than 7 days ago). Register it in
     `DependencyInjection/ServiceCollectionExtensions.cs` next to the other hosted services.
   - `ILinkAttemptLimiter`, modelled on `Services/LoginAttemptLimiter.cs`: 5 failures per account in 15 min, a 15 min
     block, answered with 429 `TooManyAttempts`. Use it in `link-minecraft-account`.
   - **`UserService.LinkMinecraftAccountAsync` rewrite** (DESIGN § 5.4, decision I7):
     - case A sets `Uuid`/`Username` (only claim codes reach it; claim codes come in link 4);
     - case B folds the web account into the Minecraft account in the order the plan gives (email cleared on the shell
       before it is set on the Minecraft account);
     - refusals: `AlreadyRegistered` and `AlreadyLinked`;
     - it returns the surviving id.
   - `UsersController.LinkMinecraftAccount`: when the survivor isn't the caller, issue a session (the same helper
     `AuthController.Register` uses) and return `{user, accessToken}`.
   - **Tests:**
     - case B keeps the Minecraft account's id, groups and balances per the merge rules, moves the credentials, and
       revokes the shell's sessions;
     - each refusal;
     - the limiter;
     - the `Purpose` backfill and repository;
     - the generator's distribution;
     - the cleanup service;
     - a `[MySqlFact]` test for the unique-index order in case B.
3. **knk-web-app:** `authClient.linkMinecraftAccount` and its caller in `AccountManagementPage.tsx`. When the response
   carries `accessToken`, store it through `tokenService` and refresh `AuthContext`. Add a test.
4. **knk-plugin** (plan § 4.2): drop `create` from the usage strings (`AccountCommandRegistry` l.78, `plugin.yml`,
   `UserCommand` l.216); delete `AccountLinkCommand.startMergeFlow` and `mergeAccounts`; add the "never give this code
   to anyone" line to `LinkCodeMessage.DEFAULT_TEMPLATE` and update `LinkCodeMessageTest`. Build on JDK 25.
5. **Docs** (knk-workspace feature branch):
   - `docs/guides/users/PLAYER_GUIDE_ACCOUNT_MANAGEMENT.md`: remove `/account create` and the web → game text;
   - `docs/specs/users/SPEC_USER_ACCOUNT_MANAGEMENT.md` Part F: password reset is built (KNG-64);
   - the plan's status line;
   - a CHANGELOG entry;
   - the report's Link 1 block.
6. **Linear:**
   - KNG-207 and KNG-208 → *In Review*, with a comment.
   - KNG-211 stays open (its NAS half is the developer's), with a comment.

## Watch out for

- **Behaviour-neutral:** nothing here may change today's `/account link` → register flow or reset mails. Run the
  existing `AuthService`/`UsersController` tests unchanged.
- **Reset tokens live in `linkcodes`.** Make sure the backfill and the new `Purpose` filter keep a pending reset token
  valid across the migration.
- **`MergeWithForfeitAsync` posts ledger entries and runs title progression.** Call it, don't copy it.
- **Plugin:** `KnKPlugin.java` is claimed by the KNG-182 row. This link doesn't need to touch it.

## Exit criteria

- All five steps pushed; builds green; test counts ≥ baseline, apart from new tests.
- The E0 commit hash recorded.
- The handoff file for link 2 (`2026-10-21-invitations-link-2.md`, E1 / KNG-206) written and pushed.
