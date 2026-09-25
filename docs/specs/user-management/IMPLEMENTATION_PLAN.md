# User Management — Implementation Plan (Tailored Admin Module)

**Status:** All three phases shipped 2026-09-24. Phase 1 (composite player-profile view) and
Phase 2 (quick actions + audit log write path) — see "Phase 1 status" and "Phase 2 status" under
§5 below. Phase 3 (moderation search/filters) — see "Phase 3 status" under §5. All §5 open items
resolved: item 2 (presence tracking) and item 3 (audit log retention policy) — see "Audit log
retention status". This module is feature-complete.
**Last updated:** 2026-09-24 (Phase 3 implementation session added "Phase 3 status" under §5,
resolved §5 item 2, and closed the Phase 1/2 carried-forward "no generic-dashboard entry point"
item). Previously updated 2026-09-24 (audit log retention policy session added "Audit log
retention status" under §5, resolved §5 item 3). Previously updated 2026-09-24 (Phase 2
implementation session added "Phase 2 status" under §5). Previously updated 2026-09-24 (Phase 1
implementation session added "Phase 1 status" under §5, resolved §5 item 4, and flagged a real
generic-dashboard registration gap as carried-forward item 1 — see that section). Previously
updated 2026-09-23 (initial draft).

Ref: `DESIGN.md` in this folder. Depends on: `docs/specs/user-features/IMPLEMENTATION_PLAN.md`
§1 (entities, resolution engine, `permissions/check`/`permissions/effective` endpoints) and,
for Phase 2's audit-log write path, that plan's §3/§4/§5/§6 (owner-mode, title, premium,
salary services).

## 0. Cross-plan coordination note

**Resolved 2026-09-24 (Phase 2 session), the opposite way this note originally hoped for:**
this note asked whoever built `user-features`'s services to thread in the audit write as they
went, rather than this module retrofitting later. In practice `user-features` Phases 1/3/4/5/6
all shipped before `AuditLogEntry`/`AuditLogService` existed (there was nothing to thread into),
so this Phase 2 session did the retrofit itself — see "Phase 2 status" below and
`user-features/IMPLEMENTATION_PLAN.md` §6's carried-forward item 4 for the full list of call
sites. Left here for anyone comparing this plan's original intent against what actually happened,
not as a still-open task.

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
2. ~~Presence-tracking mechanism~~ — resolved 2026-09-24 as part of Phase 3: dedicated
   `PUT /api/users/{id}/presence`, not a periodic sync. See "Phase 3 status" below and
   `DESIGN.md` §7 item 2.
3. ~~Audit log retention policy~~ — resolved 2026-09-24: `AuditLogRetentionConfiguration`
   singleton (default 180 days) + `RetentionPolicyService` cleanup. See "Audit log retention
   status" below.
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
2. ~~No quick actions yet~~ — **done 2026-09-24**, see "Phase 2 status" below.
3. **No dedicated component test for `PlayerProfilePage.tsx`** — still true after Phase 2 added
   controls to the same page; matches this repo's existing convention for admin pages
   (`GameSettingsPage.tsx` has none either), flagged rather than silently assumed acceptable.
4. ~~§0's audit-log cross-plan dependency~~ — **closed 2026-09-24**, see "Phase 2 status" below
   and `user-features/IMPLEMENTATION_PLAN.md` §6's carried-forward item 4.

### Phase 2 status — shipped 2026-09-24

Both repo bullets done, on the same standing `claude/user-management` branch as Phase 1, in all
three repos. Full verification writeup in `ACTIVE_SESSIONS.md`, "User management Phase 2".

**knk-web-api** — new `Models/AuditLogEntry.cs` (append-only, `Action` stored as its
PascalCase string name via `HasConversion<string>()`, not an int, matching this codebase's
`System.Text.Json` enum-serialization convention), migration `AddUserManagementPhase2AuditLog`
(clean new-table create, no risky-default backfill needed unlike prior column-add migrations),
`Services/AuditLogService.RecordAsync`/`SearchAsync` (username resolution for the read path via
plain per-id `IUserRepository.GetByIdAsync` lookups — no batch-get-by-ids method existed to reuse,
and a paged admin view's per-page id count doesn't warrant adding one), new
`Controllers/AuditLogController` (`GET /api/audit-log`, explicit `api/audit-log` route since the
plan's own kebab-case spelling doesn't match the controller-name convention), and four new
quick-action endpoints added directly to `UsersController` (`POST {id}/groups`,
`DELETE {id}/groups/{groupId}`, `POST {id}/grants`, `POST {id}/vanish-mode`) — each a thin
wrapper over the *same* `IUserPermissionGroupService`/`IPermissionGrantService`/`IUserService`
methods the generic FormWizard CRUD controllers already call, per `DESIGN.md` §3's "not a
parallel code path" instruction.

