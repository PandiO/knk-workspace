# Kits — Implementation Plan

**Status:** Phases 1-7 (§1-§7) shipped 2026-09-25 — see each section's "status" note below. The
§2 audit-log gap (`GiveKitAsync` never wrote `KitGranted`) is closed — see "§2 follow-up". §8 (seed
data) not started, ready whenever picked up on the same `claude/kits` branch in each repo (§0's
one-branch-per-repo rule).
**Last updated:** 2026-09-25 (§7: `KitScan` shipped in all three code repos and verified live in a
browser against a local API; §2 audit-log gap closed after merging `knk-web-api` `master` into
`claude/kits` — see "§7 status" and "§2 follow-up"). Previously updated 2026-09-25 (§4/§5: knk-plugin data access, item-building/`KitGrantPlacer`, the
`/kit` command surface, and the first-join grant hook — see "§4 status"/"§5 status" for the
branch-base merge this phase needed (`claude/kits` had never actually been forked from
`claude/user-features`, despite Phase 1 assuming it was), the `javac`-against-Maven-Central
verification method, and a real correctness bug caught before commit (first-join kits were being
claimed server-side but never placed into the player's inventory)). Previously updated 2026-09-25
(§3: Kit admin `FormConfiguration` authored and verified end-to-end;
see "§3 status" for the FormConfigBuilder-authoring-mechanism finding and the `entityApiMapping.ts`
gap this phase closed). Previously updated 2026-09-25 (`DESIGN.md` §0c: removed Phase 5's in-game CRUD fallback logic
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

### §1 status — shipped 2026-09-25

All of §1's knk-web-api bullets are done: `Models/Item/{Kit,KitContent,KitClaim,KitPurchase}.cs`,
`Properties/KnKDbContext.cs` (four new `DbSet`s + `OnModelCreating` config), `Dtos/KitDtos.cs`
(`KitDto`/`KitContentDto`/`KitAvailabilityDto`/`KitClaimResultDto`/`KitContentSlotDto`),
`Mapping/KitProfile.cs`, and migration `20260925105914_AddKitsPhase1Schema` (+ its `.Designer.cs`
and the updated `KnKDbContextModelSnapshot.cs`). Branch: `claude/kits` in `knk-web-api`, forked
from `origin/claude/user-features`'s tip at commit `bc67f95055ee6d4df5c5a4f29ed3569d7f15dbe2` —
confirmed still unmerged into `master` at branch time
(`git merge-base --is-ancestor origin/claude/user-features origin/master` returned false).
Commit `7537c71` on that branch. `claude/kits` was also created and pushed (no commits needed) in
`knk-plugin` (from `origin/main`) and `knk-web-app` (from `origin/main`), plus `knk-workspace`
(from `origin/main`, this doc update's own branch) — per §0's one-standing-branch-per-repo rule,
so no future phase session needs to re-derive the branch base.

Delete behaviors verified by direct code read against the exact DESIGN.md §2.1/§2.2 requirement:
`KitContent`'s composite key is `(KitId, SlotIndex)` (not `(KitId, ItemBlueprintId)`), its
`ItemBlueprintId` FK is `Restrict` (the cascade-delete-bug fix) while its `KitId` FK is `Cascade`;
`Kit`'s six equipment-slot FKs (`HelmetId`/.../`HandId`) and its two gating FKs
(`MinTitleBracketId`/`RequiredPermissionGroupId`) are all `Restrict`, matching every other
catalog-lookup FK precedent in this codebase (`ItemBlueprint.CategoryId`/`GradeId`/
`IconMaterialRefId`). `KitClaim`/`KitPurchase` are intentionally not `[FormConfigurableEntity]`
(append-only, viewed not edited, same convention as `AuditLogEntry`); `KitPurchase` has a unique
index on `(KitId, UserId)`.

**Not build- or migration-verified — the one real gap in this phase.** This sandbox has no
`dotnet` SDK, no `dotnet-ef` tool, and no local MySQL instance, and every .NET download host
(`builds.dotnet.microsoft.com`, `dotnetcli.azureedge.net`, `dotnetbuilds.azureedge.net`,
`download.visualstudio.microsoft.com`) is policy-blocked by this sandbox's egress proxy (confirmed
via the proxy's own status endpoint, same class of finding `user-features`'s own sessions
repeatedly hit for `repo.papermc.io` on the plugin side); `apt-get install dotnet-sdk-8.0` also
404s against the configured Ubuntu mirror. The migration `.cs`/`.Designer.cs` and the updated
`KnKDbContextModelSnapshot.cs` were hand-authored, not `dotnet ef migrations add`-generated: built
by directly extending the most recent real migration (`20260924094432_AddUserFeaturesPhase6Salary`
and its `.Designer.cs`) with the four new entity blocks EF's snapshot format requires (property/
key/index declarations, relationship declarations, and `Kit`'s one navigation-only block for its
`Contents` collection), verified by `diff` against the original file to confirm only the four
intended insertion points changed and nothing else drifted, plus a brace/paren balance check.
Column types, FK/index naming, and collation follow the exact patterns of the four most recent
real migrations in this repo. **Needs, before this phase is trusted the way earlier ones
eventually were:** a real `dotnet build` (confirms the four new model files and the DbContext
changes compile), then `dotnet ef database update` against a real local MySQL copy (confirms the
hand-authored migration/snapshot pair is actually valid and applies cleanly) — on a machine that
can reach the .NET download hosts, matching `user-features` Phase 5's own precedent for its
similarly SDK-less migration.

**Not started, per this phase's own explicit scope:** §2 (`KitService`/`KitsController`) and
everything after it — a follow-up session picks up Phase 2 on this same `claude/kits` branch.

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

### §2 status — shipped 2026-09-25

All of §2's bullets are done on the same `claude/kits` branch (knk-web-api), continued from
Phase 1's commit `7537c71` — no new branch forked, per §0's one-standing-branch-per-repo rule.
`Services/KitService.cs` (+ `Services/Interfaces/IKitService.cs`) implements all five
`DESIGN.md` §4.1 methods (`GetAvailableForUserAsync`/`ClaimKitAsync`/`PurchaseKitAsync`/
`GiveKitAsync`/`GrantFirstJoinKitsAsync`), calling straight into `ITitleService`/
`IUserPermissionGroupService`/`IPermissionResolutionService` for gating (§3) — all three
confirmed live in this codebase by direct code read before writing any Kits code, no new
resolution logic written. `Repositories/KitRepository.cs` (+ `Repositories/Interfaces/
IKitRepository.cs`) matches `ItemBlueprintRepository`'s CRUD/paged-search shape.
`Controllers/KitsController.cs` (new) — standard CRUD plus `available`/`claim`/`purchase`/`give`/
`grant-first-join`; `give` is `[Authorize]`-gated with `actorUserId` resolved from the caller's
own JWT claims (the same `uid`/`sub`/`NameIdentifier` fallback chain `UsersController` already
uses), never client-supplied. Additive DTOs `KitPurchaseResultDto`/`GiveKitRequestDto`
(`Dtos/KitDtos.cs`) and a `Kit -> KitClaimResultDto` AutoMapper map (`Mapping/KitProfile.cs`).
`Tests/knkwebapi_v2.Tests/Services/KitServiceTests.cs` (new) — 29 tests covering every
combination this section's own bullet list names: gating (title-only/group-only/node-only/
all-three/none), cooldown boundary (exactly-at/just-before/just-after expiry), cost deduction
(sufficient/insufficient Coins/Gems, confirming the untouched currency field stays untouched),
single-purchase premium (unpurchased blocked, purchased free with no cooldown check at all),
first-join grant (cost/cooldown bypass, gating still enforced, only flagged kits granted), and
`GiveKitAsync`'s full gating/cooldown/cost bypass.

**Atomicity (`DESIGN.md` §5.1's "deduct-then-record, one transaction, a failed deduction never
produces a claim row"):** `IKitRepository.AddClaimAsync`/`AddPurchaseAsync` take the
already-mutated `User` entity alongside the new claim/purchase row and persist both via one
`SaveChangesAsync()` call on the shared `KnKDbContext` — EF Core commits a single `SaveChanges`
call as one DB transaction on its own, so no explicit `BeginTransactionAsync` was needed. Every
balance/gating/cooldown check throws before either entity is even staged, so a failed check never
produces a partial write.

**One deliberate deviation from this section's own `IAuditLogService` bullet, flagged rather than
silently dropped:** the bullet above (and `DESIGN.md` §4.1) describe `GiveKitAsync` injecting
`IAuditLogService` and calling `Record(actorUserId, targetUserId, "KitGranted", ...)`, citing
`docs/specs/user-management/IMPLEMENTATION_PLAN.md` Phase 2 as already shipped. **Re-verified
false this session, by direct code read**: no `AuditLogEntry`/`AuditLogService`/`IAuditLogService`
exists anywhere in `knk-web-api`, and that plan's own Phase 2 status line still reads "Draft" —
not started. `GiveKitAsync` implements every other part of §4.1 in full (gating/cooldown/cost
bypass, a normal `KitClaim` row written) and leaves a `// TODO(kits-phase2)` comment at the exact
call site citing this paragraph, rather than inventing a stub/fake `IAuditLogService` that would
need to be found and swapped out later. **Whoever ships `user-management` Phase 2 (or a later
Kits phase) needs to wire the real call into `GiveKitAsync`** — this is the one remaining gap
between this phase and `DESIGN.md` §4.1 as written.

**Build/test verification — also resolves Phase 1's one open risk as a byproduct:** this
session's sandbox, unlike Phase 1's, had a working path to a `dotnet` SDK — `apt-get install
dotnet-sdk-8.0` succeeded after `apt-get update` (Phase 1's blocked `.NET` download hosts weren't
needed; the Ubuntu-packaged SDK came through the distro mirror instead). `dotnet build` succeeded
for both `knkwebapi_v2.csproj` and the test project, which incidentally **confirms Phase 1's
previously build-unverified models/DbContext/hand-authored migration classes actually compile** —
the one open item "§1 status" flagged. Full suite: 397 passed / 5 failed / 402 total, all 29 new
Kit tests green; the 5 failures are pre-existing and unrelated to Kits (`FieldValidationService
Tests`, two `PathResolutionServiceTests` cases, `ClientActivityStoreTests`,
`FormSubmissionProgressRepositoryTests`), matching the same pre-existing-failure pattern other
rows in this file document. **Not done, and still Phase 1's own open item:** actually applying
the migration to a live MySQL instance — no reachable MySQL existed in this sandbox either.

**Not started, per this phase's own explicit scope:** §3 (admin `FormConfiguration`), §4/§5
(knk-plugin data access + commands), §6 (web-app Grant Kit UI), §7 (`KitScan`), §8 (seed data).
**Next:** §3 and §6 can both start now — §3 only needs Phase 1's `[FormConfigurableEntity]` tag
(already present), §6 only needs this phase's `give` endpoint (now shipped); §4/§5 are
independent `knk-plugin` work with no dependency on §3/§6.

### §2 follow-up — audit-log gap closed 2026-09-25 (Phase 7 session)

The `TODO(kits-phase2)` described above is gone. **`knk-web-api` `claude/kits`: `fe151ef` (merge
of `origin/master` `3be3226`), `2c83019` (the fix).**

- **Merge first.** `claude/kits` was 7 commits behind `master` (merge base `bc67f95`), and
  `IAuditLogService` only exists on `master` (user-management Phase 2, `d52bdfc`). The only
  textual conflict was `Properties/KnKDbContext.cs`'s `DbSet` block (kept both sides).
  `Migrations/KnKDbContextModelSnapshot.cs` auto-merged, even though the hand-off expected a
  conflict there. **The merge also needed two semantic fixes git couldn't see:** master's
  `3be3226` split `TitleBracket.Name` into `MaleName`/`FemaleName` + `NameFor(Gender?)` and gave
  `ITitleService.ResolveAsync` a gender parameter. So `KitService`'s title-gating denial message
  now uses `required.NameFor(user.Gender)`, and `KitServiceTests`' fixtures were updated to match.
  Without this, `claude/kits` wouldn't compile after the merge. No migration file was touched.
  `AddKitsPhase1Schema` (`20260925105914`) sorts between master's `SeedDefaultPermissionGroup` and
  `AddUserFeaturesPhase6RealTitleDataAndFreeze`. It only creates new tables, so it's harmless in
  that position, and EF applies it as pending on a DB that already has master's later migration.
- **The fix.** `AuditAction.KitGranted = 11` was appended, with no renumbering. The column is a
  32-char string, so no migration is needed. `IAuditLogService` is injected into `KitService`.
  `GiveKitAsync` now calls `RecordAsync(actorUserId, targetUserId, AuditAction.KitGranted,
  {kitId, kitName, claimId})` after writing the `KitClaim` row. The details are JSON-serialized,
  like every other `RecordAsync` caller. The method is named `RecordAsync`, not the `Record` this
  section's bullet uses.
- **Tests.** `KitServiceTests` covers three cases: a give records exactly one `KitGranted` entry
  with the right actor/target/details, a self-claim records none, and a failed give (unknown
  target) records none.
- **Verified for real.** `dotnet build` passes. On the full suite, the pre-merge `claude/kits`
  baseline was 402 tests / 5 failed, `origin/master` was 406 / 5 failed, and the merged result is
  **437 / 5 failed**. That's 406 + 29 Kit tests + 2 new, and the same 5 pre-existing failures by
  name in all three runs (`ClientActivityStoreTests`, `FormSubmissionProgressRepositoryTests`,
  `FieldValidationServiceTests`, two `PathResolutionServiceTests` cases). On a fresh local MySQL 8
  DB, `dotnet ef database update` applied the whole merged chain cleanly, and
  `dotnet ef migrations has-pending-model-changes` reported no drift, which confirms the
  auto-merged snapshot. Live: a real `POST api/Kits/1/give` (JWT-authenticated staff user) returned
  200, and `GET api/audit-log?targetUserId=` then returned a `KitGranted` row with
  `actorUserId` = the caller from the JWT, not client-supplied. **The gap is closed end-to-end.**
  The web-app's Phase 6 `'KitGranted'` label needed no change. Only its now-stale "not yet written
  server-side" comments were updated (`knk-web-app` `ae24214`, which also adds master's
  `PlayerFrozen`/`PlayerUnfrozen` to the TS union and labels).

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

### §3 status — shipped 2026-09-25

`Kit.cs`'s `[FormConfigurableEntity("Kit")]` was already present from Phase 1 — confirmed by
direct code read, nothing else needed server-side. **The FormConfiguration-authoring mechanism
question this section flagged was investigated, not assumed**: it is not a seeder script or a
call made against a running instance's admin API in the sense of a committed automation — it is
the `FormConfigBuilder` React page (`knk-web-app src/components/FormConfigBuilder/
FormConfigBuilder.tsx`) itself, a thin UI wrapper whose Save button does exactly one thing,
`formConfigClient.create()` → `POST /api/FormConfigurations` with a `FormConfigurationDto`
payload. There is no other path; `knk-web-api/test-phase3-4.sh` (a pre-existing ad-hoc
verification script in that repo, unrelated to Kits) confirms this same "call the live API
directly" pattern is already this codebase's own convention for exercising this engine outside
the browser. This session authored the config by POSTing that exact DTO shape to a locally-run
instance of that same endpoint — functionally identical to clicking through the builder UI, since
there is no seeder and no other mechanism to imitate — then confirmed the result by loading the
real `FormWizardPage` in a browser (Playwright) against it, not just checking the POST succeeded.

**Local verification environment, since no reachable dev instance existed in this sandbox
either:** `apt-get install dotnet-sdk-8.0 mysql-server` (same distro-mirror path Phase 2 used),
a fresh local MySQL database, `dotnet ef database update` applying every migration through
`20260925105914_AddKitsPhase1Schema` cleanly — **this also closes Phase 1's last open item**,
"not migration-verified," which had been carried since Phase 1 pending a reachable MySQL
instance. `knk-web-api` and `knk-web-app` (`npm start`) were then run locally against each other.

**Steps/fields authored, exactly per this section's field matrix** (verified against live
`Kit`/`KitContent` entity metadata before authoring, not assumed): General Information
(`Name`, `Description`, six `ItemBlueprint` object pickers for `Helmet`/`Chestplate`/`Leggings`/
`Boots`/`Shield`/`Hand`, `GrantOnFirstJoin`, `CooldownSeconds`); Contents (M2M step,
`relatedEntityPropertyName: "Contents"`, `joinEntityType: "KitContent"`, one child step carrying
`SlotIndex`/`Quantity`); Access Conditions (`TitleBracket`/`PermissionGroup` object pickers,
`RequiredPermissionNode` plain text); Economy (`CostAmount`, `CostCurrency` enum dropdown sourced
live from `KitCostCurrency`, `IsSinglePurchasePremium`, `PremiumPriceGems`). Object-picker fields
were authored on the navigation property (`Helmet`, not `HelmetId`) per this engine's own
`fieldName + "Id"` FK-normalization convention (`normalizeFormSubmission.ts`), matching how
`ItemBlueprint.Category`/`DefaultEnchantments` are already authored — confirmed by reading that
convention directly rather than guessing field names.

