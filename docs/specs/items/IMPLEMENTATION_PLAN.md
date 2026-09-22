# Items — Implementation Plan

**Status:** Draft — first version of this document
**Last updated:** 2026-09-22 (revised twice same day: first to fold in `docs/specs/legacy/items.md`,
then to bring `Tag`/`Category` enrichment and `Origin` into scope per explicit developer decision)

Ref: `docs/vision/vision.md` §9.1 (Items). Sources checked while writing this:
`docs/specs/legacy/items.md` (v1/v2 legacy spec-mining — see §0), `docs/reports/
IMPLEMENTATION_STATUS_AUDIT.md`, `docs/reports/LEGACY_VS_V2_GAP_ANALYSIS.md` (both
2026-09-10, see §0 on staleness), `docs/reports/web-api-scan-2026-09-18.md`,
`docs/architecture/web-api-architecture.md`, `docs/architecture/web-app-architecture.md`,
`docs/specs/gate-structure-animation/GATE_FORMCONFIG.md` (field-matrix/WorldTask-bound-field
precedent), `docs/specs/world-tasks/API_CONTRACT.md`, `docs/specs/form-configurations/
{m2m-editor-current-spec,m2m-join-creation-improvement-spec}.md`, plus a direct, current
read of `knk-plugin`/`knk-web-api`/`knk-web-app` source (2026-09-22) — see §1 for what that
read found that the docs above didn't (or got wrong).

## 0. Revision note — the legacy doc exists, just not where expected; two source reports are stale

This document originally shipped saying `docs/specs/legacy/items.md` didn't exist anywhere in
the repo. That was true of `main` but wrong overall: it exists, complete, on an unmerged
branch, `legacy-spec-mining` (along with five sibling docs of the same shape for other
features — `user-system.md`, `inventory-menus.md`, `towns-districts-gates.md`, `kits.md`,
`siege-minigame.md` — none of which have been pulled into `main` yet; only `items.md` was,
for this plan). It has now been cherry-picked into `docs/specs/legacy/items.md` on `main` and
is folded into this plan below (§1.5, §2, §3, §7). There was still no prior *Items
implementation plan* to revise (that part of the original note holds) — this remains a first
plan, now informed by real legacy findings rather than none.

- **`IMPLEMENTATION_STATUS_AUDIT.md` and `LEGACY_VS_V2_GAP_ANALYSIS.md` (both dated
  2026-09-10) are stale on at least one material point relevant here**: the audit's §8
  states Gate Structure Animation is "entirely unmerged." A direct check of the currently
  checked-out branch (forked from `main`/`master` after 2026-09-10) shows `GateStructure`,
  `GateDoor`, `GateBlockSnapshot`/`GateOpenedBlockSnapshot`, the animation migrations, and the
  plugin/web-app gate code are all present — i.e. **Gate Structure Animation has since merged
  to trunk across all three repos.** This matters for this plan because `GATE_FORMCONFIG.md`'s
  field-matrix/WorldTask-bound-field pattern (the explicit precedent this plan is asked to
  follow) is therefore a *live, merged* pattern to build on, not one still stuck on a branch.
  Refreshing those two reports generally is out of scope here; this note exists so this plan
  isn't built on a stale premise.

