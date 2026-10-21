# Minecraft catalogue (materials and blocks): implementation plan

**Status:** Draft, decisions D1-D9 taken by the developer (2026-10-21, §11). Nothing is implemented yet.
**Last updated:** 2026-10-21
**Issue:** [KNG-200](https://linear.app/kngpandi/issue/KNG-200). Related: [KNG-195](https://linear.app/kngpandi/issue/KNG-195) (hybrid submit fixes, In Review), [KNG-182](https://linear.app/kngpandi/issue/KNG-182) (Minecraft 26.3).

Scope: the catalogue of Minecraft materials (`MinecraftMaterialRef`) and block states
(`MinecraftBlockRef`). The enchantment catalogue (`MinecraftEnchantmentRef`, its own static JSON
and `HybridEnchantmentPicker`) is deferred by the developer. It shares the hybrid machinery
below, so §9 notes where it has to keep working.

## 0. Goal (developer, 2026-10-19)

> **Scope update 2026-10-21 (developer, D7-D9 in §11).** The material picker only matters for
> item blueprints (`ItemBlueprint.IconMaterialRefId`). The existing database rows may be merged
> into or deleted by the scan; no new or empty database is involved. Icons **are a requirement of
> this improvement**, only not urgent in the current state: the old static URLs are not repaired
> (D6), and the scan resolves icons from phase 3 on. The block-state picker moves to a later,
> optional phase 6.

- An admin starts a scan from the web app. The running Minecraft server reads every item and
  block of its version and the API stores them in the database.
- Every entry gets an image URL from a public, versioned asset source, so the web app can show
  the real item (item blueprints first, more pages later).
- Pickers (form configurations) search one clean, de-duplicated list from the database.
- Block-specific data (orientation, other states) lives with blocks, not with the generic entry.

## 1. Current state (verified 2026-10-20)

Checked on web-api `master` `2d71155`, web-app `main` `e30c815` and plugin `main` `79be488`.
These are the history findings from 2026-10-19, re-checked one by one.

### 1.1 API (knk-web-api)

- `Models/MinecraftMaterialRef.cs`: `Id`, `NamespaceKey` (varchar 191, **unique index**),
  `LegacyName`, `Category` (required, free text), `IconUrl`. The table is `minecraftmaterialrefs`
  with collation `utf8mb4_general_ci`, so the unique index is already case-insensitive.
- `Models/MinecraftBlockRef.cs`: `Id`, `NamespaceKey`, `BlockStateString`, `LogicalType`,
  `IconUrl`. **No unique index, no FK to the material, and no entity references it.** The plugin's
  `BlockSnapshot.minecraftBlockRefId` is always 0 (`GateLoaderAdapter.java:756`).
- FKs to `MinecraftMaterialRef` are all `Restrict`: `Category.IconMaterialRefId`,
  `ItemBlueprint.IconMaterialRefId`, `GateStructure.IconMaterialRefId`,
  `GateDoor.FallbackMaterialRefId`, `MenuTemplate.BackgroundMaterialRefId`,
  `MenuItemTemplate.MaterialRefId` and `LootboxType.DisplayMaterialRefId`.
  `ItemBlueprint.IconMaterialRefId` is not just an icon: the plugin builds the real `ItemStack`
  from it (`ItemBlueprintBukkitMapper`), so changing a ref's key changes game items.
- Static catalogue: `Data/minecraft_material_catalog.json`, loaded by the singleton
  `MinecraftMaterialCatalogService`.
  - It has 1537 entries with `namespaceKey`, `displayName`, `category`, `texturePath` and
    `iconUrl`, and no `legacyName`.
  - There are no duplicate keys and every key is already lower-case `minecraft:`.
  - Categories: ITEM 1304, BLOCK 201, BANNER 32. These are not meaningful:
    `minecraft:stone`, `minecraft:water` and `minecraft:wall_torch` are ITEM, while BLOCK is
    mostly planks, slabs and stairs.
  - 51 display names occur more than once (119 entries). For example `minecraft:torch` and
    `minecraft:wall_torch` are both "Torch" with the same icon, and every wood type's sign and
    wall sign share a name.
  - **Icons.**
    - 1477 URLs point at PrismarineJS `minecraft-assets` `data/1.21.4/`.
    - **823 of them use the path `block/<name>.png`, which does not exist**: Prismarine's folder
      is `blocks/`. All 7 sampled `block/` URLs return 404, while `blocks/stone.png` returns 200.
      The generator copied the texture id `minecraft:block/x` into the path.
    - 60 entries have no URL and 3 point at `missingno`.
    - Block items use a flat face texture rather than an inventory render: `oak_stairs` and
      `chest` show `oak_planks`.
- Hybrid search (`SearchHybrid=true` filter on `POST api/MinecraftMaterialRefs/search` and
  `.../MinecraftBlockRefs/search`, and `GET api/MinecraftMaterialRefs/hybrid`):
  - It loads all DB rows and the whole static file, merges them in memory and pages afterwards.
  - DB rows that are not in the file are appended **without the search or category filter**.
  - `SortBy` is ignored, and the returned `PageSize` is the item count of the page.
  - Unsaved catalogue rows are returned with `Id = 0` (`h.Id ?? 0`).
  - The block variant builds `dbItems.ToDictionary(x => x.NamespaceKey)`. **Two saved states of
    one block make the search throw.** It also matches every block state to the material
    catalogue by key only.
- Writes:
  - `POST api/MinecraftMaterialRefs` (create) has no existing-key check, so a duplicate fails on
    the unique index as a 500.
  - `POST .../get-or-create` exists, fills `IconUrl` from the static file, and has no
    normalisation.
  - Blocks have no get-or-create at all.
- Material rows are created by six code paths, each with its own rules:

  | Code path | Trims the key? | Fallback category |
  |---|---|---|
  | `MinecraftMaterialRefService.GetOrCreateAsync` | no | required from the caller |
  | `ItemBlueprintService.EnsureIconMaterialRefAsync` | yes | "Uncategorized" |
  | `CategoryService` (same pattern) | yes | "Uncategorized" |
  | `KitSeed` | no | "ITEM" |
  | `ItemBlueprintV1Seed` | no | "ITEM" |
  | `EnchantBookSeed` | no | "ITEM" |
  | `LootboxSeed` | no | "ITEM" |

  The seeds take `IMinecraftMaterialCatalogService` at startup (`Program.cs` ~l.293).
- `FieldType.HybridMinecraftMaterialRefPicker = 8` is stored in FormConfigurations as the
  **string** name (`JsonStringEnumConverter`). For example `Data/FormConfigurationSeeds/GateStructure.json`
  uses it for `IconMaterialRefId`. Its settings JSON is `{categoryFilter, multiSelect}`.
- The API already calls the plugin over HTTP (`RegionService` → plugin `RegionHttpServer`,
  loopback by default) and hands it headless jobs through WorldTasks.

### 1.2 Web app (knk-web-app)

- `src/components/minecraft/HybridMaterialPicker.tsx` is a thin wrapper around
  `PagedEntityTable` (`entityTypeName="MinecraftMaterialRef"`, filter `category`). There is no
  block picker.
- `PagedEntityTable` switches to hybrid mode on the entity name alone (material, block and
  enchantment refs). That includes the ObjectDashboard list and every generic Object/List picker
  on those types.
- **Duplicate rows:** `tableRowKey` and `isSameSelection` (`src/utils/forms/sessionPinnedRows.ts`)
  treat `id: 0` as a real id (`present(0) === true`).
  - Every unsaved row on a page gets the same React key `id:0`. Duplicate keys make React reuse
    the wrong row when the list changes, so rows appear doubled or stale after search or paging.
  - All unsaved rows also count as one selection.
  - The existing test only covers an unsaved row **without** an id.
- Selecting an unsaved row calls plain `POST create` (`PagedEntityTable.tsx` ~l.541-556), not
  `persistFromCatalog` (get-or-create). Two quick picks, or a key someone saved in between, end
  in a 500 or a conflict.
- Multi-select "select all" adds unsaved rows without creating them.
- `fetchData` has no guard against stale responses. A slow, broad search can overwrite the
  result of a later, narrower one.
- Icons:
  - The table columns (`src/config/objectConfigs.tsx`) render `<img>` with no `onError`.
  - `DisplayField` hides a broken image; `DisplaySection` swaps in an SVG placeholder.
  - With 823 broken URLs, most block rows show a broken image.
- Other `hybrid` callers that must move before the routes can go:
  - The FormWizard ItemScan/KitScan path: `getHybrid` + `persistFromCatalog`, i.e. a correct
    get-or-create.
  - Roads `MaterialKeyInput`: `getHybrid` for suggestions only.
- KNG-195 (branch `claude/kng-195-form-submit-fixes`, In Review) changes
  `normalizeFormSubmission`. An id-0 row is sent by namespaceKey, the enchantment picker is
  normalised, and ItemBlueprint/Category DTOs accept `iconMaterialRefNamespaceKey`. Phase 1
  builds on that branch after it merges.

### 1.3 Plugin (knk-plugin)

- There is no registry scan anywhere (no `Registry.ITEM/BLOCK`, `Material.values()`,
  `ItemType`/`BlockType`).
- Material refs are read only with `GET /MinecraftMaterialRefs/{id}`
  (`MinecraftMaterialRefsQueryApiImpl`, cached by id). There is no write.
- `MaterialNamespaceResolver` resolves `matchMaterial(key)`, then the part after `:`, then the
  upper-snake token. `legacyName` is never used.
- Block identity in gates is the `minecraft:` key, and the full state is
  `BlockData.getAsString()` (`blockDataJson`, e.g. `minecraft:oak_door[facing=north,half=lower]`).
  `GateDoor.ScanMaterialWhitelist/Blacklist` are key strings, not ref ids.
- Ways in from the API:
  - `HeadlessWorldTaskPoller` polls `GET /WorldTasks/status/Pending`. Its only handler is
    `GateBlockScanTaskHandler`.
  - `RegionHttpServer` serves region endpoints only.
  - Bulk POST examples to copy: `WorldAnalyticsApiImpl` (`/batches`) and `StatisticsApiImpl`.
- KNG-182 moves the plugin to Paper `26.3.build.205-stable` (branch `claude/mc-26.2-upgrade`).

## 2. Target domain model

There is one canonical row per Minecraft namespaced key. It is not split into two catalogues,
because one key is often both an item and a block (`minecraft:stone`).

### 2.1 `MinecraftMaterialRef`: the catalogue entry, evolved in place

The name, table and ids stay the same. All seven FKs keep pointing at the same rows, and
`objectType`/`relatedEntityType` strings in stored FormConfigurations and displays stay valid.
Conceptually it becomes the registry entry. The UI can label it "Minecraft material".

| Column | Notes |
|---|---|
| `Id`, `NamespaceKey` | unchanged; key normalised (§3) and unique |
| `DisplayName` (new) | from the scan (§5.3); backfilled from the static file for existing rows |
| `IsItem`, `IsBlock` (new, bool) | from the scan; a key can be both. Pickers filter on these, not on `Category` |
| `MaxStackSize` (new, nullable) | from the scan; useful for blueprints |
| `DefaultBlockState` (new, nullable) | `BlockData.getAsString()` of the default state when `IsBlock` |
| `CatalogStatus` (new) | `Active` (in the latest scan), `Missing` (not in the latest scan, kept for its references), `Unverified` (created by a seed, a form or the bootstrap import and never seen in a scan) |
| `FirstSeenVersion`, `LastSeenVersion`, `LastScanId` (new) | provenance |
| `IconUrl` | resolved icon, written by the sync |
| `IconUrlOverride` (new) | manual URL; wins over `IconUrl` and is never overwritten by a scan |
| `IconSource`, `IconStatus` (new) | provider + version used; `Resolved` / `Missing` / `Broken` |
| `Category` | **kept** (required, used by `categoryFilter` settings and seeds). New rows get a value derived from the flags (`BLOCK` when `IsBlock`, else `ITEM`). Existing values are not rewritten. Becomes display-only after phase 4 |
| `LegacyName` | kept; nothing reads it (the plugin ignores it) |

### 2.2 `MinecraftBlockRef`: a reusable block state

- `MaterialRefId` (new FK → `MinecraftMaterialRef`, `Restrict`). It starts nullable, is
  backfilled, and becomes required once every row is linked.
- `NamespaceKey` stays as a denormalised copy for compatibility. It must equal the material's key.
- `BlockStateString`: the canonical state (§4). Null means "the block, any state".
- `StateKey` (new, char(64)): SHA-256 of `normalizedKey + canonicalState` (or of the key alone
  when the state is null). It is unique (§4) because MySQL cannot index `longtext`.
- `LogicalType` stays as a free label (e.g. a gate role). It is not part of identity.
- `IconUrl` stays as an optional override. Otherwise the material's icon is shown.

The scan does not create block refs. They are created on demand when someone saves a specific
state. The scan only stores the default state and, optionally, the property schema on the
material (§5.2).

### 2.3 `MinecraftCatalogScan` (new table)

`Id`, `Status` (`Requested`, `Running`, `Ingesting`, `Completed`, `Failed`), `RequestedByUserId`,
`WorldTaskId`, `MinecraftVersion`, `ServerVersion`, `SchemaVersion`, `ContentHash`,
`EntryCount`, the counters `Inserted`, `Updated`, `Unchanged`, `MarkedMissing` and `IconsMissing`,
`Error`, `CreatedAt` and `CompletedAt`.

## 3. Unique keys and normalisation

- One `MinecraftNamespaceKey.Normalize(string)` in the API, and the same rules in a web helper and
  in the plugin:
  1. Trim, then lower-case with the invariant culture.
  2. Reject inner whitespace.
  3. If there is no `:`, prefix `minecraft:`.
  4. Validate against `^[a-z0-9_.-]+:[a-z0-9_./-]+$`; otherwise 400.
- It is applied in every write path: create, update, get-or-create, `EnsureIconMaterialRefAsync`
  in ItemBlueprint and Category, the four seeds, ingest, and the block-ref service. The six
  get-or-create copies become **one** `IMinecraftMaterialRefResolver.GetOrCreateAsync(key, origin)`,
  which sets `CatalogStatus=Unverified` for rows the catalogue doesn't know.
- `POST create` with an existing key answers **409 with the existing id** instead of a 500. The
  web app uses get-or-create anyway (phase 1).
- Uniqueness:
  - Materials: the existing unique index on `NamespaceKey`.
  - Blocks: a unique index on `StateKey`, added only after the duplicate audit is clean (§6).
- Existing data is not rewritten blindly. The phase 2 migration normalises only rows whose
  normalised key is free. Collisions go into the audit report (§6).

## 4. Identity of block states

- Canonical form: `namespace:key[prop=value,...]`, lower-case, with properties sorted
  alphabetically and no spaces. Null or empty brackets mean "no state".
- The plugin is the authority when it is available. It runs
  `Bukkit.createBlockData(s).getAsString()`, which fills in every property, and then sorts.
  The API applies the same textual canonicalisation (parse, sort, re-join), so a state typed in
  the web app and one captured in the game produce the same `StateKey`.
- Full versus partial states (`minecraft:oak_stairs[facing=north]`), decision D2: store what was
  given, canonicalised, and flag `IsPartial` when it has fewer properties than the block's
  schema. A partial state is then a different identity from
  the full one, on purpose: it means "any oak stairs facing north".
- Each state is a row, not a column on the material, and the material holds no state. This
  fixes the hybrid collision for good: two states of `oak_stairs` are two block refs with one
  `MaterialRefId`.

## 5. Plugin ↔ API scan contract

### 5.1 Flow

1. The web app calls `POST api/MinecraftCatalog/scans` (`RequirePermission knk.admin.content`).
   The API answers 409 if a scan is `Requested`, `Running` or `Ingesting`. Otherwise it creates a
   `MinecraftCatalogScan` and a headless WorldTask `TaskType="MinecraftCatalogScan"`,
   `InputJson={"scanId":N}`, and returns the scan.
2. The plugin's `HeadlessWorldTaskPoller` picks the task up (default poll every 5 s, backing off
   to 60 s when idle). A new `MinecraftCatalogScanTaskHandler` reads the registry on the main
   thread, builds the snapshot off-thread and calls `PUT api/MinecraftCatalog/scans/{scanId}/snapshot`
   (`RequirePluginService`, `X-API-Key`).
