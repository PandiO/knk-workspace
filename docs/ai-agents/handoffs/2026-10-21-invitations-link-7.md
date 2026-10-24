# Invitations chain — link 7: I3 prep (KNG-218 code + docs) and the final write-up

**Written:** 2026-10-21 by link 6 (KNG-216), after it finished.
**Charter:** [INVITATIONS_CHAIN.md](INVITATIONS_CHAIN.md). Read it first; it overrides this file. **This is the last
link** (charter § 0: ≤ 7 links). Anything left over becomes a written follow-up list plus Linear comments.
**Plan:** [IMPLEMENTATION_PLAN.md](../../specs/invitations/IMPLEMENTATION_PLAN.md) § 8 and § 9;
[DESIGN.md](../../specs/invitations/DESIGN.md) (decisions § 8).
**Previous link's report block:** [2026-10-21-invitations-chain.md](../../reports/2026-10-21-invitations-chain.md) "Link 6".

## State at hand-over

| Repo | Branch `claude/player-signup-invitation-flow-f4v7ul` | Base | Tests at hand-over |
|---|---|---|---|
| knk-workspace | link 6 docs commit on top of `main` (merged 2026-10-21) | `main` | — |
| knk-web-api | `641f9c1` (link 6: Cloudflare Access sync) | `master` `2d71155` (merged, unchanged on 2026-10-21) | **2925 passed, 4 failed, 81 skipped**; the 4 known-red (`PathResolutionServiceTests` ×2, `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_ValidatesRequired`, `ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`) are red on `master` too. Re-take the baseline. |
| knk-web-app | `eeea86f` (link 6: access-sync line, PIN step) | `main` `e30c815` (unchanged) | **165 suites / 1003 tests**; build compiles with `main`'s pre-existing warnings |
| knk-plugin | `90b01850` (link 5) | `claude/mc-26.2-upgrade` `88497649` (KNG-182, unmerged) | core 2178 / api-client 271 / paper 1889, 0 failures. Link 7 doesn't change the plugin. |

- **Link 6's exit criteria are met:** the Cloudflare mechanism was verified first and written into DESIGN § 5.8 (a Zero
  Trust email list; no Access-group code); § 7.1 and § 7.2 built and pushed; API and web-app builds green; counts above
  the baseline; the 4 known-red unchanged; `CloudflareAccess:SyncEnabled` defaults to false; the NAS proxy and
  dashboard steps are in [alpha go-live § 6.1](../../guides/alpha-go-live.md). KNG-216 is *In Review*.
- **Tracker:** the chain's row is on workspace `main`. Update it there (charter § 1.2), then move it to "Recently
  completed" at the end (nothing merged).
