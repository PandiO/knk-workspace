# Items — Implementation Plan

**Status:** Draft — first version of this document
**Last updated:** 2026-09-22

Ref: `docs/vision/vision.md` §9.1 (Items). Sources checked while writing this:
`docs/reports/IMPLEMENTATION_STATUS_AUDIT.md`, `docs/reports/LEGACY_VS_V2_GAP_ANALYSIS.md`
(both 2026-09-10, see §0 on staleness), `docs/reports/web-api-scan-2026-09-18.md`,
`docs/architecture/web-api-architecture.md`, `docs/architecture/web-app-architecture.md`,
`docs/specs/gate-structure-animation/GATE_FORMCONFIG.md` (field-matrix/WorldTask-bound-field
precedent), `docs/specs/world-tasks/API_CONTRACT.md`, `docs/specs/form-configurations/
{m2m-editor-current-spec,m2m-join-creation-improvement-spec}.md`, plus a direct, current
read of `knk-plugin`/`knk-web-api`/`knk-web-app` source (2026-09-22) — see §1 for what that
read found that the docs above didn't (or got wrong).

## 0. This is a first draft, not a revision — and two source reports are stale

Two things the task that produced this document assumed turned out not to hold:

- **`docs/specs/legacy/items.md` and a prior `docs/specs/items/IMPLEMENTATION_PLAN.md` do
  not exist.** `docs/specs/legacy/` contains only its own `README.md` (no per-feature legacy
  analyses have been written for *any* feature yet, not just Items). There was no prior Items
  plan to revise — this document is new, not an update of earlier work, unlike the
  InventoryMenu precedent it otherwise follows the shape of.
- **`IMPLEMENTATION_STATUS_AUDIT.md` and `LEGACY_VS_V2_GAP_ANALYSIS.md` (both dated
  2026-09-10) are now stale on at least one material point relevant here**: the audit's §8
  states Gate Structure Animation is "entirely unmerged." A direct check of the currently
  checked-out branch (forked from `main`/`master` after 2026-09-10) shows `GateStructure`,
  `GateDoor`, `GateBlockSnapshot`/`GateOpenedBlockSnapshot`, the animation migrations, and the
  plugin/web-app gate code are all present — i.e. **Gate Structure Animation has since merged
  to trunk across all three repos.** This matters for this plan because `GATE_FORMCONFIG.md`'s
  field-matrix/WorldTask-bound-field pattern (the explicit precedent this plan is asked to
  follow) is therefore a *live, merged* pattern to build on, not one still stuck on a branch.
  Refreshing those two reports generally is out of scope here; this note exists so this plan
  isn't built on a stale premise.

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

## 2. What vision.md §9.1 wants vs. what `ItemBlueprint` actually has today

Vision.md §9.1 describes a two-entity split (`ItemTemplate` catalog row +
`ItemInstance` live/owned copy). The current code has **only a narrower predecessor of the
template half**, under the name `ItemBlueprint`:

| Vision.md `ItemTemplate` field | Current `ItemBlueprint` reality |
|---|---|
| name | `Name` — present |
| category | **absent.** `Category` exists as its own self-referencing entity (`Models/Category.cs`, `ParentCategoryId`/`ChildCategories`, its own icon FK) but has **zero link** to `ItemBlueprint` — no `CategoryId` anywhere on the model. |
| grade | **absent.** No `Grade` entity, enum, or field exists anywhere in the current codebase, despite vision.md saying to "keep v2's `Item`/`Grade`/`Category`/`Origin` model." |
| itemtype / origin | **absent.** No such field or enum exists. (Not to be confused with `objectConfigs.tsx`'s unrelated legacy `itemType` — §1.3.) |
| `basePriceMin`/`basePriceMax`, purchase-currency (coins/gems) | **absent.** No pricing fields anywhere on `ItemBlueprint`/its DTOs. |
| base drop amount, default loot/lore config | Partially covered by `DefaultQuantity`/`DefaultDisplayDescription` (used as default lore text), but no loot-table/probability concept. |
| — (not in vision's template list, but present today) | `IconMaterialRefId`/`IconMaterial`, `DefaultDisplayName`, `MaxStackSize`, `DefaultEnchantmentIds`/`DefaultEnchantments` (M2M via `ItemBlueprintDefaultEnchantment`, with `Level`). |

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

**Decision:** add a `CategoryId` link now (Phase 1) — `Category` already exists, fully built,
and linking it is a small, mechanical, additive migration with an obvious precedent
(`IconMaterialRefId`'s own FK/attribute pattern). **Do not** add `Grade`/pricing/origin in
this pass — vision.md doesn't specify their concrete values/enum today (unlike the Gate
feature, where `GateType`'s four values were already fixed before `GATE_FORMCONFIG.md` was
written), and inventing them here would be exactly the kind of unscoped addition this
project's conventions warn against. This is flagged as an open question in §7.1 in case that
call is wrong.

Everything else vision.md §9.1 lists as `[OPEN]`, deferred, or belonging to a later pass —
`ItemInstance`/live-instance tracking, soulbound/ghosted, cascade-to-instances, item-age/
owner-count bonuses, loot boxes, price fields, purchase-currency, crafting restriction,
purchase gating, the delivery-fallback stash, and all of §9.2 Kits — stays out of scope here,
exactly as vision.md itself already scoped it.

## 4. Web-app admin management via FormWizard/FormConfigBuilder

Unlike InventoryMenu (where this layer was explicitly deferred), this is real, in-scope work
for Items — but per §1.3, most of the *engine* work is already done. What's actually needed:

### 4.1 Field matrix (modeled on `GATE_FORMCONFIG.md`)

`ItemBlueprint` has no polymorphic "type" enum the way `GateStructure` has `GateType` — so,
unlike Gate's four-way type-dependent matrix, this is a single, flat step layout:

| Step | Fields |
|---|---|
| General Information | `Name`, `Description`, `CategoryId` (new, §3 — object picker, existing `Category` rows only per §1.4), `IconMaterialRefId` (`HybridMinecraftMaterialRefPicker` → `HybridMaterialPicker`, picks `MinecraftMaterialRef`), `DefaultDisplayName`, `DefaultDisplayDescription`, `DefaultQuantity`, `MaxStackSize` |
| Default Enchantments | M2M step: `isManyToManyRelationship=true`, `relatedEntityPropertyName="DefaultEnchantments"`, `joinEntityType="ItemBlueprintDefaultEnchantment"`, child step field `Level` (Integer) — reuses the already-working `ManyToManyRelationshipEditor` "Create New Join Entry" flow (§1.4) to pick an *existing* `EnchantmentDefinition` and set its `Level` |
| (optional, see §5) Scan | One WorldTask-bound field, `taskType: "ItemScan"`, pre-filling several General Information fields — ephemeral in `WorldTask.OutputJson` until the `ItemBlueprint` is actually created, exactly like Gate's `BlockSnapshots`/`OpenedBlockSnapshots` fields |

No field-conditional-within-a-step or step-display-condition logic is needed (nothing here is
optional-based-on-another-field the way Gate's `AllowPassThrough`-gated fields are).

### 4.2 `Category` and `EnchantmentDefinition` need their own `FormConfiguration`s too

Because inline related-entity creation is unreachable (§1.4), an admin populating
`ItemBlueprint.CategoryId`/`DefaultEnchantments` needs `Category` and `EnchantmentDefinition`
rows to already exist. Both entities already carry `[FormConfigurableEntity]` (confirmed §1.1)
so this is the same "author a `FormConfiguration`" work as `ItemBlueprint` itself, just for two
more entity types — not new engine work, but real additional scope. `AbilityDefinition`'s
own optional 1:1 extension (`EnchantmentDefinition.AbilityDefinition`) can stay out of the
`EnchantmentDefinition` form for now (custom-ability authoring already has its own tooling
per Custom Enchantments' completed status) unless the developer wants it folded in.

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

1. **Phase 1 — Schema hardening.** Add `CategoryId`/`Category` (nullable FK, `Restrict`
   delete, same `[RelatedEntityField(typeof(Category))]`/`[NavigationPair]` pattern as
   `IconMaterialRefId`) to `ItemBlueprint`; EF migration; DTO/mapper updates
   (`ItemBlueprintDtos.cs`, `ItemBlueprintMapper.java` on the plugin side, plus
   `KnkItemBlueprint` domain record). Small, mechanical, no dependencies. Resolves the §3
   Category decision; Grade/Tag/pricing stay explicitly out (§7.1).
2. **Phase 2 — `Category` and `EnchantmentDefinition` admin `FormConfiguration`s.** These
   need to be independently authorable *before* Phase 3 is useful, since inline related-entity
   creation isn't reachable (§1.4/§4.2). Pure `FormConfigBuilder` authoring work (or a seeder,
   pending §7.2) — no new engine code.
3. **Phase 3 — `ItemBlueprint` admin `FormConfiguration`.** General Information step +
   Default Enchantments M2M step (§4.1), using the already-built `RelatedEntityField`/M2M
   machinery and Phase 1's new `CategoryId` field. This is the "web-app-centered admin
   management" deliverable and is usable on its own without Phase 4/5.
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

## 7. Open questions / design gaps needing a decision

1. **Category-only now, or also Grade/Tag/pricing?** (§3.) Recommended: Category only: Grade/
   Tag/pricing have no concrete field/enum definition anywhere yet (unlike Gate's `GateType`,
   which was fixed before its FormConfig was designed) — deciding those values now would be
   scope invention, not reconciliation.
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
