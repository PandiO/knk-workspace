# User Features — Design (Player Progression & Social Status)

**Status:** Ready for implementation — all open questions resolved, including the smaller
implementation-detail ones originally left in `IMPLEMENTATION_PLAN.md` §7. See
`IMPLEMENTATION_PLAN.md` for the phased build-out, and `docs/specs/user-management/` for the
separate tailored-admin-UI feature this design's data model now underpins.
**Last updated:** 2026-09-23 (second revision same day: `User`/`PermissionGroup` are now
TPT subtypes of a shared `PermissionHolder` base table rather than `PermissionGrant.HolderId`
being an unconstrained polymorphic pointer; vanish/owner/staff-mode state now persists across
a restart instead of matching v1's in-memory-only behavior; title thresholds confirmed as
v1's 5/10/12/15 ported as-is. First revision same day: all §7 open questions walked through
and resolved with the developer; verified account linking — which vision §5.4 called "not yet
merged" on a `UserFeatures` branch — is in fact already merged to `main`/`master` in all
three component repos, and confirmed no rank/tier/permission/premium/salary/title code exists
anywhere yet, so this remains close to greenfield)

Ref: `docs/vision/vision.md` §5 (Player Progression & Social Status). Sources: `docs/specs/
legacy/user-system.md` (v1/v2 legacy spec-mining), `docs/specs/user-features/
COMMAND_PERMISSION_SCAN.md` (new v1/v2/v3 command & permission inventory, 2026-09-23),
`docs/reports/plugin-scan-2026-09-21.md` (v3 codebase scan), `docs/specs/users/*` +
`docs/specs/plugin-auth/*` (existing account/auth system — adjacent, not restated here).

## 0. Scope

This document covers vision §5 only — rank/permission architecture, Title/XP progression,
Premium tiers, Salary, Owner/staff-mode, in-game rank & group management. It does **not**
cover account creation, linking, or web/Minecraft authentication — that's a separate,
already-shipped system (`docs/specs/users/`), confirmed ✅ done and merged everywhere per
`docs/reports/IMPLEMENTATION_STATUS_AUDIT.md` §1. The existing `User` entity (coins, gems,
XP, account fields) is the foundation this design builds on top of, not something it
replaces.

## 1. Decisions made explicitly for this pass

- **Title and Premium stay separate tracks**, mirroring v1's Title (earned via XP)
  vs. Donator (purchased/granted) split — not merged into one rank concept. (Resolves
  `user-system.md` open question 4.)
- **The permission system is a fully in-house build, LuckPerms-feature-equivalent, with zero
  external dependency** — not an MVP-trimmed subset. This is explicit developer intent, not
  just vision §5.1's stated rationale (engine-portability): the goal is "I want LuckPerms
  functionality, but built in-house."
- **Group-based data shape, not flattened onto `User`.** Vision §5.1's "rank/tier becomes a
  first-class concept living directly on `User`" is satisfied by `User` itself acting as a
  PermissionHolder (its own direct grants/denials) plus a many-to-many membership join to
  `PermissionGroup` — not by putting rank fields straight on the `User` row. A flat
  single-`RankId`-on-`User` shape was considered and rejected: it can't represent a player
  holding a staff group *and* a premium group at the same time, which vision explicitly
  needs.
- **Group inheritance is single-parent** (a simple chain), not multi-parent. The scenario that
  motivated asking — a player simultaneously holding a staff rank and a premium rank — is
  already covered by §2.1's many-to-many *membership* (a user just holds both groups
  directly); that's a different mechanism from *inheritance* (one group's permission set
  extending another's), which multi-membership makes unnecessary here. Each group still
  inherits from at most one parent group.
- **`/knk`'s per-subcommand permission granularity is in scope now**, not deferred — see §2.3
  and §6.1.
- **The four dead legacy `k&k.*` checks are migrated as part of this feature**, not tracked
  separately — see §2.3 and §6.
- **Title promotion jumps straight to the target level** on an XP change that crosses multiple
  brackets at once, rather than porting v1's one-level-per-tick catch-up drain — see §3.
- **Dynamic per-entity permission nodes get first-class wildcard support** in the resolution
  engine (§2.2), not a special case bolted on — the existing `customenchantments.<id>`
  pattern is the first real consumer, but the engine itself is generic.