- **Second revision, same day**: after reading the reconciliation, the developer explicitly
  decided to bring `Tag`/`Category` (§1.5's "newly-surfaced gap") and `Origin` into scope,
  overriding this doc's earlier recommendation to defer both. Origin's shape was also given
  explicitly: "a reference to either a structure, district, town, province or kingdom" —
  Province/Kingdom acknowledged as not yet implemented. §1.5, §2, §3, §4, §6, §7 below are
  updated accordingly; superseded text is struck through rather than deleted so the reasoning
  trail stays visible.

## 1. Reconciliation — what's already built (read this before assuming greenfield)

The task that produced this document assumed most of Items was unbuilt. A direct code read
(not just docs) found the opposite for the catalog/admin layer: **the backend and plugin data
layers for `ItemBlueprint`/`EnchantmentDefinition` are essentially done.** Only the web-app
admin *form* and the in-game scan capability are genuinely greenfield. Specifics:

### 1.1 `knk-web-api` — done
- `Models/Item/ItemBlueprint.cs`, `EnchantmentDefinition.cs`, `AbilityDefinition.cs`,
  `ItemBlueprintDefaultEnchantment.cs` (the M2M join, composite PK, `Level` column) all exist
  as real EF Core entities, fully configured in `KnKDbContext.OnModelCreating`
  (`Properties/KnKDbContext.cs:715-735`, plus their own entity blocks).
- Full CRUD + paged search controllers exist and work: `ItemBlueprintsController`,
  `EnchantmentDefinitionsController` (`GetAll`/`GetById`/`Create`/`Update`/`Delete`/`search`),
  backed by real services/repositories (`ItemBlueprintService`/`EnchantmentDefinitionService`,
  cross-validated against material/enchantment refs) — not stubs.
- **`ItemBlueprint` and `EnchantmentDefinition` already carry `[FormConfigurableEntity]` and
  `[RelatedEntityField]`/`[NavigationPair]` on every FK-shaped property** — the exact metadata
  attributes `MetadataService` needs to expose them to the generic form builder, the same
  mechanism `GateStructure` uses (`Models/Item/ItemBlueprint.cs:5,11,14,24,26`;
  `Models/Item/EnchantmentDefinition.cs:6,22,25,30,35`). This part of the "Gate precedent"
  is **already satisfied** for both entities.
- `AbilityDefinition.SeedCanonicalAsync` (12 hardcoded custom-ability entries, idempotent
  upsert at startup, `Program.cs:195`) is a real, working seed-data precedent — but it seeds
  catalog *data*, not a `FormConfiguration`. See §1.4.
- Custom Enchantments (vision.md's "native to the v3 plugin") is fully done per
  `IMPLEMENTATION_STATUS_AUDIT.md` §5 — `EnchantmentDefinition`/`AbilityDefinition` are its
  output. This plan reuses that catalog as-is; it does not touch it.

### 1.2 `knk-plugin` — done for the catalog side, no item-scan capability at all
- `ItemBlueprintsDataAccess`, `EnchantmentDefinitionsDataAccess`, `MinecraftMaterialRefsDataAccess`
  (`knk-core/.../dataaccess/`) all exist, follow the confirmed `FetchPolicy`/`FetchResult`/
  `DataAccessExecutor` cache-first pattern, and are wired into `DataAccessFactory.java` and
  instantiated in `KnKPlugin.java` (lines 106-108, 326-337) — read-only/query-only gateways
  (`getByIdAsync`, `searchAsync`/`listAsync`, `refreshAsync`, `invalidate*`; no create/update/
  delete, consistent with the web app being the authoring surface).
- Two working debug commands already exercise this data end-to-end:
  `/knk itemblueprints give` (`ItemBlueprintsDebugCommand.java`, 550 lines — resolves a
  blueprint's material + enchantments and builds/gives the real `ItemStack`) and
  `/knk enchantments apply` (`EnchantmentDefinitionsDebugCommand.java`) plus `/ce info`
  (`InfoEnchantmentCommand.java`, reads a held item's **lore-encoded custom enchantments**
  back out via `EnchantmentRepository`/`LocalEnchantmentRepositoryImpl`'s regex parser).
- **Nothing reads `PersistentDataContainer` on any `ItemStack`/`ItemMeta` anywhere in the
  plugin.** The only PDC usage in the codebase is on `TextDisplay` entities for gate
  holograms (`GateDisplayManager.java`) — architecturally unrelated. Vision.md §9.1's
  "PDC stores the `ItemInstance` id, lore is regenerated display, no longer scanned from
  lore" design is **100% unbuilt** — current reality for custom enchantments is the opposite
  of that end-state (lore *is* the source of truth today, via the pre-existing
  `EnchantmentRepository`/`LocalEnchantmentRepositoryImpl` lore parser). See §5's open
  question on whether/how the item-scan flow should touch this.
- No `ItemScan`-like `taskType`, handler, or command exists anywhere. This part is genuinely
  new (§4).

### 1.3 `knk-web-app` — data layer and generic engines done; no form exists yet
- `apiClients/itemBlueprintClient.ts` / `enchantmentDefinitionClient.ts`: full CRUD + paged
  search, both fully registered in the generic CRUD dispatch table
  (`utils/entityApiMapping.ts`, all four `getXFunctionForEntity` helpers) that
  `ManyToManyRelationshipEditor`, `FieldRenderers`' `Object`/`List` fields, and
  `PagedEntityTable`'s inline-create all key off of. (`itemBlueprintClient.ts.orig` is a
  byte-identical, unimported stray file — safe to delete, unrelated to this plan.)
- **The generic `FormWizard`/`DisplayWizard`/`FormConfigBuilder`/`ManyToManyRelationshipEditor`
  engine has no hardcoded entity allowlist.** Entity navigation (`/forms/:entityName`) is
  driven entirely by live backend metadata (`metadataClient.getAllEntityMetadata`), not the
  legacy static `config/objectConfigs.tsx` map. **Once a `FormConfiguration` exists for
  `ItemBlueprint`, it will appear and work with zero new frontend engine code** — confirmed
  by reading `FormWizardPage.tsx`'s entity-selection path directly.
- `config/objectConfigs.tsx`'s existing `itemType`/`category` entries are a **different,
  legacy concept** — `itemType` there is a minimal `{blockData, data, name}` shape nested
  under the old `category` config, unconnected to `ItemBlueprintDto` and not wired to any
  API client. **Do not build on or extend `objectConfigs.tsx` for this feature** — it's the
  deprecated static path; the FormConfiguration/metadata path is the current one.
- `HybridMaterialPicker` picks `MinecraftMaterialRef` — directly reusable for
  `ItemBlueprint.iconMaterialRefId` once a `FormConfiguration` sets that field's `fieldType`
  to `HybridMinecraftMaterialRefPicker`. **`HybridEnchantmentPicker` picks
  `MinecraftEnchantmentRef` (the vanilla reference table), not `EnchantmentDefinition`** — it
  is *not* the right widget for `ItemBlueprint`'s enchantments; those are selected through the
  M2M step (§1.4), not a hybrid picker field.
- `WorldBoundFieldRenderer.tsx` is the real, currently-wired renderer for WorldTask-bound
  fields (`FormWizard.tsx:11,2173`) — a January-dated doc in `docs/specs/world-tasks/`
  (`WORLDTASK_FEATURE_INTEGRATION.md`) calling it "unused legacy, superseded by
  `WorldTaskCta`" is **stale**; `WorldTaskCta.tsx` is not what's wired into `FormWizard`
  today. Trust `GATE_FORMCONFIG.md`'s citations of `WorldBoundFieldRenderer`, not the
  January doc.

### 1.4 The one real, verified regression: inline "create a new related catalog entity" is not reachable

`docs/specs/form-configurations/m2m-join-creation-improvement-spec.md` claims (under "Final
Decisions (Implemented)") that on-the-fly join-entity creation is done. That's **half true**:

- **Creating the join row itself** (an `ItemBlueprintDefaultEnchantment` with its `Level`
  field, linking an *existing* `EnchantmentDefinition`) **is implemented and reachable** —
  `ManyToManyRelationshipEditor.tsx`'s "Create New Join Entry" button
  (`handleCreateJoinEntry`, lines 235-257) opens the join entity's nested form. This is the
  mechanism `ItemBlueprint.DefaultEnchantments` will use.
- **Creating a wholly new `EnchantmentDefinition` catalog row inline** (without leaving the
  `ItemBlueprint` form) has the supporting code written —
  `handleCreateRelatedEntity` (lines 293-384) and a `ChildFormModal` are both present — **but
  there is no button or any JSX element that ever sets `showCreateRelatedModal` to `true`**.
  It's dead/unreachable code. This is corroborated, not contradicted, by the file's own
  `__tests__`: they assert a `"Create New EnchantmentDefinition"` button and a
  `"Create Join Entry"`-labeled button that don't match the current component's actual text
  (`"Create New Join Entry"`) or its lack of a `PagedEntityTable` import — i.e. the tests
  describe an earlier or aspirational version of this component that the current source
  doesn't match. **Treat "create new related entity inline" as still an open gap for this
  feature**, matching (not better than) the state the InventoryMenu reconciliation already
  flagged for the general M2M mechanism — the improvement spec's own Open Question 4
  ("should this be allowed for all types or only specific ones?") is still genuinely open.
  Practical effect: **`Category` and `EnchantmentDefinition` need their own, independently
  reachable admin `FormConfiguration`s** so an admin can create those rows *before* linking
  them from an `ItemBlueprint` form — see Phase 2.

### 1.5 Legacy precedent (`docs/specs/legacy/items.md`) — Category/Grade/Price are restorations, not new scope

v1 (`Products/*`, raw JDBC) had no class literally called `Item` — its item entity was
`Product` (2361 lines), with `ItemType`+`ProductMaterial` for the material mapping and
`ProductCategory` for taxonomy. v2 (`model/item/*`, Hibernate) introduced an explicit
`Item`+`Itemtype` pair. **Neither legacy version is a strict subset of the other**, and
**v3's current `ItemBlueprint` is narrower than both**:

| Concept | v1 (`Product`) | v2 (`Item`) | v3 (`ItemBlueprint`, today) |
|---|---|---|---|
| Category | `ProductCategory` — flat, single-level | `Category` — parent/child nesting + `Tag` M2M | `Category` exists (matches v2's nesting) but **has zero link to `ItemBlueprint`** |
| Grade | hardcoded `int` 1–5, feeds real drop-chance/drop-amount/lore tables | `Grade` entity (id/name/stars), data-driven, admin-creatable — but **nothing reads it**, no behavior wired | **absent entirely** |
| Material/"itemtype" | two inconsistent resolution paths (`ItemType.BlockID` numeric parsing vs. `ProductMaterial`+`ItemType` string concat — a confirmed legacy bug) | `Itemtype` — one unified `Material`+`BlockData` path | **already present**, via `IconMaterialRefId`/`IconMaterial` → `MinecraftMaterialRef`. Despite being named/framed as an "icon" field in the current model and DTOs, `ItemBlueprintBukkitMapper.fromBlueprint` resolves the actual `ItemStack`'s `Material` from that same namespace key — i.e. **this field already does double duty as both display icon and real material identity**, matching v1/v2's `Itemtype` concept. Correcting §2 below: "itemtype" is not a gap. |
| Price | `PriceMin`/`PriceMax` + a full property-category sellability matrix (`canProductbeSold`) | single flat `basePrice`, no matrix — vision.md §9.1 explicitly says this direction is **"kept"** for v3 (`basePriceMin`/`basePriceMax`), not `[OPEN]` | **absent entirely** |
| Origin | no equivalent | `Item.origin` — `Set<Dominion>` multi-select, but **no code anywhere reads it for any gameplay effect** (legacy doc's own open question #4) | **absent entirely.** Now **in scope** (developer decision) as a single reference to a `Structure`/`District`/`Town`/`Province`/`Kingdom` — a materially different shape from v2's multi-select `Dominion` set. See §3 for the design (`OriginId` → `Domain`, not a new polymorphic mechanism). |
| Tag | no equivalent | `Category.tags` (M2M `Tag` entity) — attached to **Category, not Item** directly | **absent from both `Category` and `ItemBlueprint`.** Now **in scope** (developer decision): a new `Tag` entity + `CategoryTag` join, attached to `Category` (matching v2's shape, reachable from `ItemBlueprint` transitively via `CategoryId`), not a direct `ItemBlueprint` field — see §3. |
| Soulbound/Ghosted | lore-string convention only, never persisted as columns; the only real player-facing effect (blocking manual drop) worked, but death-protection was already dead/commented-out code | **no equivalent at all** | absent (vision.md instance-level, out of this plan's scope regardless) |
| Custom enchantments | lore-string convention (`"Poison II"` etc.), hand-rolled Roman-numeral level parsing | **no equivalent at all** | v3's *current* custom-enchantment runtime (`EnchantmentRepository`/`LocalEnchantmentRepositoryImpl`, §1.2) is, mechanically, **the same lore-string approach v1 used** — never modernized even now, despite vision.md §9.1 wanting to eventually move away from lore-as-source-of-truth for `ItemInstance` |
| Premium currency | `GemProducts extends Product` — same shape, separate table + `GemPrice` | **no trace found anywhere** in v2 (legacy doc's open question #1, never resolved) | absent; vision.md §9.1 already made the design call this legacy ambiguity couldn't: currency type is "a property of the template, not a separate class" — settled, not still open |
| Admin creation UX | one-shot `/product set <name> <category> <grade> <min> <max> <description>`, no edit flow | generic multi-step `CreationStage` wizard: name → displayName → description → category → itemtype → grade → origin | this plan's Phase 3 field-matrix (§4.1) should mirror v2's proven step order, adjusted for what's actually being kept |

**Practical effect on this plan's scope decision (§3):** `Category` and `Grade` are not
speculative additions — v1 had working (if crude) versions of both, v2 modernized `Grade`'s
*data model* (even though it never wired behavior to it, which is the win worth keeping), and
vision.md explicitly names `Grade`/`Category`/pricing among the things to "keep... as the
foundation." Treat all three as restorations of a previously-real feature, not invented scope.

~~`Origin` and `Tag`-on-`Item` are the opposite case: legacy evidence for `Origin` shows it was
built but never actually used for anything, and `Tag` was never an `Item`-level concept in
either legacy version — weaker justification for adding either right now.~~ **Superseded by
developer decision**: both are now in scope. `Origin`, though, is *not* a restoration of v2's
`Item.origin` shape — v2's was a multi-select `Set<Dominion>`; what's wanted now is a single
reference into the `Kingdom → Province → Town → District → Structure` region hierarchy
(vision.md §2, "Kingdom, Province, Town, District are all fundamentally the same kind of
thing... each nested inside the one above it"), with `Province`/`Kingdom` explicitly
acknowledged as not built yet. See §3 for the design this drives.

**Also directly relevant to the WorldTask item-scan design (§5):** v2 had
`RegisterSession` (`model/item/RegisterSession.java`) — an in-memory, non-persisted, per-`User`
workflow where an admin holds an item and runs `/itemtype add hand` (captures `Material`+data
from the held item, no `BlockData`) or `/itemtype add click` (starts a 5-second window of
right-clicking blocks, capturing full `Material`+`BlockData` per block to register new
`Itemtype` rows). This is a real, direct legacy precedent for "hold an item, trigger an
in-game capture of its properties" — the `ItemScan` `WorldTask` this plan proposes is a
generalization of `RegisterSession`'s `hand`-registration mode (capture from a held item, not
a clicked block) onto the modern `WorldTask`/`FormWizard` hybrid pattern, capturing full item
metadata (display name, lore, enchantments) rather than just `Material`+`BlockData`. Not
reinventing a concept — reviving one that already proved out the core UX, re-architected onto
infrastructure that didn't exist in v2 (`RegisterSession`'s in-memory command-triggered flow
predates `WorldTask` entirely).

## 2. What vision.md §9.1 wants vs. what `ItemBlueprint` actually has today

Vision.md §9.1 describes a two-entity split (`ItemTemplate` catalog row +
`ItemInstance` live/owned copy). The current code has **only a narrower predecessor of the
template half**, under the name `ItemBlueprint`. Cross-checked against legacy precedent
(§1.5) — corrected from this doc's first version, which wrongly called `itemtype` absent:

| Vision.md `ItemTemplate` field | Current `ItemBlueprint` reality | Legacy precedent |
|---|---|---|
| name | `Name` — present | v1 `Product.Name`, v2 `Item.name` — both had it |
| category | **absent.** `Category` exists as its own self-referencing entity (`Models/Category.cs`, `ParentCategoryId`/`ChildCategories`, its own icon FK) but has **zero link** to `ItemBlueprint` — no `CategoryId` anywhere on the model. | v1 `ProductCategory` (flat), v2 `Category` (nested + tags) — a working, linked field in both legacy versions. A real regression, not new scope. |
| grade | **absent.** No `Grade` entity, enum, or field exists anywhere in the current codebase, despite vision.md saying to "keep v2's `Item`/`Grade`/`Category`/`Origin` model." | v1: hardcoded int 1–5 driving real drop-chance/amount tables. v2: data-driven `Grade` entity, but unwired to any behavior. A real regression; v2's *data model* (not its inertness) is the part worth keeping. |
| itemtype (material identity) | **already present**, not absent. `IconMaterialRefId`/`IconMaterial` → `MinecraftMaterialRef` is framed as an "icon" field in the model/DTOs, but `ItemBlueprintBukkitMapper.fromBlueprint` resolves the real `ItemStack`'s `Material` from that same namespace key — this field already does double duty as icon *and* material identity. | v1 had two inconsistent resolution paths for this (a confirmed bug); v2 unified it into one `Itemtype` (`Material`+`BlockData`) path — v3's `IconMaterialRefId`/`MinecraftMaterialRef` is that same unification, just under a different name. |
| origin | **absent.** No such field exists. **Now in scope** — but not as a restoration of v2's `Item.origin` shape (a multi-select `Set<Dominion>`, never used for anything, per the legacy doc's own open question). Instead: a single `OriginId` FK to `Domain`, covering `Structure`/`District`/`Town` today and `Province`/`Kingdom` automatically once those are built as `Domain` subtypes — see §3 for why. | Weak legacy precedent for the *shape* (v2's version was unused dead weight), but the developer wants it restored anyway with a different, more useful shape. |
| `basePriceMin`/`basePriceMax`, purchase-currency (coins/gems) | **absent.** No pricing fields anywhere on `ItemBlueprint`/its DTOs. | v1 had a real `PriceMin`/`PriceMax` + full sellability matrix; v2 flattened to a single `basePrice` with no matrix. Vision.md explicitly says the range is **"kept"** for v3 — a restoration, not invented scope (the *gating*/matrix logic stays deferred per vision.md, just not the plain range fields). |
| tag | not named in vision.md's field list at all, and **absent** from both `Category` and `ItemBlueprint` today | v2 `Category.tags` (M2M) — attached to **Category, not Item**. Never an `Item`-level concept in either legacy version. **Now in scope** (developer decision): new `Tag` entity + `CategoryTag` join on `Category`, matching v2's shape — reachable from `ItemBlueprint` transitively via `CategoryId`, not a direct `ItemBlueprint` field (see §3 if direct item-level tagging turns out to be what's actually wanted instead). |
| base drop amount, default loot/lore config | Partially covered by `DefaultQuantity`/`DefaultDisplayDescription` (used as default lore text), but no loot-table/probability concept. | v1 had real grade-weighted drop-chance/amount tables; v2 dropped them entirely. Vision.md keeps loot boxes but explicitly defers the formula — consistent with staying out of this plan. |
| — (not in vision's template list, but present today) | `IconMaterialRefId`/`IconMaterial`, `DefaultDisplayName`, `MaxStackSize`, `DefaultEnchantmentIds`/`DefaultEnchantments` (M2M via `ItemBlueprintDefaultEnchantment`, with `Level`). | No direct v1/v2 equivalent for the M2M enchantment-default concept specifically — v1/v2 stored a single item's enchantments as a string blob (v1) or not at all (v2, no enchantment concept on `Item`). |

**`ItemInstance` does not exist at all** — confirmed by a forward-looking `TODO` comment in
the code itself (`Models/Item/EnchantmentDefinition.cs:38-39`: `// TODO: Add
ItemInstanceEnchantment when item instances are implemented`). None of vision.md's
instance-level concepts (soulbound/ghosted, `createdAt`/`ownerCount`, per-field override
flags, cascade-to-instances) exist in any form.

## 3. Scope decision for this plan

This plan covers **only** the two things the task asked for: (a) web-app admin management of
`ItemBlueprint` (and its already-existing child data — enchantments via the M2M join) through
`FormWizard`/`FormConfigBuilder`, and (b) a new in-game item-scan `WorldTask` flow that
pre-fills that form. Per §2, it also has to decide what to do about the `Category`/pricing/
grade gap, since "child data — category/grade/tag" was named as in-scope by the task that
requested this document but doesn't exist as fields yet.

**Decision, revised after reading `docs/specs/legacy/items.md` (§1.5):** add `CategoryId`,
a `Grade` entity + `GradeId` link, and `basePriceMin`/`basePriceMax` now (Phase 1). This
doc's first version deferred all three for lack of a concrete precedent — that was wrong.
`Category` and `Grade` both had working data models in v1/v2 (v2's `Grade` entity in
particular is the exact data-driven shape worth keeping, it just never got wired to
behavior — that inertness is fine to inherit, the *entity* is what's needed for the admin
form); vision.md explicitly lists both among "v2's `Item`/`Grade`/`Category`/`Origin` model...
the foundation," and separately calls the price *range* "kept" (not `[OPEN]`). These are
restorations of previously-real fields, not invented scope — the `GateType`-enum-precedent
bar this doc's first version was applying doesn't fit; that bar was for inventing a *new*
concept with no history, not for restoring one both legacy versions already had in some form.

~~**Still deferred**, now with legacy evidence backing the call rather than just an absence of
one: `Origin`... and `Tag`...~~ **Superseded**: the developer explicitly wants both in scope.
Revised decision below.

### 3.1 `Tag` and `Category` enrichment — now in scope

Add a `Tag` entity (`Id`, `Name` unique) and a `CategoryTag` join entity (`CategoryId`+`TagId`
composite key, no extra columns — the "plain" case of the same join-entity pattern
`ItemBlueprintDefaultEnchantment` already establishes, just without a `Level`-equivalent
field), matching v2's `Category.tags`/`Tag.categories` shape exactly. Attached to `Category`,
not `ItemBlueprint` directly — reachable from an item transitively via `CategoryId` (Phase 1
per above). This follows legacy precedent faithfully (§1.5: `Tag` was always `Category`-scoped
in v2, never an `Item`-level field) rather than inventing a new direct `ItemBlueprint.Tags`
relationship with no history. If the developer actually wants items taggable independently of
their category (not just inheriting their category's tags), that's a different, bigger design
than "restore what v2 had" — flagged as open question §7.9 rather than assumed.

An explicit join entity (not EF Core's implicit skip-navigation many-to-many) is deliberate:
`[RelatedEntityField]`/the `ManyToManyRelationshipEditor` mechanism (§1.4) is built around an
explicit join *entity* with its own FK-bearing class — an implicit skip-navigation has no
such class and wouldn't be pickable by that mechanism at all. `ItemBlueprintDefaultEnchantment`
is the only real precedent for this pattern in the codebase; `CategoryTag` follows it exactly.

### 3.2 `Origin` — a single reference into the region hierarchy, not a restoration of v2's shape

The developer's own words: "a reference to either a structure, district, town, province or
kingdom" (province/kingdom acknowledged not yet built). This is **not** v2's `Item.origin`
(§1.5) — that was a multi-select `Set<Dominion>` nobody ever read. What's wanted is closer to
vision.md §2's own framing: *"Kingdom, Province, Town, District are all fundamentally the same
kind of thing: a region of the game world, each nested inside the one above it"*
(`Kingdom → Province → Town → District → Street (cross-cutting) → Structure`).

**Design: `ItemBlueprint.OriginId` (nullable `int`) → `Domain.Id`** (`Restrict` delete, same
`[RelatedEntityField(typeof(Domain))]`/`[NavigationPair]` pattern as every other FK on this
entity), not a discriminator+separate-FK polymorphic scheme. This works today and is
automatically future-proof, confirmed directly against the current schema:

- `Town`, `District`, and `Structure` (which `GateStructure` itself inherits from) are all
  **TPT subtypes of `Domain`** (`Models/Town.cs:8`, `District.cs:8`, `Structure.cs:7`,
  `GateStructure.cs:8`), and `Domain` already has its own base `DbSet<Domain>`
  (`Properties/KnKDbContext.cs:19`) alongside the subtype-specific ones — querying it directly
  returns every `Town`/`District`/`Structure` row, resolved to its concrete runtime type. One
  FK to `Domain` already reaches all three of "structure, district, town" today.
- `Domain` itself already carries `[FormConfigurableEntity("Domain")]` (`Models/Domain.cs:7`)
  — the metadata plumbing a `[RelatedEntityField(typeof(Domain))]` picker needs is already in
  place, same as every other entity in §1.1.
- **When `Province`/`Kingdom` are eventually built**, the natural implementation (per vision.md
  §2's framing above) is as two more `Domain` TPT subtypes, extending the existing
  `Town`/`District`/`Structure` chain upward. If so, `ItemBlueprint.OriginId` needs **zero
  schema change** to support them — they'd just start showing up in the same picker the moment
  they exist. This is the concrete reason this design beats a closed enum/discriminator: it
  doesn't need to know about `Province`/`Kingdom` today to be ready for them.
- This *is* a real assumption, not a certainty: it assumes `Province`/`Kingdom` get built as
  `Domain` subtypes rather than some structurally different concept. Vision.md's wording
  strongly suggests this ("fundamentally the same kind of thing"), but it isn't a made
  decision on record anywhere. Flagged as open question §7.8.

**A genuine technical gap this surfaces, not just a data-entry addition**: unlike every other
`RelatedEntityField`-picked entity in this codebase, `Domain` has **no paged search endpoint**
today — `DomainsController` only has `GetAll` (unfiltered, unpaged; confirmed by reading the
controller directly, only `GetAll`/`GetById`/`Create`/`Update`/`Delete`/`by-region`/
`search-region-decisions` exist) and `DomainRepository` has no `SearchAsync` (unlike
`TownRepository.SearchAsync(PagedQuery)`, the pattern every other picker relies on). The
web-app side has **no `domainClient.ts` at all** and no `'domain'` case in
`entityApiMapping.ts`'s dispatch tables — confirmed by direct grep, zero hits. The Origin
picker needs both built: a `POST api/Domains/search` endpoint (mirroring `TownsController`'s,
ideally surfacing the existing `domainType`/subtype-indicator convention already used by
`DomainRegionDecisionDto`/`ParentDomainDto` so the picker can show "Ironhaven (Town)" rather
than an ambiguous bare name) and a new `domainClient.ts` + `entityApiMapping.ts` registration
on the frontend. This is real, additional Phase 1/2 scope (§6), not something the existing
generic engine already covers for free the way `Category`/`Grade`/pricing were.

Everything else vision.md §9.1 lists as `[OPEN]`, deferred, or belonging to a later pass —
`ItemInstance`/live-instance tracking, soulbound/ghosted, cascade-to-instances, item-age/
owner-count bonuses, loot-box drop-chance/amount formulas, purchase-currency (coins/gems)
fields and purchase gating/rank-requirements (the plain price *range* is the one exception,
now in scope per above), crafting restriction, the delivery-fallback stash, and all of §9.2
Kits — stays out of scope here, exactly as vision.md itself already scoped it.

## 4. Web-app admin management via FormWizard/FormConfigBuilder

Unlike InventoryMenu (where this layer was explicitly deferred), this is real, in-scope work
for Items — but per §1.3, most of the *engine* work is already done. What's actually needed:

### 4.1 Field matrix (modeled on `GATE_FORMCONFIG.md`)

`ItemBlueprint` has no polymorphic "type" enum the way `GateStructure` has `GateType` — so,
unlike Gate's four-way type-dependent matrix, this is a single, flat step layout:

Field order below follows v2's own proven `CreationStage` wizard sequence (§1.5) —
name → displayName → description → category → itemtype(material) → grade → origin — now
including `origin`, revised from this doc's earlier version which left it out:

| Step | Fields |
|---|---|
| General Information | `Name`, `DefaultDisplayName`, `Description`, `DefaultDisplayDescription`, `CategoryId` (new, §3.1 — object picker, existing `Category` rows only per §1.4), `IconMaterialRefId` (`HybridMinecraftMaterialRefPicker` → `HybridMaterialPicker`, picks `MinecraftMaterialRef` — doubles as material identity, §1.5), `GradeId` (new, §3 — object picker, existing `Grade` rows only, same inline-creation caveat as `Category`), `OriginId` (new, §3.2 — object picker on `Domain`, needs the new search endpoint/client described there), `DefaultQuantity`, `MaxStackSize` |
| Pricing | `BasePriceMin`, `BasePriceMax` (new, §3) — kept as its own step so purchase-currency/gating fields (deferred, vision.md §9.1) have an obvious place to land later without reshuffling General Information |
| Default Enchantments | M2M step: `isManyToManyRelationship=true`, `relatedEntityPropertyName="DefaultEnchantments"`, `joinEntityType="ItemBlueprintDefaultEnchantment"`, child step field `Level` (Integer) — reuses the already-working `ManyToManyRelationshipEditor` "Create New Join Entry" flow (§1.4) to pick an *existing* `EnchantmentDefinition` and set its `Level` |
| (optional, see §5) Scan | One WorldTask-bound field, `taskType: "ItemScan"`, pre-filling several General Information fields — ephemeral in `WorldTask.OutputJson` until the `ItemBlueprint` is actually created, exactly like Gate's `BlockSnapshots`/`OpenedBlockSnapshots` fields |

No field-conditional-within-a-step or step-display-condition logic is needed (nothing here is
optional-based-on-another-field the way Gate's `AllowPassThrough`-gated fields are).

**Tags are not an `ItemBlueprint` field** (§3.1) — they're authored on `Category`'s own form
(a `Tags` M2M step there, `CategoryTag` join, same mechanism as above), and an item inherits
its tags transitively through `CategoryId`. Nothing to add to this matrix for `Tag` itself.

### 4.2 `Category`, `Tag`, `Grade`, and `EnchantmentDefinition` need their own `FormConfiguration`s too

Because inline related-entity creation is unreachable (§1.4), an admin populating
`ItemBlueprint.CategoryId`/`GradeId`/`DefaultEnchantments` needs `Category`, `Grade`, and
`EnchantmentDefinition` rows to already exist — and now, per §3.1, `Category`'s own `Tags` M2M
step means `Tag` rows need to pre-exist too, one level further removed from `ItemBlueprint`
itself. `Category` and `EnchantmentDefinition` already carry `[FormConfigurableEntity]`
(confirmed §1.1); `Grade` and `Tag` don't exist yet at all, so both need the attribute added
as part of creating them in Phase 1 (mechanical — same pattern as every other entity in §1.1).
This is the same "author a `FormConfiguration`" work as `ItemBlueprint` itself, just for four
more entity types — not new engine work, but real additional scope:

- `Grade`'s field list, per v2's proven shape (§1.5): `Name` (unique), `Stars` (int).
- `Tag`'s field list: `Name` (unique) — a one-field form.
- `Category`'s *own* `FormConfiguration` now needs its own `Tags` M2M step (`joinEntityType:
  "CategoryTag"`, `relatedEntityPropertyName: "Tags"`, no child-step fields since `CategoryTag`
  carries no extra columns) in addition to whatever fields it already needs for its existing
  `ParentCategoryId`/`IconMaterialRefId`.

`AbilityDefinition`'s own optional 1:1 extension (`EnchantmentDefinition.AbilityDefinition`)
can stay out of the `EnchantmentDefinition` form for now (custom-ability authoring already has
its own tooling per Custom Enchantments' completed status) unless the developer wants it
folded in.

`Domain` (for `OriginId`, §3.2) is the one exception that does **not** need a new
`FormConfiguration` authored *by this plan* — `Origin` only ever *selects* an existing
`Town`/`District`/`Structure`, never creates one, and Town/District/Structure creation is
established, working functionality (not greenfield the way Items is), wired into the same
generic FormConfiguration/DisplayConfiguration pipeline per `IMPLEMENTATION_STATUS_AUDIT.md`
§10 — reasonable to assume real `FormConfiguration`s already exist for them, though this
wasn't independently re-verified in this pass the way it was for Items. What `Domain` needs
instead is the search endpoint/client infrastructure described in §3.2 — a different kind of
gap than "author a form," and not contingent on Phase 2's FormConfig-authoring work at all.

### 4.3 Authoring/seeding the FormConfiguration itself

**No `FormConfiguration` seeder mechanism exists anywhere in this codebase** — confirmed by a
direct search (no `DbInitializer`/`SeedData`/`.HasData()` for any `FormConfiguration`,
anywhere, for any entity). The only seed precedent is `AbilityDefinition.SeedCanonicalAsync`,
which seeds catalog *data*, not form config. This means `GateStructure`'s own
`FormConfiguration` (per `GATE_FORMCONFIG.md` item 4, "Seeden van de configuratie... Nog niet
gedaan") is presumably also either hand-authored live via `FormConfigBuilder` or still
missing — either way, there's no existing "seed a FormConfiguration in code" convention in
this project to copy. §7.2 asks the developer to decide between authoring live via
`FormConfigBuilder` (matches how the rest of the project seems to do it, zero code) or writing
a small idempotent seeder (more reproducible across dev/prod, more code, no precedent yet).

## 5. In-game item-scan WorldTask flow

This is entirely new capability — no item-related `taskType`, handler, or plugin command
touches this today (§1.2). The only two real `taskType`s with actual server-side branching
logic anywhere in the backend are `GateBlockScan`/`GateOpenedBlockScan`
(`WorldTaskTypes` class, `Dtos/GateBlockScanDtos.cs:9-17`; `TaskType` itself is an open
string field on `WorldTask`, not a closed enum, so adding `ItemScan` needs no schema change
to the `WorldTask` table itself).

### 5.1 Player-driven, not headless — a real design fork from the Gate precedent

The plugin has **two** task-handler interfaces (`knk-paper/.../tasks/`):
`IWorldTaskHandler` (player-driven: claim via `linkCode`, then the player does something —
`LocationTaskHandler`, `WgRegionIdTaskHandler`) and `IHeadlessWorldTaskHandler` (webapp/poller-
initiated, no player interaction — `GateBlockScanTaskHandler`, which operates on a
*pre-existing* world location with no one needing to be present).

An item scan fundamentally requires **a specific player, holding a specific physical item, at
the moment of the scan** — there is no "location" to headlessly revisit later. **This must be
built as an `IWorldTaskHandler`** (the `LocationTaskHandler`/`WgRegionIdTaskHandler` pattern:
claim code → player runs an in-game trigger while holding the item → handler reads live
`Player` state), **not** `GateBlockScanTaskHandler`'s headless pattern. This also matches the
web-app side: `WorldBoundFieldRenderer.tsx`'s `HEADLESS_TASK_TYPES` set (currently just the
two gate-scan types) controls whether the claim-code banner is shown to the player — `ItemScan`
should **not** be added to that set; it needs the normal claim-code UI Location/WgRegionId use.

### 5.2 Handler behavior and OutputJson shape

On trigger, read the player's held main-hand `ItemStack`:
- `Material` (`getType()`) — not read anywhere in the plugin today, confirmed.
- `ItemMeta.getDisplayName()` / `hasDisplayName()`.
- `ItemMeta.getLore()` — reuse, don't reimplement: `EnchantmentRepository`/
  `LocalEnchantmentRepositoryImpl`'s existing regex-based lore parser (already used by
  `/ce info`, `InfoEnchantmentCommand.java`) to also pull out any KnK custom enchantments
  already lore-encoded on the item.
- `ItemMeta.getEnchants()` — vanilla Bukkit enchantments (not currently read anywhere either).
- `PersistentDataContainer` — read defensively for forward-compatibility, but see §7.4: since
  nothing in this codebase ever *writes* PDC data to an item (no `ItemInstance` exists), this
  will be empty for every item scanned for the foreseeable future.

Output shape, modeled directly on `GateBlockScanTaskHandler.buildOutputJson`'s
status/warnings/payload convention (`{"status": ..., "blockCount": ..., "snapshots": [...],
"warnings": [...]}`):

```json
{
  "fieldName": "ItemScan",
  "status": "Success",
  "material": "minecraft:diamond_sword",
  "displayName": "Flametongue",
  "lore": ["§7A blade wreathed in fire"],
  "vanillaEnchantments": [{ "key": "minecraft:fire_aspect", "level": 2 }],
  "customEnchantments": [{ "key": "knk:lifesteal", "level": 1 }],
  "persistentDataContainer": {},
  "capturedAt": 1674845123456,
  "warnings": []
}
```

### 5.3 Web-app changes

- `FieldEditor.tsx`: add an `ItemScan` option alongside the existing `worldTaskType` dropdown
  entries (same place the `GateBlockScan`/`GateOpenedBlockScan` extra-options branch lives,
  around line 1133) — likely no scan-specific builder options needed initially, unlike Gate's
  open/closed state selector.
- `WorldBoundFieldRenderer.tsx`: add `"ItemScan"` to `TASK_OUTPUT_FIELD_MAP` and to
  `extractTaskResult`'s dispatch, mapping the scan's output onto the `ItemBlueprint` form's
  fields — `material` → resolve/`get-or-create` a `MinecraftMaterialRef` (reusing the same
  hybrid-picker "get-or-create-from-namespace-key" endpoint pattern `MinecraftMaterialRefsController`
  already exposes) → `IconMaterialRefId`; `displayName` → `DefaultDisplayName`; `lore` →
  `DefaultDisplayDescription`; `vanillaEnchantments`/`customEnchantments` → best-effort
  pre-population of the Default Enchantments M2M step (§7.3 — matching parsed keys against
  existing `EnchantmentDefinition` rows is a real design question, not just plumbing).
- Do **not** add `ItemScan` to `HEADLESS_TASK_TYPES` (§5.1).

## 6. Sequencing

**Not blocked by anything currently in flight.** Gate Structure Animation is already merged
(§0). InventoryMenu touches unrelated entities (`MenuTemplate`/etc.) on its own branch. Custom
Enchantments is done and only reused, not modified. This can start immediately.

1. **Phase 1 — Schema hardening.** Grown from this doc's earlier version to cover §3.1/§3.2:
   - `ItemBlueprint`: `CategoryId`/`Category` FK, a new `Grade` entity (`Id`/`Name`/`Stars`)
     + `GradeId` link, `BasePriceMin`/`BasePriceMax` (plain fields, no gating logic), and
     `OriginId`/`Origin` FK to `Domain` — all `[RelatedEntityField]`/`[NavigationPair]`,
     same pattern as `IconMaterialRefId`.
   - A new `Tag` entity (`Id`/`Name`) and `CategoryTag` join entity (`CategoryId`+`TagId`,
     no extra columns) on `Category` (§3.1).
   - `DomainsController`: a new `POST api/Domains/search` (paged, name-filtered, ideally
     surfacing `domainType`) + matching `DomainRepository.SearchAsync` (§3.2) — needed for
     the `OriginId` picker regardless of FormConfig authoring, since no such endpoint exists
     today.
   - `knk-web-app`: a new `domainClient.ts` + `'domain'` registration in
     `entityApiMapping.ts`'s four dispatch functions (§3.2) — same reason.
   - EF migration; DTO/mapper updates (`ItemBlueprintDtos.cs`, `CategoryDtos.cs`,
     `ItemBlueprintMapper.java`/`CategoryMapper` on the plugin side if `Category`/`Tag` need
     plugin-side representation — not yet confirmed either way, see §7.11). Mechanical for the
     entity/field additions; the `Domain` search endpoint is the one piece here that's genuinely
     new engine work, not just an additive column.
2. **Phase 2 — `Category`, `Tag`, `Grade`, and `EnchantmentDefinition` admin
   `FormConfiguration`s.** These need to be independently authorable *before* Phase 3 is
   useful, since inline related-entity creation isn't reachable (§1.4/§4.2) — `Category`'s own
   form now also needs its `Tags` M2M step. Pure `FormConfigBuilder` authoring work (or a
   seeder, pending §7.2) — no new engine code. `Town`/`District`/`Structure` (for `Origin`)
   are assumed already covered by existing tooling, not this plan's to build (§4.2).
3. **Phase 3 — `ItemBlueprint` admin `FormConfiguration`.** General Information step
   (now including `OriginId`) + Pricing step + Default Enchantments M2M step (§4.1), using the
   already-built `RelatedEntityField`/M2M machinery and Phase 1's new fields. This is the
   "web-app-centered admin management" deliverable and is usable on its own without Phase 4/5.
4. **Phase 4 — `ItemScan` WorldTask capability.** Plugin `IWorldTaskHandler` (§5.1/5.2),
   web-api `taskType` constant (optional but recommended for parity with Gate's
   `WorldTaskTypes` class), web-app `FieldEditor`/`WorldBoundFieldRenderer` support (§5.3).
   Independent of Phases 1-3's mechanics, but sequenced after Phase 3 because the scan's
   OutputJson→field mapping needs Phase 3's field list to be stable before it's worth wiring.
5. **Phase 5 — Wire the scan field into `ItemBlueprint`'s `FormConfiguration` + end-to-end
   verification.** Add the WorldTask-bound field from §4.1's Scan step; verify
   FormConfig → WorldTask claim → in-game scan → OutputJson → pre-filled form →
   `ItemBlueprint` created, mirroring `GATE_FORMCONFIG.md` item 5's still-open checklist for
   Gate itself.

Phases 1-3 deliver the admin-management requirement independently and are worth shipping even
if Phase 4/5 (the scan flow) slips — they're the higher-value, lower-risk half of this plan.
Phase 1 is now bigger than this doc's earlier version (five new/changed entities plus one new
endpoint, instead of three field additions) — still no cross-repo blocking dependency, but
worth re-confirming it's still comfortable as a single phase rather than splitting `Origin`'s
`Domain`-search work out on its own, given it's the one piece that isn't purely additive.

## 7. Open questions / design gaps needing a decision

1. ~~**Category-only now, or also Grade/Tag/pricing?**~~ **Resolved**: Category, Grade,
   pricing, `Tag`, and `Origin` are all now in scope for Phase 1 — see §3/§3.1/§3.2.
2. **FormConfiguration authoring mechanism.** (§4.3.) Live via `FormConfigBuilder` (no code,
   matches the apparent project convention of zero committed FormConfig seeders so far) vs. a
   small hand-written idempotent seeder (precedent: `AbilityDefinition.SeedCanonicalAsync`;
   more reproducible across dev/prod, but no existing pattern for seeding *forms* specifically
   to copy).
3. **Enchantment auto-matching on scan.** (§5.3.) Should the scan handler/renderer try to
   auto-match parsed vanilla/custom enchantment keys against existing `EnchantmentDefinition`
   rows (richer pre-fill, real risk of wrong matches) or just surface the raw parsed data for
   the admin to manually pick in the M2M step (safer, more clicks)?
4. **Is reading `PersistentDataContainer` during a scan worth doing yet?** (§5.2.) Nothing
   writes PDC data to items anywhere in the codebase today (`ItemInstance` doesn't exist), so
   it will read empty for the foreseeable future. Recommended: still read it defensively (cheap,
   forward-compatible for whenever `ItemInstance` work starts) but confirm this is acceptable
   as a currently-inert field rather than assuming it needs to do something now.
5. **Create-only, or also re-scan-to-update an existing `ItemBlueprint`?** Vision.md doesn't
   address this, and the Gate precedent (`WorldTask`+`FormWizard`) only supports the creation
   direction today. Out of scope unless explicitly wanted.
6. **Scan trigger UX.** Reuse the existing chat-command claim flow
   (`WorldTaskChatListener`, as `Location`/`WgRegionId` do) or something more specific to
   physically holding an item (e.g. a dedicated `/knk itemscan claim <code>` command that reads
   the sender's main hand at the moment it's run)? Needs a decision before Phase 4 starts —
   this plan assumes the latter (a dedicated command reading main-hand state) since that's the
   only way to guarantee the *right* item is being read at trigger time, but this hasn't been
   confirmed with the developer.
7. **The unreachable inline-create UI in `ManyToManyRelationshipEditor.tsx`** (§1.4) — is this
   worth fixing (wire up the already-written `handleCreateRelatedEntity`/`ChildFormModal`
   path) as part of this plan, or left as Phase 2's workaround (standalone `Category`/
   `EnchantmentDefinition` forms) for now, same as the InventoryMenu plan chose not to fix the
   general M2M gap? Recommended: leave it — fixing the shared component is its own
   cross-cutting task, not specific to Items, and Phase 2 already provides a working path.
8. ~~**`Origin` — add it anyway for parity, or leave it out?**~~ **Resolved**: in scope,
   as a single `OriginId` FK to `Domain` (§3.2) — but two real sub-questions this decision
   itself raises, neither settled yet:
   - **8a. Is `Province`/`Kingdom`-as-future-`Domain`-subtypes a safe assumption?** §3.2's
     whole "zero schema change later" argument rests on `Province`/`Kingdom` eventually being
     built as `Domain` TPT subtypes, matching vision.md §2's "fundamentally the same kind of
     thing" framing. That's a strong textual hint, not a made decision on record anywhere. If
     it turns out wrong (e.g. `Province`/`Kingdom` get modeled as a structurally different
     concept later), `OriginId` would need to be revisited then. Worth explicitly confirming
     this reading rather than discovering the mismatch when `Province`/`Kingdom` actually get
     built.
   - **8b. Single reference confirmed, not v2's multi-select?** The developer's phrasing ("a
     reference to either... ") was read as singular/exclusive-or — one `OriginId`, not a set.
     Flagging so that reading can be confirmed rather than assumed; if an item can originate
     from multiple places at once, this needs to be a M2M (`ItemBlueprintOrigin` join,
     `Domain` on the far side) instead of a plain FK, which is a bigger addition (closer to
     the `DefaultEnchantments` shape than to `CategoryId`'s).
9. ~~**`Tag` on `Category` — separate from this plan?**~~ **Resolved**: in scope, as
   `Category`-attached (§3.1), not a direct `ItemBlueprint` field. One sub-question: **is
   category-inherited tagging actually what's wanted, or should items be taggable
   independently of their category** (a direct `ItemBlueprint`↔`Tag` M2M, bigger than what
   v2 ever had)? §3.1 assumed the former (restore v2's shape) since that's what has precedent;
   confirm before Phase 1 if the latter was actually intended.
10. **Premium-currency items (`GemProducts`) — confirm vision.md's design call is final.**
    (§1.5.) The legacy doc leaves this as an open question (no v2-era trace of `GemProducts`
    or a successor found anywhere); vision.md §9.1 already answers it for v3 ("premium-currency
    items live here as a property of the template, not a separate class"), so this plan treats
    it as settled rather than reopening it. Flagging only so the developer can confirm that
    reading is actually what they intended, since the legacy record itself never resolved it.
11. **Does `knk-plugin` need `Grade`/`Tag`/`Origin` representation at all?** (§6 Phase 1.)
    `ItemBlueprintsDataAccess`/`KnkItemBlueprint` (§1.2) currently only carry the fields
    `ItemBlueprintBukkitMapper` actually needs to materialize an `ItemStack` (material, name,
    lore, enchantments). `Grade`/pricing/`Origin` are arguably admin/display-only metadata with
    no in-game rendering need yet (no star-lore rendering, no origin-based gameplay effect is
    in scope per §3/§6) — plausibly web-api/web-app-only additions, with the plugin side
    untouched. `Tag` likely doesn't need plugin representation at all (it's `Category`-level,
    and `Category` itself isn't currently in `KnkItemBlueprint`'s plugin-side shape either).
    Worth confirming before Phase 1 whether any of these need to reach the plugin, or if
    catalog-only (web-api + web-app) is the right scope for all four.
