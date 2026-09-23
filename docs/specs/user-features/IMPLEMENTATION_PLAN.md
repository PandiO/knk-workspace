# User Features — Implementation Plan (Rank/Permission/Progression)

**Status:** Draft — phased plan, ready to start Phase 1. Open items in §7 are
implementation-detail questions, not blockers.
**Last updated:** 2026-09-23

Ref: `docs/vision/vision.md` §5. Sources: `docs/specs/user-features/DESIGN.md` (architecture,
all decisions resolved), `docs/specs/user-features/COMMAND_PERMISSION_SCAN.md` (v1/v2/v3
node inventory), `docs/specs/legacy/user-system.md` (v1/v2 legacy mining), a direct read of
`knk-web-api`'s `Models/User.cs`/`Models/Category.cs` and `knk-plugin`'s
`listeners/PlayerListener.java`/`utils/ScoreboardUtil.java`/`commands/KnkAdminCommand.java`/
`plugin.yml` (2026-09-23, confirming DESIGN.md §0's greenfield claim and the exact
leftover-check line numbers all still hold — `PlayerListener.java:140/171/190`,
`ScoreboardUtil.java:51`).

## 0. What this plan does not re-litigate

Every architectural question is closed — see `DESIGN.md` §7 for the decision record. This
document is sequencing and per-repo scope only. If something below conflicts with `DESIGN.md`,
`DESIGN.md` wins; flag the conflict rather than silently picking one.

## 1. Cross-repo entity/API surface (built once, used by every phase)

**knk-web-api:**
- `Models/PermissionGroup.cs`, `Models/PermissionGrant.cs`, `Models/UserPermissionGroup.cs`
  (join entity) — per `DESIGN.md` §2.1 shape, `[FormConfigurableEntity]`/`[RelatedEntityField]`
  annotated per existing convention.
- EF migration adding the three tables + FK from `UserPermissionGroup` to `User`/
  `PermissionGroup`.
- `PermissionGroupsController`, `PermissionGrantsController` (CRUD, matching
  `CategoriesController`/`ItemBlueprintsController` shape).
- `PermissionResolutionService` — the actual resolution engine (§2.2 of DESIGN.md): given a
  `User` and a node, walk direct grants → group memberships (by weight) → each group's
  inheritance chain → wildcard-match at each level → return grant/deny/undeclared. This is the
  one piece of logic every other phase depends on; gets its own unit test suite (multi-group,
  inheritance chain, wildcard vs. exact precedence, expired grant/membership exclusion).
- `Dtos/PermissionCheckRequestDto`/`PermissionCheckResponseDto` + a lightweight
  `GET /api/users/{id}/permissions/check?node=...` endpoint — this is what `knk-plugin` calls
  per permission check, so it needs to be cheap (cached response, short TTL) rather than
  re-walking the whole resolution chain over REST on every `hasPermission`-equivalent call.

**knk-plugin:**
- `knk-core`: `PermissionHolder`/`PermissionCheckResult` domain types (Bukkit-free, mirroring
  the `MenuTemplateAssembler`-style separation already used for InventoryMenu).
- `knk-api-client`: `PermissionApi` port + impl, DTOs, mapper — same shape as
  `UserAccountApi`.
- `knk-paper`: `dataaccess/PermissionsDataAccess` (cache-first, per `DataAccessFactory`'s
  existing per-entity `FetchPolicy` convention — short TTL given permission checks are
  latency-sensitive and happen constantly), and a `KnkPermissible`-style helper that call
  sites use instead of raw `Player.hasPermission(...)` for anything going through the new
  model (raw Bukkit `hasPermission` stays for genuinely Bukkit-native nodes if any remain
  after §2 below).

**knk-web-app:**
- `apiClients/permissionGroupClient.ts`, `permissionGrantClient.ts` (per-resource REST client
  pattern, per `itemBlueprintClient.ts` precedent).
