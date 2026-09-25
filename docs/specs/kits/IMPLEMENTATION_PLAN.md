# Kits — Implementation Plan

**Status:** Draft, ready for implementation.
**Last updated:** 2026-09-25 (initial draft).

Ref: `DESIGN.md` in this folder for the architecture and every decision this plan sequences.
`SEED_DATA.md` for the legacy dev-DB backup mapped into v3 seed content. If anything below
conflicts with `DESIGN.md`, `DESIGN.md` wins — flag the conflict rather than silently picking one.

## 0. Branch and sequencing dependency

**This feature cannot be built against `main`/`master` today.** Kit's gating (`DESIGN.md` §3)
depends on `PermissionResolutionService`/`TitleBracket`/`PermissionGroup`, which are shipped but
still only on the unmerged `claude/user-features` branch (knk-web-api, knk-plugin). Per
`ACTIVE_SESSIONS.md`'s branch convention, Kits gets its own standing branch,
`claude/kits`, forked from `claude/user-features`'s current tip in knk-web-api and knk-plugin
(not from `main`), and from `main` in knk-web-app (no compile-time dependency on the unmerged
backend branch, same reasoning `user-management` used). **Before starting, re-check whether
`claude/user-features` has merged to `main`/`master` in the meantime** — if it has, fork
`claude/kits` from `main` instead and this whole paragraph is moot. Claim the feature in
`docs/ACTIVE_SESSIONS.md` before starting, noting this dependency explicitly so a parallel
session doesn't fork from a stale base.

## 1. Phase 1 — Schema (knk-web-api)

- `Models/Item/Kit.cs` — the `Kit` entity per `DESIGN.md` §2.1: nullable equipment-slot FKs
  (`HelmetId`/`ChestplateId`/`LeggingsId`/`BootsId`/`ShieldId`/`HandId`, all
  `[RelatedEntityField(typeof(ItemBlueprint))]`/`[NavigationPair]`-annotated, `Restrict` delete
  behavior — never `Cascade`), `MinTitleBracketId`/`RequiredPermissionGroupId`/
  `RequiredPermissionNode` gating fields, `GrantOnFirstJoin`, `CooldownSeconds`,
  `CostAmount`/`CostCurrency` (new `KitCostCurrency` enum: `Coins`/`Gems`),
  `IsSinglePurchasePremium`/`PremiumPriceGems`.
- `Models/Item/KitContent.cs` — composite-key join entity per `DESIGN.md` §2.2: `KitId`
  (cascade delete) + `ItemBlueprintId` (**Restrict** delete — the cascade-delete-bug fix) +
  `QuantityOverride`.
- `Models/Item/KitClaim.cs` — per `DESIGN.md` §2.3, not `[FormConfigurableEntity]` (append-only,
  viewed not edited, same convention as `AuditLogEntry`).
- `Models/Item/KitPurchase.cs` — per `DESIGN.md` §2.4, unique constraint on
  `(KitId, UserId)`.
- `Properties/KnKDbContext.cs`: register all four `DbSet<T>`s, configure `KitContent`'s composite
  key and the two different delete behaviors on its two FKs (this is the one part of this
  migration worth writing by hand rather than trusting EF's default — EF defaults every FK it can
  to `Cascade` unless told otherwise, and `ItemBlueprintId` here specifically must not be).
  Configure `KitPurchase`'s unique index on `(KitId, UserId)`.
- `Dtos/KitDtos.cs` — `KitDto` (full CRUD shape, including nested `Contents`), `KitAvailabilityDto`
  (per `DESIGN.md` §4.1's `GetAvailableForUserAsync` — kit summary + `CanClaim`/`DenialReason`/
  `CooldownExpiresAt`/`IsPurchased` fields), `KitClaimResultDto` (resolved loadout: slot →
  `ItemBlueprintId`, contents → `(ItemBlueprintId, Quantity)[]`, for the plugin to build from).
- `Mapping/KitProfile.cs` — AutoMapper profile, same one-per-feature-area convention as every
  other entity.
- EF migration. **Hand-check the same class of risk `user-features`'s migrations already hit
  twice** (§3/§6 status in that plan): no new column here defaults destructively for existing
  rows, since this is a wholly new set of tables with no pre-existing data to corrupt — lower
  risk than those migrations, but still worth a dry run against a local DB copy before applying,
  per that plan's established practice.

## 2. Phase 2 — `KitService` and API surface (knk-web-api)