**Confirmed rendering and a full round-trip, not just "wrote a payload that should work"**: a
Playwright browser session logged into the running web app, opened `/forms/kit`, and screenshotted
all four steps in sequence — General Information, Contents (M2M editor), Access Conditions, and
Economy (enum dropdown correctly offering `Coins`/`Gems`) — every field rendered exactly as
configured. Submitting the form initially failed with **"No API client configured for kit"** —
a real, necessary gap this phase's plan hadn't named: `knk-web-app`'s generic
`Create`/`Update`/`Delete`/fetch-by-id dispatch (`utils/entityApiMapping.ts`) is its own
per-entity hardcoded registry (distinct from the metadata engine's "no allowlist" fact, and not
mentioned by this section or by the Items-plan precedent it cites) that every FormWizard-authored
entity needs an entry in before its Submit button can work at all. Added `apiClients/kitClient.ts`
(mirrors `itemBlueprintClient.ts`'s shape exactly: `getAll`/`getById`/`create`/`update`/`delete`/
`searchPaged`) and registered `'kit'` in all four `entityApiMapping.ts` dispatch functions, plus
the matching `Controllers.Kits`/`KitOperation` enum entries and a `KitDto`/`KitContentDto` TS type
mirroring `knk-web-api`'s `Dtos/KitDtos.cs` field-for-field. After that fix, a full submit
returned `201` and a real `Kit` row persisted; a follow-up direct-API round-trip with every field
populated (equipment FK, two `Contents` slots, `TitleBracket`/`PermissionGroup` FKs, permission
node, cooldown, cost/currency, premium fields) read back byte-for-byte identical. `npm run build`
and `npm run test:ci` both pass on the final state (236 tests, the same 16 pre-existing/unrelated
failures confirmed via a stash-and-rerun diff — zero regressions from this phase's changes).

**Commits, `claude/kits`:** `knk-web-app` `8b8849f` (the `entityApiMapping.ts`/`kitClient.ts`
registration fix — the only code this phase adds; the `FormConfiguration` itself is database
data, not a commit). No `knk-web-api` code changes this phase (Phase 1's tag was already there).
Nothing pushed to `main`/`master` in any repo.

**Not started, per this phase's own explicit scope:** §4/§5 (knk-plugin data access + commands),
§6 (web-app Grant Kit UI), §7 (`KitScan`), §8 (seed data). **Next:** §4/§5/§6 can all start now —
none of them depend on anything this phase added beyond Phase 2's already-shipped API surface;
§7 (`KitScan`) additionally needs this phase's now-stable field set, which it has.

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

### §4 status — shipped 2026-09-25

All of §4's bullets are done on `claude/kits` (knk-plugin), continued from Phase 3's state (no
new branch forked, per §0's one-standing-branch-per-repo rule) — but **only after resolving a
real, unassumed branch-base gap this section itself warned about**: see the "branch-base
resolution" paragraph below before anything else.

**`knk-core`/`knk-api-client` (Bukkit-free):** `dataaccess/KitsDataAccess.java` — same
`FetchPolicy`/`FetchResult`/`DataAccessExecutor` cache-first shape as `ItemBlueprintsDataAccess`
(`getByIdAsync`/`refreshAsync`/`searchAsync`/`listAsync`/`invalidate*`), plus a deliberately
**never-cached** `getAvailableForUserAsync(userId)` passthrough — per-user cooldown/cost/purchase
state must be fresh on every `/kit list`, the same reasoning `DESIGN.md` §4.1 gives for why
`ClaimKitAsync` never trusts a caller's own prior availability read either. `ports/api/{
KitsQueryApi,KitsCommandApi}.java` — `KitsQueryApi` is read-only (`search`/`getById`/
`getAvailableForUser`), no `create`/`update`/`delete` client method exists at all (`DESIGN.md`
§4.0/§4.5: `Kit` CRUD is FormWizard-only); `KitsCommandApi` covers `claimAsync`/`purchaseAsync`/
`giveAsync(targetUserId, kitId)`/`grantFirstJoinKitsAsync`. `domain/item/{KnkKit,KnkKitContent,
KnkKitAvailability,KnkKitClaimResult,KnkKitPurchaseResult}.java` — Bukkit-free records mirroring
`knk-web-api`'s `KitDto`/`KitContentDto`+`KitContentSlotDto`/`KitAvailabilityDto`/
`KitClaimResultDto`/`KitPurchaseResultDto` field-for-field (read directly from `Dtos/KitDtos.cs`,
not assumed from this plan's summary — one deliberate simplification: `KitContentDto` and
`KitContentSlotDto` are wire-identical `(SlotIndex, ItemBlueprintId, Quantity)` shapes server-side,
so the plugin uses one shared `KitContentSlotDto`/`KnkKitContent` type for both instead of two
structurally-identical client types). `dto/*`, `mapper/KitsMapper.java`, `impl/{KitsQueryApiImpl,
KitsCommandApiImpl}.java` (new, built on `BaseApiImpl` like the newer `PermissionsApiImpl`, not
the older raw-OkHttp shape `ItemBlueprintsQueryApiImpl` predates), wired into `KnkApiClient`
(`getKitsQueryApi()`/`getKitsCommandApi()`). `DataAccessFactory.createKitsDataAccess` — passes
`entitySettings.kits().ttl()` (the entity's own configured TTL) the same way
`createPermissionsDataAccess` does, **not** the known-broken pattern this section's own bullet
list flagged (most other `create*DataAccess` call sites pass the *global* cache TTL from
`KnKPlugin.java` instead of the entity's own `ttl-minutes`/`-seconds`) — `KnKPlugin.java`'s call
site still passes `config.cache().ttl()` like every other pre-existing call site, so this doesn't
newly fix that pre-existing gap, but it does correctly wire the config plumbing
(`KnkConfig.EntityCacheSettings.kits`, `ConfigLoader`, `config.yml`'s new `entities.kits` block)
so a future cleanup pass fixing all 11 broken call sites at once picks Kits up for free.

**`knk-paper` (Bukkit-dependent):** `kit/KitGrantPlacer.java` — one shared static routine,
`resolveAsync` (network calls, off-main-thread safe: resolves each referenced `ItemBlueprint` via
the existing `ItemBlueprintsDataAccess`, builds each `ItemStack` via the existing
`ItemBlueprintBukkitMapper.fromBlueprint` — the same call `ItemBlueprintsDebugCommand` already
makes) and `place` (main-thread only, touches `Player`/`Inventory`): applies `DESIGN.md` §4.2's
exact five-step algorithm per item, in order Helmet→Chestplate→Leggings→Boots→Shield→Hand→
Contents (ascending `SlotIndex`), using the item's own `ItemBlueprint.MaxStackSize` (not just
Bukkit's material-default max stack) as the merge cap. **One deliberate, flagged scope narrowing
against a plausible broader reading, not silently assumed:** `KitGrantPlacer` does **not** apply
`ItemBlueprint.DefaultEnchantments` the way `/knk itemblueprints give` does — this section's own
bullet list says only "build each ItemStack via the existing mapper" (i.e. the single
`ItemBlueprintBukkitMapper.fromBlueprint` call), not the separate enchantment-application/
lore-reordering logic `ItemBlueprintsDebugCommand#executeGive` layers on top of that call. Taken
literally rather than assuming parity was intended. **If full `/knk itemblueprints give` parity
turns out to matter for Kit contents, that enchantment-application logic isn't reusable as-is (it's
private to `ItemBlueprintsDebugCommand`)** — a follow-up would need to extract it into a shared
helper first, the same "reuse, don't reimplement" precedent `DESIGN.md` §6.1 already used for
`ScannedItemJsonBuilder`.

**Branch-base resolution (the open question `IMPLEMENTATION_PLAN.md` §0/§10 and the task's own
instructions both named as real, not to be assumed either way):** checked directly, not assumed.
`claude/user-features` is **still unmerged** into `knk-plugin`'s `main` (`git merge-base
--is-ancestor origin/claude/user-features origin/main` → false). More importantly,
**`knk-plugin`'s `claude/kits` was confirmed bit-identical to `origin/main`** (`git rev-parse`
both → the same commit, `9cf81a7`) — i.e. still forked from `main`, never rebased onto
`claude/user-features`, exactly the risk Phase 1's own status note flagged without resolving.
`KnkPermissible`/`PermissionsDataAccess` were confirmed **absent** from `claude/kits` as checked
out (`grep` for both classes found zero matches before this session's changes). **Fixed by
merging `origin/claude/user-features` into `claude/kits` directly** (`git merge`, no `-m`-only
squash) — this fast-forwarded cleanly with **zero conflicts**, since `claude/kits` had no
divergent commits of its own yet to conflict with `user-features`' 14 commits. `claude/kits` is
now at `user-features`' tip (`2df0383`) plus this phase's own commit on top; `KnkPermissible`/
`PermissionsDataAccess`/`WorldTaskHandlerRegistry`/`ItemBlueprintsDataAccess`/
`ItemBlueprintBukkitMapper` are all now confirmed present and were the base this phase's code was
actually written and verified against. **Nothing pushed to `main`/`master`** — only `claude/kits`
was updated.

**Verification — real `javac` against Maven Central, not `./gradlew`, and why:** `repo.papermc.io`
returned a `403`/`connect_rejected` via this sandbox's egress proxy (confirmed directly with
`curl`, not assumed) — the same finding every prior session in this repo has hit. Worse than
usual: even `./gradlew --offline :knk-core:compileJava` failed immediately at Gradle's own
settings-evaluation stage (`knk-paper/build.gradle.kts`'s `com.gradleup.shadow` plugin isn't
cached either), so Gradle wasn't usable for **any** module this session, not just the Bukkit-
dependent ones. Fell back to the established precedent: fetched real `jackson-databind`/
`jackson-core`/`jackson-annotations`/`jackson-datatype-jsr310`/`gson`/`okhttp`/`okio-jvm`/
`kotlin-stdlib` jars directly from Maven Central (reachable, confirmed via `curl` `200`) and
compiled with `javac` directly. **`knk-core`** (163 files, excluding only the 9 pre-existing
Bukkit-`Vector`-dependent files in `util`/`gates`/`domain.gates` that predate this phase and were
untouched by it) — **0 errors**. **`knk-api-client`** (146 files, the entire module including the
full edited `KnkApiClient.java`, not just the new Kits files in isolation) against the `knk-core`
output plus the fetched jars — **0 errors**. **`knk-paper`** (the Bukkit-dependent half, including
`KitCommand.java`/`KitGrantPlacer.java` and every edited file) has no reachable `paper-api` jar in
this sandbox (checked: not cached anywhere on disk either) — syntax-checked via `javac` with the
`knk-core`/`knk-api-client` output on the classpath but no `paper-api`: every resulting error
(2,722 across the whole module, dominated by the pre-existing, deeply Bukkit-integrated
`KnKPlugin.java`) was confirmed to be a missing-package (`org.bukkit`/`io.papermc`/`net.kyori`) or
a cascading missing-symbol error consequence of that, with **zero genuine syntax errors** among
them — specifically confirmed for every new/edited file (`KitCommand.java`, `KitGrantPlacer.java`,
`PlayerListener.java`, `KnKPlugin.java`'s touched lines, `DataAccessFactory.java` which had **zero
errors at all**, being Bukkit-free itself). Hand-reviewed line-by-line against the real declared
signatures of `ItemBlueprintsDataAccess`, `MinecraftMaterialRefsDataAccess`,
`ItemBlueprintBukkitMapper`, `KnkPermissible`, `PlayerInventory`, and `CacheManager`/`UserCache`.
**Not compiler- or live-verified:** the actual in-game behavior of `/kit list|get|give|purchase`,
`/kit manage`, and the first-join grant — needs a real `./gradlew build` plus a live dev-server
pass on a machine that can reach `repo.papermc.io`, the same gap every prior `knk-plugin`
cloud-sandbox session in this file has carried forward.

**Not started, per this phase's own explicit scope:** §6 (web-app Grant Kit UI), §7 (`KitScan`),
§8 (seed data) — §5 (commands/first-join hook) was picked up in the same session, see "§5 status"
below.

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

### §5 status — shipped 2026-09-25

Done in the same session as Phase 4 (see "§4 status" for the branch-base merge and verification
method both phases share), continued on the same `claude/kits` commit.

`commands/KitCommand.java` (new) — plain `CommandExecutor` with manual subcommand dispatch,
matching `ItemCommand.java`/`GateCommand.java`/`ItemBlueprintsDebugCommand.java`'s existing shape
(confirmed by reading all three directly: none of them use Mojang's Brigadier library or Aikar's
ACF, just a `switch` over `args[0]`, despite this plan's own "Brigadier-based" phrasing — matched
the real, working convention rather than introducing a new command framework no other command in
this codebase uses). `/kit list` (`GetAvailableForUserAsync`, gating/cooldown/cost/premium state
per kit), `/kit get <name>` (self-claim via `claimAsync`), `/kit give <player> <name>` (staff-give
via **`giveAsync`**, not `claimAsync` — a different call path, per `DESIGN.md` §4.1/§4.3), `/kit
purchase <name>` (`purchaseAsync`, `IsSinglePurchasePremium` kits only). Kit names are resolved to
ids via `KitsDataAccess.searchAsync` with a `Name` filter, then a client-side case-insensitive
exact-name match against the returned page (defensive against the generic search filter's exact-
vs-contains semantics not being nailed down anywhere in the docs — an inexact "first result"
fallback was deliberately not used, since silently granting the wrong kit on a near-miss name is
worse than a clean "not found"). Every subcommand's permission node (`knk.kit.list`/`.get`/`.give`/
`.purchase`/`.manage`) is checked via `KnkPermissible.hasPermission(player, node)` inside the
command, **not** a `plugin.yml` `permission:` entry — matching `/knk` and `/ownermode`/
`/staffmode`'s existing precedent exactly (a `plugin.yml`-level node would be checked by Bukkit
*before* this executor ever ran, making the five separate per-action nodes unreachable). The
`knk.kit.*` nodes are still declared under `plugin.yml`'s `permissions:` block for documentation
purposes only, with the same "this declaration isn't what's actually checked" caveat `knk.mode.
owner`/`knk.mode.staff` already carry.

**`/kit manage` — confirmed pure FormWizard pointer, no CRUD, per `DESIGN.md` §0c (not the earlier
superseded draft):** `create`/`set`/`content`/`delete` (and bare `/kit manage`) each just send a
chat message and return; none call `KitsController`, no field/value parsing, no `KitsApi` write
client exists anywhere in `knk-plugin` (confirmed none was added). **One flagged, deliberate
deviation from this section's own example copy:** `DESIGN.md`/this plan both write the pointer
message as "`<web-app base URL>/forms/kit`" but explicitly say "the exact copy is an implementation
detail." No web-app base URL exists anywhere in `knk-plugin`'s config today (`config.yml` only has
`api.base-url`, the REST API's own origin, not the separate React web-app's) — rather than
fabricating a plausible-looking but unconfigured domain into a player-facing message, or adding a
whole new top-level `KnkConfig` record section (a disproportionate change for one chat message,
and one that would've also required updating `AccountCommandRegistryTest.java`'s `KnkConfig`
constructor call), the message names just the **route** (`/forms/kit`, `/forms/kit/edit/<id>`) —
satisfying this section's actual requirement ("names the FormWizard route, not just 'use the web
app' with no pointer") without inventing infrastructure. A future phase that adds a real
`web-app.base-url` config value can prefix it here trivially.

**First-join hook, with one real correctness fix over a literal reading of this section's own
bullet:** `PlayerListener.java`'s `onJoin` — **this section's bullet describes "the existing `if
(user.isNewUser())` branch... currently just the welcome message, around line 142"; that branch
does not actually exist anywhere in current `PlayerListener.java`** (confirmed by `grep` — no
`isNewUser()` call anywhere in this file; the join-time welcome message lives in a *different*
listener, `UserAccountListener.onPlayerJoin`, and doesn't branch on new-vs-returning at all either).
Read as stale plan text rather than silently worked around: added a **new** `if (user.isNewUser())`
block, placed immediately after `triggerBackgroundSalaryPayout(player, user.id())` in `onJoin`
(the nearest real anchor this section's own description points at), calling a new
`triggerBackgroundFirstJoinKits(player, user.id())` that mirrors `triggerBackgroundSalaryPayout`'s
exact fire-and-forget/logged-failure shape. **A second, more material fix over the first draft of
this method written during the session:** an initial version called
`kitsCommandApi.grantFirstJoinKitsAsync(userId)` and only logged the count of kits granted,
without ever placing the resolved items into the player's inventory — technically satisfying this
section's one-line bullet ("add an async call to grantFirstJoinKitsAsync") but making the whole
feature pointless (the server would record a `KitClaim` and the player would receive nothing).
Caught on review and fixed before committing: `triggerBackgroundFirstJoinKits` now resolves every
returned `KnkKitClaimResult` via `KitGrantPlacer.resolveAsync` (off the main thread, in parallel
across however many first-join kits exist) and, once resolution completes, hops onto the main
thread (guarded by `Bukkit.getPlayer(uuid) == null` in case the player disconnected mid-resolve,
the same guard `UserAccountListener` already uses) to call `KitGrantPlacer.place`, exactly like
`KitCommand`'s own grant/place plumbing does for `/kit get`/`/kit give`. Needed threading
`ItemBlueprintsDataAccess`/`MinecraftMaterialRefsDataAccess` through as two new `PlayerListener`
constructor parameters (previously only `KitsCommandApi` was needed) — `KnKPlugin.java`'s
construction call site updated accordingly.

**Verification:** covered by "§4 status" above — same session, same `javac`-against-Maven-Central
method for the Bukkit-free layer (N/A here, this phase is entirely `knk-paper`) and the same
syntax-check-without-`paper-api` method for `KitCommand.java`/the `PlayerListener.java`/
`KnKPlugin.java` edits, with zero genuine syntax errors found among them. **Not live-verified** —
same carried-forward gap as §4.

**Not started, per this phase's own explicit scope:** §6 (web-app Grant Kit UI), §7 (`KitScan`),
§8 (seed data — the natural end-to-end verification path for `/kit get <name>` once real Kit rows
exist, per §8's own text). **Next:** any of §6/§7/§8 can start now; §8 in particular would let a
future session close the "not live-verified" gap both §4 and §5 carry forward, once seeded on a
machine that can also reach `repo.papermc.io` for a real `./gradlew build`.

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

### §6 status — shipped 2026-09-25

**knk-web-app**, `claude/kits`, commit `71f69fb` (on top of `278becd`, a merge of `origin/main`
into `claude/kits` — see the stale-plan finding below for why that merge was needed first).

**A real, material stale-plan discrepancy found before writing any code, not silently trusted
or worked around** (this plan's own established convention, per "§4 status"/"§5 status"): this
section's own header and the hand-off briefing both asserted `PlayerProfilePage.tsx` "already
exists (shipped, per `user-management`'s Phase 1 status)." A direct `Glob`/`Grep` of
`knk-web-app`'s `claude/kits` tree found no such file anywhere, and
`docs/specs/user-management/IMPLEMENTATION_PLAN.md` itself was still headed `**Status:** Draft`
with no "§1 status" note of any kind — unlike this plan's own §1-§5, none of which ever shipped
without one. Flagged to the developer directly rather than either (a) silently building a
minimal stand-in profile page as a workaround, or (b) silently taking on all of `user-management`
Phase 1-3 as unplanned scope. **Developer's answer, verified rather than taken on faith:**
`user-management` is in fact fully implemented, just not yet merged into this plan's branch — the
real code was sitting on `origin/main` in `knk-web-app` (`127581d`/`90c2ee8`/`2428b10`, User
management Phases 1-3) and `origin/master` in `knk-web-api` (`2b5b122`/`d52bdfc`/`0e44410`, plus
`AuditLogService` — see below), with the workspace-side status notes/`ACTIVE_SESSIONS.md` entries
for that feature living on a separate `knk-workspace` branch, `claude/user-management`
(`4ed634d`), not yet merged into `main` either. Confirmed by direct `git log`/`git show` on all
three before proceeding, not assumed from the developer's summary alone. **Fix**: merged
`origin/main` into `knk-web-app`'s `claude/kits` (commit `278becd`, clean auto-merge, no
conflicts — `entityApiMapping.ts`/`enums.ts` were the only files both branches touched, and Kits'
`'kit'` entries and User-management's own additions were in disjoint sections) — this is what
actually brought in the real `PlayerProfilePage.tsx` (711 lines), `UserModerationPage.tsx`,
`userManagementClient.ts`, and the `/admin/users/:id` route this phase needed. Did **not** merge
`knk-workspace`'s `claude/user-management` doc branch into `claude/kits` — that would have pulled
in a large amount of unrelated documentation (event-listener catalogs, command catalogs, etc.);
this plan's own docs already had everything needed (`DESIGN.md` §2/§3's section/quick-action
convention), and the real `PlayerProfilePage.tsx` code was read directly for the actual current
shape rather than trusted from either doc.

**What shipped, read against the real (post-merge) `PlayerProfilePage.tsx`, not assumed:**
- `apiClients/kitClient.ts` — added `getAvailableForUser(userId)` (`GET api/Kits/available` with
  `userId` as a query param) and `give(kitId, targetUserId)` (`POST api/Kits/{id}/give`, body
  `{ targetUserId }`), following the exact `invokeServiceCall(data, operation, controller,
  method)` shape every other method in this file and `itemBlueprintClient.ts` already use — no
  new client pattern introduced. Phase 3's five CRUD methods are untouched.
- `types/dtos/kit/KitDtos.ts` — added `KitAvailabilityDto`, `KitContentSlotDto`,
  `KitClaimResultDto`, `GiveKitRequestDto`, each hand-checked field-for-field against
  `knk-web-api`'s real `Dtos/KitDtos.cs` (read directly off `claude/kits`, commit `3589593`) —
  not guessed from `DESIGN.md`'s prose description of the fields.
- `pages/admin/PlayerProfilePage.tsx` — new "Kits" section, placed between the existing
  Permissions and Recent Activity sections (same card styling/table pattern the Groups section
  already established), listing every kit via `getAvailableForUser` with its status (Available /
  the real `denialReason` text), active cooldown (`cooldownExpiresAt`, only shown while still in
  the future), and cost (free / `costAmount` + `costCurrency` / premium gems price +
  purchased-or-not), plus a per-row **Grant** button calling `give(kitId, targetUserId)`. On
  success, re-fetches both the kit list and the Recent Activity feed in parallel — matched
  exactly to this page's own established `refreshAfterAction` pattern (read directly from the
  real group-assign/grant-node handlers already on the page, not invented fresh).
- Added a `'KitGranted'` case to `AuditAction`/`auditActionLabel` (both already existed for
  `user-management`'s own action types) so the Recent Activity feed already knows how to render a
  kit grant the moment the entry exists — see the audit-log gap below for why none exist yet.

**The audit-log gap (flagged at hand-off, re-verified here) is real but its status changed
mid-session, and this phase still cannot close it — flagged again, not silently left unexplained:**
`knk-web-api`'s `KitService.GiveKitAsync` (`claude/kits`, commit `3589593`) still has the literal
`TODO(kits-phase2)` comment where an `AuditLogService.Record(...)` call belongs, confirmed by
direct `git show` of the method body. What changed: `IAuditLogService`/`AuditLogService`/
`AuditLogEntry` **do now exist** on `knk-web-api`'s `origin/master` (commit `d52bdfc`, "Add User
management Phase 2: audit log + quick actions" — `user-management` Phase 2 has in fact shipped,
just not documented as such anywhere in `knk-workspace/main` yet, matching the same
"code shipped, workspace docs lag behind on a separate branch" pattern as Phase 1/3 above). So
the service this TODO needs is real and ready to be wired in. **This session could not do that
wiring**: it would require (a) merging `origin/master` into `knk-web-api`'s own `claude/kits`
branch (still at `3589593`, based on an earlier `master`) and (b) adding the
`AuditLogService.Record` call at the TODO site and pushing — and this session's `add_repo` request
for push access to `knk-web-api` was denied by this environment's own auto-mode permission
classifier. `knk-web-api` was only ever readable this session (its `claude/kits` tip, `3589593`,
was cloned and read directly for the DTO/controller contracts above), never writable. **Net
effect**: a real `Grant` click today writes a normal `KitClaim` row (so the kit list's own
re-fetch correctly shows the grant took effect) but nothing shows up in Recent Activity, since
`GiveKitAsync` still never calls `AuditLogService.Record`. The web-app side (the `'KitGranted'`
case added above) is ready and needs no further change — a future session with `knk-web-api` push
access just needs to merge `master` into `claude/kits` there and add the one call at the existing
TODO site.

**Verification**: real `npm install` (with `CYPRESS_INSTALL_BINARY=0` — the Cypress binary
download itself failed on this sandbox's network, unrelated to anything in this phase; `test:ci`/
`build` don't need it) and a real `npm run build` + `CI=true npm run test:ci`, not a
build-only or hand-reviewed check. `npm run build`: clean, only pre-existing ESLint warnings in
files this phase never touched. Tests: 236 total, 220 passed, 16 failed — confirmed via a real
stash-and-rerun diff (stashed this phase's 4 changed files, reran, got the identical 16 failing
suites by name, `diff` clean) that all 16 are pre-existing and unrelated, exactly matching Phase
3's own documented baseline ("236 tests, the same 16 pre-existing/unrelated failures"), zero
regressions from this phase's change. Did not have a reachable `knk-web-api` instance to drive a
live Playwright round-trip against (no local MySQL/`dotnet` stood up this session, and no push
access as noted above meant no reason to stand one up purely for read-only verification either) —
verified instead by direct code-reading of the real, current `KitsController`/`KitService`
contract (`available`/`give` request/response shapes) rather than guessing from `DESIGN.md`'s
prose, plus the component-level build/test coverage above. This is a real gap relative to Phase
3's own live-Playwright-verified bar, flagged rather than glossed over.

**Not required, not done**: `Kit`'s own generic admin table getting a "Give to player" row action
(explicitly optional in `DESIGN.md` §4.6) — skipped, no time-to-spare nice-to-have attempted.

**Addendum (Phase 7 session):** the audit-log gap above is closed — see "§2 follow-up" for the
merge, fix, and live verification. Recent Activity now shows kit grants with no further change to
this phase's code.

**Not started, per this phase's own explicit scope**: §7 (`KitScan`), §8 (seed data). **Next**:
either can start now; separately, and not blocking either, a future session with `knk-web-api`
push access should merge `origin/master` into that repo's `claude/kits` and add the
`AuditLogService.Record` call at `GiveKitAsync`'s existing `TODO(kits-phase2)` site to close the
audit-log gap for real — at that point this phase's web-app work needs zero further changes for
Recent Activity to start showing kit grants.

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

### §7 status — shipped 2026-09-25

All three repos, on `claude/kits`. **`knk-plugin`: `009cd34`** (merge of `origin/main` `07d3ef6`,
clean) **+ `f70f0ac`**. **`knk-web-api`: `c6950b5`**. **`knk-web-app`: `a41060a`**. No
`main`/`master` push anywhere.

**What shipped:**
- **knk-plugin.**
  - `tasks/ScannedItemJsonBuilder` holds the per-item JSON logic, extracted verbatim from
    `ItemScanTaskHandler`: material, `maxStackSize`, display name with humanized fallback, lore,
    vanilla enchantments, lore-parsed custom enchantments, and PDC. `ItemScanTaskHandler` now
    copies the builder's fields onto its flat root.
  - `tasks/KitScanTaskHandler` is single-shot, synchronous, and not headless. It captures:
    - `helmet`/`chestplate`/`leggings`/`boots` via the armor getters
    - `shield` via off-hand
    - `hand` via main hand, with no slot recorded
    - `contents` from `getStorageContents()` 0-35, skipping air and `getHeldItemSlot()`

    Each item is the shared JSON plus `quantity` (and `slot` for contents). Empty equipment
    slots are JSON `null`. An empty inventory gives `status: "Warning"` plus a warning line.
  - Registered in `KnKPlugin.java` by field name **and** by taskType `"KitScan"`.
  - `/knk kitscan claim <linkCode>` was added to `KnkAdminCommand.java`, mirroring
    `/knk itemscan claim`, and dispatches into the same `KnkTaskClaimCommand`.
- **knk-web-api.** `WorldTaskTypes.KitScan` was added (`Dtos/GateBlockScanDtos.cs`), because
  `ItemScan`'s constant *did* land there (§10's open question, checked). There is no schema change.
- **knk-web-app.**
  - `FieldEditor.tsx`: `KitScan` dropdown option, plus a hint naming both claim commands.
  - `WorldBoundFieldRenderer.tsx`: `KIT_SCAN_TASK_TYPE`/`isKitScanTask`, **not** in
    `HEADLESS_TASK_TYPES`, plus a KitScan result summary (status / equipment slots / inventory
    slots).
  - `FormWizard.tsx`: `applyKitScanResult`, dispatched beside the `ItemScan` branch in
    `onTaskCompleted`. The plan's "line ~2572" was accurate. It:
    - snapshots step data before any `await`
    - resolves each distinct scanned item via `searchPaged` exact match (`iconNamespaceKey`
      case-insensitive + `defaultDisplayName`) or auto-creates it, using the same
      `getHybrid`/`persistFromCatalog` material calls and `enchantmentDefinitionClient` matching
      `applyItemScanResult` makes
    - caches per material+name, so e.g. two arrow stacks resolve to one blueprint
    - builds `ScanConflictField[]` (one per filled equipment field whose scan is non-null, one
      for Contents as a whole) through the unmodified `ScanConflictModal`
    - writes `Contents` as a full `{SlotIndex, ItemBlueprintId, Quantity}[]` replacement
  - New unit test in `WorldBoundFieldRenderer.results.test.ts`.

**Discrepancies between the plan/design text and the real code, flagged rather than silently
resolved:**
1. **`ItemScan` never emitted `quantity`.** `DESIGN.md` §6.1 lists quantity among the per-item
   fields "`ItemScanTaskHandler` already extracts". It doesn't: it emits `maxStackSize`, not the
   stack amount. To keep ItemScan's output unchanged (§7's own requirement), the shared builder
   emits exactly ItemScan's fields and `KitScanTaskHandler` adds `quantity` itself.
2. **`KnkTaskClaimCommand` does not dispatch "purely by `fieldName`"** (§7 bullet /
   `DESIGN.md` §6.2). It calls `WorldTaskHandlerRegistry.startTask(player, taskType, fieldName,
   …)`, which tries **taskType first** and then falls back to fieldName. The Kit form binds the
   WorldTask to a *real* Kit field (the local run used `Description`; the claimed task came back
   `fieldName=Description`). Registering only by `getFieldName()` would therefore make `/knk
   task-claim` silently start nothing. So the handler is also registered under taskType
   `"KitScan"`, the same dual registration `ItemScan` already needed for the same reason.
3. **Which field hosts the KitScan panel was never specified, and the renderer assumes one
   value per field.** `WorldBoundFieldRenderer` writes a completed task's extracted value into its
   bound field via `onChange`. A kit scan has no single value for any one Kit field. So KitScan is
   special-cased to **never** write into its bound field: the field is only an anchor for the
   panel, and `applyKitScanResult` does every write. Confirmed live that the bound `Description`
   kept its text across scans.
4. **Conflict prompt before resolution, not after** (a deliberate ordering change from
   `applyItemScanResult`). Resolution can *create* `ItemBlueprint` rows, so resolving first would
   leave orphans whenever the admin keeps current values or cancels. Verified live: declined items
   ("Diamond Boots", "Golden Apple") were never created.
5. **An empty scanned inventory leaves `Contents` alone**, the same way a `null` equipment slot
   leaves its picker alone. `DESIGN.md` §6.5 doesn't cover this case. The rule "a scan only
   writes what it found" seemed safer than wiping the list.

**Two pre-existing gaps found during live verification. Neither was caused by this phase, and
neither was fixed here (out of scope):**
- **Kit edit mode loses equipment on submit.** Phase 3 authored the equipment pickers on the
  navigation property (`Helmet`, not `HelmetId`). `KitDto` exposes only `HelmetId`, and
  `FormWizard.resolveObjectFieldValueForEdit`'s nav fallback only applies to fields ending in
  `Id`. So `/forms/kit/edit/:id` loads every equipment picker **empty**, and an *untouched*
  Submit writes `null` to all six FKs. Reproduced: kit 2 had `helmetId: 20`/`handId: 26` before
  and `null`/`null` after. `Contents` survives. Fix options: have `KitDto` also carry the nav
  objects, or broaden the edit loader's fallback.
- **An M2M step's value only survives if the step declares a field named after
  `relatedEntityPropertyName`.** `FormWizard.normalizeStepData` and `normalizeFormSubmission` both
  walk `step.fields` only. FormConfigBuilder does **not** auto-add that field. My local Kit config
  first had a field-less Contents step, and scanned contents were dropped on Next/Submit. Adding a
  `Contents` List field fixed it. The real Phase 3 config lives only in the dev DB (not in any
  repo), so **check it has a `Contents` field on its Contents step**. Without one, manual Contents
  authoring wouldn't persist from the form either (Phase 3's Contents round-trip was verified via
  direct API, not via the form).

**Developer action needed before `KitScan` is usable on the real dev DB** (data, not code — same
situation as Phase 3): in FormConfigBuilder, enable **World Task → `KitScan`** on one Kit field.
Use a plain String field such as `Description`: KitScan never writes into it, so the field's
content isn't at risk. Also confirm the Contents step has its `Contents` field (above).

**Verification, with the method for each repo:**
- **knk-plugin.** The `javac` fallback still applies, with one improvement over earlier sessions.
  - **Gradle:** this sandbox's egress now reaches the Gradle plugin portal and Maven Central, so
    `./gradlew` got past settings evaluation for the first time. But `knk-core` itself has
    `compileOnly paper-api`, and `repo.papermc.io` is still a 403. The first attempt also hit
    Maven Central 429 rate limits.
  - **`knk-core` / `knk-api-client`:** `javac` against Maven-Central jars gave **0 errors** for
    `knk-core` (163 Bukkit-free files) and `knk-api-client` (146 files).
  - **Stronger than a syntax check:** `ScannedItemJsonBuilder`, `ItemScanTaskHandler`,
    `KitScanTaskHandler` and `IWorldTaskHandler` were **really compiled** (0 errors) against
    minimal hand-written Bukkit stubs. The stubs cover exactly the API those files touch, with
    signatures matching Paper's.
  - **Equivalence harness:** the *original* `ItemScanTaskHandler` (compiled from git) and the
    refactored one were run side by side. **Output was byte-for-byte identical on 6/6 fixtures**
    (minus `capturedAt`): empty hand, plain sword, snowball, renamed sword with a real
    `LocalEnchantmentRepositoryImpl`-generated `Chaos I` lore line + 2 vanilla enchants + 3 PDC
    keys (incl. an unreadable one), bread with empty meta, and arrows with lore.
  - **KitScan output:** a sample inventory produced exactly the §6.3 shape. Held slot 2 and an
    air slot were skipped, off-hand became `shield`, nulls were kept for empty armor, and an empty
    inventory produced the warning.
  - **Everything else in `knk-paper`:** a `javac` parse-only pass over all 211 files had **0
    syntax errors**, including the `KnKPlugin.java`/`KnkAdminCommand.java` edits. A deliberately
    broken control file did produce errors, so the check is real.
  - **Not verified:** a real `./gradlew build` and an **in-game scan**, which can't run here.
- **knk-web-api.** `dotnet build` passes, and the full suite is 437 / 5 pre-existing failures (see
  "§2 follow-up").
- **knk-web-app.** `npm install` (`CYPRESS_INSTALL_BINARY=0`; `package-lock.json` churn reverted),
  then `npm run build` (clean apart from pre-existing warnings), then `CI=true npm run test:ci`:
  **237 tests, 221 passed, 16 failed**. That's Phase 6's 236/220/16 plus the one new passing
  test. A stash-and-rerun gave the **identical 16 failing suites**, and the ESLint warning list
  was identical apart from one line number shifted by the new import.
- **Live end-to-end (Playwright, Chromium) against a locally run `knk-web-api` (fresh MySQL, the
  merged `claude/kits`) and `npm start`.** The Kit `FormConfiguration` was recreated locally
  (Phase 3's lives only in the dev DB), with a `KitScan` World Task on `Description`. The
  in-game half was stood in for by claiming and completing the real WorldTask through
  `POST api/WorldTasks/{id}/claim|complete`, with the handler's output shape.
  - **Scan 1** (fields empty): no modal, applied directly. The pre-existing "Iron Helmet"
    blueprint was **reused**. Iron Boots / Shield / Iron Sword / Bread / Arrow were auto-created,
    with **one** Arrow for two stacks.
  - **Scan 2** (over filled fields): the modal listed exactly **Helmet, Boots, Contents (3
    existing)**; the scan's null shield/hand raised none. Choices were Helmet → scan, Boots →
    keep, Contents → keep. Declined items were **not** created.
  - **Submit:** DB rows matched exactly — Helmet = the re-scanned reused "Leather Cap", Boots
    kept, `kit_contents` = (0, Bread, 16), (9, Arrow, 64), (35, Arrow, 32).
  - **Create mode** (`/forms/kit`): a new kit was persisted with a reused helmet, an auto-created
    "Longbow" (`maxStackSize` 1 from the scan), and a Contents row.
  - **Local-harness artifacts, not product changes:**
    - `FormWizardPage` hardcodes `userId = '1'` (pre-existing TODO). User ids share the
      `permission_holders` key space with `PermissionGroup` (TPT), and id 1 is the seeded Default
      group, so the Playwright script rewrote that id in outgoing requests.
    - My local config had no Economy step, so cost fields were nulled on submit.

**Not done, per this phase's scope:** §8 (seed data). **Next:** §8 can start any time. Separately,
the two pre-existing Kit-form gaps above are worth a small follow-up before admins rely on edit
mode.

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
  extend, or is `TaskType` passed as a bare string today? Check before assuming either way) — **resolved in "§7 status"**: it existed, and `KitScan` was added beside it.
