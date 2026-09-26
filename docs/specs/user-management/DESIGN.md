# User Management — Design (Tailored Admin Module)

**Status:** All four phases shipped 2026-09-24. Phase 1 (§2, composite player-profile view) and
Phase 2 (§3 quick actions + §4 audit log) — see `IMPLEMENTATION_PLAN.md`'s "Phase 1 status" and
"Phase 2 status". Phase 3 (§5, moderation search/filters) — see "Phase 3 status". All §7 open
items now resolved: item 1 (premium-tier UI flag) via user-features Phase 5; item 2 (presence
tracking) via a dedicated `PUT /api/users/{id}/presence` endpoint, resolved as part of Phase 3 —
see below; item 3 (audit log retention policy) via `IMPLEMENTATION_PLAN.md`'s "Audit log
retention status"; item 4 (aggregate endpoint vs. several calls) via Phase 1 shipping the
aggregate. This module is feature-complete; see `IMPLEMENTATION_PLAN.md`'s "Phase 3 status" for
what a future session might still pick up (none of it blocking).
**Last updated:** 2026-09-25 (§8 in-game front end + actor attribution note, InventoryMenu content
port). Previously updated 2026-09-24 (Phase 3 implementation session), 2026-09-24
(audit log retention policy session), 2026-09-24 (Phase 2 implementation session), 2026-09-24
(Phase 1 implementation session).

Ref: `docs/vision/vision.md` §5. Sources: `docs/specs/user-features/DESIGN.md` +
`IMPLEMENTATION_PLAN.md` (the rank/permission/progression data model this module is a UI over),
a direct read of `knk-web-app`'s generic admin-dashboard system (`ObjectDashboard`,
`PagedEntityTable`, `objectConfigs.tsx`, `metadataClient`/`useEntityMetadata`,
`DisplayWizard`/`FormWizard`) and `knk-web-api`'s `Models/User.cs` (2026-09-23).

## 0. Why this is a separate feature, not a phase of `user-features`

`knk-web-app` already has a fully generic admin path: any `[FormConfigurableEntity]`-annotated
model automatically gets a paged, filterable table (`ObjectDashboard`/`PagedEntityTable`,
driven by `EntityMetadataDto` from `metadataClient`) plus create/edit/delete via `FormWizard`.
Once `User`, `PermissionGroup`, and `PermissionGrant` are annotated per the `user-features`
plan, **they already show up there for free** — flat CRUD needs no new work.

What that generic system cannot express is anything that isn't "one row of one entity type":
- A single **composite view** of everything about one player — account, resolved permissions,
  title/XP, premium tier, salary state — spanning `User`, `PermissionGrant`,
  `UserPermissionGroup`, and the title/salary fields on `User`, in one page.
- **Quick actions** that are really a sequence of writes across those tables (assign a group +
  see the effect immediately), not a single entity's create/edit form.
- An **audit/history log** — a new concept with no existing entity or endpoint anywhere in the
  codebase today (confirmed: `Models/User.cs`'s own doc-comments say mutations are "logged to
  audit trail," but no `AuditLog`/`AuditEntry` entity or service exists — that comment describes
  an intent, not a built system).
- **Moderation-oriented search** ("everyone in group X," "premium tiers expiring this week,"
  "currently online staff") — cross-entity queries the generic per-entity table's column
  filters can't do, and "currently online" has no backing data today either (confirmed: no
  `IsOnline`/`LastSeenAt` field exists on `User` — `knk-plugin`'s `PlayerListener` already
  hooks join/quit events, it just doesn't report them anywhere durable yet).

This is real, standalone scope — new aggregate backend endpoints, a new audit entity/service,
new online-presence tracking, and dedicated frontend views — not a natural sub-phase of the
permission engine itself. Confirmed with the developer: separate spec, sequenced after
`user-features` Phase 1 (the resolution engine + `permissions/effective` endpoint this module
is built on).

## 1. Scope — confirmed priorities (all four, in this order)

1. **Composite player profile view** — the core deliverable; everything else surfaces from here.
2. **Group/grant quick actions** — assign/revoke group, grant/deny a node with optional expiry,
   directly from the profile view.
3. **Audit/history log** — who changed what, when, for which player.
4. **Moderation-oriented search/filters** — find-players-by-state views.

All four were explicitly requested; none are cut. §6 sequences them into phases rather than
building all four simultaneously.

## 2. Composite player profile view

One page per player (`/admin/users/:id`, distinct from the generic `/objects/user/:id` FormWizard
edit screen — this is a read-first dashboard, not a form), assembled from:
- **Account** — `User`'s existing fields (username, email, linked Minecraft UUID, coins/gems,
  created date) — same data `AccountManagementPage.tsx` shows for self-service, reused here for
  admin viewing of *other* players.