3. The plugin then completes the WorldTask with a short summary as `outputJson`. The snapshot
   itself does not go into `outputJson`.
4. The web app polls `GET api/MinecraftCatalog/scans/{id}`, or the scan list, and shows the
   counters.

The scan is **not** automatic on every start. As an extra, the plugin can report its version at
startup (pattern `DomainWorldBackfillReporter`), and the web app then shows "the catalogue is
from 1.21.10, the server runs 26.3: scan now?".

### 5.2 Snapshot body (schema version 1)

```json
{
  "schemaVersion": 1,
  "scanId": 12,
  "minecraftVersion": "1.21.10",
  "serverVersion": "<Bukkit.getVersion()>",
  "contentHash": "<sha256 over the sorted entries>",
  "entries": [
    {
      "key": "minecraft:oak_stairs",
      "isItem": true,
      "isBlock": true,
      "maxStackSize": 64,
      "translationKey": "block.minecraft.oak_stairs",
      "displayName": "Oak Stairs",
      "defaultBlockState": "minecraft:oak_stairs[facing=north,half=bottom,shape=straight,waterlogged=false]",
      "blockStateProperties": { "facing": ["north","south","west","east"], "half": ["top","bottom"] }
    }
  ]
}
```

- **Source on 1.21.10:** `Material.values()` minus `isLegacy()` and `isAir()` (air excluded),
  with `isItem()`, `isBlock()`, `getMaxStackSize()`, `createBlockData().getAsString()` and
  `getKey()`.
