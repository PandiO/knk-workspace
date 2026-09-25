# Kits — Implementation Plan

**Status:** Draft, ready for implementation.
**Last updated:** 2026-09-25 (`DESIGN.md` §0c: removed Phase 5's in-game CRUD fallback logic
entirely — `/kit manage` is now a pure pointer to the FormWizard, no `KitsApi` CRUD client needed;
`Kit` creation/editing/deletion is FormWizard-only). Previously updated 2026-09-25 (added a
`GiveKitAsync` staff-grant path to Phase 2, an in-game CRUD fallback command tree to Phase 5, and
a new Phase 6 for the web-app player-profile "Grant Kit" UI — see `DESIGN.md` §0b; renumbered
`KitScan`/seed-data/sequencing/open-items phases accordingly). Previously updated 2026-09-25
(added `KitScan` WorldTask authoring flow, slot-indexed `KitContent`/unified grant-placement
algorithm — see `DESIGN.md` §0a). Previously updated 2026-09-25 (initial draft).

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
- `Models/Item/KitContent.cs` — composite-key join entity per `DESIGN.md` §2.2 (revised, §0a):
  `KitId` (cascade delete) + `SlotIndex` (0-35, the composite key's second half — **not**
  `ItemBlueprintId`, since two different slots may legitimately hold the same `ItemBlueprint`) +
  `ItemBlueprintId` (**Restrict** delete — the cascade-delete-bug fix) + `Quantity` (required,
  the actual stack size for that slot).
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
  `CooldownExpiresAt`/`IsPurchased` fields), `KitClaimResultDto` (resolved loadout: each named
  equipment field → `ItemBlueprintId` or null, `Contents` →
  `(SlotIndex, ItemBlueprintId, Quantity)[]`, for the plugin to place via `DESIGN.md` §4.2's
  placement algorithm).
- `Mapping/KitProfile.cs` — AutoMapper profile, same one-per-feature-area convention as every
  other entity.
- EF migration. **Hand-check the same class of risk `user-features`'s migrations already hit
  twice** (§3/§6 status in that plan): no new column here defaults destructively for existing
  rows, since this is a wholly new set of tables with no pre-existing data to corrupt — lower
  risk than those migrations, but still worth a dry run against a local DB copy before applying,
  per that plan's established practice.

## 2. Phase 2 — `KitService` and API surface (knk-web-api)

