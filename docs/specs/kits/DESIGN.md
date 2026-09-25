# Kits — Design

**Status:** Draft, all open questions resolved with the developer — ready for implementation.
**Last updated:** 2026-09-25 (added §0a/§6: `KitScan` WorldTask authoring flow, slot-indexed
`KitContent`, and the unified grant-placement algorithm). Previously updated 2026-09-25 (initial
draft).

Ref: `docs/vision/vision.md` §9.2 (Kits). Sources: `docs/specs/legacy/kits.md` (v1/v2
source-mined spec), `docs/reports/LEGACY_VS_V2_GAP_ANALYSIS.md`, `docs/specs/items/
IMPLEMENTATION_PLAN.md` (now fully shipped — see §1 below), `docs/specs/user-features/{DESIGN,
IMPLEMENTATION_PLAN}.md` and `docs/specs/user-management/{DESIGN,IMPLEMENTATION_PLAN}.md` (the
rank/permission/progression model this plan hooks into, per explicit developer instruction — see
§3), plus a direct read of `knk-web-api`'s `Models/Item/ItemBlueprint.cs`, `Models/User.cs`,
`Models/PermissionGroup.cs`, `Models/TitleBracket.cs`, `Models/PermissionGrant.cs`, and
`knk-plugin`'s `PlayerListener.java` (2026-09-25, on branch `claude/user-management`, which has
Items Phases 1-5 and User Features/User Management merged in).

## 0a. Revision note — WorldTask-scan authoring added, `Contents` becomes slot-indexed