- **Repos you change:** knk-web-api (the migration) and knk-workspace. Dry-run pushes in those two. No JDK needed.
- **Toolchains:** .NET 8 (`sudo apt-get install -y dotnet-sdk-8.0` if missing); `dotnet build knkwebapi_v2.csproj`
  (the `.sln` path casing fails on Linux; report follow-ups). `dotnet ef` for the migration
  (`dotnet tool install --global dotnet-ef --version 8.*` if missing). Node only if you touch the web app (you shouldn't).

## Your work (plan § 8 + the final write-up), in this order

1. **Claim** (charter § 5.1): tracker row on `main`; KNG-218 to *In Progress*.
2. **Setup** (charter § 1): fetch, merge `origin/master` / `origin/main`, dry-run pushes, API baseline.
3. **knk-web-api:** data migration **`SeedAlphaTesterGroup`** (`dotnet ef migrations add`): a permission group `Alpha
   Tester` (low `Weight`, parent `Default`, no extra nodes), idempotent (skip when the name exists — link 3's tests and
   dev databases may already have it). `Invitations:InvitableGroups` already defaults to `["Alpha Tester"]`. Check how
   link 3's `SeedInvitationStaffNode` and the older `SeedDefaultPermissionGroup` migrations are written and follow them;
   add a test in the style of the other seed tests.
4. **`docs/guides/invitations-smoke-test.md`** (style of the other `*-smoke-test.md`): every "Done when" of E1, I1, I2,
   A1, plus plan § 8's extra checks, the switch-over steps 1–5 and the kill switches. Pull the live checklists from the
   report's link 1–6 blocks; A1's are in "Link 6" and alpha go-live § 6.1.
5. **`docs/architecture/account-identity-and-admission.md`** (new living doc): identity anchor (the Minecraft UUID; web
   shells), code kinds and `LinkCodePurpose`, admission (`AdmissionService`, plugin `admission.mode`), the linking cases
   (A, B fold), the Cloudflare Access sync (desired set, reconcile, inline add, bypass), the mail flow (outbox,
   dispatcher), with links to DESIGN.
6. **Living docs written for the state after the switch-over** (plan § 8 "Docs"): alpha-go-live § 4 (env:
   `Security__Registration__Mode`, `Invitations__*`, `CloudflareAccess__*`, `Email__*`), § 5 (whitelist → admission
   mode), § 6/§ 6.1 (Access after the switch: API-owned list + staff include, 30-day session), § 9 checklist, § 10
   (the invite is now the system mail; keep a short text for shared codes), § 12; the closed-alpha runbook and
   production-installation (same keys; `mailrelay` and `cfproxy` containers); the player guide "Getting an account";
   `docs/FEATURE_REGISTER.md` "Accounts" row; specs README; plan status. Mark them clearly as describing the
   feature-branch state until merge.
7. **Final summary** in the report (charter "Link 7"): what was built per issue; decisions to review, ranked (flags
   L1-…L6-…); the combined live checklist; merge and deploy order (plan § 9; plugin after KNG-182); what the developer
   must do on the NAS (E0 relay, `cfproxy`) and in Cloudflare (list, policy, token, bypass app, session).
8. **Close out:** report block "Link 7", CHANGELOG, tracker row → "Recently completed" (nothing merged), Linear:
   KNG-218 comment (it stays open for the switch-over itself), **KNG-205 → *In Review***. No handoff file (last link).

## Things from link 6 that matter for you

- Switch-over step 2 (plan § 8) is now concrete: alpha go-live § 6.1 steps 1–7. Testers without an account get a
  personal invite rather than a hand-added list entry: **the sync removes anything in `knk-api-testers` that isn't an
  invite or an account** (L6-2). The staff *Emails* include in the policy is never touched.
- New settings: `CloudflareAccess__SyncEnabled|AccountId|ListId|ApiToken|ProxyUrl|ReconcileMinutes|
  InlineAddTimeoutSeconds|MaxRemovalsPerRun`. The token is env-only (`/etc/knk/api.env`), permission Account → Zero
  Trust → Edit (L6-11: inferred, live check).
- Register responses carry `accessGate: true` while the sync is on; the web app then shows the Cloudflare PIN panel.
  `GET api/Invitations/access-sync` feeds the line on `/admin/invitations`.
- Free Zero Trust plan: **50 seats** — a hard ceiling on alpha testers + staff. Put it in the final summary.

## Open flags (for context; none block you)

Link 1: L1-1…L1-7. Link 2: L2-1…L2-12. Link 3: L3-1…L3-12. Link 4: L4-1…L4-16. Link 5: L5-1…L5-9. Link 6: L6-1 email
list only; L6-2 whole list API-owned; L6-3 `MaxRemovalsPerRun` 25; L6-4 wake-ups via `RevokeSessionsAsync`, privacy
erasure and unused expiry by the 5-min run; L6-5 inline add on every register path, `accessGate` even if the add failed;
L6-6 2 s debounce; L6-7 duplicate append unverified; L6-8 `register` returns `{ user, accessGate }`; L6-9 PIN panel with
*Continue*; L6-10 line always shown; L6-11 token permission inferred. Details in the report.

## Risks to keep in mind

- Living-doc edits must not read as if the switch-over already happened on the live alpha: say "after the switch-over"
  and "on the feature branch, not merged".
- The migration must be additive and idempotent; it runs on the alpha database with the existing groups.
- Session nesting: this is link 7 of 7. Do not start another link; leftovers go to the follow-up list and Linear.

## Exit criteria

- `SeedAlphaTesterGroup` built, tested, pushed; API build green; counts ≥ the baseline; the 4 known-red unchanged.
- The smoke-test guide, the architecture doc and the living-doc updates pushed on the feature branch.
- The report's final summary written; tracker row in "Recently completed"; KNG-205 *In Review*.