- `Services/KitService.cs` implementing `DESIGN.md` §4.1's five methods:
  `GetAvailableForUserAsync`, `ClaimKitAsync`, `PurchaseKitAsync`, **`GiveKitAsync`** (new, §0b —
  bypasses gating/cooldown/cost by design, still runs §4.2's placement algorithm),
  `GrantFirstJoinKitsAsync`. Injects `ITitleService`, `IUserPermissionGroupService`,
  `IPermissionResolutionService` (all already exist, per `DESIGN.md` §3 — this service is a
  caller, not a reimplementer, of gating logic), an `IUserService`/direct repository access for
  balance deduction, and **`IAuditLogService`** (new dependency, §0b — already exists per
  `docs/specs/user-management/IMPLEMENTATION_PLAN.md` Phase 2; `GiveKitAsync` calls
  `Record(actorUserId, targetUserId, "KitGranted", ...)`).
- Add `KitGranted` to the `AuditLogEntry.Action` set (`Models/AuditLogEntry.cs`, per
  `docs/specs/user-management/DESIGN.md` §4 — it's a string/enum value, not a schema change to
  the table itself).
- `Repositories/KitRepository.cs` — thin EF Core wrapper, matching the `ItemBlueprintRepository`
  shape (CRUD + a paged search for the generic `FormConfiguration` table).
- `Controllers/KitsController.cs`:
  - Standard CRUD (`GetAll`/`GetById`/`Create`/`Update`/`Delete`/`search`) — same shape as
    `ItemBlueprintsController`, drives the generic web-app admin table for free once
    `[FormConfigurableEntity]` is set (Phase 3). **`Kit` CRUD is FormWizard-only** (`DESIGN.md`
    §4.0, revised) — unlike granting, no in-game surface calls these endpoints.
  - `GET api/Kits/available?userId=` → `GetAvailableForUserAsync`.
  - `POST api/Kits/{id}/claim?userId=` → `ClaimKitAsync`.
  - `POST api/Kits/{id}/purchase?userId=` → `PurchaseKitAsync`.
  - **`POST api/Kits/{id}/give`** (new, §0b — body `{ targetUserId }`, `actorUserId` resolved from
    the authenticated caller, never client-supplied) → `GiveKitAsync`. Called by both `/kit give`
    in-game (Phase 5) and the web-app player-profile "Grant Kit" action (Phase 6) — the one give
    endpoint, two callers.
  - `POST api/Kits/grant-first-join?userId=` → `GrantFirstJoinKitsAsync` (called by the plugin's
    first-join hook, `DESIGN.md` §4.4 — not the generic CRUD path).
- Unit tests for `KitService`: gating combinations (title-only, group-only, node-only, all three,
  none), cooldown boundary (exactly at expiry, just before, just after), cost deduction
  (sufficient/insufficient balance, wrong currency field touched), single-purchase premium
  (unpurchased → blocked, purchased → free/no-cooldown claim), first-join grant (cost bypass,
  cooldown bypass, gating still enforced), **`GiveKitAsync` (gating/cooldown/cost all bypassed
  regardless of state, placement algorithm still runs, `AuditLogService.Record` called exactly
  once per give)**. Mirrors the rigor `PermissionResolutionService`'s own 22-test suite set for
  this codebase (`user-features` §1 status).

## 3. Phase 3 — Admin `FormConfiguration` (knk-web-app + knk-web-api)

**This is the *only* Kit authoring surface** (`DESIGN.md` §4.0, revised) — Phase 5's `/kit manage`
command tree is a pure pointer back to this form, not a fallback editor; nothing in-game creates,
edits, or deletes a `Kit` row.

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
    child step fields `SlotIndex` (Integer, 0-35) and `Quantity` (Integer) — same
    `ManyToManyRelationshipEditor` pattern `ItemBlueprint.DefaultEnchantments` already uses, now
    with two child fields instead of one (mechanically no different — the editor already supports
    an arbitrary child-step field list).
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
- `knk-api-client`: `KitsApi` port + impl — **read-only** (`getByIdAsync`/`listAsync`/
  `searchAsync`, mirrors `ItemBlueprintsApi` exactly, no Kit-specific exception — `DESIGN.md`
  §4.5, revised: `Kit` CRUD is FormWizard-only, so `knk-plugin` never needs a
  `createAsync`/`updateAsync`/`deleteAsync` client for it). `KitsCommandApi` (write/action side:
  `claimAsync`/`purchaseAsync`/**`giveAsync(targetUserId, kitId)`** (new, §0b)/
  `grantFirstJoinKitsAsync`, mirrors `UsersCommandApi`'s per-action POST/PUT pattern).
- `KnkKit` domain type (`knk-core/.../domain/item/`) — Bukkit-free DTO mirroring `KnkItemBlueprint`'s
  existing separation pattern.
- **Item-building reuses `ItemBlueprintBukkitMapper` as-is** — no new mapper. Given a
  `KitClaimResultDto`, resolve each referenced `ItemBlueprint` via the existing
  `ItemBlueprintsDataAccess`, build each `ItemStack` via the existing mapper (same call
  `ItemBlueprintsDebugCommand` already makes), then run **`DESIGN.md` §4.2's unified placement
  algorithm** for every resolved item (Helmet → Chestplate → Leggings → Boots → Shield → Hand →
  `Contents` by ascending `SlotIndex`) — not a simpler direct-equip/`addItem` path. A single
  `KitGrantPlacer` helper class (`knk-paper/.../kit/`) implements the shared five-step routine
  (empty → place; occupied+`isSimilar()` → merge with overflow; occupied+different →
  `firstEmpty()` in 0-35; no empty slot → `dropItemNaturally`) once, called once per item in
  order — not five copies of near-identical slot-conflict logic.

## 5. Phase 5 — Command surface and first-join hook (knk-plugin)

- `commands/KitCommand.java` per `DESIGN.md` §4.3 (`/kit list`/`get`/`give`/`purchase`),
  Brigadier-based, matching `ItemCommand.java`/`GateCommand.java`'s existing structure. Permission
  nodes `knk.kit.list`/`knk.kit.get`/`knk.kit.give`/`knk.kit.purchase`, checked via
  `KnkPermissible` (the in-house resolution engine from `user-features`), not a `plugin.yml` node.
  `/kit give` calls **`KitsCommandApi.giveAsync(targetUserId, kitId)`** (Phase 4's `give` client
  method) → `POST api/Kits/{id}/give` → `GiveKitAsync` — **not** the same call path as `/kit get`.
- **`/kit manage` — a FormWizard pointer, not a fallback editor (revised, §0c/`DESIGN.md` §4.5)**
  — a `/kit manage` sub-tree on the same `KitCommand.java`, gated by a single `knk.kit.manage`
  node (separate from the `list`/`get`/`give`/`purchase` player-facing nodes above). Recognized
  subcommands: `create`, `set <name> <field> <value>`, `content add|remove`, `delete <name>` (kept
  as literals so tab-completion/muscle memory lands somewhere useful) — **every one of them just
  sends a chat message naming the FormWizard route** (e.g. `<web-app base URL>/forms/kit` to
  create, `/forms/kit/edit/<id>` to edit an existing one) and returns; **none of them call
  `KitsController` at all.** No parsing of `<field>`/`<value>`, no `ItemBlueprint` name resolution,
  no `KitContent` manipulation — this is intentionally the simplest possible handler, since its
  only job is redirecting.
- `PlayerListener.java`: in the existing `if (user.isNewUser())` branch (currently just the
  welcome message, around line 142), add an async call to
  `kitsCommandApi.grantFirstJoinKitsAsync(user.id())`, following the exact pattern
  `triggerBackgroundSalaryPayout` already uses immediately below it (fire-and-forget, logged
  failure, never blocks the join event itself).

Phases 4 and 5 are the only two with a hard ordering dependency on each other (5 calls what 4
builds); both depend on Phases 1-2 (the backend contract) being stable, and are independent of
Phase 3 (the admin form is for authoring Kits, not for granting them) — including `/kit manage`,
which needs no backend dependency at all now that it's a pure pointer (§0c).

## 6. Phase 6 — Web-app: "Grant Kit" on the player profile page (new, `DESIGN.md` §4.6)

Depends on Phase 2 (`GiveKitAsync`/`POST api/Kits/{id}/give` must exist) and on
`docs/specs/user-management`'s `PlayerProfilePage.tsx` already existing (it does — shipped, per
that plan's Phase 1 status). Independent of Phases 3-5 (this is a different repo surface reading/
writing the same backend, not built on top of the FormWizard or the plugin).

**knk-web-app:**
- `apiClients/kitClient.ts` — `getAvailableForUser(userId)`, `give(kitId, targetUserId)`, mirroring
  the existing per-resource REST client pattern (`itemBlueprintClient.ts`).
- `PlayerProfilePage.tsx`: new "Kits" section (alongside the existing account/permissions/groups/
  title/premium/salary/owner-staff-mode sections, `docs/specs/user-management/DESIGN.md` §2) —
  lists every kit via `getAvailableForUser(the viewed player's id)` with its gating/cooldown/cost/
  purchase state, a "Grant" button per row calling `give(kitId, targetUserId)`, and a re-fetch of
  the list plus the page's existing "Recent activity" audit section afterward (same
  re-fetch-and-show-the-resolved-effect convention `docs/specs/user-management/DESIGN.md` §3
  already established for its own group/grant quick actions).
- No backend work here — Phase 2 already built everything this phase calls.

## 7. Phase 7 — `KitScan` WorldTask authoring flow (new, `DESIGN.md` §6)

An alternative to Phase 3's manual form authoring: scan a player's live inventory in-game and
relay it into the open Kit form. Depends on Phase 3 (the Kit `FormConfiguration`'s fields must
exist and be stable before a scan can target them) and Phase 1/2 (nothing to scan into
otherwise); independent of Phases 4/5 (granting a kit doesn't need this authoring path to exist).

**knk-plugin:**
- Extract a shared `ScannedItemJsonBuilder.build(ItemStack)` helper from
  `ItemScanTaskHandler`'s existing per-item JSON logic (material/displayName-or-humanized-
  fallback/lore/vanilla+custom enchantments/quantity) — used by **both** `ItemScanTaskHandler`
  and the new handler below, per `DESIGN.md` §6.1's explicit "reuse, don't reimplement" call.
  This is a refactor of existing, working code — verify `ItemScanTaskHandler`'s own behavior is
  unchanged after extraction (its existing tests, if any, are the check).
- `tasks/KitScanTaskHandler.java` — new `IWorldTaskHandler` (single-shot, synchronous, not
  headless — same shape as `ItemScanTaskHandler`, `DESIGN.md` §6.2), field name `"KitScan"`.
  `buildOutputJson` per `DESIGN.md` §6.3: `Helmet`/`Chestplate`/`Leggings`/`Boots` via their
  dedicated `PlayerInventory` getters, `Shield` via `getItemInOffHand()`, `Hand` via
  `getItemInMainHand()` (no slot recorded), `Contents` by iterating
  `getStorageContents()` indices 0-35, skipping `getHeldItemSlot()` and every empty slot,
  tagging each remaining entry with its index.
- Register `KitScanTaskHandler` into `WorldTaskHandlerRegistry` (`KnKPlugin.java`, same
  convention as every other handler). **This registration alone is what makes the generic
  `/knk task-claim <linkCode>` command work for `KitScan`** (`DESIGN.md` §6.2 — confirmed by
  reading `KnkTaskClaimCommand`, which dispatches purely by the claimed task's `fieldName`
  against the registry, no per-type code). This is the primary, must-work entry point and is
  **not optional** — do not treat the dedicated command below as a replacement for it.
- `commands/KnkAdminCommand.java`: **additionally**, register `/knk kitscan claim <linkCode>`
  following the exact block already registered for `/knk itemscan claim` (`DESIGN.md` §6.2) — a
  purely additive convenience wrapper dispatching into the same `KnkTaskClaimCommand.onCommand`
  that `/knk task-claim` already uses. Both commands must remain claimable; shipping only this
  one and dropping generic `/knk task-claim` support would be a regression from every other
  `WorldTask` field's behavior, not a simplification.

**knk-web-api:**
- No schema change (`WorldTask.TaskType` is already an open string field, per the Items plan's
  own finding — adding `"KitScan"` needs no migration).
- Optional, for parity with `GateBlockScan`'s `WorldTaskTypes` class: add a `KitScan` constant
  alongside `ItemScan`'s, if one was added for it — check first, since the Items plan's original
  doc only recommended this, and confirm whether it actually landed before assuming the constant
  exists to extend.

**knk-web-app:**
- `FieldEditor.tsx`: add a `KitScan` option alongside the existing `ItemScan` entry in the
  `worldTaskType` dropdown.
- `WorldBoundFieldRenderer.tsx`: add a `KIT_SCAN_TASK_TYPE = 'KitScan'` constant and an
  `isKitScanTask` helper mirroring `isItemScanTask` exactly (`DESIGN.md` §6.6) — **not** added to
  `HEADLESS_TASK_TYPES`.
- `FormWizard.tsx`: add `applyKitScanResult`, structured identically to the existing
  `applyItemScanResult` (`DESIGN.md` §6.4/§6.5):
  - Snapshot the Kit form's current step data *before* any `await`, for the same
    already-documented stale-closure race `applyItemScanResult`'s own comments warn about.
  - For each of the (up to 7) distinct scanned items (6 named slots + however many `Contents`
    entries), resolve to an `ItemBlueprintId` via `itemBlueprintClient.searchPaged` exact-match
    or create (`DESIGN.md` §6.4) — reusing the exact `minecraftMaterialRefClient.persistFromCatalog`
    call `applyItemScanResult` already makes for material resolution.
  - Build the `ScanConflictField[]` list per `DESIGN.md` §6.5 (one per already-filled equipment
    field the scan also produced a value for, one for `Contents` as a whole if it already has
    entries) and route through the **existing, unmodified** `ScanConflictModal`.
  - Apply the resolved patch via `applyMultipleFieldChanges`, writing `Contents` as a full
    `{ SlotIndex, ItemBlueprintId, Quantity }[]` replacement (all-or-nothing, per `DESIGN.md`
    §6.5 — not a per-slot merge).
- Dispatch: in the task-poll handler (`FormWizard.tsx` line ~2572's
  `task?.taskType === 'ItemScan'` check), add the matching `'KitScan'` branch calling
  `applyKitScanResult`.

## 8. Phase 8 — Seed data

Per `SEED_DATA.md`: seed `Category`/`Grade`/`Tag` rows (if not already present from other seed
efforts), the 9 `ItemBlueprint` rows, and the two `Kit` rows (`Default`, `Archer`) +
`KitContent` rows, all mapped from the legacy dev-DB backup
(`knightsandkings_dev_backup_19_10_21.json`). This is example/development seed content, not
final live-game balance — flagged as such in `SEED_DATA.md` given the source data's own
"Test"/"Open Beta" tags and joke item names (Maggoty Bread).

This phase has no code dependency on Phases 1-7 being complete (it's just data), but is
sequenced last here since seeding before the schema exists is meaningless, and seeding is the
natural way to verify Phases 1-5 end-to-end (create the two kits via the seed, `/kit get Default`
in-game, confirm the loadout is correct) — Phase 7 (`KitScan`) has its own independent
verification path (scan a live inventory, confirm the form fills correctly) that doesn't need
the seed data at all.

## 9. Sequencing summary

```
Phase 1 (schema) ──▶ Phase 2 (service/API) ──┬──▶ Phase 3 (admin form) ──▶ Phase 7 (KitScan)
                                              ├──▶ Phase 6 (web-app Grant Kit UI)
                                              └──▶ Phase 4 (plugin data access/item-building)
                                                        └──▶ Phase 5 (commands, first-join hook)
                                                                  └──▶ Phase 8 (seed data, verification)
```

Phases 1-3 deliver a fully admin-authorable Kit catalog on their own (creatable/editable via the
web app, nothing to grant yet) and are worth shipping independently if Phases 4-8 slip, matching
the sequencing precedent both the Items and user-features plans already established for this
codebase. Phase 6 (web-app Grant Kit UI) and Phase 7 (`KitScan`) are both pure add-ons — Phase 6
only needs Phase 2, Phase 7 only needs Phase 3 — neither blocks nor is blocked by granting
(Phases 4/5) or seeding (Phase 8).

## 10. Open items

None outstanding — all six developer-escalated/-requested decisions (`DESIGN.md`
§0/§0a/§0b/§0c) are resolved and folded into the design above. Two soft items worth
re-confirming at kickoff:
- §0's branch-base check (has `claude/user-features` merged to `main` yet?).
- Phase 7's `WorldTaskTypes` constant question (does an `ItemScan` constant actually exist to
  extend, or is `TaskType` passed as a bare string today? Check before assuming either way).