- **Authoring surface is both web app FormConfig admin UI and in-game commands, from day
  one** — not staged. See §6.2.
- **`User` and `PermissionGroup` are both TPT subtypes of a new `PermissionHolder` base
  table**, giving `PermissionGrant.HolderId` a real, single, DB-enforced foreign key instead
  of an unconstrained `HolderType`+`HolderId` pair. Same EF Core TPT pattern already used for
  `Domain`/`Town`/`District`/`Structure` (`Town : Domain`, sharing `Domain.Id` as PK) — see §1
  for the schema note. Chosen over the simpler polymorphic shape despite the extra upfront
  migration work, since referential integrity on every permission grant matters more here than
  it did for the Items plan's `Origin` polymorphism question.
- **Owner/staff-mode vanish state persists across a server restart** — not v1's in-memory-only
  behavior. A staff member's vanish state survives a restart rather than needing to be
  re-toggled.
- **Title/XP bracket thresholds port v1's 5/10/12/15 as-is** for now (placeholder content,
  easy to retune later via the admin UI once it exists — not a design constraint).
- **Salary's personal multiplier is a plain field on `User`** (`PersonalSalaryMultiplier`,
  decimal), not modeled through the permission/grant system — it's a numeric override, not an
  access-control concept.
- **The tailored user-management admin module is a separate feature**, not a phase of this
  plan — see `docs/specs/user-management/DESIGN.md`. It depends on this design's data model
  (resolved permissions, groups, title/XP, premium tier, salary state) but is sequenced and
  scoped independently, since it's genuinely its own chunk of work (composite views, new
  aggregate endpoints, audit log) rather than a natural sub-phase of the permission engine
  itself.

## 2. Rank/Permission architecture

### 2.1 Core model — one permission-holder concept

Per vision §5.1, groups, premium ranks, and staff roles are not three mechanisms — they're
three instances of one underlying **PermissionHolder** concept: a named bundle of grants,
denials, a chat prefix/suffix, and an optional parent (for inheritance). A `User` also acts
as a PermissionHolder in its own right, so individual grants/denials layer on top of whatever
the player's group(s) already give them.

Entity shape (names indicative, `Models/` conventions — `[FormConfigurableEntity]`,
`[RelatedEntityField]`/`[NavigationPair]` per `Category.cs`/`User.cs` precedent):

- **PermissionHolder** — new base table (TPT), `Id`, `ChatPrefix`, `ChatSuffix` (the fields
  every kind of holder needs). `User` and `PermissionGroup` both become `: PermissionHolder`
  subtypes, sharing `PermissionHolder.Id` as their own PK — same pattern as `Town`/`District`/
  `Structure : Domain`. **Note:** this means `User`'s own chat prefix/suffix (if it ever gets
  a personal one, distinct from whatever its groups display) lives on the shared base row, not
  duplicated per-subtype — worth confirming at implementation time whether `User` needs its
  own `ChatPrefix`/`ChatSuffix` at all or purely inherits display formatting from group
  membership (see `IMPLEMENTATION_PLAN.md` §7).
- **PermissionGroup : PermissionHolder** — adds `Name`, `ParentGroupId` (nullable FK to
  `PermissionGroup`, single-parent inheritance — confirmed, see §1), `Weight` (int, tie-break
  for prefix/suffix display when a user is in multiple groups, LuckPerms-style, highest wins)
- **PermissionGrant** — `Id`, `HolderId` (real FK to `PermissionHolder.Id` — confirmed, see
  §1), `Node` (string, dot-path, wildcard-capable — e.g. `knk.gate.*`,
  `customenchantments.*`), `Value` (bool: true = grant, false = explicit deny), `ExpiresAt`
  (nullable `DateTime` — temporary grants, matches vision §5.1's expiry requirement for
  temporary tiers)
- **UserPermissionGroup** — join entity for `User` ↔ `PermissionGroup`, many-to-many (a player
  can hold multiple groups at once — e.g. a staff group *and* a premium-tier group
  simultaneously — confirmed, see §1), `ExpiresAt` (nullable — each membership independently
  expirable)

### 2.2 Resolution order