- **On 26.3 (KNG-182):** check on that branch whether `Material` is still complete or whether
  `Registry.ITEM`/`Registry.BLOCK` (`ItemType`/`BlockType`) must be used. The reader sits behind
  a small `CatalogSource` interface in knk-paper, with the DTO in knk-api-client, so only the
  reader changes.
- `blockStateProperties` is optional in v1. It prepares a later state picker.
- Size: about 1.5k entries is roughly 0.5 MB of JSON. One request is enough. Above 10,000
  entries the API answers 413.

### 5.3 Display names

The server has translation keys, not English names. The plugin renders the key with
`GlobalTranslator` to `en_US` if the server jar carries `en_us` (decision D4; verify live).
Otherwise the API derives a title-case name from the key (`oak_stairs` →
"Oak Stairs"). Pickers always show the key under the name, so "Torch" and "Wall Torch" can be
told apart even if the names match.

## 6. Transactions and idempotency (API ingest)

1. **Validation, before any write:**
   - `schemaVersion` is known.
   - The scan exists and is `Requested` or `Running`.
   - There is at least 1 entry.
   - Every key normalises cleanly and is unique within the payload. A duplicate key answers 400
     and nothing is written.
   - The `contentHash` is recomputed and must match.
2. **Idempotency.**
   - The same `scanId` with the same `contentHash` on a `Completed` scan answers 200 with the
     stored result and no writes. A plugin retry after a timeout is safe.
   - A different hash on a completed scan answers 409.
   - A second scan with an identical hash still runs. It is cheap and only updates
     `LastScanId` and `LastSeen*`.
