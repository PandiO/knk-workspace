# Invitations chain — link 6: A1 — Cloudflare Access sync and the sign-up bypass (KNG-216)

**Written:** 2026-10-21 by link 5 (KNG-214 plugin), after it finished.
**Charter:** [INVITATIONS_CHAIN.md](INVITATIONS_CHAIN.md). Read it first; it overrides this file.
**Plan:** [IMPLEMENTATION_PLAN.md](../../specs/invitations/IMPLEMENTATION_PLAN.md) § 7;
[DESIGN.md](../../specs/invitations/DESIGN.md) § 5.8 (decision I8 in § 8).
**Previous link's report block:** [2026-10-21-invitations-chain.md](../../reports/2026-10-21-invitations-chain.md) "Link 5".

## State at hand-over

| Repo | Branch `claude/player-signup-invitation-flow-f4v7ul` | Base | Tests at hand-over |
|---|---|---|---|
| knk-workspace | link 5 docs commit on top of link 4's | `main` | — |
| knk-web-api | `44c5f63` (unchanged since link 4) | `master` `2d71155` (merged, unchanged on 2026-10-21) | **2904 passed, 4 failed, 81 skipped** (link 4's numbers; the 4 known-red: `PathResolutionServiceTests` ×2, `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_ValidatesRequired`, `ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`; red on `master` too). Re-take the baseline. |
| knk-web-app | `60ec323` (unchanged since link 4) | `main` `e30c815` (unchanged) | **165 suites / 997 tests** (link 4's numbers); build compiles with `main`'s pre-existing warnings |
| knk-plugin | `90b01850` (link 5: admission gate, `AccountLinked` notice) | `claude/mc-26.2-upgrade` `88497649` (KNG-182, unmerged) | core 2178 / api-client 271 / paper 1889, 0 failures. **Link 6 doesn't change the plugin.** |

- **Link 5's exit criteria are met**: § 6.2 built and pushed on JDK 25, plugin build green, counts above the baseline,
  `admission.mode` defaults to `whitelist`; the Paper 26.3 finding is recorded (report "Link 5", DESIGN § 5.2,
  plan § 6.2a) and the live checks are in the report's checklist. KNG-214 is complete (links 4 + 5) and *In Review*.
- **Tracker:** the chain's row is on workspace `main`. Update it there (charter § 1.2).
- **Repos you change:** knk-web-api, knk-web-app and knk-workspace. Dry-run pushes in those three. No JDK needed.
- **Toolchains:** .NET 8 (`sudo apt-get install -y dotnet-sdk-8.0` if missing), Node 22 with `npx npm@11 ci` (the
  bundled npm 10 rejects the lock file; report follow-ups).

## Your work (plan § 7), in this order

1. **Claim** (charter § 5.1): tracker row on `main`; KNG-216 to *In Progress*.
2. **Setup** (charter § 1): fetch, merge `origin/master` / `origin/main`, dry-run pushes, baselines.
3. **Verify Cloudflare first** (charter "Link 6" specifics; plan § 7 "First, verify"): from Cloudflare's current API
   docs, whether an Access policy can include a Zero Trust email list (free plan; the selector's name in the API),
   otherwise an Access group (`GET`/`PUT accounts/{account}/access/groups/{group}`); the token permission names; the
   list's entry limit. **Write the result into DESIGN § 5.8** before coding, and implement only the verified mechanism
   behind `ICloudflareAccessList`.
4. **knk-web-api** (§ 7.1): `Configuration/CloudflareAccessSettings.cs` (`SyncEnabled` **false** by default — charter
   § 3), named `HttpClient "cloudflare"` with the optional proxy, `Services/CloudflareAccess/` (list implementation,
   `CloudflareAccessSyncService` with the wake-up channel, status singleton, `TryAddNowAsync` after registration),
   `GET api/Invitations/access-sync` (`knk.admin.invites`, on the `ProtectedRoutes` list), tests with a fake
   `HttpMessageHandler`. `ApiToken` is a secret: env only, never in `appsettings*.json`, logs or fixtures.
5. **knk-web-app** (§ 7.2): the status line on `InvitationsPage`; the PIN step on `InviteSignupForm` only when the
   register response carries `accessGate: true`.
6. **Ops steps for the developer** (§ 7.3): the `cfproxy` container and the dashboard steps as a section of the
   alpha-go-live guide on the feature branch (charter "Link 6"). Never a blocker: write them, don't do them.
7. **Docs, report block "Link 6", plan status, CHANGELOG, Linear, handoff for link 7**
   (`2026-10-21-invitations-link-7.md`, KNG-218 prep + the final write-up).

## Things from link 5 that matter for you

- The bypass path list in DESIGN § 5.8 / plan § 7.3 step 5 includes `/link*` and `/api/Admission/claim/check`: both
  exist (link 4) and the plugin's disconnect screen points players to `{web.public-url}/link` (or
  `admission.link-url`). Keep them in the bypass.
- The game server's gate (`admission.mode`) is independent of Access. Access only fronts the web app; the plugin talks
  to the API on the internal network.
- Switch-over order the final link must write (report "Link 5" deploy notes): API `Mode=Invite`, plugin
  `admission.mode: invite` (restart), vanilla whitelist off, `web.public-url` set — together, after both deploys.

## Open flags (for context; none block you)

Link 1: L1-1…L1-7. Link 2: L2-1…L2-12. Link 3: L3-1…L3-12. Link 4: L4-1…L4-16. Link 5: L5-1 `admission.*` message keys
incl. `account-linked`; L5-2 unknown mode → whitelist; L5-3 no-code answer → unavailable; L5-4 gate before bans; L5-5
offline fallback = offline-store identity; L5-6 no KNG-171 shortcut; L5-7 operator create refusal logged, join goes on;
L5-8 `{url}` fallback; L5-9 notice acknowledged once shown. Details in the report.

## Risks to keep in mind

- **`CloudflareAccess:SyncEnabled` must default to false** (behaviour-neutral, charter § 3).
- The sync must never remove entries outside the API-owned list (staff emails stay as a separate include).
- Group mode is read-modify-`PUT`: serialise it, and touch only the owned include rule.
- The inline add must not fail or slow a registration beyond its timeout.

## Exit criteria

- The Cloudflare mechanism verified and written into DESIGN § 5.8; only that mechanism implemented.
- § 7.1 and § 7.2 built and pushed; API and web-app builds green; counts ≥ the baseline; the 4 known-red unchanged;
  `SyncEnabled` defaults to false.
- The NAS proxy and dashboard steps written in the alpha-go-live guide on the feature branch.
- The handoff file for link 7 (`2026-10-21-invitations-link-7.md`, KNG-218 + final write-up) written and pushed.
