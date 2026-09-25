# Kits — Design

**Status:** Draft, all open questions resolved with the developer — ready for implementation.
**Last updated:** 2026-09-25 (initial draft).

Ref: `docs/vision/vision.md` §9.2 (Kits). Sources: `docs/specs/legacy/kits.md` (v1/v2
source-mined spec), `docs/reports/LEGACY_VS_V2_GAP_ANALYSIS.md`, `docs/specs/items/
IMPLEMENTATION_PLAN.md` (now fully shipped — see §1 below), `docs/specs/user-features/{DESIGN,
IMPLEMENTATION_PLAN}.md` and `docs/specs/user-management/{DESIGN,IMPLEMENTATION_PLAN}.md` (the
rank/permission/progression model this plan hooks into, per explicit developer instruction — see
§3), plus a direct read of `knk-web-api`'s `Models/Item/ItemBlueprint.cs`, `Models/User.cs`,
`Models/PermissionGroup.cs`, `Models/TitleBracket.cs`, `Models/PermissionGrant.cs`, and
`knk-plugin`'s `PlayerListener.java` (2026-09-25, on branch `claude/user-management`, which has
Items Phases 1-5 and User Features/User Management merged in).

## 0. What this plan does not re-litigate

Vision.md §9.2 already makes every major call for this feature: build on v2's model (not v1's
hardcoded single kit), fix the cascade-delete bug, unify starter-kit into the general system via
a `grantOnFirstJoin` flag, enforce permission parity between grant paths, keep two forms of
premium kit, and add real cooldown/claim tracking. This document is the concrete data model and
architecture that satisfies those calls — it does not reopen any of them.

Three points were escalated to the developer directly (not inferable from the docs) and are
resolved as follows:

1. **Access-gating mechanism** — hook into the newly-shipped user-features/user-management
   permission model (§3), not a new bespoke or generic "AccessCondition" entity.
2. **Single-purchase premium kits** — modeled as Gems-priced (an existing in-game currency);
   real-money-to-Gems checkout is out of scope for this plan (§5.2).
3. **Seed data fidelity** — the "Archer" kit's hand slot is seeded verbatim from the legacy DB
   backup (Maggoty Bread, not a bow) even though it looks like leftover test data — see
   `SEED_DATA.md`.

## 1. Reconciliation — what's already built that this plan depends on

A direct code read (not just docs, several of which are stale on this point) confirms all of the
following are already shipped on `main`/`master` or on an unmerged-but-stable branch this plan
should fork from:

- **`ItemBlueprint`** (`Models/Item/ItemBlueprint.cs`) — fully built per the Items plan: `Name`,
  `Description`, `IconMaterialRefId`, `DefaultDisplayName`/`DefaultDisplayDescription`,
  `DefaultQuantity`, `MaxStackSize`, `CategoryId`, `GradeId`, `BasePriceMin`/`BasePriceMax`,
  `DefaultEnchantments`, `Tags`, `Origins`. Confirmed live on `main` (`git log main` shows "Items
  Phase 4/5 round 5: merged items-feature to main/master"). **Kit contents/equipment slots
  reference `ItemBlueprint`, not a live `ItemInstance`** — `ItemInstance` still doesn't exist
  anywhere in the codebase (vision §9.1's instance-level work is unstarted), so a granted kit
  item is a freshly-built `ItemStack` from its blueprint, exactly like
  `ItemBlueprintsDebugCommand`'s existing `/knk itemblueprints give` already does. This plan
  reuses that build logic rather than reimplementing it (§4.3).
- **Permission/rank model** (`Models/PermissionHolder.cs`, `PermissionGroup.cs`,
  `PermissionGrant.cs`, `TitleBracket.cs`, `UserPermissionGroup.cs`) — fully built per
  `user-features` §1/§3/§4/§5: `PermissionResolutionService` (grant/deny/wildcard resolution),
  `TitleBracket` (level/title, resolved from `User.ExperiencePoints`), `PermissionGroup` (with
  `IsPremiumTier`, `Weight`, single-parent inheritance). Currently live on the unmerged
  `claude/user-features` branch (web-api and plugin) — not yet on `main`/`master`. **This plan's
  first phase needs to branch from `claude/user-features`'s tip, not from `main`**, until that
  work merges — flag this in `ACTIVE_SESSIONS.md` when starting (§6).
- **`User.Coins`/`User.Gems`** (both `int`) — the two currency fields Kit's cost model spends
  directly (§5).
- **First-join detection** (`PlayerListener.onJoin`, `UserSummary.isNewUser()`) — already exists
  and is already used for the welcome message. This is a safe, one-shot signal derived from
  account creation itself (`getOrCreateAsync`'s `WasCreated`-style flag), **not** a time-windowed
  flag re-checked on every event — structurally immune to v1's `PlayerMoveEvent`-retrigger
  duplication bug (legacy spec bug #1) without this plan needing to build anything new to avoid
  it (§4.4).

## 2. Data model

All new entities live in `knk-web-api`'s `Models/Item/` folder, alongside `ItemBlueprint` and its
existing satellite entities (`Grade`, `Tag`, `ItemBlueprintOrigin`, etc.) — same convention, since
Kit is fundamentally an item-catalog composition, not a user-domain concept.

### 2.1 `Kit`

```csharp
[FormConfigurableEntity("Kit")]
public class Kit
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public string? Description { get; set; }

    // Equipment loadout — all nullable, unlike v2's NOT NULL columns (legacy spec bug #5: v2's
    // assignKit() dereferenced these with no null checks, relying entirely on the wizard/schema
    // to guarantee non-null values). Nullable + a defensive check at grant time (§4.2) means a
    // Kit can be armor-only, weapon-only, or consumables-only without a workaround, and a
    // partially-configured Kit row can never NPE a grant.
    [RelatedEntityField(typeof(ItemBlueprint))] public int? HelmetId { get; set; }
    [RelatedEntityField(typeof(ItemBlueprint))] public int? ChestplateId { get; set; }
    [RelatedEntityField(typeof(ItemBlueprint))] public int? LeggingsId { get; set; }
    [RelatedEntityField(typeof(ItemBlueprint))] public int? BootsId { get; set; }
    [RelatedEntityField(typeof(ItemBlueprint))] public int? ShieldId { get; set; }
    [RelatedEntityField(typeof(ItemBlueprint))] public int? HandId { get; set; }
    // (+ matching nullable navigation properties, [NavigationPair]-annotated, same pattern as
    // ItemBlueprint.IconMaterialRefId/IconMaterial)

    // Bonus contents — see KitContent below for the cascade-delete fix
    [RelatedEntityField(typeof(KitContent))]
    public ICollection<KitContent> Contents { get; set; } = new List<KitContent>();

    // Access gating — reuses the user-features/user-management model directly, no new gating
    // entity (developer decision, §0/§3)
    [RelatedEntityField(typeof(TitleBracket))] public int? MinTitleBracketId { get; set; }
    [RelatedEntityField(typeof(PermissionGroup))] public int? RequiredPermissionGroupId { get; set; }
    public string? RequiredPermissionNode { get; set; }

    // Availability
    public bool GrantOnFirstJoin { get; set; }
    public int CooldownSeconds { get; set; } // 0 = no cooldown (freely repeatable, e.g. a
                                              // loadout-preview/reset kit — legacy edge case #7,
                                              // now an explicit admin choice instead of an
                                              // unconditional gap)

    // Per-claim cost — optional, charged every successful claim (not the one-time purchase below)
    public int? CostAmount { get; set; }
    public KitCostCurrency? CostCurrency { get; set; }

    // Single-purchase premium kit (vision §9.2's second premium form) — deliberately separate
    // from CostAmount/CooldownSeconds: paid once, then claimable indefinitely with no further
    // cost or cooldown (§5.2)
    public bool IsSinglePurchasePremium { get; set; }
    public int? PremiumPriceGems { get; set; }
}

public enum KitCostCurrency { Coins, Gems }
```

**Why `MinTitleBracketId`/`RequiredPermissionGroupId`/`RequiredPermissionNode` and not a single
field:** these cover three genuinely different gating shapes an admin might want, and a Kit can
combine any subset (AND, all set conditions must pass):
- `MinTitleBracketId` — a level/title floor (e.g. "Knight kit," requires the Knight bracket or
  higher), resolved the same way `TitleBracket` resolution already works: the player's current
  bracket (derived from `ExperiencePoints`) must be at or above the required bracket.
- `RequiredPermissionGroupId` — a rank/premium-tier gate (e.g. "requires the Royal premium
  tier," or "requires the Moderator staff group") — this directly answers legacy open question
  #3 ("was rank/donator-tiered kit access ever a real intended requirement?") by reusing
  `PermissionGroup` rather than inventing a parallel rank concept.
- `RequiredPermissionNode` — a fine-grained, per-kit permission node (e.g. `knk.kit.veteran`),
  checked through `PermissionResolutionService` exactly like every other node check in the
  codebase — covers cases that don't map cleanly to "requires this group," like a
  one-off event kit granted to hand-picked players via a direct `PermissionGrant`.

No new "AccessCondition" entity, and no duplication of District/Territory's future access-gating
model — if that generic mechanism gets built later, Kit's three fields here are a strict subset
of what it would need to express and can be migrated onto it then; nothing here blocks that.

### 2.2 `KitContent` — the cascade-delete fix

```csharp
public class KitContent
{
    public int KitId { get; set; }
    public Kit Kit { get; set; } = null!;         // cascade delete — fully owned by Kit
    public int ItemBlueprintId { get; set; }
    public ItemBlueprint ItemBlueprint { get; set; } = null!; // Restrict delete — NOT cascade

    public int? QuantityOverride { get; set; } // null = use ItemBlueprint.DefaultQuantity
}
```

Composite key `(KitId, ItemBlueprintId)`. **This directly fixes legacy spec bug/edge-case #4**:
v2's `Kit.contents` was `@ManyToMany(cascade = CascadeType.ALL)` against the shared `Item`
entity, meaning deleting a Kit risked cascading a delete into `Item` rows still referenced by
shops/storages/other kits. Here, deleting a `Kit` deletes its `KitContent` join rows (which are
meaningless without their parent Kit) but the FK to `ItemBlueprint` is `DeleteBehavior.Restrict`
— an `ItemBlueprint` still referenced by any `KitContent` (or equipment slot FK) cannot be
deleted at all until every reference is removed first. **This is also the concrete instance of
vision §9.2's standing rule** ("any entity referencing shared Item/ItemTemplate rows in v3" must
not cascade-delete into it) — Kit's equipment-slot FKs (`HelmetId` etc.) get the same
`Restrict` treatment for the same reason.

**Quantity resolution** deliberately replaces legacy's hardcoded category/name heuristic
(v2: weapons=1, item named "arrow"=64, everything else=32) with the item catalog's own
`ItemBlueprint.DefaultQuantity` field (already exists, already means "how many of this item a
player normally gets" per the Items plan) as the default, overridable per-kit via
`QuantityOverride` on `KitContent` (contents) — equipment slots always grant exactly 1 (you
cannot equip more than one helmet), so no per-slot quantity field exists there. This is simpler
than porting the legacy heuristic and correctly reuses data that already exists on the template,
rather than re-deriving "how many arrows" from the item's name at grant time.

### 2.3 `KitClaim` — cooldown and claim history

```csharp
public class KitClaim
{
    public int Id { get; set; }
    public int KitId { get; set; }
    public Kit Kit { get; set; } = null!;
    public int UserId { get; set; }
    public User User { get; set; } = null!;
    public DateTime ClaimedAt { get; set; } = DateTime.UtcNow;
}
```

Not `[FormConfigurableEntity]` — append-only log, viewed not edited, same convention as
`AuditLogEntry` (`docs/specs/user-management/DESIGN.md` §4). One row per successful claim
(including first-join grants — §4.4). Cooldown check: the most recent `ClaimedAt` for
`(KitId, UserId)` plus `CooldownSeconds` must be in the past. **This directly fixes legacy edge
case #7** — kits are no longer freely repeatable with zero tracking; `CooldownSeconds = 0` is
now an explicit admin choice (a genuine "reset/preview" kit) rather than an unconditional gap
every kit shared.

### 2.4 `KitPurchase` — one-time premium unlock

```csharp
public class KitPurchase
{
    public int Id { get; set; }
    public int KitId { get; set; }
    public int UserId { get; set; }
    public DateTime PurchasedAt { get; set; } = DateTime.UtcNow;
    public int GemsPaid { get; set; }
}
```

Unique constraint on `(KitId, UserId)`. Deliberately a separate table from `KitClaim`: a
single-purchase premium kit (`IsSinglePurchasePremium`) is bought once (this table gets exactly
one row per user), and thereafter claimable indefinitely with **no** cooldown and **no**
per-claim cost — vision §9.2 explicitly frames this as "separate from the cooldown-based
general-availability model." `KitService.ClaimKitAsync` still writes a `KitClaim` row on every
actual grant (for history/audit purposes) even for a purchased kit — `KitPurchase` answers "has
this player unlocked it," `KitClaim` answers "when did they last actually take it."

## 3. Gating resolution — reusing user-features/user-management, not reinventing it

Per the developer's explicit instruction, Kit's `ClaimKitAsync` gating check calls straight into
the already-shipped services, in this order (all must pass):

1. **`MinTitleBracketId`** (if set): resolve the player's current bracket via the same logic
   `ITitleService` already exposes (`user-management`'s `UserProfileSummaryService` already
   calls `ITitleService.ResolveAsync` for exactly this) and compare bracket ordering.
2. **`RequiredPermissionGroupId`** (if set): check `UserPermissionGroupService.GetByUserAsync`
   for an active (non-expired) membership in that group — the same query the profile view and
   premium-tier resolution already use.
3. **`RequiredPermissionNode`** (if set): call `IPermissionResolutionService`'s existing
   single-node check (the same one `GET /api/users/{id}/permissions/check` exposes) for that
   node against the claiming user.

No new resolution logic is written here — `KitService` is a caller of these three existing
services, exactly the same relationship `UserProfileSummaryService` already has with them. This
also means Kit gating automatically benefits from anything those services already handle
correctly (group inheritance, wildcard nodes, expiring memberships) without Kit needing its own
copy of that logic.

## 4. Grant paths — permission parity by construction, not convention

Legacy spec bug #3 existed because v2's command and menu grant paths were two independent code
paths that happened to diverge. This plan makes that structurally impossible: **there is exactly
one grant path, `KitService.ClaimKitAsync(userId, kitId)`**, and every surface (command, future
menu, first-join hook) calls it. There is nowhere else in the codebase a Kit item is ever built
and handed to a player.

### 4.1 `KitService` (knk-web-api)

- `GetAvailableForUserAsync(userId)` — every Kit, annotated per-kit with whether this user could
  claim it right now and why not if not (gating failed / on cooldown until `T` / insufficient
  balance / already purchased) — this is what both the `/kit list` command and the future menu
  render from, so denial messaging is identical on both surfaces by construction (directly
  answers vision §9.2's "clear, user-friendly denial messaging in both surfaces" requirement).
- `ClaimKitAsync(userId, kitId)` — re-validates gating (§3) + cooldown (§2.3) +
  `IsSinglePurchasePremium` state (§2.4) + `CostAmount`/`CostCurrency` balance, atomically
  deducts cost (if any, and if not a purchased premium kit), writes a `KitClaim` row, and returns
  the resolved loadout (`HelmetId`/`ChestplateId`/.../`HandId`/`ShieldId` + resolved
  `(ItemBlueprintId, quantity)` list for `Contents`) for the caller to actually build/give
  in-game. **Never trust a caller's own gating check** — this method re-checks everything itself
  even though `GetAvailableForUserAsync` already told the caller the answer moments earlier,
  since that's exactly the kind of staleness window vision §10 already flags as a bug class to
  avoid (menu condition-at-click-time, not just render-time).
- `PurchaseKitAsync(userId, kitId)` — for `IsSinglePurchasePremium` kits only: checks no existing
  `KitPurchase` row, deducts `PremiumPriceGems` from `User.Gems`, writes the `KitPurchase` row.
  Does not itself grant the kit — purchasing and claiming stay separate calls (a player can
  purchase now and claim later, or the purchase flow can immediately follow with a claim call).
- `GrantFirstJoinKitsAsync(userId)` — see §4.4.

### 4.2 Grant execution (knk-plugin) — reuses the existing item-building pipeline

`KitCommand`/the future menu handler call `KitsCommandApi.claimAsync(kitId)` (thin wrapper over
`POST api/Kits/{id}/claim`), then use the response's `ItemBlueprintId`s to build each `ItemStack`
via the **already-existing** `ItemBlueprintBukkitMapper`/`ItemBlueprintsDataAccess` pipeline
(`ItemBlueprintsDebugCommand` already does exactly this for a single item) — no new
item-construction logic. Slot assignment defensively checks each nullable slot before acting
(directly fixes legacy bug #5): a Kit with `HelmetId == null` simply doesn't touch the helmet
slot, rather than assuming every Kit is a full loadout.

### 4.3 Command surface (knk-plugin)

New `commands/KitCommand.java`, following the existing Brigadier-based `commands/` convention
(`ItemCommand.java`/`GateCommand.java`, not ACF/`@CommandAlias` — v3 doesn't use Aikar's command
framework anywhere, unlike legacy v2):
- `/kit list` — calls `GetAvailableForUserAsync`, shows gating/cooldown/cost state per kit.
- `/kit get <name>` — self-claim, gated by `knk.kit.get`.
- `/kit give <player> <name>` — staff-to-other, gated by `knk.kit.give`.
- `/kit purchase <name>` — gated by `knk.kit.purchase`, only for `IsSinglePurchasePremium` kits.

Per-action permission nodes (not per-kit), matching legacy's structure — but checked through
`KnkPermissible`/`PermissionsDataAccess` (the new in-house resolution engine), not a Bukkit
`plugin.yml` node. **v2's duplicate-`"g"`-alias bug (legacy bug #2) doesn't reproduce here**:
Brigadier subcommands are distinct literals (`get`/`give`), not ACF's string-alias registration,
so there's no mechanism for two subcommands to collide on the same alias the way ACF's
`@Subcommand("give|g")`/`@Subcommand("get|g")` did.

### 4.4 First-join grant (knk-plugin)

`PlayerListener.onJoin`, in the existing `if (user.isNewUser())` branch (`PlayerListener.java`
line ~142, currently just a welcome message) — add a call to
`kitsCommandApi.grantFirstJoinKitsAsync(user.id())`, mirroring the existing
`triggerBackgroundSalaryPayout` call pattern immediately below it (async, fire-and-forget with
logged failure, not blocking the join event). Server-side, `GrantFirstJoinKitsAsync`:
- Selects every `Kit` with `GrantOnFirstJoin = true`.
- Still runs the §3 gating check per kit (a brand-new player is bracket-0/group-less by
  definition, so a kit gated behind a higher title or a premium group correctly won't
  auto-grant even if someone mistakenly flags it `GrantOnFirstJoin` — the flag doesn't bypass
  gating, it bypasses the *pull* requirement).
- **Ignores `CostAmount`/`CostCurrency` entirely** — a first-join grant is a welcome gift, never
  charged, regardless of what a normal `/kit get` claim of the same kit would cost. This is a
  deliberate, explicit rule (not left to admin discipline) since a `GrantOnFirstJoin` kit with a
  nonzero cost would otherwise silently charge — or fail to grant to — a brand-new player with
  the default starting `Coins`/`Gems` balance.
- **Ignores `CooldownSeconds`** — one-time by construction (a player only has one first join),
  but still writes a normal `KitClaim` row, so it shows up in the same claim history as any
  other grant.

This satisfies vision §9.2's "unify starter kit into the general Kit system" directly: there is
no separate starter-kit code path at all, just a `Kit` row with `GrantOnFirstJoin = true` — and
because it's driven by `isNewUser()` (§1) rather than a time-windowed listener flag, it cannot
reproduce v1's `PlayerMoveEvent`-retrigger duplication bug (legacy bug #1).

## 5. Economy

### 5.1 Per-claim cost (`CostAmount`/`CostCurrency`)

Optional, checked and deducted atomically inside `ClaimKitAsync` before the `KitClaim` row is
written (deduct-then-record, inside one transaction — a failed deduction never produces a claim
row). Spends `User.Coins` or `User.Gems` directly (both already exist, both `int`) — no new
currency concept.

### 5.2 Single-purchase premium kits — Gems, not real money (developer decision)

Vision §9.2 describes these as "bought with real money." **No payment gateway (Stripe or
equivalent) exists anywhere in the codebase today**, and building one is out of scope for this
plan. Per the developer's explicit decision, `PremiumPriceGems` is spent from the player's
existing `Gems` balance — the same premium currency already planned for `ItemBlueprint` pricing
(vision §9.1) — rather than this plan designing a real-money checkout flow. **How a player
originally acquires enough Gems to afford a premium kit (a Gems top-up/store flow) is explicitly
a separate, future integration**, not something this plan builds or blocks on.

### 5.3 Premium-tier-exclusive kits (the other premium form)

These aren't a separate economic mechanism — they're an ordinary `Kit` with
`RequiredPermissionGroupId` pointing at an `IsPremiumTier = true` group (e.g. the seeded
Noble/Royal/Dragon Blood tiers from `user-features` Phase 5), optionally combined with its own
`CostAmount`/`CooldownSeconds` like any other kit. No separate field or flag needed — §2.1's
three gating fields already express "only players in this premium group" on their own.

## 6. Menu grant path — deferred, blocked on InventoryMenu

Vision §10 confirms `knk-plugin`'s `InventoryMenus` branch is still a single, unmerged planning
commit — zero UI framework code exists to build a Kit menu screen against yet, and vision §10
itself lists "the two currently-live v2 screens (Kit and Siege overviews)" as known,
not-yet-planned porting work once the engine ships. **This plan does not build a Kit menu** —
`/kit get`/`/kit give`/`/kit purchase` (§4.3) is the complete grant surface for now. When
InventoryMenu ships, porting the Kit screen is a follow-on phase that **must** call the exact
same `KitService.ClaimKitAsync`/`PurchaseKitAsync` (§4.1) the command path uses — this is now
structurally guaranteed rather than a checklist item to remember, since there is no second
item-granting code path anywhere for a menu implementation to accidentally bypass (directly
prevents legacy bug #3 from reproducing).

## 7. Open items carried forward (not blocking this plan)

- **`ItemInstance`** doesn't exist yet (§1) — Kit contents/equipment reference `ItemBlueprint`
  only. If/when `ItemInstance` is built, granting a kit item that should be soulbound/ghosted/
  instance-tracked from the moment of grant is a natural extension point here, but is explicitly
  out of scope now, matching vision §9.1's own scoping.
- **A generic District/Territory access-gating mechanism** (vision §2.2/§2.3) doesn't exist yet
  either. Kit's three gating fields (§2.1) are a deliberately narrow, kit-specific version of the
  same idea — if a shared mechanism gets built later, migrating Kit onto it is a small, isolated
  follow-up, not a redesign.