3. **Icons, before the transaction.** Resolve them in memory with the provider (§7): one mapping
   download per version, cached. No HTTP happens inside the DB transaction.
4. **One transaction** (`BeginTransactionAsync`), with the scan set to `Ingesting`:
   - Load all material rows (about 2k) into a dictionary by normalised key.
   - Insert missing rows.
   - Update the facts on existing rows: flags, name, default state, `LastSeen*`,
     `CatalogStatus=Active`, and `IconUrl`/`IconSource`/`IconStatus` unless `IconUrlOverride` is
     set.
   - **Clean-up of the existing rows (decision D7).** Rows are matched by normalised key, so an
     existing row keeps its `Id` and every reference to it stays valid. Then, in the same
     transaction:
     - Rows whose key only differs by notation (case, spaces, missing `minecraft:`) from a scanned
       key are **merged** into the scanned row: the seven FKs are repointed, then the duplicate
       is deleted.
     - Rows not in the snapshot that nothing references (none of the seven FKs, and no id in
       form drafts) are **deleted**.
     - Rows not in the snapshot that are still referenced become `Missing` (D3). The scan result
       lists them with their referrers, and the admin page offers "merge into …" for each one.
     - The scan result counts merged, deleted and missing rows, and logs every deleted key.
   - `Id` of kept rows, `Category`, `LegacyName` and `IconUrlOverride` are never changed by a
     scan.
   - `SaveChanges` runs in batches. On commit the scan becomes `Completed` with its counters. On
     any error it rolls back and the scan becomes `Failed` with the error text.