Added after the initial draft, per explicit developer request: an alternative, in-game way to
author a Kit (scan a player's live inventory and relay it into the open web-app form), modeled
directly on the **real, already-shipped** `ItemScan` mechanism (`ItemScanTaskHandler.java`,
`FormWizard.tsx`'s `applyItemScanResult`, `WorldBoundFieldRenderer.tsx`'s `isItemScanTask`,
`ScanConflictModal.tsx`) — confirmed by direct code read to be materially ahead of what
`docs/specs/items/IMPLEMENTATION_PLAN.md` §5 itself describes (that doc's "no selective-field
preservation" non-goal was superseded in the field by real 2026-09-23 live-testing feedback; the
conflict-modal mechanism this plan reuses didn't exist when that doc was written). See §6.

This also forced a real model change to §2.2's `KitContent`: capturing "the exact slot number"
per scanned item only makes sense if `KitContent` is keyed by slot, not by item identity — see
§2.2's rewritten shape. It also surfaced a correctness gap in the original §4.2 grant
description (unconditional `setHelmet()`-style overwrite would silently delete gear a player is
already wearing) — §4.2 is rewritten to apply the same "check what's already there" logic
uniformly to every granted slot, not just `Contents`.

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
  work merges — flag this in `ACTIVE_SESSIONS.md` when starting (`IMPLEMENTATION_PLAN.md` §0).
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

### 2.2 `KitContent` — slot-indexed, and the cascade-delete fix

**Revised (§0a): keyed by slot, not by item.** Since a scanned kit (§6) must reproduce a
player's inventory layout exactly — including two non-stacking stacks of the same
`ItemBlueprint` sitting in two different slots, which a real inventory snapshot can genuinely
contain — `KitContent` cannot be keyed by `(KitId, ItemBlueprintId)` the way a "one entry per
distinct item" model would assume. It's keyed by `(KitId, SlotIndex)` instead: a Kit's general
contents are modeled as *up to 36 positional slots* (Bukkit's `PlayerInventory` storage range,
indices 0-35 — hotbar 0-8 plus the main storage grid 9-35), each independently holding one
`ItemBlueprint` + quantity, mirroring an actual inventory rather than an unordered bag:

```csharp
public class KitContent
{
    public int KitId { get; set; }
    public Kit Kit { get; set; } = null!;         // cascade delete — fully owned by Kit
    public int SlotIndex { get; set; }            // 0-35, Bukkit PlayerInventory storage index
    public int ItemBlueprintId { get; set; }
    public ItemBlueprint ItemBlueprint { get; set; } = null!; // Restrict delete — NOT cascade
    public int Quantity { get; set; } = 1;        // the actual stack size for this slot
}
```

Composite key `(KitId, SlotIndex)` — at most one item occupies a given slot, same as a real
inventory. **This directly fixes legacy spec bug/edge-case #4**: v2's `Kit.contents` was
`@ManyToMany(cascade = CascadeType.ALL)` against the shared `Item` entity, meaning deleting a Kit
risked cascading a delete into `Item` rows still referenced by shops/storages/other kits. Here,
deleting a `Kit` deletes its `KitContent` join rows (meaningless without their parent Kit) but the
FK to `ItemBlueprint` is `DeleteBehavior.Restrict` — an `ItemBlueprint` still referenced by any
`KitContent` (or equipment slot FK) cannot be deleted at all until every reference is removed
first. **This is also the concrete instance of vision §9.2's standing rule** ("any entity
referencing shared Item/ItemTemplate rows in v3" must not cascade-delete into it) — Kit's
equipment-slot FKs (`HelmetId` etc.) get the same `Restrict` treatment for the same reason.

**Quantity is now a plain, required field** (the actual scanned/authored stack size), not an
override on top of `ItemBlueprint.DefaultQuantity` — a positional slot model has no natural
"default to fall back to" the way an unordered bag did; a slot either holds N of an item or it's
empty. When hand-authoring a Kit through the web-app form (no scan involved, §3), the admin sets
both `SlotIndex` and `Quantity` directly on each `Contents` entry.

**Why armor/hand/shield stay separate named fields, not more `KitContent` slots**: `HelmetId`/
`ChestplateId`/`LeggingsId`/`BootsId`/`ShieldId`/`HandId` (§2.1) remain their own FK fields rather
than folding into `KitContent`'s slot range, because each maps to a distinct, non-interchangeable
Bukkit API surface at grant time (armor/off-hand/main-hand setters, §4.2) rather than a raw
storage-array index — and because giving them dedicated fields keeps the admin form (§3)
readable ("what does this kit equip" vs. "what does this kit dump into a numbered slot").

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
  the resolved loadout (`HelmetId`/`ChestplateId`/.../`HandId`/`ShieldId` + a resolved
  `(SlotIndex, ItemBlueprintId, Quantity)` list for `Contents`, §2.2) for the caller to actually
  build/place in-game (§4.2). **Never trust a caller's own gating check** — this method re-checks everything itself
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
item-construction logic. Every nullable slot (§2.1) is checked before acting (directly fixes
legacy bug #5): a Kit with `HelmetId == null` simply doesn't touch the helmet slot, rather than
assuming every Kit is a full loadout.

**Revised (§0a) — a single, unified per-item placement routine, not a blind overwrite.** The
original version of this section had armor/shield/hand grant unconditionally via
`setHelmet()`/`setItemInOffHand()`/`setItemInMainHand()`, which would silently delete whatever
the player already had equipped there. Since `KitContent`'s slot model (§2.2) already needs a
"what's already in this slot" conflict routine, the same routine is applied to **every** granted
item — armor, shield, hand, and each `KitContent` entry alike — not just `Contents`:

For each resolved item to grant, in order Helmet → Chestplate → Leggings → Boots → Shield → Hand
→ `Contents` (ascending `SlotIndex`):
1. **Determine the target slot**: the item's own dedicated Bukkit slot for
   Helmet/Chestplate/Leggings/Boots/Shield (armor slots, off-hand); **the player's currently
   active hotbar slot** for Hand (i.e. whatever `getHeldItemSlot()` returns *at grant time* —
   deliberately not the slot it happened to occupy when originally scanned, since "hand" means
   "what the player is holding," which by definition is whichever hotbar slot is currently
   selected); the stored `SlotIndex` (0-35) for a `Contents` entry.
2. **Empty target** → place the built `ItemStack` there directly.
3. **Occupied, and the existing stack is a Bukkit `ItemStack.isSimilar()` match** (same material,
   display name, lore, enchantments — the exact check the developer asked for: "type matches
   including name and lore") → merge into the existing stack up to `ItemBlueprint.MaxStackSize`;
   any amount that doesn't fit continues to step 4 as its own remainder stack.
4. **Occupied with a non-matching item (or a merge remainder from step 3)** → search the
   player's general inventory (`PlayerInventory.firstEmpty()` over indices 0-35 — a displaced
   item always goes to general storage, never bumps into a *different* armor slot) for the first
   empty slot and place it there.
5. **No empty slot anywhere** → `player.getWorld().dropItemNaturally(player.getLocation(), stack)`
   — drop it on the ground rather than losing it silently, per the developer's explicit
   instruction.

This is the one grant-time algorithm every surface (command, first-join, future menu) shares —
consistent with §4's "exactly one grant path" principle; it isn't a `Contents`-only special case
bolted on top of a simpler armor-equip path.

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

## 6. Kit authoring via WorldTask scan (`KitScanTaskHandler`) — new, §0a

An alternative to hand-authoring a Kit through the FormWizard (§3): scan a player's live
inventory in-game and relay it straight into the open Kit form, exactly the way `ItemScan`
(`docs/specs/items/IMPLEMENTATION_PLAN.md` §5, now fully shipped — see §0a) pre-fills an
`ItemBlueprint` form from a held item. This is additive — §3's manual authoring path is unchanged
and still how an admin builds a Kit with no player physically holding the items.

### 6.1 What gets scanned

On trigger, the handler reads the **triggering player's entire inventory**, not just their held
item:
- `Helmet`/`Chestplate`/`Leggings`/`Boots` via `PlayerInventory.getHelmet()`/`getChestplate()`/
  `getLeggings()`/`getBoots()`.
- `Shield` (off-hand) via `getItemInOffHand()` — captured regardless of the actual item type; the
  field name reflects its typical use, not a restriction on what can occupy it (unchanged from
  §2.1's original framing).
- `Hand` via `getItemInMainHand()` — no slot number is recorded for this one (§4.2 already
  established that "hand" targets whatever hotbar slot is active *at grant time*, not a fixed
  original index).
- `Contents` via `PlayerInventory.getStorageContents()` (indices 0-35): every **non-air** slot
  becomes one scanned content entry, tagged with its exact index — **except** whichever index
  equals `getHeldItemSlot()` at scan time, which is excluded here since that item is already
  captured as `Hand` above (avoids scanning the same physical item twice, once as `Hand` and
  once as a `Contents` entry at its hotbar position).

Each scanned item (all six named slots plus every `Contents` entry) captures the same per-item
fields `ItemScanTaskHandler` already extracts for a single held item — material, display name
(or humanized material name fallback), lore, vanilla enchantments, custom enchantments (via the
same reused `EnchantmentRepository`/`LocalEnchantmentRepositoryImpl` lore parser), quantity (the
stack's actual `getAmount()`, not a hardcoded default). **This logic is factored into one shared
helper both `ItemScanTaskHandler` and `KitScanTaskHandler` call** (e.g. a
`ScannedItemJsonBuilder.build(ItemStack)` extracted from `ItemScanTaskHandler`'s existing
per-item logic) — per this codebase's own "reuse, don't reimplement" precedent (§1), not two
copies of the same material/lore/enchantment-reading code.

### 6.2 Execution model — same as `ItemScan`, not headless

Identical reasoning to `ItemScanTaskHandler`'s own doc-comment: a kit scan requires a specific
player's live inventory at the moment of the scan, so this is a single-shot, synchronous
`IWorldTaskHandler` (not `IHeadlessWorldTaskHandler`) — `startTask` reads the inventory and
completes the task in one call, no multi-step session, `isHandling`/`getTaskId` are no-ops
matching `ItemScanTaskHandler`'s own.

**Correction to this section's original wording**: the earlier draft called the generic entry
point a "`/knk task-claim` chat flow (`WorldTaskChatListener`)" — that's wrong on inspection.
`WorldTaskChatListener` only routes **mid-task follow-up chat input** for already-claimed,
stateful handlers (`onPlayerChat`, e.g. a `WgRegionId`/`Location` session's "save"/"cancel"
messages) — it has nothing to do with *initial* claiming, and `ItemScanTaskHandler`/
`KitScanTaskHandler` never register into it (`isHandling` always returns `false`, so there's no
session for it to route into even if they did).

**The two real, generic-by-construction entry points, both mandatory, neither optional**:
1. **`/knk task-claim <id|linkCode>`** (`KnkTaskClaimCommand`, already registered for every
   `WorldTask` field, no per-type special-casing) — confirmed by reading `KnkTaskClaimCommand`
   directly: it looks up the claimed task's `fieldName` and dispatches via
   `handlerRegistry.startTask(...)`, purely by registry lookup. **This means `/knk task-claim
   <linkCode>` already works for `KitScan` the moment `KitScanTaskHandler` is registered into
   `WorldTaskHandlerRegistry` (§6.2 above) — no additional command code is needed for this path
   at all.** This is the primary, must-work entry point; it is not superseded or replaced by #2.
2. **`/knk kitscan claim <linkCode>`** (new, this plan) — a thin, purely additive convenience
   wrapper, following the exact precedent already registered for `/knk itemscan claim`
   (`KnkAdminCommand.java`): it does nothing `/knk task-claim` couldn't already do, it just saves
   typing `task-claim` plus remembering the code is a kit scan. Both commands call the identical
   `KnkTaskClaimCommand.onCommand` logic underneath — there is exactly one claim implementation,
   two ways to invoke it.

Implementation-wise, this means Phase 6 (`IMPLEMENTATION_PLAN.md`) must not treat the dedicated
`/knk kitscan claim` command as the only or primary way in — registering the handler into
`WorldTaskHandlerRegistry` is what makes `/knk task-claim` work, and that registration is required
regardless of whether the dedicated command is ever added.

### 6.3 `OutputJson` shape

```json
{
  "fieldName": "KitScan",
  "status": "Success",
  "helmet": { "material": "minecraft:iron_helmet", "displayName": "Iron Helmet", "lore": [], "quantity": 1, "vanillaEnchantments": [], "customEnchantments": [] },
  "chestplate": null,
  "leggings": null,
  "boots": null,
  "shield": null,
  "hand": { "material": "minecraft:iron_sword", "displayName": "Iron Sword", "lore": [], "quantity": 1, "vanillaEnchantments": [], "customEnchantments": [] },
  "contents": [
    { "slot": 9, "material": "minecraft:arrow", "displayName": "Arrow", "lore": [], "quantity": 64, "vanillaEnchantments": [], "customEnchantments": [] }
  ],
  "capturedAt": 1674845123456,
  "warnings": []
}
```

A `null` named slot means that equipment slot was empty at scan time (mirrors `ItemScan`'s own
`isEmptyHand` handling, generalized to six slots instead of one). `contents` omits empty slots
entirely (there's no "empty content" concept the way a `null` equipment slot has one).

### 6.4 Web-app: resolving each scanned item to an `ItemBlueprint`, then filling the Kit form

This is the one place `KitScan` is genuinely more involved than `ItemScan`: `ItemScan` fills
fields *on the one entity being edited*, but `KitScan` must populate **FK-picker fields**, each
pointing at a *different, already-existing* `ItemBlueprint` row per scanned item. For each of the
(up to seven) distinct scanned items:
1. **Auto-match**: search `itemBlueprintClient.searchPaged({ searchTerm: displayName })` (the
   exact pattern `applyItemScanResult` already uses for enchantment matching, §0a) and keep an
   exact match on `IconMaterial.namespaceKey` (case-insensitive) + `DefaultDisplayName`.
2. **No match → auto-create** a minimal `ItemBlueprint` (`DefaultDisplayName`, `IconMaterialRefId`
   resolved/persisted via the same `minecraftMaterialRefClient.persistFromCatalog` call
   `applyItemScanResult` already makes) so the Kit field has something concrete to reference. This
   is deliberately **not** a per-item confirmation prompt — the developer's request was about
   slot fidelity and the field-conflict check (§6.5) below, not an item-matching UX; auto-create
   keeps a full-inventory scan (up to 41 items) from turning into up to 41 manual decisions.
   Enchantment matching on each resolved item follows the same "auto-match with confirmation
   deferred to the item's own edit screen" approach already established for `ItemScan` — not
   re-litigated per Kit slot.
3. **Write the resolved `ItemBlueprintId`** into the corresponding Kit form field
   (`HelmetId`/.../`HandId`) or `Contents` entry (`{ SlotIndex, ItemBlueprintId, Quantity }`),
   using the same `applyMultipleFieldChanges`-style functional-setState pattern
   `applyItemScanResult` already uses to avoid the stale-closure race its own comments document.

**Known cost, not a blocker**: up to ~41 sequential search-or-create round trips per scan (worse
than `ItemScan`'s single-entity case). Acceptable for now — matches the existing per-enchantment
loop's own N-round-trip shape — a future batch endpoint is a reasonable follow-up if this proves
slow in practice, not a Phase 1 requirement.

### 6.5 Field-conflict check — reuses `ScanConflictModal` unchanged

Directly answers the developer's request ("do the check for existing data in those form fields,
same as is done for scanning an item for ItemBlueprint"): before applying the resolved patch,
build a `ScanConflictField[]` (the existing, generic `ScanConflictModal.tsx` component — no
changes needed to it) for every Kit field that **already has a value** and that the scan also
produced a value for:
- One conflict entry per already-filled equipment field (`HelmetId`/`ChestplateId`/
  `LeggingsId`/`BootsId`/`ShieldId`/`HandId`) whose scan result is non-null.
- One conflict entry for `Contents` as a whole (labeled with its existing entry count, same
  pattern `applyItemScanResult` already uses for the `DefaultEnchantments` M2M step) if the
  Kit's `Contents` step already has any entries — the resolution is all-or-nothing for the whole
  list (either replace every content slot with the fresh scan, or keep every existing entry),
  not a per-slot merge; a per-slot three-way merge (kept slot + scanned slot + possibly-different
  index) is real added complexity with no clear default behavior, and isn't what was asked for.

Same defaulting behavior as `ItemScan`'s modal: every conflicting field defaults to "use scan
result" (triggering a scan is itself a request for fresh data), with the admin able to flip
individual fields back to "keep current" before applying. Fields with no existing value apply the
scan result immediately with no prompt, exactly like `ItemScan`.

### 6.6 Not added to `HEADLESS_TASK_TYPES`

Same as `ItemScan` (`WorldBoundFieldRenderer.tsx`'s `HEADLESS_TASK_TYPES` set) — `KitScan` needs
the normal claim-code banner UI, not the headless-task treatment.

## 7. Menu grant path — deferred, blocked on InventoryMenu

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

## 8. Open items carried forward (not blocking this plan)

- **`ItemInstance`** doesn't exist yet (§1) — Kit contents/equipment reference `ItemBlueprint`
  only. If/when `ItemInstance` is built, granting a kit item that should be soulbound/ghosted/
  instance-tracked from the moment of grant is a natural extension point here, but is explicitly
  out of scope now, matching vision §9.1's own scoping.
- **A generic District/Territory access-gating mechanism** (vision §2.2/§2.3) doesn't exist yet
  either. Kit's three gating fields (§2.1) are a deliberately narrow, kit-specific version of the
  same idea — if a shared mechanism gets built later, migrating Kit onto it is a small, isolated
  follow-up, not a redesign.
