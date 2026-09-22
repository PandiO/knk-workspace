# Items — Implementation Plan

**Status:** Draft, all open questions resolved — ready for implementation
**Last updated:** 2026-09-22 (revised four times same day: to fold in `docs/specs/legacy/items.md`,
to bring `Tag`/`Category` enrichment and `Origin` into scope, to finalize their shape —
`Origin` as a chronologically-ordered collection, `Tag` at both `Category` and `ItemBlueprint`
levels, plugin-side representation and standalone data-access gateways confirmed in scope —
and finally to walk through and resolve all remaining open questions in §7, all per explicit
developer decisions)

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

### 3.1 `Tag` and `Category` enrichment — now in scope, at **both** levels (developer decision)

Add a `Tag` entity (`Id`, `Name` unique). Two separate join entities, not one:

- **`CategoryTag`** (`CategoryId`+`TagId` composite key, no extra columns) — matches v2's
  `Category.tags`/`Tag.categories` shape exactly, attached to `Category`. An item inherits
  these transitively via `CategoryId`.
- **`ItemBlueprintTag`** (`ItemBlueprintId`+`TagId` composite key, no extra columns) — a
  second, direct M2M so an item can carry tags of its own, independent of its category. No
  legacy precedent for this half (§1.5: v2 never tagged items directly) — this is genuinely
  new scope, confirmed explicitly by the developer rather than inferred from history.

Both are the "plain" case of the same join-entity pattern `ItemBlueprintDefaultEnchantment`
already establishes (composite key, no extra columns beyond the two FKs) — an explicit join
entity, not EF Core's implicit skip-navigation many-to-many, is deliberate:
`[RelatedEntityField]`/the `ManyToManyRelationshipEditor` mechanism (§1.4) is built around an
explicit join *entity* with its own FK-bearing class; an implicit skip-navigation has no such
class and wouldn't be pickable by that mechanism at all.

**Not addressed by this plan, left as a follow-on for whatever consumes tags later (display
config, search/filter UI, etc.):** how "effective tags" (category-inherited ∪ item-direct) get
computed and shown. That's a read/display-time concern with no bearing on this schema — the
two M2M relationships are independently correct on their own; nothing here needs a merged
view to exist yet.

### 3.2 `Origin` — a chronologically-ordered provenance collection, not a single FK (revised)

**Superseded from this doc's first pass at this section**, which proposed a single
`ItemBlueprint.OriginId` FK. The developer's actual intent, given directly: *"Assume origin is
a collection with chronological order of multiple origins, the first and oldest entry is where
the item is procured/produced. The next are where possible alterations are done to it. For now
I will only use the origin with single entry (ie. where the item is produced). But the m2m
chronological order is for futureproofing."*

**Design: a new M2M join entity, `ItemBlueprintOrigin`**, matching the shape (and reusing the
same mechanism) as `ItemBlueprintDefaultEnchantment` — a real join entity with its own
independent `Id` (not a composite key on `(ItemBlueprintId, DomainId)`, deliberately — the
*same* `Domain` could legitimately appear twice in one item's history, e.g. produced and later
re-altered in the same town, so `DomainId` can't be part of a uniqueness constraint the way
`EnchantmentDefinitionId` is on the enchantment join):

- `Id` (int PK)
- `ItemBlueprintId` (FK, cascade delete)
- `DomainId` (FK → `Domain`, `Restrict` delete — same target entity and all the same
  TPT/future-proofing reasoning as this doc's earlier single-FK draft, just now the far side
  of a collection instead of a scalar)
- `SequenceNumber` (`int`) — defines chronological order; `0` (or `1`, pick one convention) is
  the production/procurement origin, higher numbers are later alterations. Unique constraint
  on `(ItemBlueprintId, SequenceNumber)` so ordering stays well-defined with no duplicate slots.

**For now, only `SequenceNumber = 0` (production origin) will actually be populated in
practice** — the collection shape exists for the "alteration history" future use the developer
named, not because Phase 1 needs to build alteration-tracking itself. Nothing in this plan
builds UI/logic for adding a second entry beyond what the generic M2M editor already provides
for free; a second entry is just as easy to add later as the first, precisely because this is
already a collection.