- **Permissions** — calls `GET /api/users/{id}/permissions/effective` (from `user-features`
  Phase 1) to show the full resolved grant set: which nodes are granted/denied, and whether each
  comes from the player's own direct grants or from a specific group (with that group's name
  linked). This is the "what can this player actually do" view vision's LuckPerms-equivalent
  bar implicitly demands but the generic `PermissionGrant` table alone can't show (a flat table
  of grants doesn't resolve inheritance or wildcards for you).
- **Groups** — the player's current `UserPermissionGroup` memberships, with expiry countdowns
  where set.
- **Title/XP** — current title, XP total, progress toward the next bracket (or prestige-only
  display past the final one, per `user-features` `DESIGN.md` §3).
- **Premium tier** — which premium `PermissionGroup`(s) are active and their expiry, surfaced
  distinctly from other groups even though they're the same underlying entity (per
  `user-features` `DESIGN.md` §4/§5, premium tiers are just `PermissionGroup` rows — this view
  is where that fact needs a UI-level "these are the premium ones" distinction, likely a
  `IsPremiumTier` flag on `PermissionGroup` or a naming convention the frontend filters on; see
  §7).
- **Salary** — last payout time, current effective multiplier (global × personal × rank,
  broken down), `PersonalSalaryMultiplier` (editable inline).
- **Owner/staff-mode** — current vanish/mode state (now persisted per `user-features`
  `DESIGN.md` §6.1), with a toggle here as an alternative to the in-game command.

Backend: this view is a genuine aggregate — either one new `UsersController` endpoint
(`GET /api/users/{id}/profile-summary`, composing calls the service layer already makes
internally) or several parallel frontend calls to existing per-concern endpoints. Recommend the
former: one round trip, one place to keep in sync as the underlying model evolves, and it
mirrors how `permissions/effective` is already a purpose-built aggregate rather than the
frontend stitching together raw `PermissionGrant` rows itself.

## 3. Group/grant quick actions

From the profile view:
- Assign/remove a `UserPermissionGroup` membership (with optional expiry), via a picker over
  existing `PermissionGroup`s — thin wrapper over the same service the generic FormWizard CRUD
  uses, not a parallel code path (per `user-features` `DESIGN.md` §6.2's "same service layer"
  principle).