5. **Concurrency.**
   - The single active scan is enforced at request time (step 1 of §5.1) and re-checked at
     ingest with `SELECT … FOR UPDATE` on the scan row.
   - A concurrent get-or-create from a form that hits the unique index during ingest is caught:
     the code reloads the row and continues.
   - Get-or-create itself catches `DbUpdateException` (duplicate key) and returns the row that
     won. That ends the "two quick picks" race.

## 7. Image assets: selection and fallback

> **Part of this improvement (decision D8, revised 2026-10-21).** Icons are required for KNG-200:
> the providers are built in phase 3 and every scan resolves icons; `MinecraftIcon` comes with the
> DB-only picker in phase 4. Only the old static URLs are left as they are (D6).

- Use `IMinecraftIconProvider` with an ordered list of providers in config
  (`MinecraftCatalog:Icons:Providers`). Each provider declares the versions it has.
  1. **PrismarineJS `minecraft-assets`.**
     - It has `items_textures.json` and `blocks_textures.json` per version.
     - It is available up to 26.1; 26.2 and 26.3 returned 404 on 2026-10-20.
     - The provider maps texture ids correctly: `minecraft:block/x` → `blocks/x.png`, and
       `minecraft:item(s)/x` → `items/x.png`. That is the 823-URL bug fixed at the root.
     - Block-only keys (`wall_torch`) use `blocks_textures.json`.
  2. **InventivetalentDev `minecraft-assets`.**
     - Raw textures exist per version branch, and 26.3 is there.
     - There is no item → texture mapping, so it uses a heuristic (`item/<name>.png`, then
       `block/<name>.png`), checked with a HEAD request.
     - It serves as the fallback for versions Prismarine lacks.