Standard LuckPerms-equivalent precedence, closest-wins:
1. User's own explicit grants/denials (most specific — always wins)
2. Each group the user belongs to, own node list, ordered by group `weight` (highest first)
3. Walk up each group's inheritance chain
4. Undeclared → deny (fail-closed, matches current Bukkit-default convention)

An explicit deny at any more-specific level overrides a grant at a less-specific level —
this is the "exclusions, not just grants" requirement from vision §5.1.

Wildcard matching is first-class in the resolution engine (confirmed, see §1): a node like
`knk.gate.*` or `customenchantments.*` matches any more-specific node sharing that prefix,
resolved by longest-matching-segment-prefix specificity (an exact node match beats a wildcard
match at the same holder/level). This isn't a special case for `customenchantments.<id>` —
it's the same generic mechanism vision §5.1 already asks for, and dynamic per-entity nodes are
just its first real consumer.

### 2.3 Migration relative to current v3 state

Per the command/permission scan: v3 currently has ~18 static flat nodes and no group concept
at all, so there's no existing grant table to migrate — this is close to greenfield. Confirmed
in scope for this rollout (§1), not deferred:
- The four leftover `k&k.*` checks in `PlayerListener`/`ScoreboardUtil` (dead — nothing
  grants that namespace) are ported onto the new model's owner/staff concept — see §6.1.
- `/knk`'s current all-or-nothing `knk.admin` gate is broken into per-subcommand nodes
  (`knk.admin.towns`, `knk.admin.gate`, etc.) once real groups exist to assign them to — see
  §6.1. `knk.admin` itself is kept as a wildcard-style umbrella node (existing admin grants
  keep working without redefinition) rather than removed outright.

## 3. Title / XP track

Kept as the earned-progression axis, per vision §5.2 and v1 precedent (`user-system.md`):
- Titles are level brackets keyed off an `experiencePoints` total the player already has on
  `User` (this field already exists — confirmed in `docs/specs/users/SPEC_USER.md`, just
  currently unused for any progression logic).
- Past the final title, XP keeps climbing as a pure prestige signal (vision §5.2).
- Demotion via XP deduction — kept for now, flagged `[OPEN]` in vision for a future redesign
  that decouples title from raw XP. Not re-opened here; carried forward as-is (confirmed
  staying deferred, see §1).
- Title changes (promotion or demotion) **jump straight to the target bracket** on any XP
  change, rather than porting v1's one-level-per-tick catch-up drain (confirmed, see §1) — a
  single `experiencePoints` write recomputes and applies the resulting title directly. v1's
  reward/penalty thresholds at 5/10/12/15 are ported as-is for the bracket boundaries
  (confirmed, see §1) — placeholder content, retunable later via the admin UI.

## 4. Premium tier track

Kept separate from Title, per §1's decision. Per vision §5.3:
- Renamed from "donor" to **premium**; grants real power/progress advantages, not purely
  cosmetic — an intentional, explicitly-documented-as-such direction change from the
  original 2017 no-pay-to-win stance.
- v1's temporary-tier-with-restore mechanism (`DonatorTemp`, `previousDonatorID`) is the
  closest existing precedent for the expiry support vision §5.1 requires generally — the
  `PermissionGrant.expiresAt` field in §2.1 is designed to cover this without a
  premium-specific side table.