**Everything this doc's earlier draft established about the *target* entity still holds** —
`Town`/`District`/`Structure` (and `GateStructure`, which is a `Structure`) are already
`Domain` TPT subtypes sharing one base `DbSet<Domain>` (`Models/Town.cs:8`, `District.cs:8`,
`Structure.cs:7`, `GateStructure.cs:8`, `Properties/KnKDbContext.cs:19`), `Domain` already
carries `[FormConfigurableEntity("Domain")]` (`Models/Domain.cs:7`), and vision.md §2's
*"Kingdom, Province, Town, District are all fundamentally the same kind of thing"* framing is
why `DomainId` (not something narrower) is still the right FK target — confirmed as a safe
working assumption by the developer directly. When `Province`/`Kingdom` are eventually built
as `Domain` subtypes, `ItemBlueprintOrigin.DomainId` needs zero schema change to reference
them.

**FormConfiguration shape (§4.1 revised)**: `Origin` is no longer a plain object-picker field
in the General Information step — it's its own M2M step, same pattern as Default Enchantments:
`relatedEntityPropertyName: "Origins"`, `joinEntityType: "ItemBlueprintOrigin"`, child step
field `SequenceNumber` (Integer), related-entity picker on `Domain`.

**The `Domain` search-endpoint/client gap this doc's earlier draft identified still applies
unchanged**: unlike every other `RelatedEntityField`-picked entity in this codebase, `Domain`
has **no paged search endpoint** today — `DomainsController` only has `GetAll` (unfiltered,
unpaged; confirmed by reading the controller directly, only `GetAll`/`GetById`/`Create`/
`Update`/`Delete`/`by-region`/`search-region-decisions` exist) and `DomainRepository` has no
`SearchAsync` (unlike `TownRepository.SearchAsync(PagedQuery)`, the pattern every other picker
relies on). The web-app side has **no `domainClient.ts` at all** and no `'domain'` case in
`entityApiMapping.ts`'s dispatch tables — confirmed by direct grep, zero hits. The Origin
picker needs both built: a `POST api/Domains/search` endpoint (mirroring `TownsController`'s,
ideally surfacing the existing `domainType`/subtype-indicator convention already used by
`DomainRegionDecisionDto`/`ParentDomainDto` so the picker can show "Ironhaven (Town)" rather
than an ambiguous bare name) and a new `domainClient.ts` + `entityApiMapping.ts` registration
on the frontend. This is real, additional Phase 1/2 scope (§6), not something the existing
generic engine already covers for free the way `Category`/`Grade`/pricing were.