**The retrofit (§0/user-features §6 item 4) went wider than "thread it into the two named call
sites,"** found by reading each candidate service before assuming it was covered, not by
guessing from the plan's own list:
- `SalaryService.PayOutAsync` — action `SalaryPayout`, actor `null` (system-initiated, matching
  `AuditLogEntry.ActorUserId`'s own doc comment), only recorded when `Paid == true`.
- `UserService.AdjustBalancesAsync` — action `BalanceAdjusted` (the `// TODO: Log to audit trail`
  this item pointed at). Also detects a resulting title-bracket change (comparing
  `ITitleService.ResolveAsync` before/after, since `TitleService` itself has no mutating method —
  it's pure XP-derived, per its own doc comment) and records a second `TitleChanged` entry with a
  `direction` field derived from the XP delta's sign, **not** from comparing `TitleBracketId`
  values directly — `TitleBracketId` is an auto-increment PK unrelated to rank order, an easy
  mistake caught and fixed before it shipped (would have made "recently demoted" queries, planned
  for Phase 3, silently wrong).
- **A real, previously-unaudited second write route, found while doing this retrofit, not
  assumed covered:** the generic `UserService.UpdateAsync` (the FormWizard's `PUT /api/Users/{id}`)
  maps `Coins`/`Gems`/`ExperiencePoints`/`PersonalSalaryMultiplier` straight from `UserDto` onto
  the entity — confirmed by reading `UserMappingProfile`, which explicitly `opt.Ignore()`s
  `ActiveMode`/`LastSalaryPayoutAt` for exactly this reason ("a generic edit that omits it must
  not silently reset/overwrite it") but does *not* ignore those four fields. So an admin editing
  a player through the generic dashboard form could change coins/gems/XP/salary-multiplier with
  zero audit trail, bypassing `AdjustBalancesAsync` entirely. Retrofitted the same way (diff
  before/after, `BalanceAdjusted` + derived `TitleChanged`), actor from
  `GetUserIdFromClaims(User)` threaded through a new optional `UserService.UpdateAsync` parameter.
- `UserService.UpdateActiveModeAsync` — action `VanishToggled`, only recorded when the mode
  actually changes (a no-op call, e.g. re-setting the same mode, writes nothing). This is the
  same method the in-game `/staffmode`/`/ownermode` commands call via
  `UsersCommandApi.setActiveModeById` → `PUT .../active-mode` (per `user-features` §6.1's
  carried-forward note), so the owner/staff-mode command handlers `DESIGN.md` §0 names are
  covered transitively — the plugin doesn't write to the DB directly, confirmed rather than
  assumed.
- `UserPermissionGroupService.UpsertAsync`/`DeleteAsync` — actions `GroupAssigned`/`GroupRemoved`.
- `PermissionGrantService.CreateAsync`/`UpdateAsync`/`DeleteAsync` — actions `GrantAdded`/
  `GrantUpdated`/`GrantRemoved`. **One design call made and tested, not glossed over:**
  `PermissionGrant.HolderId` can point at a `User` *or* a `PermissionGroup` (TPT base
  `PermissionHolder`, `DESIGN.md` §2.1) — a grant on a group affects every member indirectly, not
  one player, so there's no single `TargetUserId` to log against. Resolved by checking
  `IUserRepository.GetByIdAsync(holderId) != null` before writing an entry; group-holder grants
  are silently *not* audited per-player rather than logged against a group id `AuditLogEntry`
  doesn't have a column for. Verified live: granting a node on `PermissionGroup` id 2 produced no
  audit-log row, granting on a `User` id did.

All of the above are threaded through the *existing* mutation methods rather than adding new
"AuditedX" wrapper methods, so the generic FormWizard CRUD controllers (`UserPermissionGroupsController`,
`PermissionGrantsController`) get audit coverage for free too, not just the new quick-action
endpoints — confirmed live (see below).

**knk-web-app** — `PlayerProfilePage.tsx` gained: a mode-toggle button row (highlights the
current mode, disabled while in flight); a group-assign form (`<select>` populated from a new
narrow `permissionGroupClient.getAll()` — `PermissionGroup` still isn't registered in
`objectConfigs.tsx`, Phase 1's carried-forward item 1, so this is page-scoped rather than the
generic path) plus a per-row remove (×) button on the groups table; a grant/deny-node mini-form
(node text input, grant/deny select, optional expiry). Every quick action re-fetches
`getProfileSummary` *and* the new activity feed on success, per `DESIGN.md` §3. New "Recent
Activity" section reads `GET /api/audit-log?targetUserId=...`, rendering a human-readable action
label, actor username or "system" for a null actor, and timestamp. New types
(`AuditLogEntryDto`/`AuditAction`/`AssignGroupRequest`/`GrantNodeRequest` in
`UserProfileSummaryDtos.ts`; `PermissionGrantDto.ts`/`PermissionGroupDto.ts`) and client methods
kept in the existing `userManagementClient.ts` rather than new files, except the narrow
`permissionGroupClient.ts` (a different resource). Added `Controllers.AuditLog = 'audit-log'` and
`Controllers.PermissionGroups` to `utils/enums.ts` (the audit-log route doesn't match the
`api/[controller]` PascalCase convention, so `getAuditLog` passes an empty `operation` and lets
`requestData` become the query string, rather than a path segment).

**Verification — cloud sandbox this session, same rigor as Phase 1, not just build/test green.**
`repo.papermc.io` doesn't apply (`knk-plugin` untouched — Phase 2 is web-api/web-app only per the
plan's own per-repo bullets). `.NET 8 SDK` + `dotnet-ef` via `apt`. **Docker worked this
session** — `dockerd` started manually (no systemd), `mysql:8.0` pulled clean on the first
attempt (no rate-limit retry needed this time). Generated the migration against the real DB,
hand-reviewed it before applying (this codebase's own precedent for risky auto-generated
defaults) — a clean new-table create needed no hand-fixing, unlike prior column-add migrations.
Applied all 27 prior migrations clean. `dotnet test`: 391/396 (13 new: 4 `AuditLogServiceTests`,
2 `SalaryServiceTests`, 3 `UserServiceTests`, 2 `UserPermissionGroupServiceTests`, 4 new
`PermissionGrantServiceTests` covering the User-vs-PermissionGroup holder branch specifically),
same 5 pre-existing unrelated failures every prior phase documents.

**Live API pass, not just unit tests:** created a real test user via the live API, then in
sequence via `curl` — toggled vanish mode, granted a direct node, assigned a group, adjusted
balances (+5000 XP, crossing several title brackets), removed the group, edited coins through the
*generic* `PUT /api/Users/{id}` (to specifically exercise the newly-found second write route,
not just the dedicated endpoint), backdated `LastSalaryPayoutAt` by 3 hours via SQL and triggered
a real payout — then fetched `GET /api/audit-log?targetUserId=...` and confirmed all 8 entries
present, correctly ordered (`Timestamp` descending), correctly attributed (`actorUserId: null` for
every unauthenticated call), correct `TitleChanged` promotion detection (Novice → Master, correct
direction), and correct coin-balance arithmetic reconciling across every mutation
(250 → 200 → 977 → 980, matching `-50 balances` → `+777 generic edit` → `+3 payout` exactly).
Logged in via the real `/api/Auth/login` endpoint and repeated the vanish-mode toggle with a
bearer token: `actorUserId`/`actorUsername` correctly resolved to the authenticated caller instead
of `null`. Confirmed a grant on a `PermissionGroup` holder produces zero audit rows (the
User-vs-group branch, live not just mocked). Confirmed `404` on an unknown-user quick action.
Confirmed Phase 1's `profile-summary` endpoint has no regression (re-fetched, all sections still
resolve correctly against the now-mutated data).

**Full frontend pass:** `npm install` (`CYPRESS_INSTALL_BINARY=0`, same sandbox egress block as
every prior phase, unrelated to this one), `tsc --noEmit` clean, `npm run build` clean (only the
same pre-existing lint warnings every other untouched file in the repo already has — none in any
file this phase touched, confirmed by grepping the build output for this phase's filenames
specifically), `npm run test:ci` unchanged from baseline (10 pre-existing failing suites,
byte-for-byte the same list Phase 1 documented, none touching this phase's files). Then a real
**Playwright browser pass**, not a static screenshot: registered/logged in through the live auth
endpoints exactly like Phase 1 did, loaded `/admin/users/4` in actual Chromium, and — beyond just
screenshotting — **actually clicked the "Staff mode" button** (not curl) and confirmed the badge,
the highlighted button state, and the header all updated correctly after a real re-fetch.
Screenshotted the fully-populated page (mode toggle, group picker, grant form, and a Recent
Activity feed with all 8 seeded entries correctly labeled/attributed/timestamped) and the
not-found state for an unknown id. Console clean of anything from this phase's own code — the
only errors present are the same TLS-proxy/cert resource errors from the sandbox's own network
policy Phase 1 already documented as environment noise, plus the *expected* logged 404 from the
not-found test case itself.

**dotnet test:** 391/396 (13 new — see above), same 5 pre-existing unrelated failures every prior
phase's row documents (`PathResolutionServiceTests`×2, `FormSubmissionProgressRepositoryTests`,
`FieldValidationServiceTests`, `ClientActivityStoreTests`). The LAN dev DB (`192.168.50.119`) was
never touched — confirmed via `git diff` on `appsettings.json` showing zero changes; every command
used a `ConnectionStrings__MySqlDbConnection` environment-variable override.

**Carried forward:**
1. **No entry point from the generic dashboard** — unchanged from Phase 1's own carried-forward
   item 1 (still not registered in `objectConfigs.tsx`); this phase didn't resolve it either,
   same reasoning (Phase 3's moderation list is the more natural place, don't build both).
2. **No dedicated component test for `PlayerProfilePage.tsx`** or for the new quick-action forms —
   matches this repo's existing convention, same as Phase 1's item 3.
3. ~~**Audit log retention policy**~~ (`DESIGN.md` §7 item 3 / this file's §5 item 3) — resolved
   2026-09-24. See "Audit log retention status" below.
4. **Grants on a `PermissionGroup` holder are unaudited** — a deliberate scope boundary (see
   above), not an oversight, but flagged in case a future phase decides group-level grant changes
   *should* surface somewhere (e.g. an audit entry per affected member, or a separate
   group-level audit view) — no such requirement exists today.
5. **Phase 3 (moderation search/filters) not started** — gated on §5 item 2 (presence-tracking
   mechanism), unchanged.

### Audit log retention status — resolved 2026-09-24

Small, scoped follow-up on the standing `claude/user-management` branch, knk-web-api only (see
"Scope confirmation" below). Full writeup in `ACTIVE_SESSIONS.md`, "User management — audit log
retention policy".

**Three decisions made and flagged here, not silently picked, per this task's own instruction:**

1. **Retention window: configurable, not a hardcoded constant.** New singleton
   `AuditLogRetentionConfiguration` (`Id="global"`, `RetentionDays` int, default **180 days**),
   admin GET/PUT at `/api/AuditLogRetentionConfiguration` — mirrors `SalaryConfiguration`'s
   pattern exactly (lazy-created on first read, `UpsertAsync`, singleton row), and matches this
   codebase's repeated precedent of "raw GET/PUT only, no FormConfiguration authored" for
   admin-only config (`SalaryConfigurationController`, `GameSettingsController`). **The 180-day
   default is a real product decision, not derived from any doc** — the existing
   `RetentionPolicyService` precedent for `FormSubmissionProgress` is 14 days, but that's
   transient in-progress form state, not an audit/compliance-adjacent trail; `DESIGN.md` §7 item
   3's own phrasing ("dropped after N months") suggested something longer, so 180 (~6 months) was
   chosen as a reasonable starting point. **Flagging this explicitly for the developer to revisit**
   — there's no compliance requirement on record anywhere in this codebase's docs that pins the
   number, so treat 180 as a placeholder tuned via `PUT` rather than a researched figure.
2. **Deletion, not archival.** Confirmed `AuditLogEntry`'s own doc comment: `ActorUserId`/
   `TargetUserId` are plain int columns with no FK navigation, deliberately, so there was nothing
   an archive step would need to detach first. A straight `ExecuteDeleteAsync` bulk delete matches
   `DESIGN.md` §7 item 3's own "dropped after N months" framing. No export/archive mechanism was
   built — flagging in case a future compliance need changes this, but nothing in the current docs
   asks for one.
3. **`RetentionPolicyService` extended, not replaced or generalized.** Read the existing service
   before deciding: it hardcodes one entity type (`FormSubmissionProgress`, 14-day retention) with
   no generic "list of cleanup tasks" abstraction. Rather than refactor it into something generic
   for two entity types (over-engineering for a "small, scoped follow-up"), added a second,
   independently-try/caught `RunAuditLogCleanupAsync` step to the same `RunCleanupAsync` run, using
   the same `IServiceProvider`-scoped-per-run pattern the existing code already uses. Reads
   `AuditLogRetentionConfiguration` fresh on **every** run (not cached at startup like
   `FormSubmissionProgress`'s 14-day constant is), so a `PUT` to the config endpoint changes
   behavior on the next scheduled run with no restart needed — verified live (see below).

**Scope confirmation, checked rather than assumed:** grepped every doc under
`docs/specs/user-management/` and `docs/specs/user-features/` for "audit"/"retention" — nothing
suggests a web-app or plugin surface for this; Phase 2's audit log is web-api only per its own
per-repo bullets, and retention is purely a backend cleanup-job concern with an admin-only raw
endpoint (no UI, per the precedent in decision 1 above). **knk-web-app and knk-plugin: confirmed
untouched, not just skipped.**

**Files (knk-web-api, all new except as noted):** `Models/AuditLogRetentionConfiguration.cs`;
`Dtos/AuditLogRetentionConfigurationDtos.cs`; `Repositories/AuditLogRetentionConfigurationRepository.cs`
+ `Repositories/Interfaces/IAuditLogRetentionConfigurationRepository.cs`;
`Services/AuditLogRetentionConfigurationService.cs` + `Services/Interfaces/IAuditLogRetentionConfigurationService.cs`;
`Controllers/AuditLogRetentionConfigurationController.cs`; `Repositories/AuditLogRepository.cs`
(+`DeleteOlderThanAsync`, bulk `ExecuteDeleteAsync`) and its interface (modified); `Properties/KnKDbContext.cs`
(+`DbSet<AuditLogRetentionConfiguration>` and `OnModelCreating` entity config, modified);
`Services/RetentionPolicyService.cs` (+`RunAuditLogCleanupAsync`, modified); migration
`20260924150229_AddAuditLogRetentionConfiguration` (clean new-table create, no backfill needed,
same as Phase 2's own audit-log migration). No DI registration changes needed — this codebase's
convention-based reflection registration (`DependencyInjection/ServiceCollectionExtensions.cs`,
matches any `IXxx`/`Xxx` Repository/Service pair by name) picks up all the new
repository/service classes automatically, confirmed by their successful resolution at runtime.

**Verification — cloud sandbox this session, live not just build/test green, per this task's own
instruction.** `.NET 8 SDK` + `dotnet-ef` via `apt`. **Docker worked this session** — `dockerd`
started manually (no systemd), `mysql:8.0` hit Docker Hub's `429` rate limit on the first pull
attempt, succeeded on retry (same transient issue Phase 1's session hit). Generated the migration
against the real DB, hand-reviewed before applying (this codebase's own precedent) — clean
new-table create, nothing to hand-fix. Applied all 28 prior migrations clean.

**Live retention-behavior pass, seeded and triggered directly rather than waiting for the real
24h schedule:** seeded 5 `AuditLogEntry` rows via direct SQL with backdated `Timestamp` values
(200/190/181/10/1 days old — no FK on this table, so no real `User` row was needed to seed
against). Started the app — `RetentionPolicyService` already runs its cleanup immediately on
startup, so no interval-shortening was needed. Confirmed via log output and a direct DB query: the
config row was lazily created at the 180-day default, the three >180-day rows (200d/190d/181d)
were deleted, and both recent rows (10d/1d) survived untouched. **Then verified the dynamic
re-read specifically** (decision 3 above): `PUT /api/AuditLogRetentionConfiguration` with
`{"retentionDays":30}` (confirmed via `GET` afterward), seeded one more row at 60 days old
(inside the old 180-day window, outside the new 30-day one), restarted the app to trigger another
run, and confirmed via log + DB query that the 60-day row was now deleted while the 10-day/1-day
rows still survived — proving the config change took effect without a code change or a service
restart being *required* for the config itself (a restart was used here only as a convenient way
to force an out-of-schedule run, not because the config needed one). Also confirmed `PUT` with
`{"retentionDays":0}` correctly returns `400` with a validation message (`retentionDays must be at
least 1`).

**dotnet test:** 391/396, same 5 pre-existing unrelated failures every prior phase's row documents
(`PathResolutionServiceTests`×2, `FormSubmissionProgressRepositoryTests`, `FieldValidationServiceTests`,
`ClientActivityStoreTests`) — no new failures. No new tests were added for this change (matches
this repo's existing convention of not requiring dedicated tests for every admin-config
controller — `SalaryConfigurationController`/`GameSettingsController` have none either — and the
live verification above exercises the actual cleanup logic, migration, and endpoints end to end
more directly than a mocked unit test would for this particular kind of change). Flagging this as
a deliberate choice, not an oversight, in case the developer wants
`AuditLogRetentionConfigurationServiceTests`/`AuditLogRepositoryTests.DeleteOlderThanAsync_...`
added later for regression coverage. The LAN dev DB (`192.168.50.119`) was never touched —
confirmed via `git diff` on `appsettings.json` showing zero changes; every command used a
`ConnectionStrings__MySqlDbConnection` environment-variable override against a disposable
`mysql:8.0` Docker container, removed after this session.

**Carried forward:** none new. This closes `DESIGN.md` §7 item 3 / this file's §5 item 3. The
180-day default (decision 1 above) is worth a second look from the developer since it's this
session's own placeholder judgment call, not a documented requirement.

### Phase 3 status — shipped 2026-09-24

`knk-web-api`: `Models/User.cs` gains `IsOnline`/`LastSeenAt` (migration
`AddUserManagementPhase3Presence`, clean additive column-add, `IsOnline` defaults `false`,
`LastSeenAt` nullable — no backfill needed for existing rows); `PUT /api/users/{id}/presence`
(new `IUserRepository.UpdatePresenceAsync`/`IUserService.UpdatePresenceAsync`, not audit-logged —
a passive system signal, not an admin action, see decision 1 below); `GET /api/Users/search?
groupId=&onlineOnly=` (new `IUserRepository.SearchByGroupAsync`, joins `UserPermissionGroups`);
`GET /api/PermissionGroups/{id}/expiring-memberships?withinDays=` (new
`IPermissionGroupRepository.GetExpiringMembershipsAsync`, excludes permanent (`ExpiresAt=null`)
and already-expired memberships); `GET /api/audit-log` gains `action`/`direction` query params
(direction matches `TitleChanged` entries' freeform `Details` JSON via a string `Contains`, no
dedicated column — see decision 2). `AuditLogServiceTests`/`UserServiceTests` extended (5 new
tests) — commit `0e44410` on the standing `claude/user-management` branch.

`knk-plugin`: new `UsersCommandApi.setPresenceById(int, boolean)` + `UsersCommandApiImpl`
(`PUT /Users/{id}/presence`, matches the existing `setCoinsById`/`setGatePassThroughMethodById`
per-user-id PUT pattern) + `PresenceUpdateDto`; `PlayerListener.onJoin`/`onLeave` now call it via
a new constructor-injected `UsersCommandApi` field, resolving the target user id from
`cacheManager.getUserCache()` (same cache `onJoin` already reads for the welcome message — no
new reliability risk). Silently no-ops if the user isn't cached yet, logs a warning on API
failure, never blocks login/quit on it. First commit on `claude/user-management` in this repo —
Phase 1/2 didn't need the plugin — commit `89212c9`.

`knk-web-app`: new `UserModerationPage.tsx` at `/admin/users`, three tabs each backed by one
Phase 3 endpoint (by-group + online-only, premium-expiring-soon, recently-demoted), added to
`App.tsx` routing and `Navigation.tsx` ("Moderation" link). `UserListDto` (shared with the
generic `POST /api/users/search`) widened with `isOnline`/`lastSeenAt` rather than duplicated —
low-risk additive fields, single existing consumer (`userClient.ts`) checked first. New
`ExpiringMembershipDto` type. Commit `2428b10` on the standing `claude/user-management` branch.

**Three decisions made and flagged, not silently picked, per this task's own instruction:**
(1) **presence updates are not audit-logged** — `AuditLogEntry`/`DESIGN.md` §4 scope the audit
trail to admin/system mutations *affecting a player's state* (balance, group, grant changes);
join/quit presence pings would just be volume noise at every-login frequency, and nothing in
`DESIGN.md` asked for a login history feature. (2) **the `onlineOnly` query param on
`GET /api/Users/search`** — the plan's own Phase 3 bullet only named `groupId`; `onlineOnly` was
added as this session's own reasonable extension so "currently online" (DESIGN.md §5) has
somewhere to plug into the UI, since no standalone "list all online players" endpoint exists in
the plan. **This means "currently online" in the shipped UI is scoped to "online within a
selected group", not a server-wide online roster** — flagged explicitly in case the developer
wants a groupless variant later (a straightforward addition: drop the `NOT NULL` groupId
requirement in `SearchByGroupAsync`/`UsersController.SearchByGroup`). (3) **`direction` matching
via `Details.Contains(...)` rather than a dedicated column** — matches this table's own "append-
only, viewed not edited" scope from Phase 2; a dedicated `Direction` column would need a second
migration and a backfill decision for existing `TitleChanged` rows for one query's sake, judged
not worth it at current audit-log volume (confirmed live: a handful of rows in dev). If audit-log
volume grows enough that this LIKE-style match becomes a real query-performance concern, it's a
candidate to revisit.

**Verification — cloud sandbox this session, live not just build/test-green, same rigor as prior
phases.** `.NET 8 SDK`+`dotnet-ef` via `apt` (as in every prior phase). Docker's `mysql:8.0` pull
hit a *persistent* 429 this session (four retries over several minutes, unlike prior phases'
one-retry-and-it-clears experience) — fell back to `apt-get install mysql-server`, started
manually (`mysqld_safe`, no systemd) per this project's own documented fallback. Migration
generated against this real local MySQL 8.0, hand-reviewed before applying (clean additive
column-add, nothing to hand-fix) — all 29 migrations applied clean. **Live API pass:** created
real test users/groups via `curl`, exercised every new endpoint directly — group search,
online-only filter (toggled via the real presence endpoint, confirmed the online user was
included/excluded correctly as presence flipped), expiring-memberships (confirmed a permanent
membership is correctly excluded, only the one with a real `ExpiresAt` inside the window showed),
and the demotion filter (forced a real promotion then a real bracket-crossing demotion via
`PUT .../balances`, confirmed `direction=demotion` returned exactly the demotion entry and
`direction=promotion` returned exactly the promotion entry — not a coincidental single-entry
match, both directions independently verified against the same player's history). 404 on an
unknown user id for the presence endpoint confirmed. `dotnet test`: 396/401 (5 new), same 5
pre-existing unrelated failures every prior phase documents — one real regression was caught and
fixed here, not shipped: the pre-existing `AuditLogServiceTests.SearchAsync_ResolvesActorAndTargetUsernames`
mocked the repository's old 4-arg `SearchAsync` overload, which the service's new 2-arg-forwarding
implementation no longer calls, causing a `NullReferenceException` — fixed by updating the mock
setup to the actual 6-arg call the service now makes, per this codebase's own precedent of
updating call sites' tests rather than papering over a shape change.

**knk-plugin verification:** `repo.papermc.io` policy-blocked in this sandbox (same finding every
prior session), confirmed via the proxy's own status endpoint rather than assumed. Maven Central
itself also hit intermittent 429s this session (a new wrinkle — Gradle's plugin-portal
resolution for the unrelated `knk-paper` shadow-jar dependency chain failed outright on it, so
even `./gradlew :knk-core:compileJava` couldn't be used since Gradle configures every module in
the build regardless of which task is requested) — worked around by fetching the actual runtime
dependency jars (Jackson, OkHttp, Gson, Kotlin stdlib, JUnit console) directly from
`repo1.maven.org` via `curl` with retries, then compiling with plain `javac`/running with the
JUnit console-standalone launcher, bypassing Gradle's build-graph resolution entirely — same
spirit as Phase 1's workaround, adapted for this session's specific failure mode. All 140
Bukkit-free `knk-core` files (including the touched `UsersCommandApi.java`) and all 120
`knk-api-client` files (fully Bukkit-free, including the new `PresenceUpdateDto` and updated
`UsersCommandApiImpl`) compiled with **zero errors**; confirmed `setPresenceById` present in the
compiled bytecode via `javap`. All 350 Bukkit-free `knk-core` unit tests pass (0 failures),
including the updated `UsersDataAccessTest`'s `StubUsersCommandApi`. The `knk-paper` changes
(`PlayerListener.java`, `KnKPlugin.java` — Bukkit-dependent) are hand-reviewed only, not
compiler-verified — needs a real `./gradlew build` on a machine that can reach
`repo.papermc.io`/an unrate-limited Maven Central. Not live-tested against a real or simulated
Minecraft client/server this session (no reachable dev server in this sandbox) — the live
verification for presence specifically was via direct `curl` calls to the same
`PUT /api/users/{id}/presence` endpoint `PlayerListener` calls, not an actual player join/quit;
a real join/quit pass on the developer's own dev server is still worth doing before relying on
this in production, though the code path itself (cache lookup → `UsersCommandApi` call →
exception-swallowed-and-logged) mirrors `onValidateLogin`'s own established pattern closely
enough that this is a low-risk gap, not an unknown one.

**Full frontend pass:** `npm install` (`CYPRESS_INSTALL_BINARY=0`, same sandbox egress
convention as every prior phase), `tsc --noEmit` clean, `npm run build` clean (only pre-existing
lint warnings in untouched files, confirmed by name). Real **Playwright browser pass** (Playwright
itself isn't a project dependency — installed standalone in a scratch directory, pointed at the
sandbox's pre-installed Chromium via `executablePath`, since this Chromium build has removed
"old" headless mode and needed `--headless=new` explicitly): logged in through the live
`/auth/login` form with a real registered account, loaded `/admin/users` in actual Chromium,
and **exercised all three tabs with real seeded data** — group search (2 rows), online-only
filter (correctly narrowed to 1), premium-expiring-soon (correctly excluded a permanent
membership, showed only the one with a real expiry), recently-demoted (1 row, correct
promotion/demotion JSON). **Clicked a result row and confirmed it navigated to the real
`PlayerProfilePage` at `/admin/users/:id`** with that player's actual data rendered — the
concrete proof that this phase closes Phase 1/2's carried-forward "no generic-dashboard entry
point into `PlayerProfilePage`" item (see below). Confirmed the "Moderation" nav link renders and
highlights correctly. One real script-level pitfall hit and fixed during this pass, not a product
bug: an early automation script's `text=Search` selector ambiguously matched the tab's own intro
paragraph (which also contains the word "search") before the actual Search button, making it
look like the search feature was silently no-op'ing (0 rows) until the selector was scoped to
`button:has-text("Search")` — worth noting for whoever next drives this page via a headless
script. Console clean of anything from this phase's own code (only the same TLS-proxy/cert noise
prior phases documented). The LAN dev DB (`192.168.50.119`) was never touched — confirmed via
`git diff` on `appsettings.json` showing zero changes throughout this session.

**Closes the Phase 1/2 carried-forward item:** `User` still isn't registered in
`objectConfigs.tsx` (unchanged — deliberately not attempted, since `DESIGN.md` §0's own reasoning
for why this module exists at all is that `User`'s moderation needs don't fit the generic
column-filter dashboard), but `/admin/users`'s row-links into `PlayerProfilePage.tsx` **are** the
generic-dashboard-free entry point that item was always waiting on — confirmed live above. No
longer an open item.

**Closes `DESIGN.md` §7 item 2 / this file's §5 item 2 (presence-tracking mechanism).** All
`DESIGN.md` §7 open items are now resolved — this module is feature-complete pending only the
carried-forward verification gaps named above (a real `knk-paper` Gradle build, and a real
Minecraft client join/quit pass), neither of which blocks anything else in the project.

**Next:** none required for this module. If picked up again: (a) a real `./gradlew build` +
live-server join/quit test for the plugin side, from a machine that can reach
`repo.papermc.io`; (b) consider a groupless "currently online" endpoint if the developer wants a
server-wide online roster rather than the shipped group-scoped one (decision 2 above); (c) the
`AuditLogRetentionConfiguration` 180-day default is still worth a second look (carried from the
retention-policy session, unrelated to this phase).