- Account linking (web ↔ Minecraft) already underpins this per vision §5.3's note. Vision
  describes it as "not yet merged" on a `UserFeatures` branch — that's stale: confirmed
  directly (2026-09-23) that account linking is merged to `main`/`master` in all three
  component repos (`knk-web-api`'s `UserFeatures` branch was merged via commit `6b4ceb4`;
  `knk-plugin`'s `AccountCommand`/`AccountLinkCommand`/`BearerAuthProvider` link flow and
  `knk-web-app`'s `LinkCodeDisplay`/`AccountManagementPage` are all present on `main`). Not
  reopened here either way — just noting the ground truth for whoever reads this next.

## 5. Salary

Per vision §5.4, kept: hourly payout, scaled by global/personal/rank-based multipliers, all
admin-configurable via the web app. Offline-gap handling: a payout covering the gap is made
on next join if ≥1 hour has passed, rather than lost (explicit vision requirement, direct
fix for v1's silent-loss behavior — `user-system.md` doesn't document v1 handling this at
all, so this is new-in-v3 behavior, not a port).

Multiplier sourcing: global (admin-set config), rank-based (read from the player's resolved
`PermissionGroup` memberships — the one place Salary genuinely depends on §2's permission
model), and personal (a plain `PersonalSalaryMultiplier` decimal field directly on `User` —
confirmed, see §1; not modeled through the grant system, since it's a numeric override rather
than an access-control concept).

## 6. Owner-mode / staff-mode and in-game rank management

### 6.1 Owner-mode / staff-mode (vision §5.5)

Rebuild the v1 vanish-like toggle (`/ownermode`, `/staffmode`) as first-class v3 commands,
gated by the new permission model (e.g. `knk.mode.owner`/`knk.mode.staff`) instead of static
`k&k.owner`/`k&k.staff` checks. This directly replaces the four leftover legacy checks from
§2.3 (`PlayerListener.java:140/171/190`, `ScoreboardUtil.java:51`) — each is rewired to a
permission-engine lookup against the acting player's resolved grants, not a literal string
check against a dead namespace.

Unlike v1's in-memory-only state, vanish/mode state **persists across a server restart**
(confirmed, see §1) — a new `IsVanished`/`ActiveMode`-style field on `User`, restored on
login rather than defaulting off after every restart.

`/knk`'s per-subcommand breakdown (§2.3) lands in the same phase as this, since both are
"replace an ad hoc admin/owner check with a real permission node" work — see
`IMPLEMENTATION_PLAN.md` §2 for sequencing.

### 6.2 In-game rank/group management (vision §5.6)

Rebuild v1's `/user <group> <player>`-style commands against the new in-house PermissionGroup
model instead of dispatching to an external plugin — the entire reason vision §5.1 wants this
in-house in the first place. Authoring is **both** in-game commands and a web app admin UI
from day one (confirmed, see §1):
- **Web app**: `PermissionGroup`/`PermissionGrant` CRUD via the existing `FormConfigurableEntity`/
  FormWizard pattern (matching `Category`/`ItemBlueprint`/gate-structure admin screens) —
  consistent authoring surface for every other admin entity, and the natural place to browse/
  audit the full grant table.
- **In-game**: player-facing, low-latency actions a staff member does without leaving the
  game — assigning a player to a group, granting/revoking a single node, checking a player's
  effective permissions. These call the same service layer the web app CRUD uses, not a
  separate code path.

## 7. Open questions — resolved 2026-09-23

All seven questions below were resolved directly with the developer this session; kept here
as the decision record (also folded into §1 and the relevant body sections above).

1. **Group inheritance shape** → single-parent chain. The staff+premium-simultaneously
   scenario that motivated asking is covered by many-to-many *membership* (§2.1), not
   inheritance — multi-parent inheritance is unneeded.
2. **`/knk` command granularity** → in scope now (§2.3, §6.1).
3. **Legacy `k&k.*` leftovers** → migrated as part of this rollout (§2.3, §6.1).
4. **Title promotion pacing** → jump straight to target bracket, no tick-based catch-up (§3).
5. **Title/XP-demotion coupling** → stays deferred, per vision's own `[OPEN]` flag (§3).
6. **Dynamic per-entity nodes** → first-class wildcard support in the resolution engine (§2.2),
   not a special case.
7. **Authoring surface** → both web app FormConfig UI and in-game commands, from day one
   (§6.2).

A second round, covering the smaller items originally left in `IMPLEMENTATION_PLAN.md` §7 plus
one new question raised by the user-management module discussion, was also resolved
2026-09-23:

8. **`PermissionGrant.HolderId` shape** → shared `PermissionHolder` base table (TPT), real FK
   — not the simpler polymorphic pair (§2.1).
9. **Salary personal multiplier** → plain `PersonalSalaryMultiplier` field on `User`, not a
   permission grant (§5).
10. **Title/XP bracket thresholds** → port v1's 5/10/12/15 as-is, placeholder content (§3).
11. **Owner/staff-mode vanish persistence** → persists across a restart, not v1's in-memory-only
    behavior (§6.1).
12. **Tailored user-management admin module** → separate feature/spec, sequenced after this
    design's Phase 1, not folded into this plan (§1). See `docs/specs/user-management/
    DESIGN.md`.

All architectural and implementation-detail questions for this design are now closed.