**Confirmed by the developer, no longer open**: `Province`/`Kingdom`-as-future-`Domain`-
subtypes is a safe assumption to build on (this doc's former §7.8a). The single-vs-multi
question (former §7.8b) is answered by the design above — multi, chronologically ordered,
single-entry-in-practice for now.

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
name → displayName → description → category → itemtype(material) → grade — `origin` and `tag`
are no longer simple fields in this sequence, see below:

| Step | Fields |
|---|---|
| General Information | `Name`, `DefaultDisplayName`, `Description`, `DefaultDisplayDescription`, `CategoryId` (new, §3.1 — object picker, existing `Category` rows only per §1.4), `IconMaterialRefId` (`HybridMinecraftMaterialRefPicker` → `HybridMaterialPicker`, picks `MinecraftMaterialRef` — doubles as material identity, §1.5), `GradeId` (new, §3 — object picker, existing `Grade` rows only, same inline-creation caveat as `Category`), `DefaultQuantity`, `MaxStackSize` |
| Pricing | `BasePriceMin`, `BasePriceMax` (new, §3) — kept as its own step so purchase-currency/gating fields (deferred, vision.md §9.1) have an obvious place to land later without reshuffling General Information |
| Default Enchantments | M2M step: `isManyToManyRelationship=true`, `relatedEntityPropertyName="DefaultEnchantments"`, `joinEntityType="ItemBlueprintDefaultEnchantment"`, child step field `Level` (Integer) — reuses the already-working `ManyToManyRelationshipEditor` "Create New Join Entry" flow (§1.4) to pick an *existing* `EnchantmentDefinition` and set its `Level` |
| Origin (revised, §3.2) | M2M step: `relatedEntityPropertyName="Origins"`, `joinEntityType="ItemBlueprintOrigin"`, child step field `SequenceNumber` (Integer) — picks an *existing* `Domain` row (Town/District/Structure today) per entry, ordered by `SequenceNumber` (`0` = production origin) |
| Tags (new, §3.1) | M2M step: `relatedEntityPropertyName="Tags"`, `joinEntityType="ItemBlueprintTag"`, no child-step fields (plain join, no extra columns) — direct item-level tags, independent of whatever `Category`'s own `Tags` step contributes |
| (optional, see §5) Scan | One WorldTask-bound field, `taskType: "ItemScan"`, pre-filling several General Information fields — ephemeral in `WorldTask.OutputJson` until the `ItemBlueprint` is actually created, exactly like Gate's `BlockSnapshots`/`OpenedBlockSnapshots` fields |

No field-conditional-within-a-step or step-display-condition logic is needed (nothing here is
optional-based-on-another-field the way Gate's `AllowPassThrough`-gated fields are). Five M2M
steps in one form (Default Enchantments, Origin, Tags, plus whatever `Category`'s own form
needs) is more than any existing `FormConfiguration` in this codebase currently has — nothing
in the mechanism itself limits step count, but worth a sanity check once this is actually
built in `FormConfigBuilder` that the UI stays usable with this many M2M sections on one form.

### 4.2 `Category`, `Tag`, `Grade`, and `EnchantmentDefinition` need their own `FormConfiguration`s too

Because inline related-entity creation is unreachable (§1.4), an admin populating
`ItemBlueprint.CategoryId`/`GradeId`/`DefaultEnchantments`/`Tags`/`Origins` needs `Category`,
`Grade`, `EnchantmentDefinition`, and `Tag` rows to already exist (`Domain`/`Town`/`District`/
`Structure` rows for `Origins` are assumed already populated via existing Town/District/
Structure tooling, not this plan's concern). `Category`'s own `Tags` M2M step (§3.1) means
`Tag` rows are also a dependency one level further removed, via `Category`, in addition to
being a direct `ItemBlueprint` dependency now. `Category` and `EnchantmentDefinition` already
carry `[FormConfigurableEntity]` (confirmed §1.1); `Grade` and `Tag` don't exist yet at all, so
both need the attribute added as part of creating them in Phase 1 (mechanical — same pattern
as every other entity in §1.1). This is the same "author a `FormConfiguration`" work as
`ItemBlueprint` itself, just for four more entity types — not new engine work, but real
additional scope:

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

**Trigger UX (resolved by the developer): both paths, not either/or.** The handler itself is
registered by field name in `WorldTaskHandlerRegistry` exactly like every other
`IWorldTaskHandler` — this alone makes it reachable through the standard chat-command claim
flow (`WorldTaskChatListener`, typing the claim code in chat) the same way `Location`/
`WgRegionId` already are. On top of that, add a dedicated `/knk itemscan claim <code>` command
as a second, faster entry point that does the claim-and-start in one step instead of two.
Both paths invoke the exact same handler logic (read the sender's main-hand `ItemStack` at
the moment of invocation, §5.2) — no duplicated business logic, just two ways in, matching
`WorldTaskHandlerRegistry`'s existing dual-keyed lookup capability (`getHandler(fieldName)` /
`getHandler(taskType, fieldName)`).

### 5.2 Handler behavior and OutputJson shape

On trigger, read the player's held main-hand `ItemStack`:
- `Material` (`getType()`) — not read anywhere in the plugin today, confirmed.
- `ItemMeta.getDisplayName()` / `hasDisplayName()`.
- `ItemMeta.getLore()` — reuse, don't reimplement: `EnchantmentRepository`/
  `LocalEnchantmentRepositoryImpl`'s existing regex-based lore parser (already used by
  `/ce info`, `InfoEnchantmentCommand.java`) to also pull out any KnK custom enchantments
  already lore-encoded on the item.
- `ItemMeta.getEnchants()` — vanilla Bukkit enchantments (not currently read anywhere either).
- `PersistentDataContainer` — **confirmed in scope**: read it defensively regardless of nothing
  writing to it yet (no `ItemInstance` exists today) — cheap now, forward-compatible for
  whenever `ItemInstance` work starts. Will read empty for every item scanned in the meantime;
  that's expected, not a bug to chase.

**Create-or-update, confirmed both in scope.** This mostly falls out of the generic engine for
free rather than needing new plugin/backend logic: `FormWizard` already renders the same
`FormConfiguration` for both `/forms/itemblueprint` (create) and `/forms/itemblueprint/edit/:id`
(edit), and a `WorldBoundFieldRenderer`-wrapped field behaves identically in both modes —
triggering a scan just calls the field's `onChange` with the fresh `OutputJson`, overwriting
whatever was there before, same as any other WorldTask-bound field. No extra Phase 4/5 work is
needed to support re-scanning an existing `ItemBlueprint` beyond what create-mode already
requires. One explicit non-goal, called out rather than silently assumed: **no selective-field
preservation** — a rescan on an existing item overwrites the scanned fields wholesale (an admin
who doesn't want that simply doesn't trigger a rescan). Building per-field "don't overwrite
what I already customized" protection is the instance-level cascade-override-flag concept
vision.md §9.1 describes for `ItemInstance` — deliberately out of scope for this
template-level flow.

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
  `DefaultDisplayDescription`.
- **Enchantment auto-match, confirmed with confirmation (developer decision)**:
  `vanillaEnchantments`/`customEnchantments` from the scan get matched server- or client-side
  against existing `EnchantmentDefinition` rows and pre-selected into the Default Enchantments
  M2M step — but as a pre-fill the admin reviews before saving, not a silent final write. This
  needs an actual lookup (by `MinecraftEnchantmentRefId`/namespace key for vanilla, by the same
  key convention `EnchantmentRepository` uses for custom) rather than just dumping raw parsed
  data into the step, which is real logic to design at implementation time, not just plumbing
  — but the ambiguity that existed here (match vs. no match) is resolved.
- Do **not** add `ItemScan` to `HEADLESS_TASK_TYPES` (§5.1).

## 6. Sequencing

**Not blocked by anything currently in flight.** Gate Structure Animation is already merged
(§0). InventoryMenu touches unrelated entities (`MenuTemplate`/etc.) on its own branch. Custom
Enchantments is done and only reused, not modified. This can start immediately.

1. **Phase 1 — Schema hardening.** Grown again from this doc's earlier version to cover the
   finalized §3.1/§3.2 designs:
   - `ItemBlueprint`: `CategoryId`/`Category` FK, a new `Grade` entity (`Id`/`Name`/`Stars`)
     + `GradeId` link, `BasePriceMin`/`BasePriceMax` (plain fields, no gating logic) — all
     `[RelatedEntityField]`/`[NavigationPair]`, same pattern as `IconMaterialRefId`.
   - A new `Tag` entity (`Id`/`Name`) plus **two** join entities: `CategoryTag`
     (`CategoryId`+`TagId`) and `ItemBlueprintTag` (`ItemBlueprintId`+`TagId`) — both
     composite-key, no extra columns (§3.1, "both levels" decision).
   - A new `ItemBlueprintOrigin` join entity (`Id` PK, `ItemBlueprintId`, `DomainId`,
     `SequenceNumber`, unique on `(ItemBlueprintId, SequenceNumber)`) — §3.2's revised
     collection design, replacing the single `OriginId` FK this doc originally proposed.
   - `DomainsController`: a new `POST api/Domains/search` (paged, name-filtered, ideally
     surfacing `domainType`) + matching `DomainRepository.SearchAsync` (§3.2) — needed for
     the `Origins` picker regardless of FormConfig authoring, since no such endpoint exists
     today.
   - `knk-web-app`: a new `domainClient.ts` + `'domain'` registration in
     `entityApiMapping.ts`'s four dispatch functions (§3.2) — same reason.
   - **Plugin-side representation, confirmed in scope** (resolves former §7.11): extend
     `KnkItemBlueprint` (`knk-core/.../domain/item/`) with `grade` (id/name/stars), `tags`
     (list of id/name — **direct `ItemBlueprintTag` entries only, confirmed by the developer,
     not the category-inherited set** — resolves the former §7.9 sub-question), and `origins`
     (ordered list of `{domainId, domainName, domainType, sequenceNumber}`).
     `ItemBlueprintMapper` (`knk-api-client`) and the web-api `ItemBlueprintReadDto`/mapper
     grow matching fields.
   - **Standalone plugin-side data-access gateways, confirmed in scope** (resolves the
     granularity half of former §7.11, against this doc's own recommendation): build
     `GradesDataAccess`/`TagsDataAccess` following the exact `ItemBlueprintsDataAccess`/
     `EnchantmentDefinitionsDataAccess` shape (`getByIdAsync`, `searchAsync`/`listAsync`,
     `refreshAsync`, `invalidate*`), for independent browsing even without a concrete in-game
     consumer yet. **`Domain`-for-origin needs a genuinely new gateway too, not a reuse of the
     existing `DomainsDataAccess`**: that class already exists
     (`knk-core/.../dataaccess/DomainsDataAccess.java`) but is narrowly scoped to
     `getByWgRegionIdAsync`/`refreshAsync`/`invalidate*` keyed by WorldGuard region id,
     returning a `DomainRegionSummary` — a completely different lookup shape (WG-region
     reverse lookup, backing the existing `by-region`/`search-region-decisions` endpoints)
     from what Origin needs (id-based fetch + paged search by name, matching the `search`
     endpoint §3.2 adds to `DomainsController`). Either extend `DomainsDataAccess` with the
     additional `getByIdAsync`/`searchAsync` methods (same class, two distinct responsibilities
     — a bit unusual but avoids a confusing second `Domains`-prefixed class) or give the new
     capability its own name (e.g. `DomainCatalogDataAccess`) — a naming call worth making
     deliberately at implementation time, not decided here.
   - One concrete, low-risk payoff now that plugin-side `Grade` exists:
     `ItemBlueprintBukkitMapper.fromBlueprint` could render grade as star-lore on the built
     `ItemStack`, reviving v1's
     `getGradeLore`/`"§l§bGrade: ★★★"` mechanic (§1.5) — worth doing since the data will be
     there anyway, though not required by this plan's scope.
   - EF migration; DTO/mapper updates (`ItemBlueprintDtos.cs`, `CategoryDtos.cs`). Mechanical
     for the entity/field additions; the `Domain` search endpoint and the plugin-side mapper
     work are the two pieces here that are genuinely new engine work, not just additive columns.
2. **Phase 2 — `Category`, `Tag`, `Grade`, and `EnchantmentDefinition` admin
   `FormConfiguration`s.** These need to be independently authorable *before* Phase 3 is
   useful, since inline related-entity creation isn't reachable (§1.4/§4.2) — `Category`'s own
   form now also needs its `Tags` M2M step. Pure `FormConfigBuilder` authoring work (or a
   seeder, pending §7.2) — no new engine code. `Town`/`District`/`Structure` (for `Origins`)
   are assumed already covered by existing tooling, not this plan's to build (§4.2).
3. **Phase 3 — `ItemBlueprint` admin `FormConfiguration`.** General Information step +
   Pricing step + Default Enchantments, Origin, and Tags M2M steps (§4.1 — four M2M steps
   total across this form and `Category`'s own, worth a UX sanity check per §4.1's note), using
   the already-built `RelatedEntityField`/M2M machinery and Phase 1's new fields/entities. This
   is the "web-app-centered admin management" deliverable and is usable on its own without
   Phase 4/5.
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

**All 11 items below are now resolved** (as of this same-day revision round, via direct
developer decisions) — kept here, struck through, as the decision record rather than deleted,
since several of them changed this plan's design materially (most notably `Origin`, which went
from a single FK to a chronologically-ordered M2M collection) and the reasoning is worth
keeping visible for whoever implements Phase 1. One implementation-time naming decision is
still flagged as not-yet-made (inside item 11) — everything else is a closed design call.

1. ~~**Category-only now, or also Grade/Tag/pricing?**~~ **Resolved**: Category, Grade,
   pricing, `Tag`, and `Origin` are all now in scope for Phase 1 — see §3/§3.1/§3.2.
2. ~~**FormConfiguration authoring mechanism.**~~ **Resolved by the developer**: author live
   via `FormConfigBuilder` — no seeder (§4.3).
3. ~~**Enchantment auto-matching on scan.**~~ **Resolved by the developer**: auto-match with
   confirmation — pre-select matches into the Default Enchantments M2M step, admin reviews
   before saving (§5.3).
4. ~~**Is reading `PersistentDataContainer` during a scan worth doing yet?**~~ **Resolved by
   the developer**: yes, read it defensively even though it will be empty for now (§5.2).
5. ~~**Create-only, or also re-scan-to-update an existing `ItemBlueprint`?**~~ **Resolved by
   the developer**: both — turns out to need no extra Phase 4/5 work beyond what create-mode
   already builds, since `FormWizard`/`WorldBoundFieldRenderer` already behave identically in
   create and edit mode (§5.2).
6. ~~**Scan trigger UX.**~~ **Resolved by the developer**: both — the standard chat-command
   claim flow (free, since `IWorldTaskHandler` registration already provides it) *and* a
   dedicated `/knk itemscan claim <code>` command as a faster second entry point, both driving
   the same handler logic (§5.1).
7. ~~**The unreachable inline-create UI in `ManyToManyRelationshipEditor.tsx`**~~ **Resolved by
   the developer**: leave it — Phase 2's standalone-forms workaround stands, no fix to the
   shared component as part of this plan (§1.4).
8. ~~**`Origin` — shape and forward-compatibility.**~~ **Resolved by the developer**: in scope,
   as a chronologically-ordered collection (`ItemBlueprintOrigin`, §3.2 revised) — not the
   single FK this doc originally proposed. `Province`/`Kingdom`-as-future-`Domain`-subtypes is
   confirmed a safe assumption to build on. Single-entry-in-practice for now (production
   origin only), collection shape kept for future alteration-history tracking.
9. ~~**`Tag` on `Category` — separate from this plan?**~~ **Resolved by the developer**: in
   scope at **both** levels — `Category.Tags` (inherited) and a new direct
   `ItemBlueprint.Tags` (`ItemBlueprintTag` join), independent of each other (§3.1). The
   plugin-side sub-question this raised is also resolved: `KnkItemBlueprint.tags` carries
   **direct tags only**, not the inherited set (§6 Phase 1) — nothing left open here.
10. ~~**Premium-currency items (`GemProducts`) — confirm vision.md's design call is final.**~~
    **Resolved by the developer**: confirmed settled — currency type stays a property of the
    template, not a separate class, whenever that field actually gets built (still deferred
    per vision.md §9.1, not part of this plan's Phase 1) (§1.5).
11. ~~**Does `knk-plugin` need `Grade`/`Tag`/`Origin` representation at all?**~~ **Resolved by
    the developer**: yes, the plugin needs it too (§6 Phase 1 revised accordingly —
    `KnkItemBlueprint` grows `grade`/`tags`/`origins`), **and** standalone plugin-side
    data-access gateways get built now (`GradesDataAccess`/`TagsDataAccess`, plus new
    id/search capability for `Domain` — against this doc's own recommendation to defer that,
    the developer chose to build it now regardless). One implementation detail surfaced while
    updating this section, not asked about directly but worth flagging before Phase 1 starts:
    `knk-plugin` already has a class named `DomainsDataAccess`
    (`knk-core/.../dataaccess/DomainsDataAccess.java`), but it's narrowly scoped to
    `getByWgRegionIdAsync` (WorldGuard-region reverse lookup, backing the existing
    `by-region`/`search-region-decisions` endpoints) — a different responsibility from the
    id/search-based browsing `Origin` needs. §6 Phase 1 flags this as a naming/extension
    decision to make deliberately at implementation time (extend the existing class with a
    second responsibility, or give the new capability its own name) rather than assuming
    either way.
