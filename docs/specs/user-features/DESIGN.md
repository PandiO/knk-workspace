# User Features — Design (Player Progression & Social Status)

**Status:** Draft — first design pass, incorporating explicit developer decisions below.
Not yet implementation-ready; see §7 for what's still open.
**Last updated:** 2026-09-23

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

## 2. Rank/Permission architecture

### 2.1 Core model — one permission-holder concept

Per vision §5.1, groups, premium ranks, and staff roles are not three mechanisms — they're
three instances of one underlying **PermissionHolder** concept: a named bundle of grants,
denials, a chat prefix/suffix, and an optional parent (for inheritance). A `User` also acts
as a PermissionHolder in its own right, so individual grants/denials layer on top of whatever
the player's group(s) already give them.

Proposed entity shape (names indicative, not final):

- **PermissionGroup** — `id`, `name`, `chatPrefix`, `chatSuffix`, `parentGroupId` (nullable,
  single-parent inheritance to start — see §7 for multi-parent question), `weight` (tie-break
  for prefix/suffix when a user is in multiple groups, LuckPerms-style)
- **PermissionGrant** — `holderType` (Group | User), `holderId`, `node` (string, dot-path,
  wildcard-capable — e.g. `knk.gate.*`), `value` (true = grant, false = explicit deny),
  `expiresAt` (nullable — temporary grants, matches vision §5.1's expiry requirement for
  temporary tiers)
- **User → PermissionGroup** membership is many-to-many (a player can hold multiple groups
  at once — e.g. a staff group *and* a premium-tier group simultaneously), each membership
  independently expirable.

### 2.2 Resolution order

Standard LuckPerms-equivalent precedence, closest-wins:
1. User's own explicit grants/denials (most specific — always wins)
2. Each group the user belongs to, own node list, ordered by group `weight` (highest first)
3. Walk up each group's inheritance chain
4. Undeclared → deny (fail-closed, matches current Bukkit-default convention)

An explicit deny at any more-specific level overrides a grant at a less-specific level —
this is the "exclusions, not just grants" requirement from vision §5.1.

### 2.3 Migration relative to current v3 state

Per the command/permission scan: v3 currently has ~18 static flat nodes and no group concept
at all, so there's no existing grant table to migrate — this is close to greenfield. Two
concrete things this system needs to actively resolve, not just build alongside:
- The four leftover `k&k.*` checks in `PlayerListener`/`ScoreboardUtil` (dead — nothing
  grants that namespace) need to be ported onto the new model's owner/staff concept.
- `/knk`'s current all-or-nothing `knk.admin` gate is a candidate for being broken into
  per-subcommand nodes once real groups exist to assign them to (open question — §7).

## 3. Title / XP track

Kept as the earned-progression axis, per vision §5.2 and v1 precedent (`user-system.md`):
- Titles are level brackets keyed off an `experiencePoints` total the player already has on
  `User` (this field already exists — confirmed in `docs/specs/users/SPEC_USER.md`, just
  currently unused for any progression logic).
- Past the final title, XP keeps climbing as a pure prestige signal (vision §5.2).
- Demotion via XP deduction — kept for now, flagged `[OPEN]` in vision for a future redesign
  that decouples title from raw XP. Not re-opened here; carried forward as-is.
- v1's multi-level catch-up promotion (one level drained per tick rather than jumping
  straight to the target) and the reward/penalty thresholds at 5/10/12/15 are the concrete
  legacy behavior to either port or deliberately supersede — see §7.

## 4. Premium tier track

Kept separate from Title, per §1's decision. Per vision §5.3:
- Renamed from "donor" to **premium**; grants real power/progress advantages, not purely
  cosmetic — an intentional, explicitly-documented-as-such direction change from the
  original 2017 no-pay-to-win stance.
- v1's temporary-tier-with-restore mechanism (`DonatorTemp`, `previousDonatorID`) is the
  closest existing precedent for the expiry support vision §5.1 requires generally — the
  `PermissionGrant.expiresAt` field in §2.1 is designed to cover this without a
  premium-specific side table.
- Account linking (web ↔ Minecraft) already underpins this per vision §5.3's note — already
  built, not reopened here.

## 5. Salary

Per vision §5.4, kept: hourly payout, scaled by global/personal/rank-based multipliers, all
admin-configurable via the web app. Offline-gap handling: a payout covering the gap is made
on next join if ≥1 hour has passed, rather than lost (explicit vision requirement, direct
fix for v1's silent-loss behavior — `user-system.md` doesn't document v1 handling this at
all, so this is new-in-v3 behavior, not a port).

## 6. Owner-mode / staff-mode and in-game rank management

- **Owner/staff-mode** (vision §5.5): rebuild the v1 vanish-like toggle (`/ownermode`,
  `/staffmode`) as first-class v3 commands, gated by the new permission model instead of
  static `k&k.owner`/`k&k.staff` checks. This directly replaces the four leftover legacy
  checks found in §2.3.
- **In-game rank/group management** (vision §5.6): rebuild v1's `/user <group> <player>`-
  style commands against the new in-house PermissionGroup model instead of dispatching to
  an external plugin — the entire reason vision §5.1 wants this in-house in the first place.

## 7. Open questions — needed before an implementation plan can be written

1. **Group inheritance shape**: single-parent chain (simpler, matches §2.1 as drafted) or
   multi-parent/multiple-inheritance (closer to some LuckPerms setups, more complex to
   resolve)?
2. **`/knk` command granularity**: break the current all-or-nothing `knk.admin` gate into
   per-subcommand nodes as part of this work, or leave that as separate cleanup? (Carried
   from the command/permission scan §5, Q1.)
3. **Legacy `k&k.*` leftovers**: migrate as part of this feature's rollout, or track
   separately? (Scan §5, Q2.)
4. **Title promotion pacing**: port v1's one-level-per-tick catch-up loop as-is, or design
   something new for v3?
5. **Title/XP-demotion coupling**: still explicitly deferred per vision's own `[OPEN]` flag —
   confirm it stays deferred for this pass rather than being pulled in.
6. **Dynamic per-entity nodes** (e.g. `customenchantments.<id>`): first-class wildcard
   pattern in the new model, or left as a special case? (Scan §5, Q3.)
7. **Authoring surface**: are PermissionGroups/PermissionGrants managed via the web app's
   FormWizard/FormConfigBuilder pattern (matching how Items/Gate structures are managed), an
   in-game command surface, or both from day one?