- `Services/KitService.cs` implementing `DESIGN.md` §4.1's four methods:
  `GetAvailableForUserAsync`, `ClaimKitAsync`, `PurchaseKitAsync`, `GrantFirstJoinKitsAsync`.
  Injects `ITitleService`, `IUserPermissionGroupService`, `IPermissionResolutionService` (all
  already exist, per `DESIGN.md` §3 — this service is a caller, not a reimplementer, of gating
  logic) plus a `IUserService`/direct repository access for balance deduction.
- `Repositories/KitRepository.cs` — thin EF Core wrapper, matching the `ItemBlueprintRepository`
  shape (CRUD + a paged search for the generic `FormConfiguration` table).
- `Controllers/KitsController.cs`:
  - Standard CRUD (`GetAll`/`GetById`/`Create`/`Update`/`Delete`/`search`) — same shape as
    `ItemBlueprintsController`, drives the generic web-app admin table for free once
    `[FormConfigurableEntity]` is set (Phase 3).
  - `GET api/Kits/available?userId=` → `GetAvailableForUserAsync`.
  - `POST api/Kits/{id}/claim?userId=` → `ClaimKitAsync`.
  - `POST api/Kits/{id}/purchase?userId=` → `PurchaseKitAsync`.
  - `POST api/Kits/grant-first-join?userId=` → `GrantFirstJoinKitsAsync` (called by the plugin's
    first-join hook, `DESIGN.md` §4.4 — not the generic CRUD path).
- Unit tests for `KitService`: gating combinations (title-only, group-only, node-only, all three,
  none), cooldown boundary (exactly at expiry, just before, just after), cost deduction
  (sufficient/insufficient balance, wrong currency field touched), single-purchase premium
  (unpurchased → blocked, purchased → free/no-cooldown claim), first-join grant (cost bypass,
  cooldown bypass, gating still enforced). Mirrors the rigor `PermissionResolutionService`'s own
  22-test suite set for this codebase (`user-features` §1 status).

## 3. Phase 3 — Admin `FormConfiguration` (knk-web-app + knk-web-api)

- Add `[FormConfigurableEntity("Kit")]` to `Kit.cs` (Phase 1, mechanical) — nothing else to build
  server-side; the generic `MetadataService`/`FormConfigurationsController` engine picks it up
  automatically, per the same "no hardcoded entity allowlist" fact the Items plan already
  confirmed (`docs/specs/items/IMPLEMENTATION_PLAN.md` §1.3).
- Author the `Kit` `FormConfiguration` live via `FormConfigBuilder` (no seeder mechanism exists
  in this codebase — confirmed by both the Items and user-features plans, not re-litigated here):
  - General Information: `Name`, `Description`, `HelmetId`/`ChestplateId`/`LeggingsId`/
    `BootsId`/`ShieldId`/`HandId` (each an `ItemBlueprint` object picker), `GrantOnFirstJoin`,
    `CooldownSeconds`.
  - Contents: M2M step, `relatedEntityPropertyName: "Contents"`, `joinEntityType: "KitContent"`,
    child step field `QuantityOverride` (nullable Integer) — same `ManyToManyRelationshipEditor`
    pattern `ItemBlueprint.DefaultEnchantments` already uses.
  - Access Conditions: `MinTitleBracketId` (`TitleBracket` object picker), `RequiredPermissionGroupId`
    (`PermissionGroup` object picker), `RequiredPermissionNode` (plain text, matching how
    `PermissionGrant.Node` is authored elsewhere).
  - Economy: `CostAmount`, `CostCurrency` (enum dropdown), `IsSinglePurchasePremium`,
    `PremiumPriceGems`.
- `Kit` needs no new dependent-entity forms the way Items' Phase 2 needed for `Category`/`Grade`/
  `Tag`/`EnchantmentDefinition` — `ItemBlueprint`, `TitleBracket`, and `PermissionGroup` all
  already have their own admin `FormConfiguration`s (Items and user-features plans, both
  shipped).

## 4. Phase 4 — Plugin data access and item-building (knk-plugin)

- `knk-core/.../dataaccess/KitsDataAccess.java` — cache-first read gateway, same `FetchPolicy`/
  `FetchResult`/`DataAccessExecutor` shape as `ItemBlueprintsDataAccess` (`getByIdAsync`,
  `listAsync`, `refreshAsync`, `invalidate*`), for the kit catalog and
  `getAvailableForUserAsync`. Wired into `DataAccessFactory`/`KnKPlugin.java` per the existing
  convention.
