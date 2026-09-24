# User Features — Implementation Plan (Rank/Permission/Progression)

**Status:** Phases 1-5 (§1-§5) shipped — see "§1 status", "§3 status", "§4 status" and "§5 status"
below (§2's writeup is its `ACTIVE_SESSIONS.md` entry). §6 (salary) not started, ready whenever
picked up (all open questions resolved, §7 is a decision record, not a blocker list).
**Last updated:** 2026-09-24 (Phase 5 implementation session added "§5 status" and the
"v1 Titles backup search" note under §4 status; earlier the same day, the Phase 4 session added
"§4 status" and a branch-hygiene pass added the "Branch convention" section below).
Previously updated 2026-09-23 (Phase 3 implementation session added "§3 status"; earlier the same
day, the Phase 1 implementation session and the design revision:
`PermissionGrant.HolderId` is now a real FK into a shared `PermissionHolder` base table rather
than polymorphic; salary's personal multiplier is a plain `User` field; title thresholds port
v1's 5/10/12/15 as-is; owner/staff-mode vanish state persists across a restart; the tailored
user-management admin module is confirmed a separate feature — see `docs/specs/user-management/`,
which this plan's Phase 1 now unblocks)

**Branch convention (starting 2026-09-24):** this feature uses exactly **one standing branch per
repo, `claude/user-features`**, for every remaining phase (§5, §6, and anything after). Do
**not** create a new per-phase branch name. Every future session picks up on `claude/user-features`
and commits directly onto it. This replaces the old per-phase-branch-name pattern
(`claude/user-features-phase1-*`, `-phase2-*`, `-phase3-*`, `-docs-scan-*`), which caused every
phase so far to be handed a fresh branch forked from a stale base, requiring a fast-forward
fix-up before work could start (see the Phase 2/Phase 3 entries in `ACTIVE_SESSIONS.md` for the
recurring pattern this was meant to stop). As of this pass: `knk-plugin`, `knk-web-api`, and
`knk-workspace` each have a `claude/user-features` branch created from the (verified, strict-
ancestor) Phase 3 tip; `knk-web-api`/`knk-plugin`/`knk-workspace`'s old phase1/phase2/phase3/
docs-scan branches are redundant and should be deleted once repo push permissions allow it (blocked
this session by a destructive-git-operation guard — flagged to the developer). `knk-web-app` has no
`claude/user-features` branch yet; create one only when a future phase actually needs to touch
that repo. The historical "Recently completed" rows below for Phases 1-3 are left as-is — they
correctly record which branch existed at the time work was done — this is a forward-looking policy
note, not a rewrite of history.

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
- `Models/PermissionHolder.cs` — new TPT base class, `Id`/`ChatPrefix`/`ChatSuffix` (per
  `DESIGN.md` §2.1). `Models/User.cs` changes to `class User : PermissionHolder` and
  `Models/PermissionGroup.cs` is `class PermissionGroup : PermissionHolder`, same pattern as
  `Town`/`District`/`Structure : Domain`. This is the one schema change here with real
  migration risk: `User` already has many inbound FKs from other tables (everything currently
  pointing at `User.Id`) — TPT keeps `Id` as the shared PK so those FKs are unaffected, but the
  migration needs to be written and tested carefully against a real DB copy before applying,
  not just trusted to "just work" the way the Items plan's `Domain` precedent did on a
  from-scratch entity.
- `Models/PermissionGrant.cs` — `HolderId` is now a real FK to `PermissionHolder.Id` (not
  polymorphic — confirmed, `DESIGN.md` §1).
- `Models/UserPermissionGroup.cs` (join entity) — per `DESIGN.md` §2.1 shape,
  `[FormConfigurableEntity]`/`[RelatedEntityField]` annotated per existing convention.
- EF migration: the `PermissionHolder` TPT split for `User`, plus new `PermissionGroup`/
  `PermissionGrant`/`UserPermissionGroup` tables and their FKs.
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
- `GET /api/users/{id}/permissions/effective` — the full resolved permission set (every node,
  its source holder, and whether it's a grant/deny), not just a single-node check. Confirmed
  needed (§7 item 5) as a direct requirement of the separate user-management admin module's
  composite player-profile view — build it here rather than bolting it on later.

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

### §1 status — shipped 2026-09-23

Both repo bullets above are done. knk-web-api: `PermissionHolder`/`PermissionGroup`/
`PermissionGrant`/`UserPermissionGroup` entities, the TPT migration (verified end-to-end against
a real local MySQL 8.0 copy with pre-existing data — see the full writeup in `ACTIVE_SESSIONS.md`
under "User features Phase 1" in the "Recently completed" table), `PermissionResolutionService`
(22 unit tests + a live 4-level group-chain smoke test), `PermissionGroupsController`/
`PermissionGrantsController`, and the `permissions/check`/`permissions/effective` endpoints.
knk-plugin: knk-core domain types + `PermissionsApi` port + `PermissionsDataAccess` gateway,
knk-api-client DTOs/mapper/impl wired into `KnkApiClient`, knk-paper config/wiring (its own
short-TTL cache entry, unlike the other 11 entities — see backlog item 9 below). Branches:
knk-web-api `claude/user-features-phase1-sg4rjw`, knk-plugin `claude/user-features-phase1-si2v8g`
(neither merged to main/master yet).

**Gaps intentionally left open, carried forward for whoever picks up the next phase:**

1. **[Closed by §5, 2026-09-24 — `UserPermissionGroupsController` now exists; see "§5 status".
   The web-app UI and §6.2's in-game commands still need building on top of it.]**
   **No `UserPermissionGroup` CRUD endpoint or UI exists yet** — there is currently no API path
   to assign a user to a group. §1's own knk-web-api bullet lists the entity but no dedicated
   controller (unlike `PermissionGroup`/`PermissionGrant`, which both got one); the knk-web-app
   bullet only lists `permissionGroupClient`/`permissionGrantClient`, not a membership client.
   Membership authoring is squarely §6.2's job ("in-game: assigning a player to a group... calls
   the same service layer the web app CRUD uses"), so this isn't a bug, just worth flagging
   explicitly rather than discovering it by surprise later: **whoever builds §6.2 needs to decide
   and build this from scratch** (a `UserPermissionGroupsController` following the
   `PermissionGroupsController` shape is the most direct option, but a nested
   `PermissionGroup.Members`/`User.PermissionGroupMemberships` FormWizard M2M step, matching the
   `Category.Tags` precedent from the Items plan, is the more idiomatic fit for the "web app" half
   of §6.2's authoring surface — an implementation-time call, not decided here). This session's
   own live verification seeded one test membership via raw SQL directly against the database,
   confirming the resolution engine itself has no issue consuming memberships once they exist —
   only the authoring path is missing.
2. **No `KnkPermissible`-style `Player.hasPermission(...)` replacement helper exists yet**, even
   though the original knk-plugin bullet for §1 named one ("a `KnkPermissible`-style helper that
   call sites use instead of raw `Player.hasPermission(...)`"). Not built this session because no
   call site needs it yet — §2 below (the four dead `k&k.*` checks, `/knk`'s per-subcommand nodes)
   is its first real consumer. **Whoever picks up §2 should build this helper as that phase's
   first step**, backed by `PermissionsDataAccess.checkAsync(userId, node)` (already shipped),
   before rewiring `PlayerListener`/`ScoreboardUtil`/`KnkAdminCommand` onto it.
3. **A real, pre-existing bug in `DataAccessFactory` was found while wiring `PermissionsDataAccess`**
   (unrelated to this feature, not fixed here) — every other entity's configured cache TTL in
   `config.yml` is silently ignored; only `PermissionsDataAccess` reads its own TTL correctly.
   Tracked as `docs/backlog/QOL_BUGFIX_BACKLOG.md` item 9, not this plan's problem to fix.

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

## 3. Owner-mode / staff-mode commands (knk-plugin + knk-web-api, depends on §2)

Rebuild `/ownermode`, `/staffmode` (vision §5.5) as first-class commands using
`KnkPermissible`. State **persists across a server restart** (confirmed, `DESIGN.md` §6.1) —
not v1's in-memory-only maps:
- `Models/User.cs` gets an `IsVanished`/`ActiveMode`-style field, part of the same migration
  as §1's `PermissionHolder` split (both touch `User` — sequence together, one migration, not
  two).
- On login, the plugin reads this field back and re-applies vanish state rather than defaulting
  everyone visible after a restart.

### §3 status — shipped 2026-09-23

Both repo bullets are done, on branch `claude/user-features-phase3-v8rmws` in knk-web-api (forked
from §1's unmerged `claude/user-features-phase1-sg4rjw`) and knk-plugin (forked from §2's unmerged
`claude/user-features-phase2-fvx5qj`). Full verification writeup: `ACTIVE_SESSIONS.md`, "User
features Phase 3" in the "Recently completed" table.

**Field shape decided (DESIGN.md §6.1 left it open):** a single `User.ActiveMode` enum
(`None`/`Staff`/`Owner`, `int` column, default `0`) — no separate `IsVanished` flag. v1 never
vanished a player outside a mode and the two modes were effectively exclusive (v1's `/staffmode`
refused co-owners/owners), so vanish is simply `ActiveMode != None`. Written only via a dedicated
`PUT /api/users/{id}/active-mode`; ignored by the generic `UserDto`→`User` update mapping so a
web-app edit that omits it can't silently un-vanish a player. Exposed on `UserSummaryDto`, which
is what the plugin already fetches at pre-login, so restoring on join needs no extra round trip.

**Migration decision — standalone, not held for §6.** §8's "one shared `User` migration for
§1/§3/§6" was already moot for §1 (shipped and migrated separately). Holding §3's column for §6
would have blocked this phase on one nobody has claimed, to save one trivially additive
`AddColumn` — two independent additive columns carry no real ordering risk (the only friction is a
model-snapshot conflict if §6 is developed in parallel off an older base, fixed by regenerating
§6's migration after rebasing). So `AddUserFeaturesPhase3ActiveMode` shipped on its own; **§6
should just add its own additive migration too**, not try to fold into this one.

**Behavior (ported from v1's `OwnerCommands`/`User.setOwnerMode`, read directly from
`knk-v1-archive`):** `/ownermode` (`/om`), `/staffmode` (`/sm`) with v1's args (toggle, `on|enable`,
`off|disable`, `<on|off> onquit|oq`, `help`); entering a mode hides the player from everyone who
can't see vanished players and shows an action bar; join/leave messages are suppressed while
vanished; on login the persisted mode is restored (and dropped, with a message, if the player's
grant was revoked while offline). `onquit` now means "persist the new mode without applying it to
the current session", which gives exactly v1's documented effect. **Deliberate deviations from v1,
flagged:** (1) viewers who can see vanished players are holders of `knk.mode.staff` **or**
`knk.mode.owner` (v1: only `k&k.staff` — owners relied on also having it via PermissionsEx group
inheritance); (2) `/staffmode` isn't refused for owners — anyone with `knk.mode.staff` may use it;
(3) v1's combat-tag clearing on enable is not ported (v3 has no combat-tag system yet); (4) v1's
separate "ownermode"/"staffmode" scoreboard teams and all the scattered `inOwnerModus()` gameplay
checks (pickup/crafting/gate/etc.) are not ported — separate follow-ups if wanted, none are in §3's
scope.

**Gaps/bugs carried forward:**

1. **Fixed here, but it's a §2 bug worth knowing about:** `KnkPermissible.resolveUserId` read the
   user cache with `getByUuid`, which returns empty once an entry's TTL lapses — and `UserCache`
   uses the 60-second global `cache.ttl-seconds`, with nothing refreshing an online player's entry
   mid-session. So about a minute after joining, **every** `KnkPermissible` check failed closed for
   every non-op (ops were unaffected thanks to the op bypass, which is likely why nobody noticed).
   Now reads `getStale` (a UUID's knk user id never changes). Proven with the behavior simulation
   described in `ACTIVE_SESSIONS.md` — it fails without this one-line fix.
2. **Pre-existing, not fixed:** `KnKPlugin.onEnable` constructs `CacheManager` twice (once before
   `UserManager`, once again later), so `UserManager`'s "legacy" `UserCache` is an orphaned
   instance nobody else reads — `UserManager`'s `legacyUserCache.put(...)` for brand-new users
   never reaches the cache `PlayerListener`/`KnkPermissible`/`ModeService` use. Didn't affect §3
   (pre-login populates the right cache), but worth a cleanup pass.
3. **Visibility isn't re-evaluated when a viewer's permissions change mid-session** (e.g. a staff
   grant added while they're online) — only on join and whenever a vanished player's mode changes.
   Relog fixes it. Fine until §6.2's in-game grant commands exist; those should call
   `ModeService.refreshVisibilityFor(player)` after changing a player's grants.
4. **A `/reload` (or plugin re-enable) with players online** leaves them with no in-session mode
   until they relog (visible, even if persisted as vanished). Not worth handling given `/reload`
   is unsupported on Paper anyway.
5. **If the API is unreachable at pre-login**, the user cache has no entry, so the player joins
   visible (fail-open for visibility, same as v1's every-restart behavior). Accepted: failing
   closed would mean refusing the login.
6. `PUT /api/users/{id}/active-mode` with an unknown string (e.g. `"Wizard"`) returns 500 rather
   than 400 — pre-existing global JSON-binding behavior, identical on the existing
   `gate-passthrough-method` endpoint; an unknown *integer* is correctly rejected with 400.

## 4. Title/XP track (knk-web-api service logic + knk-plugin display, depends on §1)

- `TitleService` (web-api): given a `User.ExperiencePoints`, resolve the current title
  bracket. Jump-to-target on any XP change (`DESIGN.md` §3) — no tick-based catch-up.
- Seed the title/XP bracket table with v1's thresholds at 5/10/12/15, ported as-is (confirmed,
  `DESIGN.md` §7 item 10) — placeholder content, retunable later via the admin UI once it
  exists rather than a hardcoded constant.
- Demotion path reuses the same bracket-resolution logic in reverse when XP is deducted for
  misconduct (ties to vision §6 — moderation — out of scope here beyond exposing the
  deduction hook).
- Plugin-side: display title alongside prestige XP (past-final-title climbing, vision §5.2)
  in scoreboard/tab list — reuses whatever `ScoreboardUtil` already renders `User` stats
  through.

### §4 status — shipped 2026-09-24

Both repo bullets done — see `ACTIVE_SESSIONS.md`'s "User features Phase 4" row for the full
writeup. Two things worth knowing before building §5/§6 on top of this:

1. **The "port v1's 5/10/12/15" instruction above is about reward-crossing milestones, not
   bracket boundaries** — v1's `Titles` table (19 rows, `MinExp`/`MaxExp`/`Salary`/bonuses per
   title) was pure runtime DB content, never committed to source anywhere, so there was nothing
   more specific to port. `TitleBracket` seeds exactly 5 rows using 5/10/12/15 (plus an implicit
   0) as the bracket boundaries themselves, with placeholder names (Novice/Apprentice/Journeyman/
   Veteran/Master) — already anticipated as placeholder content by `DESIGN.md` §7 item 10, not a
   scope deviation.
2. **`ScoreboardUtil` has no per-player sidebar stat rendering to "reuse"** — its `Scoreboard` is
   one static instance shared by every player, so a sidebar `Objective` can't show a different
   value per viewer. Title/prestige XP is shown in the tab list footer instead (already per-player).
   Anyone adding more per-player stats to the scoreboard later hits the same constraint.

Also added `PUT /api/users/{id}/balances`, wiring the pre-existing-but-unreachable
`UserService.AdjustBalancesAsync` to an actual route — this is the "deduction hook" referenced
above, and now the only way to change a user's XP short of the DB directly.

**v1 Titles backup search (2026-09-24, Phase 5 session) — no real data found, placeholder seed
left exactly as-is.** The developer pointed at local backups that might hold v1's real `Titles`
rows. Searched every database-like file under `D:\Shared\Werk\KnightsAndKings\archive\` (39
files: `.sql` dumps, CoreProtect/LuckPerms/LiteBans DBs, zips):
- `macbook/Database/Backup_22-03-21/KnightsAndKings_Test-7.sql` (the path given): a 2021
  Hibernate-era (v2) phpMyAdmin dump — **no `Titles` table**; titles appear only as
  `town.reguired_title` ints.
- `macbook/K&K_Database.sql` (the file the original cloud-session prompt referred to, now
  materialized) and `macbook/K&K_Database`: **schema only, zero `INSERT`s.** They do confirm
  v1's column set — `ID, MaleName, FemaleName, Salary (default 250), CoinBonus (4000), GemBonus
  (2), ExpBonus (5), MinExp (25), MaxExp (34)` — but those are column defaults, not per-title
  values.
- `macbook/Database/Players_before_tutorial.sql` (Nov 2018, the real v1 production DB
  `mcph701458`): `Player.TitleID` has an FK to `Titles`, but only the `Player` table was exported.
- Every other dump (2021 `db_backup_*`, `import.sql`, `KnightsAndKings_Test-Backup-07-09-21.sql`)
  is v2-era with no title data.

So there is still nothing real to swap in; `TitleBracket` keeps its 5 placeholder rows and no
schema change was made. If v1's real 19 titles ever turn up (e.g. an older full dump of
`mcph701458`), the swap is still the schema decision flagged then: 19 rows with per-title
`MinExp`/`MaxExp`/`Salary`/bonuses and gendered names versus the current 3-column model.

**Second pass (2026-09-24, same session, developer-requested) — checked every file under
`D:\Shared\Werk\KnightsAndKings\archive\macbook` by creation date, not just database-shaped
files, on the theory that a pre-March-2021 backup might exist under a different name/format.**
Nothing dated before March 2021 is a `Titles` dump either (oldest real candidate is still the
Nov 2018 `Players_before_tutorial.sql` above — `Player` only, no `Titles`). This pass did surface
a handful of real v1 title names/ids, scattered across non-database files, worth keeping for
when the full list is available rather than re-deriving them from scratch:
- `KnightsAndKings_iphone_notes.docx`: *"Knight(5): 1e huis & 1e property, Margrave(10): 2e huis
  & 2e property, Prince(15): 3e property & 1e kasteel"* — i.e. titleID 5 = Knight, 10 = Margrave,
  15 = Prince, confirming these line up with the 5/10/15 reward-crossing milestones (not
  bracket-boundary placeholders).
- WorldGuard region `entry-deny-message` strings (2018-2019 backups) and `Region_code.docx`
  give gendered pairs at the low end: `Serf`/`Serf`, `Squire`/`Squire`, `Knight`/`Dame`.
- Donator tiers (separate from Title, per §1) confirmed as **Noble, Royal, Dragon Blood** —
  already what §5 seeded.

That's 4 of the 19 titleIDs (0/5/10/15 sequence implied, exact id for Serf/Squire unconfirmed)
plus the 3 donator names, no XP thresholds/salary/bonus numbers. **Developer decision
2026-09-24: shelve the real-title swap entirely until a full 19-row list is available** (rather
than partially seeding these 4 names) — don't revisit until then. Keep this note for whoever
picks that up: it saves re-doing this search, and the "Knight(5)/Margrave(10)/Prince(15)"
finding is a strong signal about which of the 19 land on the 5/10/15 milestones specifically.

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

### §5 status — shipped 2026-09-24

Both repos done, on the standing `claude/user-features` branch; full verification writeup in
`ACTIVE_SESSIONS.md`, "User features Phase 5". **Doc/code conflict flagged before building:** the
second bullet above assumes "the same `PermissionGroup`/`UserPermissionGroup` CRUD from §1", but
§1 never built a membership endpoint (its own gap #1, which deferred it to §6.2), so there was no
way to grant a tier. Developer decisions, confirmed before any code was written:

1. **Membership authoring built here:** `UserPermissionGroupsController`
   (`GET ?userId=` / `?permissionGroupId=`, `PUT` upsert with optional future `expiresAt`,
   `DELETE {userId}/{permissionGroupId}`, `GET premium-tier/{userId}`). One row per user+group
   (composite PK), so re-granting a tier the user already holds just changes its expiry.
   `expiresAt` is stored and returned as UTC, matching the resolution engine's `DateTime.UtcNow`.
   §6.2's in-game commands and any web-app membership screen should call this, not add a
   second path.
2. **`PermissionGroup.IsPremiumTier` bool** marks premium groups (also resolves
   `docs/specs/user-management/DESIGN.md` §7 item 1). A user's **premium tier = their
   highest-Weight active membership in a premium group**, exposed as
   `premiumTierGroupId`/`premiumTierName`/`premiumTierExpiresAt` on `UserDto`/`UserSummaryDto`.
   Group search gained an `isPremiumTier` filter (the "convenience filter" above).
3. **Seeded v1's three donator tiers** Noble/Royal/Dragon Blood (weights 10/20/30, no grants, no
   chat prefix; v1's `PrimaryColor`/`SecondColor` values aren't recoverable). This had to be raw
   SQL rather than `InsertData`: `PermissionGroup` is a TPT subtype whose id comes from
   `permission_holders`' auto-increment, which it shares with every `User`, so fixed seed ids
   would collide. A tier is skipped if a group with that name already exists.
4. **Plugin:** premium tier shown in the tab-list footer under the title line (with a UTC
   "until" date for temporary tiers). Like the title, it refreshes on join only.

**"Restore on expiry" confirmed working as designed:** a permanent Noble plus a temporary Royal
shows Royal (and resolves Royal's grants) until the Royal membership expires, then Noble shows
through again with no bookkeeping. This is v1's `DonatorTemp`/`previousDonatorID` behavior.
Note that the bullets above and `DESIGN.md` §4 say `PermissionGrant.ExpiresAt` covers this; the
field actually doing the work is `UserPermissionGroup.ExpiresAt`. `PermissionGrant.ExpiresAt`
covers temporary single-node grants.

**Carried forward:**
1. **No perks yet.** The three tiers have no `PermissionGrant`s. What premium actually grants
   (kits, stash slots, pet slots, salary multiplier per vision §5.3/§5.4) is later work; §6's
   rank-based salary multiplier is the first expected consumer of "which premium tier is this
   user".
2. **Expired memberships are kept, not deleted** (`isActive: false` in listings). They are the
   history of past temporary tiers. Nothing prunes them; add a cleanup job only if the table
   ever gets large.
3. **No web-app screen** for memberships yet (the controller exists; knk-web-app wasn't in scope).
4. **No expiry notification in-game**, and an online player whose tier expires keeps the old
   footer (and the plugin's cached permission answers, 30s TTL) until relog or cache refresh.
   Permission checks themselves go through the API, which ignores expired memberships.

## 6. Salary system (knk-web-api, mostly independent of §1-5 — can run in parallel)

- `SalaryConfiguration` (global multiplier, admin-editable via web app) + `Models/User` gets
  `LastSalaryPayoutAt` (timestamp) and `PersonalSalaryMultiplier` (decimal, default 1.0 — a
  plain field, not a permission grant, confirmed `DESIGN.md` §7 item 9) fields. Both land in
  the same `User`-touching migration as §1/§3 — three separate features all adding columns to
  `User` in one session is exactly the kind of thing worth one migration, not three.
- `SalaryService`: on player join, if `now - LastSalaryPayoutAt >= 1 hour`, pay out the
  covered gap (vision §5.4's offline-gap fix) scaled by global × `PersonalSalaryMultiplier` ×
  rank-based multipliers. Rank-based multiplier reads the player's resolved `PermissionGroup`
  memberships from §1 — this is the one place Salary actually depends on the permission model
  rather than being fully independent; everything else here (config CRUD, the payout
  timer/hook, the personal-multiplier field itself) can be built and tested against a stub
  rank-multiplier before §1's resolution engine is fully wired, if sequencing needs it.

## 7. Decision record — items resolved 2026-09-23 (second round)

These were originally open items in this plan; all resolved directly with the developer and
folded into `DESIGN.md` §7 (items 8-12) and the sections above. Kept here for traceability.

1. Exact title bracket thresholds/names → port v1's 5/10/12/15 as-is (§4).
2. Owner/staff-mode vanish persistence → persists across a restart (§3).
3. Salary's "personal multiplier" → plain `PersonalSalaryMultiplier` field on `User` (§6).
4. `PermissionGrant.HolderId` shape → real FK into a shared `PermissionHolder` base table
   (TPT, `User`/`PermissionGroup` as subtypes — same pattern as `Domain`/`Town`), not
   polymorphic (§1).
5. Whether `GET /api/users/{id}/permissions/check` needs a companion
   `GET /api/users/{id}/permissions/effective` (full resolved set) → **yes** — this is now a
   concrete requirement of `docs/specs/user-management/DESIGN.md`'s composite player-profile
   view (§1 of that doc), not an open question. Add both endpoints in this plan's Phase 1
   rather than deferring the second one.
6. Whether a tailored user-management admin module belongs in this plan → **no**, it's a
   separate feature — see `docs/specs/user-management/DESIGN.md`, sequenced after this plan's
   Phase 1 (§1 below) since it depends on the resolution engine and `/effective` endpoint that
   Phase 1 produces.

## 8. Suggested sequencing

1. §1 (entities/API/resolution engine, including the `permissions/effective` endpoint) —
   foundation, nothing else can start without it, including `docs/specs/user-management/`.
2. §2 (legacy-check migration + `/knk` granularity) and §6 (salary config/payout scaffolding,
   stubbed rank-multiplier) can run in parallel once §1's schema is settled, even before the
   full resolution engine is wired everywhere. Note the shared migration: §1 (`PermissionHolder`
   split), §3 (vanish/mode fields), and §6 (`LastSalaryPayoutAt`/`PersonalSalaryMultiplier`)
   all add to `User` in the same window — write these as one migration, not three, to avoid
   EF migration-ordering headaches on a table this central.
3. §3 (owner/staff-mode commands) after §2.
4. §4 (title/XP) and §5 (premium tiers) after §1 is fully wired — both are direct consumers
   of the resolution engine and `PermissionGroup` model.
5. Web app admin UI (FormConfig screens from §1) can be built in parallel with §2-§5 once the
   controllers exist, same pattern as the Items plan.
6. `docs/specs/user-management/` (the tailored admin module) starts once §1 ships — it's a
   separate plan from here on, not a further phase of this one.