- **Version choice:** the exact scan version first, else the nearest lower version the provider
  has. `IconSource` records which one was used, e.g. `prismarine@26.1`.
- **Precedence:** `IconUrlOverride` > `IconUrl` from the sync > none.
  - `IconStatus=Missing` rows can be listed in the admin page for manual overrides.
  - An optional background job checks resolved URLs with HEAD requests and sets `Broken`. It runs
    outside the ingest transaction.
- **Web app:** one `MinecraftIcon` component (`src/components/minecraft/`).
  - It renders `<img loading="lazy">`. `onError` or a missing URL shows a neutral placeholder.
  - It replaces the three current renderings: the table columns, `DisplayField` and
    `DisplaySection`.
- **Limits.**
  - Flat textures are not inventory renders: stairs show planks and a chest shows planks.
    Isometric renders would need a renderer or a source that has them; that is out of scope.
  - Icons are Mojang textures hot-linked from GitHub raw. That is fine for the admin web app.
    Caching or proxying can come later.

## 8. Migration of existing data

1. **Migration `MinecraftCatalogEntryFields`** (phase 2), additive only.
   - New nullable columns on `minecraftmaterialrefs`.
   - A new `MaterialRefId` (nullable) and `StateKey` (nullable, **non-unique** index) on
     `minecraftblockrefs`.
   - The new table `minecraft_catalog_scans`.
   - Defaults: `CatalogStatus=Unverified`, `IsItem`/`IsBlock` null until known.
2. **Backfill (code, idempotent, logged).**
   - Materials:
     - Normalise keys where the normalised key is free.
     - Fill `DisplayName` from the static file.
     - Set a best guess of `IsItem`/`IsBlock` from the file category. It stays `Unverified`, and
       the first scan overwrites the flags.
   - Blocks:
     - Canonicalise `BlockStateString`.
     - Compute `StateKey`.
     - Link `MaterialRefId` by normalised key, through the resolver. If the material doesn't
       exist, it is created as `Unverified`.
3. **Audit report** (`GET api/MinecraftCatalog/audit`, admin), read-only.
   - Material keys that collide after normalisation.
   - Block refs sharing a `StateKey`.
   - Rows that are not normalised or not linked.
   - Unverified rows.
   - Materials missing from the latest scan that are still referenced, with their referrers per
     FK.
