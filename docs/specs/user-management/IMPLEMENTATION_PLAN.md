# User Management — Implementation Plan (Tailored Admin Module)

**Status:** Phase 1 (composite player-profile view) shipped 2026-09-24 — see "Phase 1 status"
under §5 below. Phase 2 (quick actions + audit log) and Phase 3 (moderation search/filters) not
started; Phase 2's write-side coordination with `user-features`'s own services (§0) should start
as soon as feasible per this plan's own sequencing note (§4 item 2).
**Last updated:** 2026-09-24 (Phase 1 implementation session added "Phase 1 status" under §5,
resolved §5 item 4, and flagged a real generic-dashboard registration gap as carried-forward item
1 — see that section). Previously updated 2026-09-23 (initial draft).

Ref: `DESIGN.md` in this folder. Depends on: `docs/specs/user-features/IMPLEMENTATION_PLAN.md`
§1 (entities, resolution engine, `permissions/check`/`permissions/effective` endpoints) and,
for Phase 2's audit-log write path, that plan's §3/§4/§5/§6 (owner-mode, title, premium,
salary services).

## 0. Cross-plan coordination note

This plan's Phase 2 (audit log) needs write hooks inside services that `user-features` is
building (`TitleService`, `SalaryService`, the owner/staff-mode command handlers, the
group/grant CRUD services). **Whoever implements those `user-features` services should thread
in an `AuditLogEntry` write per mutation as they go**, rather than this module reaching back
into already-shipped code later to retrofit it. Flag this explicitly when picking up
`user-features` Phase 1/§3/§4/§5/§6 — don't let it silently fall on this plan's Phase 2 alone.

## Phase 1 — Composite player profile view

**knk-web-api:**
- `UsersController`: `GET /api/users/{id}/profile-summary` — aggregates `User` fields,
  `permissions/effective` output, `UserPermissionGroup` rows (with group names/expiry),
  title/XP bracket + progress, active premium `PermissionGroup`(s) + expiry, salary state
  (`LastSalaryPayoutAt`, `PersonalSalaryMultiplier`, computed effective multiplier), and
  vanish/mode state — all in one response DTO (`UserProfileSummaryDto`).
- Resolves DESIGN.md §7 item 1 (premium-tier UI flag) before this ships if the flag approach
  is chosen — it's a field this endpoint needs to expose.