- `knk-api-client`: `KitsApi` port + impl (read side, mirrors `ItemBlueprintsApi`) and a
  `KitsCommandApi` (write side: `claimAsync`/`purchaseAsync`/`grantFirstJoinKitsAsync`, mirrors
  `UsersCommandApi`'s per-action POST/PUT pattern).
- `KnkKit` domain type (`knk-core/.../domain/item/`) — Bukkit-free DTO mirroring `KnkItemBlueprint`'s
  existing separation pattern.
- **Item-building reuses `ItemBlueprintBukkitMapper` as-is** — no new mapper. Given a
  `KitClaimResultDto` (slot → `ItemBlueprintId`, contents → `(ItemBlueprintId, Quantity)[]`),
  resolve each `ItemBlueprint` via the existing `ItemBlueprintsDataAccess`, build the `ItemStack`
  via the existing mapper (same call `ItemBlueprintsDebugCommand` already makes), then:
  - Equip `Helmet`/`Chestplate`/`Leggings`/`Boots` directly into their armor slots — **skip any
    slot whose resolved `ItemBlueprintId` is null** (the bug-#5 fix, `DESIGN.md` §2.1).
  - `Shield` → off-hand, if set.
  - `Hand` → main hand, if set.
  - `Contents` → `addItem` each resolved `(ItemStack, quantity)` into the player's inventory,
    respecting `MaxStackSize` (split across multiple stacks if `quantity > MaxStackSize`, same
    concern any bulk item-give already has to handle).

## 5. Phase 5 — Command surface + first-join hook (knk-plugin)

- `commands/KitCommand.java` per `DESIGN.md` §4.3 (`/kit list`/`get`/`give`/`purchase`),
  Brigadier-based, matching `ItemCommand.java`/`GateCommand.java`'s existing structure. Permission
  nodes `knk.kit.list`/`knk.kit.get`/`knk.kit.give`/`knk.kit.purchase`, checked via
  `KnkPermissible` (the in-house resolution engine from `user-features`), not a `plugin.yml` node.
- `PlayerListener.java`: in the existing `if (user.isNewUser())` branch (currently just the
  welcome message, around line 142), add an async call to
  `kitsCommandApi.grantFirstJoinKitsAsync(user.id())`, following the exact pattern
  `triggerBackgroundSalaryPayout` already uses immediately below it (fire-and-forget, logged
  failure, never blocks the join event itself).

Phases 4 and 5 are the only two with a hard ordering dependency on each other (5 calls what 4
builds); both depend on Phases 1-2 (the backend contract) being stable, and are independent of
Phase 3 (the admin form is for authoring Kits, not for granting them).

## 6. Phase 6 — Seed data

Per `SEED_DATA.md`: seed `Category`/`Grade`/`Tag` rows (if not already present from other seed
efforts), the 9 `ItemBlueprint` rows, and the two `Kit` rows (`Default`, `Archer`) +
`KitContent` rows, all mapped from the legacy dev-DB backup
(`knightsandkings_dev_backup_19_10_21.json`). This is example/development seed content, not
final live-game balance — flagged as such in `SEED_DATA.md` given the source data's own
"Test"/"Open Beta" tags and joke item names (Maggoty Bread).

This phase has no code dependency on Phases 1-5 being complete (it's just data), but is
sequenced last here since seeding before the schema exists is meaningless, and seeding is the
natural way to verify Phases 1-5 end-to-end (create the two kits via the seed, `/kit get Default`
in-game, confirm the loadout is correct).

## 7. Sequencing summary

```
Phase 1 (schema) ──▶ Phase 2 (service/API) ──┬──▶ Phase 3 (admin form)
                                              └──▶ Phase 4 (plugin data access/item-building)
                                                        └──▶ Phase 5 (commands/first-join hook)
                                                                  └──▶ Phase 6 (seed data, verification)
```

Phases 1-3 deliver a fully admin-authorable Kit catalog on their own (creatable/editable via the
web app, nothing to grant yet) and are worth shipping independently if Phases 4-6 slip, matching
the sequencing precedent both the Items and user-features plans already established for this
codebase.

## 8. Open items

None outstanding — all three developer-escalated questions (`DESIGN.md` §0) are resolved and
folded into the design above. The one soft dependency worth re-confirming at kickoff is §0's
branch-base check (has `claude/user-features` merged to `main` yet?).