4. **Resolution.** Notation duplicates and unreferenced rows are cleaned up by the scan itself
   (§6 step 4, decision D7). For what remains (referenced rows the scan doesn't know), an admin
   "merge A into B" action repoints the seven material FKs in one transaction and only then
   deletes A.
   - Block refs have no referrers, so a duplicate can simply be deleted after the audit.
   - Before that, check JSON blobs that might hold material ids, e.g. form drafts
     (`FormSubmissionProgress`) and WorldTask output; the same applies before any rename.
5. **Migration `MinecraftCatalogConstraints`** (phase 4), after the audit is clean:
   - a unique index on `StateKey`;
   - `MaterialRefId` required;
   - `StateKey` required.
6. **Not done:** the schema migrations themselves delete nothing; deletion and merging only
   happen in the scan's clean-up (§6 step 4) and the merge action. Kept rows keep their id, and
   nothing is renamed.

## 9. Retiring the hybrid picker and the static JSON

The order matters, because some callers still depend on the hybrid routes.

1. **Phase 1:** the hybrid picker is stabilised (§10) and stays the default.
2. **No bootstrap import (decision D5).** The static file is not imported. A fresh database
   starts empty until the first server scan; until then seeds and forms create `Unverified`
   rows (no icon, `Category` from the resolver default) and the hybrid picker stays available.
3. **Phase 4:** `MinecraftCatalog:PickerSource` = `Hybrid | Database`, default `Database` as soon
   as one scan has completed (on a database without a completed scan it stays `Hybrid`).
   - `PagedEntityTable` stops adding `SearchHybrid` for materials and blocks. The hybrid code
     stays reachable through the setting as a rollback.
   - The picker filters on `kind` (item/block) and `CatalogStatus != Missing`. It shows name, key
     and icon, and it sorts and pages in the database.
   - Old settings are mapped: `categoryFilter` `ICON` / `ITEM` → `kind=item`, `BLOCK` →
     `kind=block`, `BANNER` → key contains `_banner`.
   - Later (phase 6): block refs get a picker that chooses a material with `IsBlock`, then
     optionally a state.
4. **Before deleting anything,** move the other callers:
   - ItemScan/KitScan move from `getHybrid` + `persistFromCatalog` to `search` + get-or-create.
   - Roads `MaterialKeyInput` moves to `search`.
   - The seeds move from `IMinecraftMaterialCatalogService` to the resolver (§3), with
     `Unverified` rows.
5. **Phase 5,** after live sign-off:
   - Delete `GET .../hybrid`, the `SearchHybrid` branches, `GetHybridAsync`/`SearchHybridAsync`,
     the hybrid DTOs, the `isPersisted` badges and auto-create.
   - Delete `MinecraftMaterialCatalogService` and its JSON (decision D5: no bootstrap copy is
     kept). After that, a fresh database has an empty catalogue until its first scan.
   - Rename the component to `MinecraftMaterialPicker`.
   - **Keep the enum name** `HybridMinecraftMaterialRefPicker`, because stored FormConfigurations
     hold it as a string. Rename it only together with a data migration of `formfields.FieldType`
     and the seed JSON, as a separate step.
   - **The enchantment catalogue is deferred.** `PagedEntityTable` keeps hybrid mode for
     `minecraftenchantmentref` until that work is done, and the enchantment routes are not
     touched.

## 10. Phases, tests and order

Each phase is its own commit series on one feature branch per repo. Each is tested and live
checked before the next starts.

| Phase | Content | Repos | Tests |
|---|---|---|---|
| **1 Stabilise** (after KNG-195 merges) | API: hybrid filters DB-only rows by search/category, de-duplicates by normalised key, applies `SortBy`, returns `Id = null` for unsaved rows and the requested `PageSize`; block hybrid groups instead of `ToDictionary`. Normaliser + single resolver; create → 409 on an existing key; `POST MinecraftBlockRefs/get-or-create`. Web: auto-create via get-or-create (materials and blocks); unsaved rows keyed and compared by normalised key; id 0/null never counts as an id; stale-response guard; "select all" skips or creates unsaved rows. No icon work yet (D6): icons come in phases 3-4 | web-api, web-app | API: hybrid search (filter, dedupe, sort, paging, two states of one block), normaliser table tests, get-or-create race (unique index), create 409. Web: `tableRowKey`/`isSameSelection` with id 0/null, PagedEntityTable hybrid (auto-create calls get-or-create, two unsaved rows stay distinct, stale response ignored) |
| **2 Schema + audit** | Migration `MinecraftCatalogEntryFields`, backfill, audit endpoint, merge action, DTO fields (additive, old fields unchanged) | web-api | Migration up/down on a copy of the dev DB, backfill idempotent (run twice), audit finds seeded collisions, merge repoints all seven FKs and rolls back on error |
| **3 Scan + ingest + icons** | `MinecraftCatalog` controller (scans, snapshot, audit), ingest with clean-up (§6), icon providers (§7). Plugin: `CatalogSource`, `MinecraftCatalogScanTaskHandler`, api-client `MinecraftCatalogApi` (+ startup version report). Web: admin page "Minecraft catalogue" (scan button, status, counters, missing-but-referenced rows with "merge into", missing icons and overrides, audit) | web-api, plugin, web-app | API: ingest insert/update/unchanged; notation duplicates merged with FKs repointed; unreferenced rows not in the scan deleted; referenced ones kept as `Missing`; rollback leaves every row untouched; override survives; icons resolved before the transaction; duplicate key → 400 with nothing written, same hash → no-op, other hash → 409, rollback → `Failed`, one active scan. Icon provider mapping table tests (block/blocks, items, block-only keys, version fallback). Plugin: snapshot builder (legacy/air excluded, sorted, hash stable), handler completes/fails the WorldTask, api-client request body (interceptor like `WorldAnalyticsApiImplTest`). Live: scan on the dev server (1.21.10, then 26.3) |
| **4 DB-only picker** | `PickerSource` switch, item picker for `ItemBlueprint.IconMaterialRefId` first (kind=item) with `MinecraftIcon` (§7) in the picker and blueprint displays, settings mapping, callers moved off `hybrid`, seeds on the resolver; migration `MinecraftCatalogConstraints` after a clean audit | web-api, web-app | Picker search/sort/paging against the DB, `MinecraftIcon` onError placeholder, settings mapping, ItemScan/KitScan/Roads on the new calls, seeds on an empty DB without any scan (Unverified rows, no icons) and after a scan (enriched, not duplicated) |
| **5 Retire** | Remove hybrid routes/code and the catalogue service (§9.5) | web-api, web-app | Full suites; grep for `SearchHybrid`/`getHybrid`/`MinecraftMaterialCatalogService` returns only enchantment code |
| **6 Later, optional** | Block-state picker (§9.3) | web-api, web-app | Block-state picker search and canonical state on save |

**Order with other work:**

- Phase 1 waits for KNG-195. It touches `normalizeFormSubmission` and the ItemBlueprint/Category
  DTOs.
- Phase 3's plugin part is written against `main` and compiled on the KNG-182 branch as well.
  The first real scan should be on 26.3, because a 1.21.10 scan would immediately be outdated.
- Phase 2 can start in parallel with phase 1.

## 11. Decisions (developer, 2026-10-21)

D1-D6 were put to the developer as questions in the Claude app on 2026-10-21; D7-D9 and the
clarification of D5 followed in chat the same day.

| # | Question | Decision |
|---|---|---|
| D1 | Name of the canonical entry | Keep `MinecraftMaterialRef` (same table, ids and name; new columns only) |
| D2 | Partial block states | Allowed as their own identity, flagged `IsPartial` |
| D3 | Entries gone in a newer version | Kept as `Missing`, hidden in pickers, listed in the audit |
| D4 | Display names | English from the server's translations, else derived from the key (verify live) |
| D5 | Old static JSON for an empty database | **No bootstrap import.** Only a brand-new install starts empty until its first scan. The existing database stays and the scan updates its rows (D7). The JSON is deleted in phase 5 |
| D6 | Fix the 823 broken icon URLs in phase 1 | **No.** The old static URLs stay as they are; the scan resolves icons from phase 3 on |
| D7 | Existing material rows | The scan may merge and delete them: notation duplicates merged into the scanned row, unreferenced rows not in the scan deleted, referenced ones kept as `Missing` for a manual merge (§6 step 4) |
| D8 | Icons | **Required for this improvement**, not urgent in the current state: providers in phase 3, `MinecraftIcon` in phase 4 (revised the same day; an earlier note deferred them) |
| D9 | Focus | The material picker only matters for item blueprints; that picker comes first in phase 4 |