**knk-web-app:**
- New route `/admin/users/:id` (distinct from the generic `/objects/user/:id` FormWizard edit
  screen — this is additive, doesn't replace the generic path).
- `apiClients/userManagementClient.ts` — `getProfileSummary(id)`.
- `PlayerProfilePage.tsx` composing the sections from `DESIGN.md` §2: account, permissions
  (with source-group attribution), groups, title/XP, premium, salary, owner/staff-mode.
- Link into it from the generic `User` table row (an extra "View Profile" action alongside the
  existing view/edit/delete icons `ObjectDashboard`/`PagedEntityTable` already render).

## Phase 2 — Quick actions + audit log write path

**knk-web-api:**
- `Models/AuditLogEntry.cs` + migration (append-only, not `[FormConfigurableEntity]` — no
  generic CRUD form for it).
- `AuditLogService.Record(actorUserId, targetUserId, action, details)` — called from:
  - This phase's own new quick-action endpoints (below)
  - `user-features`'s group/grant CRUD, `TitleService`, `SalaryService`, owner/staff-mode
    handlers (per §0's coordination note — implemented there, not here, but this service is
    the shared dependency both plans call into)
- Quick-action endpoints on `UsersController` (or a new `UserActionsController`):
  `POST /api/users/{id}/groups` (assign), `DELETE /api/users/{id}/groups/{groupId}` (remove),
  `POST /api/users/{id}/grants` (grant/deny a node), `POST /api/users/{id}/vanish-mode`
  (toggle). Each is a thin wrapper calling the same service layer the generic FormWizard CRUD
  uses (per `user-features` DESIGN.md §6.2) plus an `AuditLogService.Record` call.
- `GET /api/audit-log?targetUserId=...&actorUserId=...` (paged).

**knk-web-app:**
- Quick-action controls added directly to `PlayerProfilePage.tsx` (group picker, node grant
  form, vanish toggle) — each re-fetches `profile-summary` after a successful write so the
  admin sees the resolved effect immediately, per `DESIGN.md` §3.
- A "Recent activity" section on the profile page reading `GET /api/audit-log?targetUserId=...`.

## Phase 3 — Moderation search/filters

**knk-web-api:**
- `GET /api/users/search?groupId=...` — users in a given group.
- `GET /api/permission-groups/{id}/expiring-memberships?withinDays=N` — for the "premium
  expiring soon" view.
- `GET /api/audit-log?action=TitleChanged&direction=demotion` (or equivalent filter) — recently
  demoted players.
- Online presence: resolve `DESIGN.md` §7 item 2 first (dedicated endpoint vs. piggybacking on
  an existing sync). Whichever is chosen: `User` gets `IsOnline`/`LastSeenAt`, and
  `knk-plugin`'s `PlayerListener` join/quit hooks report it.

**knk-plugin:**
- Wire `PlayerListener`'s existing `PlayerJoinEvent`/`PlayerQuitEvent` handlers to report
  presence per the mechanism chosen above.

**knk-web-app:**
- `/admin/users` moderation view: filterable list (by group, expiring premium, recently
  demoted, currently online), separate from the generic `ObjectDashboard` table since these are
  cross-entity queries the generic column-filter system can't express.

## 4. Sequencing

1. Phase 1 cannot start meaningfully before `user-features` Phase 1 ships (`permissions/effective`
   is a hard dependency) — frontend scaffolding (routes, empty page shell) can be stubbed
   earlier if useful, but the real profile-summary endpoint needs that dependency in place.
2. Phase 2's write-side coordination (§0) should start *as soon as* the relevant `user-features`
   service is being written, not after — this is the one place strict phase-after-phase
   sequencing would create avoidable rework.
3. Phase 3 is last, gated on resolving DESIGN.md §7 item 2 (presence mechanism) and on Phase 2's
   audit log existing (for the "recently demoted" filter).

## 5. Open items (carried from `DESIGN.md` §7 — implementation detail)

1. ~~Premium-tier UI flag~~ — resolved 2026-09-24: `PermissionGroup.IsPremiumTier` (shipped in
   user-features Phase 5). Phase 1's `profile-summary` can use it directly.
2. Presence-tracking mechanism — needed before Phase 3 starts.
3. Audit log retention policy — needed before Phase 2 ships to production, not before it's
   built.
4. ~~`profile-summary` as one aggregate endpoint vs. several parallel calls~~ — resolved
   2026-09-24: built as one aggregate endpoint per the plan's own recommendation. See "Phase 1
   status" below.

### Phase 1 status — shipped 2026-09-24

Both repo bullets done, on the standing `claude/user-management` branch (a separate branch from
`claude/user-features`, per this feature being confirmed separate — see `DESIGN.md` §0; branched
from `claude/user-features`'s tip in knk-web-api and knk-workspace since Phase 1 needs the
`permissions/effective` endpoint and resolved docs state that only exist there, not yet on
`main`/`master`; branched from `main` in knk-web-app since the frontend has no compile-time
dependency on the unmerged backend branch). Full verification writeup in `ACTIVE_SESSIONS.md`,
"User management Phase 1".

**knk-web-api** — `GET /api/users/{id}/profile-summary` (`UsersController.GetProfileSummary`),
backed by a new `UserProfileSummaryService` composing `IUserService.GetByIdAsync` (account),
`IPermissionResolutionService.GetEffectiveAsync` (permissions with source attribution),
`IUserPermissionGroupService.GetByUserAsync` (groups), `ITitleService.ResolveAsync` (title/XP —
extended with `NextTitleBracketId`/`NextTitleName`/`NextTitleMinExperience` so the profile view
can show progress toward the next bracket, per `DESIGN.md` §2's "progress toward the next
bracket"), and a new `ISalaryService.GetCurrentRankMultiplierAsync` (the same rank-multiplier
math `PayOutAsync` uses, exposed read-only so the profile view can show the current multiplier
breakdown without triggering a real payout as a side effect). New `Dtos/UserProfileSummaryDtos.cs`
(`UserProfileSummaryDto`, `SalaryStateDto`).

**knk-web-app** — new route `/admin/users/:id` (`PlayerProfilePage.tsx`), a read-first dashboard
per `DESIGN.md` §2: account, title/XP with next-bracket progress, premium tier badge, groups
table, salary breakdown, and effective permissions with per-node source attribution (direct grant
vs. named group). New `apiClients/userManagementClient.ts` (`getProfileSummary`) and
`types/dtos/userManagement/UserProfileSummaryDtos.ts` (kept separate from the shared `UserDto`
type in `types/dtos/auth/UserDtos.ts`, which predates `user-features` Phases 3-6 and doesn't carry
`activeMode`/title/premium-tier/salary fields yet — widening that shared type is bigger, riskier
scope than this view needs).

**Two real bugs found and fixed by live verification, not caught by unit tests or a build/typecheck
pass:**
1. `UserProfileSummaryService.GetAsync` originally `Task.WhenAll`'d its five per-concern calls
   ("these are all read-only, so run them concurrently" — a reasonable-looking optimization that
   was wrong). All five share one scoped `DbContext` per request via their repositories, and EF
   Core does not support concurrent operations against one context — the very first live call
   threw `InvalidOperationException: A second operation was started on this context instance
   before a previous operation completed`. Mocked unit tests never caught this because mocks don't
   share a real `DbContext`. Fixed by awaiting each call sequentially.
2. The frontend originally typed `ActiveMode`/`GatePassThroughMethod` as numeric TypeScript enums
   (`None = 0`, `Staff = 1`, `Owner = 2`), matching the C# enum's underlying values. But
   `knk-web-api` serializes enums as their PascalCase string names (`System.Text.Json`'s default),
   confirmed live via `curl` (`"activeMode":"None"`) — every comparison against the numeric enum
   silently evaluated false, so the "Visible (no mode)"/vanish badge rendered for every player
   regardless of actual mode. `tsc --noEmit` passed the whole time (a string is assignable-checked
   fine against a numeric enum's *values* being compared, TypeScript doesn't catch this shape of
   bug) — only caught by actually looking at the rendered screenshot, not just confirming the page
   didn't crash. Fixed by switching both to string literal union types matching the confirmed wire
   format, and verified again with a live toggle (set a test user's `ActiveMode` to `Staff` via
   direct SQL, confirmed the badge correctly flipped to "Staff mode", then reset it).

**A real doc/code gap flagged, not silently built around:** `DESIGN.md` §0 says annotated entities
"already show up [in the generic dashboard] for free" once `[FormConfigurableEntity]`-annotated,
and this plan's own Phase 1 bullet says to "link into it from the generic User table row." Checked
before assuming: `User` is not actually registered in knk-web-app's `objectConfigs.tsx`/
`columnDefinitionsRegistry` at all — confirmed by search, zero matches for `user` as a key. So
there is currently no generic User table row to link from. Registering `User` there properly
(excluding `PasswordHash`, building enum pickers for `ActiveMode`/`GatePassThroughMethod`, etc.)
is real, separate scope of its own, and this plan's own Phase 3 already plans a dedicated
`/admin/users` moderation list — building an ad hoc interim list page here risked duplicating that
work. Left as a carried-forward item (below) rather than either silently skipping the discoverability
question or silently building one of those two heavier things unasked. The page itself is complete
and reachable by direct URL (`/admin/users/:id`) in the meantime.

**Verification — this session ran in a cloud sandbox.** `repo.papermc.io` concerns don't apply
(knk-plugin untouched this phase — Phase 1 is web-api/web-app only per this plan's own per-repo
bullets, confirmed by re-reading before starting rather than assumed). `.NET 8 SDK` + `dotnet-ef`
installed fresh via `apt`. **Docker worked this session** (unlike several prior phases' sandboxes
that had no `dockerd`/systemd at all) — `dockerd` started manually (no systemd), and a real
`mysql:8.0` container ran against it (the image pull hit Docker Hub's own `429` rate limit on the
first attempt, succeeded on retry). Applied all 26 prior migrations clean. Created a real test
user via the live API, granted it a premium group membership (bumped `Royal`'s
`SalaryMultiplier` to 1.5 to make the math visible), a direct `PermissionGrant`
(`knk.chat.color`) and a group-sourced one (`knk.mode.staff` on `Royal`), backdated
`LastSalaryPayoutAt` by SQL to make the salary section non-trivial. Called
`GET /api/users/{id}/profile-summary` directly via `curl` and confirmed every field (title
correctly resolved to "Apprentice" with "Journeyman" as next bracket and the right XP-to-go math,
premium tier correctly surfaced as "Royal", salary breakdown `1 (global) x 2 (personal) x 1.5
(rank) = 3.0/hr`, both permission entries present with correct `sourceHolderType`/
`sourceHolderName`). Confirmed `404` for an unknown user id. **Full frontend pass, not just an
API check:** installed npm deps (`CYPRESS_INSTALL_BINARY=0` — Cypress's own binary download was
blocked by the sandbox's egress policy, unrelated to anything this phase touched),
`tsc --noEmit` clean, `npm run build` clean (only the same pre-existing lint warnings every other
file in the repo already has — none in the new files), `npm run test:ci` unchanged from baseline
(10 pre-existing failing suites, none touching anything this phase added — this repo has no
per-page component tests for other admin pages like `GameSettingsPage.tsx` either, so not adding
one for `PlayerProfilePage.tsx` matches existing convention rather than being a gap introduced
here). Then a **real browser pass via Playwright** (not just "it builds"): registered a real web
account through the live API, logged in through the real `/api/Auth/login` endpoint, seeded the
returned access token into `localStorage` the same way the app's own login flow does, and loaded
`/admin/users/4` in an actual Chromium instance — screenshotted the fully-rendered page (every
section populated with the real seeded data, styled consistently with the rest of the admin UI)
and confirmed the console was clean of anything from this feature's own code (the few console
errors present are pre-existing/environment noise: an unrelated `Auth/me` 401 from the
hand-seeded-token login path lacking a refresh-cookie round-trip, and TLS-proxy-related resource
errors from the sandbox's own network policy, not from anything this phase built). Also
screenshotted and verified the not-found state renders correctly for an unknown id.

**dotnet test:** 378/383 pass (10 of those are this phase's own new tests: 2 for
`TitleService`'s next-bracket resolution, 3 for `SalaryService.GetCurrentRankMultiplierAsync`,
3 for `UserProfileSummaryService`, 2 for `UsersController.GetProfileSummary`), the same 5
pre-existing unrelated failures every prior phase's row already documents
(`PathResolutionServiceTests`×2, `FormSubmissionProgressRepositoryTests`,
`FieldValidationServiceTests`, `ClientActivityStoreTests`). The LAN dev DB
(`192.168.50.119`) was never touched — confirmed via `git diff` on `appsettings.json` showing
zero changes; every command pointed at the disposable container via a
`ConnectionStrings__MySqlDbConnection` environment-variable override.

**Carried forward:**
1. **No entry point from the generic dashboard** — see the doc/code gap above. Either register
   `User` minimally in `objectConfigs.tsx` (narrow, but generic CRUD for a sensitive/enum-heavy
   entity deserves its own scoped pass — password-hash exclusion, `ActiveMode`/
   `GatePassThroughMethod` pickers, etc.) or fold this into Phase 3's already-planned
   `/admin/users` moderation list (which will need row links into this same page anyway) —
   whichever is picked, don't build both.
2. **No quick actions yet** — read-only view only, per this task's own Phase 1 scope; Phase 2 adds
   assign/revoke group, grant/deny node, and vanish toggle directly on this page.
3. **No dedicated component test for `PlayerProfilePage.tsx`** — matches this repo's existing
   convention for admin pages (`GameSettingsPage.tsx` has none either), flagged rather than
   silently assumed acceptable.
4. **§0's audit-log cross-plan dependency remains exactly as `user-features`' own §6 carried-forward
   item 4 describes it** — no `AuditLogEntry` entity exists yet, and this phase didn't add one
   (that's Phase 2's own scope). `SalaryService.PayOutAsync`'s coin mutation and
   `UserService.AdjustBalancesAsync` both still need retrofitting once Phase 2 builds the audit
   service — not a new finding, just confirming it wasn't accidentally addressed as a side effect
   of this phase's `SalaryService` changes (the only change here was the new read-only
   `GetCurrentRankMultiplierAsync` method, which mutates nothing and needs no audit entry).