- Grant/deny a single `PermissionGrant` node directly on the player, with optional expiry —
  same underlying write, tailored input (a node-name field with autocomplete over known nodes,
  rather than the generic form's raw entity fields).
- Toggle owner/staff-mode remotely (writes the same field the in-game command does).
Every action here re-fetches `permissions/effective` afterward so the admin sees the resolved
result immediately, not just "the write succeeded."

## 4. Audit/history log

New scope, no existing precedent:
- `Models/AuditLogEntry.cs` — `Id`, `Timestamp`, `ActorUserId` (who made the change — nullable
  for system-initiated changes like an automatic salary payout or expiry), `TargetUserId`,
  `Action` (enum or string: GroupAssigned, GroupRemoved, GrantAdded, GrantRemoved,
  TitleChanged, VanishToggled, SalaryPayout, ...), `Details` (JSON or text — before/after
  values), not `[FormConfigurableEntity]`-driven (it's append-only, viewed not edited).
- Write path: the same services from §3 (and the `user-features` plan's `TitleService`/
  `SalaryService`) each write one `AuditLogEntry` per mutation — this needs to be threaded
  through those services as they're built in the `user-features` plan, not bolted on after, so
  flag this dependency back to that plan's Phase 1/§4/§5/§6 implementers.
- Read path: `GET /api/audit-log?targetUserId=...` (or `actorUserId=...`), paged, plus a section
  on the profile view showing recent history for that player.

## 5. Moderation-oriented search/filters

- "All users in group X" — a query endpoint filtering by `UserPermissionGroup`, surfaced as a
  dedicated view (not just a column filter on the generic `User` table, since group membership
  isn't a flat column on `User`).
- "Premium tiers expiring within N days" — query over `UserPermissionGroup.ExpiresAt` scoped to
  premium-flagged groups.
- "Currently online staff" (or players generally) — requires new online-presence tracking:
  `knk-plugin`'s existing `PlayerListener` join/quit hooks report to a new
  `POST /api/users/{id}/presence` endpoint (or reuse a lighter mechanism — see §7), backing an
  `IsOnline`/`LastSeenAt` field. This is genuinely new infrastructure, not a UI-only feature.
- "Recently demoted players" — query over the audit log (§4) filtered to `TitleChanged` entries
  where the direction was a demotion.

## 6. Sequencing (this module's own phases)

1. Composite player profile view (§2) + the `profile-summary` aggregate endpoint — the
   foundational deliverable, depends only on `user-features` Phase 1 being done.
2. Quick actions (§3) — layers directly onto §1's page.
3. Audit log (§4) — needs to be wired into `user-features`'s services as they're built, so in
   practice this phase's write-side work happens *alongside* `user-features` Phase 1/4/5/6, even
   though the read-side UI here comes later. Flag this cross-plan dependency explicitly when
   picking up either plan.
4. Moderation search/filters (§5) — last, since "currently online" needs new plugin-side
   presence reporting that nothing else in either plan currently requires.

## 7. Open questions

1. ~~**Premium-tier UI distinction**~~ — **resolved 2026-09-24** (user-features Phase 5):
   `PermissionGroup.IsPremiumTier` bool, not a naming convention. The resolved current tier is
   already on `UserDto`/`UserSummaryDto` (`premiumTierGroupId`/`premiumTierName`/
   `premiumTierExpiresAt`), and `GET /api/UserPermissionGroups?userId=` lists every membership
   with `isPremiumTier`/`isActive`. See `docs/specs/user-features/IMPLEMENTATION_PLAN.md` "§5 status".
2. ~~**Presence tracking mechanism**~~ — **resolved 2026-09-24**: a dedicated
   `PUT /api/users/{id}/presence` endpoint, not a periodic sync — confirmed by reading
   `UsersDataAccess` (knk-plugin) that no periodic sync loop exists for users, only an on-demand
   refresh when a cached lookup is found stale, so there was nothing to piggyback on.
   `knk-plugin`'s `PlayerListener.onJoin`/`onLeave` call it directly via a new
   `UsersCommandApi.setPresenceById`, matching the existing `setCoinsById`/
   `setGatePassThroughMethodById` per-user-id PUT pattern. "Currently online" is therefore
   real-time-ish (set the instant a player joins/quits), not lagged behind a sync interval. See
   `IMPLEMENTATION_PLAN.md`'s "Phase 3 status" for the full writeup.
3. ~~**Audit log retention/volume**~~ — **resolved 2026-09-24**: `AuditLogRetentionConfiguration`
   singleton (admin GET/PUT `/api/AuditLogRetentionConfiguration`, default 180 days), read fresh
   on each run by the existing `RetentionPolicyService` (which already handled
   `FormSubmissionProgress` cleanup) and used to hard-delete `AuditLogEntry` rows older than the
   configured window. No archival step — `AuditLogEntry` has no FK relationships by design, so a
   straight delete matches this item's own "dropped after N months" framing. See
   `IMPLEMENTATION_PLAN.md`'s "Audit log retention status" for the full writeup.
4. ~~**`profile-summary` endpoint vs. several parallel calls**~~ — **resolved 2026-09-24**: built
   as one aggregate endpoint (`GET /api/users/{id}/profile-summary`), per the confirmed
   recommendation. See `IMPLEMENTATION_PLAN.md`'s "Phase 1 status".

## 8. In-game front end (InventoryMenu Player manager) and staff actor attribution — 2026-09-25

Added by the InventoryMenu content port (`docs/specs/inventory-menu/CONTENT_PORT_PLAN.md` CP7/CP8,
branch `claude/menu-content` in knk-web-api/knk-plugin, **not merged, not live-verified**):

- **In-game Player manager** (`/menu` → Player manager tile, node `knk.admin.user.manage`): templates
  `users.manager` (online players the viewer outranks), `users.manager.edit` (coins/gems/XP steppers
  with a per-session step size, title, groups, owner/staff mode, salary payout, freeze, kick/ban),
  `users.manager.titles`, `users.manager.groups`. It is a front end over the same endpoints as §3 —
  through knk-plugin's new `UserAdminService`, which `/knk user` and `/freeze`/`/unfreeze` now also
  call (one code path). Kick/ban run Paper's own `/kick`/`/ban` as the staff member. New plugin nodes:
  `knk.admin.user.manage`, `knk.admin.user.mode`, `knk.admin.user.salary`.
- **Actor attribution (§4's `ActorUserId`) for plugin-originated changes — partly done.** The plugin
  now sends `X-Acting-User-Id: <staff user id>` on every `UsersCommandApi` call made for `/knk user`,
  `/freeze` and the Player manager (`UsersCommandApi.withActor`). **knk-web-api does not honour it
  yet:** the plugin's calls are anonymous (no API-key authentication exists in the API — only JWT),
  so trusting the header would let any caller forge the audit actor. Until the owner picks how the
  plugin authenticates (CONTENT_PORT_PLAN.md CP7 status lists the options), plugin-made changes keep
  a null `ActorUserId` exactly as before. `POST /api/users/{id}/salary/payout` also takes no actor at
  all today.

