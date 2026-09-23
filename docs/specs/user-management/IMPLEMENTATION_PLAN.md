# User Management — Implementation Plan (Tailored Admin Module)

**Status:** Draft — sequenced, but blocked on `docs/specs/user-features/IMPLEMENTATION_PLAN.md`
Phase 1 (the resolution engine + `permissions/effective` endpoint) actually shipping. Design is
final; §5 open items are implementation detail, not blockers to *starting design/frontend
scaffolding*, but do block finishing Phase 3.
**Last updated:** 2026-09-23

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

1. Premium-tier UI flag (`IsPremiumTier` field vs. naming convention) — needed before Phase 1's
   `profile-summary` endpoint finalizes its response shape.
2. Presence-tracking mechanism — needed before Phase 3 starts.
3. Audit log retention policy — needed before Phase 2 ships to production, not before it's
   built.
4. `profile-summary` as one aggregate endpoint vs. several parallel calls — current plan assumes
   the aggregate; flag if the developer wants to reconsider before Phase 1 locks in the DTO
   shape.