- `FormConfiguration` seed entries for `PermissionGroup`/`PermissionGrant` admin screens
  (`Category`/`ItemBlueprint` FormConfig precedent — live authoring, no seeder mechanism
  exists in this codebase, matching the Items plan's finding).

## 2. Legacy-check migration + `/knk` granularity (knk-plugin only, depends on §1's resolution API)

Per `DESIGN.md` §2.3/§6.1, confirmed in scope:
- Replace the four dead `k&k.*` checks:
  - `PlayerListener.java:140` (`k&k.join.owner`) → `knk.mode.owner` via `KnkPermissible`
  - `PlayerListener.java:171`, `:190` (`k&k.owner`) → same
  - `ScoreboardUtil.java:51` (`k&k.*` wildcard) → resolved owner-status lookup via
    `PermissionResolutionService`, not a raw wildcard string check
- Split `KnkAdminCommand.java`'s subcommands off the single `knk.admin` node onto
  `knk.admin.<subcommand>` (`knk.admin.towns`, `knk.admin.gate`, etc.), declared in
  `plugin.yml` with `knk.admin` kept as a parent/umbrella node so existing `op`-based grants
  don't regress.
- Declare `knk.tasks` in `plugin.yml` while touching this file (currently used at a call site
  but never declared — a pre-existing gap unrelated to this feature, cheap to fix here).

## 3. Owner-mode / staff-mode commands (knk-plugin, depends on §2)

Rebuild `/ownermode`, `/staffmode` (vision §5.5) as first-class commands using
`KnkPermissible`. State: v1 kept this in static maps (not persisted) — carry that forward
unless the developer wants vanish state to survive a restart (flagged §7).

## 4. Title/XP track (knk-web-api service logic + knk-plugin display, depends on §1)

- `TitleService` (web-api): given a `User.ExperiencePoints`, resolve the current title
  bracket. Jump-to-target on any XP change (`DESIGN.md` §3) — no tick-based catch-up.
- Seed the title/XP bracket table itself — v1's thresholds at 5/10/12/15 are the starting
  point (see §7 for confirming exact numbers/names for v3).
- Demotion path reuses the same bracket-resolution logic in reverse when XP is deducted for
  misconduct (ties to vision §6 — moderation — out of scope here beyond exposing the
  deduction hook).
- Plugin-side: display title alongside prestige XP (past-final-title climbing, vision §5.2)
  in scoreboard/tab list — reuses whatever `ScoreboardUtil` already renders `User` stats
  through.

## 5. Premium tier track (knk-web-api + knk-plugin, depends on §1)

- Premium tiers are modeled as `PermissionGroup` rows (e.g. "Premium Bronze/Silver/Gold"),
  not a separate entity — per `DESIGN.md` §4, this is what makes the `PermissionGrant.ExpiresAt`
  field double as the temporary-tier-with-restore mechanism (v1's `DonatorTemp`/
  `previousDonatorID` precedent) for free: expiring a `UserPermissionGroup` membership just
  drops the player back to whatever their remaining groups grant, no separate "restore"
  bookkeeping needed.
- Admin UI for assigning/granting premium tiers is the same `PermissionGroup`/
  `UserPermissionGroup` CRUD from §1 — no premium-specific screen needed beyond maybe a
  convenience filter.
- Depends on account linking (already shipped, confirmed — `DESIGN.md` §4) for tying a web
  purchase/grant action to the correct in-game `User` row; no new linking work.

## 6. Salary system (knk-web-api, mostly independent of §1-5 — can run in parallel)

- `SalaryConfiguration` (global multiplier, admin-editable via web app) +
  `Models/User` gets a `LastSalaryPayoutAt` (or similar) timestamp field.
- `SalaryService`: on player join, if `now - LastSalaryPayoutAt >= 1 hour`, pay out the
  covered gap (vision §5.4's offline-gap fix) scaled by global × personal × rank-based
  multipliers. Rank-based multiplier reads the player's resolved `PermissionGroup` memberships
  from §1 — this is the one place Salary actually depends on the permission model rather than
  being fully independent; everything else here (config CRUD, the payout timer/hook) can be
  built and tested against a stub multiplier before §1 lands if sequencing needs it.
- Personal multiplier: per-user override field (see §7 for whether this needs its own
  admin-editable field or can be modeled as a `PermissionGrant`-style flag).

## 7. Open items surfaced while writing this plan (implementation detail, not blocking)

1. Exact title bracket thresholds/names for v3 — port v1's 5/10/12/15 as-is, or set new
   numbers/titles now that the mechanic is being rebuilt?
2. Should owner/staff-mode vanish state persist across a server restart (v1 didn't), or is
   in-memory-only still acceptable for v3?
3. Salary's "personal multiplier" — a plain field on `User`, or modeled through the permission/
   grant system for consistency with rank-based multipliers?
4. `PermissionGrant.HolderId` is currently polymorphic-by-`HolderType` rather than a real FK
   (§1) — acceptable for v1 of this feature, or worth a shared `PermissionHolder` base table
   (with `User`/`PermissionGroup` as subtypes) to get real referential integrity? The Items
   plan's `Domain`/TPT precedent (`Town`/`District`/`Structure`) is the direct analog if so —
   flagging since it's a bigger schema decision than the rest of this plan.
5. Should the `GET /api/users/{id}/permissions/check` endpoint be paired with a full
   `GET /api/users/{id}/permissions/effective` (resolved permission set) for the web app's own
   admin UI to show "what can this player currently do," or is per-node checking sufficient
   for v1 of the admin screens?

## 8. Suggested sequencing

1. §1 (entities/API/resolution engine) — foundation, nothing else can start without it.
2. §2 (legacy-check migration + `/knk` granularity) and §6 (salary config/payout scaffolding,
   stubbed multiplier) can run in parallel once §1's schema is settled, even before the full
   resolution engine is wired everywhere.
3. §3 (owner/staff-mode commands) after §2.
4. §4 (title/XP) and §5 (premium tiers) after §1 is fully wired — both are direct consumers
   of the resolution engine and `PermissionGroup` model.
5. Web app admin UI (FormConfig screens from §1) can be built in parallel with §2-§5 once the
   controllers exist, same pattern as the Items plan.
