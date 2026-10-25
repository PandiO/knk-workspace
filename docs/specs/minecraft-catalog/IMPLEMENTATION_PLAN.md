# Minecraft catalogue (materials and blocks): implementation plan

**Status:** Implemented and merged 2026-10-22 (knk-web-api `master` `4f34f58`, knk-web-app `main` `0622a87`, knk-plugin `main` `69c93885`); live-tested by the developer. KNG-250 (enchantments, §12) merged 2026-10-23 (knk-web-api `master` `a1f8838`, knk-web-app `main` `f9ee73c`, knk-plugin `main` `c7806b87`) after the developer's live test. Follow-up: KNG-251 (block-state picker, the optional phase 6). Decisions D1-D12 in §11.
**Last updated:** 2026-10-23
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

### 5.2a Contract v1 as implemented (2026-10-21)

This section is binding for the three repos; it refines §5.1/§5.2.

**Requesting a scan (web app → API).** `POST api/MinecraftCatalog/scans` (`knk.admin.content`,
no body). The API:
- marks active scans older than 15 minutes `Failed` ("timed out", their WorldTask `Cancelled`);
- answers 409 when a scan is still `Requested` or `Ingesting`;
- creates a `WorkflowSession` (requesting user, `EntityTypeName="MinecraftCatalogScan"`,
  `EntityId=<scanId>`), a WorldTask with `TaskType="MinecraftCatalogScan"`,
  `Status="Pending"`, `InputJson={"scanId":N}`, and the scan;
- answers 201 with the scan DTO below.

Other endpoints (all `knk.admin.content`): `GET scans?take=20` (newest first), `GET scans/{id}`,
`POST scans/{id}/cancel`, `GET audit`, `POST backfill`,
`POST materials/{sourceId}/merge-into/{targetId}`, `PUT materials/{id}/icon-override`
(body `{"iconUrlOverride": "<url>" | null}`). Reading a scan whose WorldTask has `Failed` marks
the scan `Failed` with the task's error.

**Scan DTO** (camelCase): `id`, `status` (`Requested|Running|Ingesting|Completed|Failed`),
`requestedByUserId`, `worldTaskId`, `minecraftVersion`, `serverVersion`, `entryCount`, `inserted`,
`updated`, `unchanged`, `merged`, `deleted`, `markedMissing`, `iconsMissing`, `error`,
`createdAt`, `completedAt`.

**Plugin.** A headless handler (`IHeadlessWorldTaskHandler`) for `MinecraftCatalogScan`:
1. reads `scanId` from `inputJson`;
2. on the main thread, builds the entries from `Material.values()`, skipping `isLegacy()` and
   `isAir()`;
3. off the main thread, sends `PUT {api}/MinecraftCatalog/scans/{scanId}/snapshot` with
   `X-API-Key`;
4. on 2xx calls `POST WorldTasks/{id}/complete` with
   `outputJson={"scanId":N,"entryCount":M}`; on any error calls `POST WorldTasks/{id}/fail`
   with the message;
5. calls `onFinished` in every case.

**Snapshot body:**

```json
{
  "schemaVersion": 1,
  "minecraftVersion": "1.21.10",
  "serverVersion": "<Bukkit.getVersion()>",
  "contentHash": "<64 lower-case hex>",
  "entries": [
    { "key": "minecraft:oak_stairs", "isItem": true, "isBlock": true, "maxStackSize": 64,
      "translationKey": "block.minecraft.oak_stairs", "displayName": "Oak Stairs",
      "defaultBlockState": "minecraft:oak_stairs[facing=north,half=bottom,shape=straight,waterlogged=false]" }
  ]
}
```

- `minecraftVersion` is `Bukkit.getMinecraftVersion()`.
- `key` is `Material.getKey().toString()`.
- `translationKey` is the Paper translation key (item key for items, block key for block-only
  entries), or null.
- `displayName` is the key rendered to `en_US` through `GlobalTranslator`, or null when that
  rendering just returns the key.
- `defaultBlockState` is `createBlockData().getAsString()` for blocks, else null.

**`contentHash`:**
1. Sort the entries by `key` (ordinal).
2. Make one line per entry:
   `key|isItem|isBlock|maxStackSize|translationKey|displayName|defaultBlockState`. Booleans are
   `true`/`false`, a null field is an empty string, and `maxStackSize` is a decimal integer.
3. Join the lines with `\n` (no trailing newline).
4. Take the SHA-256 of the UTF-8 bytes, as lower-case hex.

Test vector: the two entries
`{key:"minecraft:stone",isItem:true,isBlock:true,maxStackSize:64,translationKey:"block.minecraft.stone",displayName:"Stone",defaultBlockState:"minecraft:stone"}`
and
`{key:"minecraft:apple",isItem:true,isBlock:false,maxStackSize:64,translationKey:"item.minecraft.apple",displayName:null,defaultBlockState:null}`
give the text
`minecraft:apple|true|false|64|item.minecraft.apple||\nminecraft:stone|true|true|64|block.minecraft.stone|Stone|minecraft:stone`.
Both sides pin its hash in a unit test.

**Snapshot responses:**
- 200 with the scan DTO.
- 400 on an unknown `schemaVersion`, no entries, more than 10,000 entries, an invalid or
  duplicate key, or a hash mismatch. Nothing is written.
- 404 for an unknown scan.
- 409 when the scan is not `Requested`/`Running`. An exception: a `Completed` scan with the same
  hash answers 200 with the stored result.

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
     - Fill `DisplayName` from the static file, else derive it from the key.
     - Leave `IsItem`/`IsBlock` null. The file's category is too unreliable for a guess
       (`minecraft:stone` is ITEM there), so the first scan sets the flags.
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
   - Known limit: JSON blobs (form drafts in `FormSubmissionProgress`, WorldTask output) are not
     rewritten. A draft that still holds a merged or deleted id fails validation on submit with
     "MinecraftMaterialRef with id N not found"; the admin picks the material again.
   - When both materials have block refs with the same state, the merge leaves two rows with one
     `StateKey`; the audit lists them. Once phase 4 makes `StateKey` unique, the merge must drop
     the duplicate instead.
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

Each phase is its own commit series on one feature branch per repo, with automated tests per
phase. Live testing happens once, after phase 4 (D12).

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

## 10a. Implementation status

| Phase | Status | Where |
|---|---|---|
| 2 Schema + audit | Code-complete 2026-10-21, not merged | knk-web-api `claude/relaxed-davinci-hsdspe`: migration `MinecraftCatalogEntryFields`; `Services/MinecraftCatalog/` (`MinecraftNamespaceKey`, `MinecraftBlockState`, `MinecraftMaterialReferences`, `MinecraftCatalogMaintenanceService`); `MinecraftCatalogController` (`GET audit`, `POST backfill`, `POST materials/{sourceId}/merge-into/{targetId}`, all `knk.admin.content`); the backfill also runs at startup before the item seeds; read-only catalogue fields on the material/block DTOs |
| 3 Scan + ingest + icons | Code-complete 2026-10-21, not merged, not live-tested (D12) | knk-web-api `d33213b`: `MinecraftCatalogScanService` (request/list/get/cancel/ingest, icon override), `MinecraftIconResolver` (config `MinecraftCatalog:Icons`, defaults in code), snapshot/scan DTOs, scan status as concurrency token (snapshot only, no schema change). knk-plugin `a513cc71`, `b5b5450b`, `21eb8751`: knk-core `catalog/CatalogSnapshot` (hash), knk-api-client `MinecraftCatalogApi` (PUT with a 2-minute read timeout), knk-paper `catalog/BukkitMaterialCatalogSource (renamed `BukkitCatalogSource` in KNG-250)` + `tasks/MinecraftCatalogScanTaskHandler` registered in `KnKPlugin`. knk-web-app `91cc7ae`, `938d86b`, `634708d`: `/admin/minecraft-catalog` (scan, polling, cancel, history; needs-attention with merge; missing icons with overrides), `minecraftCatalogClient`, `MinecraftIcon` |
| 4 DB-only picker | Code-complete 2026-10-21, not merged, not live-tested (D12) | knk-web-api `e9d581e`; knk-web-app `b6ba680`..`de23957` (picker `kind` filter, "New" badge only for unsaved rows, `MinecraftIcon` in material/block columns, DisplayField/DisplaySection and a new item blueprint Icon column, icon-override list on the admin page). See "Phase 4 as built" below |
| 1 Stabilise | Code-complete 2026-10-21, not merged, not live-tested (D12) | Started before KNG-195 merged, because the overlap that D10 assumed doesn't exist: KNG-195 changes `normalizeFormSubmission` and DTOs/services phase 1 doesn't touch, and both repos' branches merge cleanly with `claude/kng-195-form-submit-fixes` (checked with `git merge-tree`). knk-web-api `c5da4b1`: hybrid merge by normalised key, saved-only rows filtered, `id: null` for unsaved rows, sorting and page size, one row per block state, 409 with the existing id on create/update, parallel get-or-create returns the winner, new `POST MinecraftBlockRefs/get-or-create`. knk-web-app `841488b`, `f8d0e72`, `a5af37f`: id 0/"0"/null is no id; unsaved material rows keyed and compared by the normalised key (blocks: key + state); auto-create through get-or-create (materials `persistFromCatalog`, blocks the new `getOrCreate`); stale search responses ignored. There is no select-all control in the app (the handler was never rendered), so none was added |
| Live test of phases 1-4 | Passed (developer, 2026-10-22) | Scan #1 on Minecraft 26.3: 1812 entries (1752 inserted, 60 updated, 0 merged/deleted/missing, 98 without an icon); no duplicate rows, search works, item blueprint picker OK, dashboard and picker tables OK, audit clean |
| 5 Retire | Merged 2026-10-22 after the developer's re-test | See "Phase 5 as built" below |

**Phase 5 as built:**
- **Migration `MinecraftCatalogConstraints`.** It makes `minecraftblockrefs.StateKey` unique and
  `MaterialRefId` required.
  - It first runs a check (a short-lived stored procedure with `SIGNAL`). While block refs are
    unlinked, unkeyed or duplicated, the migration stops with "KNG-200: block refs not clean…"
    before any change. It never deletes rows.
  - The backfill and the audit read block refs with `COALESCE(MaterialRefId, 0)`, so a database
    between the two migrations can still be backfilled.
  - Upgrade path for an environment that gets every KNG-200 migration at once:
    1. Run `dotnet ef database update`. The phase 2 migration applies, and the constraints
       migration refuses if the table isn't clean.
    2. Start the API once; the backfill runs at startup.
    3. Check `GET api/MinecraftCatalog/audit` and merge what it lists.
    4. Run `dotnet ef database update` again.

    The dev database (audit clean) applies it directly.
- **Removed from the API:**
  - `GET MinecraftMaterialRefs/hybrid` and the hybrid merges for materials and block refs;
  - `MinecraftCatalog:PickerSource`, `MinecraftMaterialCatalogService` with
    `Data/minecraft_material_catalog.json`, and the hybrid option DTOs.

  Seeds and inline creation make Unverified rows named from the key (D5: a new database starts
  empty until its first scan).
- **Picker searches.** They send `Picker=true`; the pre-KNG-200 name `SearchHybrid=true` is still
  accepted. A search without the flag is the admin search: all rows, Missing included.
- **Web app.**
  - Hybrid mode is left only for enchantments, which are deferred.
  - `HybridMaterialPicker` is renamed `MinecraftMaterialPicker`. The enum
    `HybridMinecraftMaterialRefPicker` is kept for stored FormConfigurations.
  - ItemScan/KitScan resolve materials with get-or-create.
  - Roads suggestions come from the picker search.
  - `getHybrid` is removed from the material client.
- **Untouched.** The enchantment catalogue (static JSON, hybrid routes and picker) and the plugin.

**Phase 4 as built (refines §9.3-9.4):**
- **The switch is server-side.** `MinecraftCatalog:PickerSource` is `Auto` (default), `Hybrid` or
  `Database`. `Auto` uses the database once a scan has `Completed`. In database mode:
  - the existing hybrid routes (`SearchHybrid=true` on `POST MinecraftMaterialRefs/search` and
    `MinecraftBlockRefs/search`, and `GET MinecraftMaterialRefs/hybrid`) answer from the database
    only;
  - every row has `isPersisted: true`, a display name and the effective icon;
  - sorting and paging happen in SQL, and Missing rows are hidden.

  Setting `Hybrid` is the rollback. Callers on `getHybrid` (FormWizard ItemScan/KitScan, Roads
  `MaterialKeyInput`) therefore keep working unchanged. They move off `hybrid` in phase 5, together
  with the deletion.
- **Picker filters (`MinecraftPickerFilters`).** `kind=item|block`. A legacy `categoryFilter`
  overrides it: ITEM/ICON → item, BLOCK → block, BANNER → keys with `_banner`, ANY → all.
  `HybridMaterialPicker` sends `kind=item` unless its settings say BLOCK or ANY (D9: item
  blueprints, menus and icons are items). Rows no scan has seen yet use their legacy category for
  the kind.
- **Single creation path.** Seeds and the inline creation in ItemBlueprint/Category/get-or-create
  normalise the key and create through `MinecraftMaterialRefFactory` (Unverified, with a display
  name).
- **Icons.** `ItemBlueprintListDto.iconUrl` feeds the blueprint overview. The audit has
  `iconOverrides`, so an override can be cleared on the admin page.
- **Column lookup in the web app.** The object dashboard and the form pickers looked up the column
  registry by the API's entity name ("ItemBlueprint"), but the registry keys are lower case, so
  they never found it. The FormWizard column settings already looked it up in lower case.
  `getColumnDefinitions` now ignores case. As a result, dashboards and pickers for every entity
  with a registry entry (town, district, gates, lootboxes, ...) show the registry's columns and
  formatters when no saved column configuration says otherwise. Check this in the live test.
- **Material table columns.** ID, Name (display name), Icon, Namespace Key, Kind and Status.
  Category and Legacy Name were dropped from the default columns.
- **Deferred to phase 5.** The migration `MinecraftCatalogConstraints` (unique `StateKey`, required
  `MaterialRefId`) needs a clean audit on the real database, which is only known at the live test
  (D12).

Open points from phase 3:
- Live checks for the end-of-chain test (D12): that `GlobalTranslator` gives English names on Paper (D4), the real entry count, payload size and ingest time, and icon coverage on 26.3 (Prismarine stops at 26.1; the rest comes from Inventivetalent guesses).
- The plugin code uses only `Material` API that the Paper 26.3 jar still has (checked with `javap`). It has not been compiled on the KNG-182 branch, because this environment has no JDK 25.
- The admin page can't clear an override on a material that has one, because the audit lists only materials without an icon and without an override. Phase 4 adds the icon to the material edit form.

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
| D10 | Start while KNG-195 is unmerged | Start phase 2 now (API only, hardly overlaps KNG-195); phase 1 follows once KNG-195 is merged |
| D11 | Phase 1 size | The full phase 1 as planned, although phase 4 replaces the hybrid picker |
| D12 | Live tests | Only at the end: phases 1-4 are built with automated tests, the developer tests everything in one live run |

## 12. Enchantments (KNG-250, 2026-10-22)

[KNG-250](https://linear.app/kngpandi/issue/KNG-250) gives `MinecraftEnchantmentRef` the KNG-200
treatment: the server scan is the source, the database the catalogue, and the static
`Data/minecraft_enchantment_catalog.json`, the hybrid merge and the hybrid mode of
`PagedEntityTable` go. It also fixes [KNG-243](https://linear.app/kngpandi/issue/KNG-243): a picker
no longer creates refs or definitions.

### 12.1 Decisions

| # | Decision |
|---|---|
| E1 | **Custom enchantments are in the scan** (developer, 2026-10-22), from knk-core `EnchantmentRegistry`, keyed `knk:<id>` |
| E2 | One enchantment picker shows vanilla and custom together, with a Custom badge and a filter (all / vanilla / custom) |
| E3 | The scan makes sure every scanned enchantment has an `EnchantmentDefinition`. It links every unlinked matching definition, and creates one when none is linked. This replaces the picker's auto-create, so blueprint and lootbox pickers (which pick definitions) offer every vanilla and custom enchantment. Existing definitions are never deleted and are only changed in two ways: they are linked, and a vanilla definition still at its ref's previous level follows the server's max level (§12.4 step 5). `AbilityDefinition` rows are never touched |
| E4 | Enchantment refs get the catalogue fields (`CatalogStatus`, `FirstSeenVersion`, `LastSeenVersion`, `LastScanId`) and the KNG-200 clean-up rules: notation duplicates merged, unreferenced unseen rows deleted, referenced ones `Missing` |
| E5 | Icon: the enchanted book icon the same scan resolved for `minecraft:enchanted_book`. It is set when the ref has no `IconUrl` or one ending in `/enchanted_book.png`, so a URL set by hand stays |
| E6 | Schema version 1 is still accepted; it leaves enchantments alone |
| E7 | Removed: the static JSON and `MinecraftEnchantmentCatalogService`, `GET MinecraftEnchantmentRefs/hybrid`, the `SearchHybrid` alias (`MinecraftPickerFilters.LegacyPicker`), `isPersisted` on enchantment list rows, and the hybrid mode of `PagedEntityTable` |

### 12.2 Snapshot schema version 2

Version 1 (§5.2a) plus an `enchantments` list:

```json
{
  "schemaVersion": 2,
  "minecraftVersion": "26.3", "serverVersion": "...", "contentHash": "...",
  "entries": [ ... as in version 1 ... ],
  "enchantments": [
    { "key": "minecraft:sharpness", "isCustom": false, "maxLevel": 5,
      "translationKey": "enchantment.minecraft.sharpness", "displayName": "Sharpness", "category": null },
    { "key": "knk:flash_chaos", "isCustom": true, "maxLevel": 1,
      "translationKey": null, "displayName": "Flash Chaos", "category": "SUPPORT" }
  ]
}
```

- **Vanilla** (and data-pack) enchantments: everything in Paper's enchantment registry.
  - `key` is the registry key.
  - `maxLevel` is `getMaxLevel()`.
  - `translationKey` is the enchantment's translation key.
  - `displayName` is its description rendered to `en_US` through `GlobalTranslator`, or null when
    that rendering just returns the key.
  - `category` is null.
  - `isCustom` is false.
- **Custom** enchantments: everything in knk-core `EnchantmentRegistry`.
  - `key` is `knk:` plus the lower-case id.
  - `displayName` and `maxLevel` come from the registry.
  - `translationKey` is null.
  - `category` is the type, `ATTACK` or `SUPPORT`.
  - `isCustom` is true.
- **Validation.** `enchantments` is required in version 2 and may be empty, with at most 1,000
  entries. Every key must be a valid namespaced key and unique in the list. A custom entry must not
  use the `minecraft` namespace. Otherwise 400, as for materials.
- **`contentHash` v2.**
  1. Take the version 1 text of the entries (§5.2a, steps 1-3).
  2. Append `\n#enchantments`.
  3. For each enchantment sorted by `key` (ordinal), append `\n` +
     `key|isCustom|maxLevel|translationKey|displayName|category`, with the same encoding as for
     materials.
  4. Take the SHA-256 of the UTF-8 bytes, as lower-case hex.
- **Test vector v2.** The two §5.2a entries plus the two enchantments above give
  `ab2c65626e6508eb4c169dabefda5ef7570f94c8d966f31adecc624dfe823154`; with no enchantments
  it is `9846ad62d84d42d5a05e0cbac900ab6f671bf3bb0dd7c1bb5961aa2316f63c3e`. The text for the first
  is
  `minecraft:apple|true|false|64|item.minecraft.apple||\nminecraft:stone|true|true|64|block.minecraft.stone|Stone|minecraft:stone\n#enchantments\nknk:flash_chaos|true|1||Flash Chaos|SUPPORT\nminecraft:sharpness|false|5|enchantment.minecraft.sharpness|Sharpness|`.
  Plugin and API pin both.
- The handler's `outputJson` adds `enchantmentCount`.
- The scan DTO adds `enchantmentCount`, `enchantmentsInserted`, `enchantmentsUpdated`,
  `enchantmentsUnchanged`, `enchantmentsMerged`, `enchantmentsDeleted`,
  `enchantmentsMarkedMissing`, `enchantmentDefinitionsCreated` and `enchantmentDefinitionsLinked`.
  All are 0 or null for a version 1 scan.

### 12.3 Which scanned key an existing row belongs to

The material normaliser adds `minecraft:` to a bare key, which is wrong for custom keys: an old
custom ref stored as `chaos` must merge into `knk:chaos`, not be deleted. So an existing ref (or an
unlinked definition) is matched in this order:

1. If its key has the `minecraft` namespace, it belongs to that normalised key.
2. If it has the `knk` namespace or no namespace, and it compares equal to a scanned custom id
   after `AbilityDefinition.MatchKey` (strip any namespace, keep lower-case letters and digits:
   `knk:flash_chaos`, `flash_chaos` and `flashchaos` are equal), it belongs to that custom key.
   For a key without namespace this only applies when the row is marked custom or no scanned
   vanilla enchantment has that name.
3. If it has no namespace, it belongs to `knk:<key>` when the row is marked custom, else to
   `minecraft:<key>`.
4. Otherwise it belongs to its own normalised key (e.g. a data-pack namespace).

Definitions match the same way. A custom definition is keyed by the ability key, e.g. `chaos`.

### 12.4 Ingest (same transaction as the materials)

1. Load all enchantment refs and group them by the key from §12.3.
2. Merge each group into its first row: the row whose key already equals the target, else the
   lowest id. `EnchantmentDefinition.MinecraftEnchantmentRefId` is repointed to the kept row, and
   the duplicates are deleted and saved before the kept row takes the key.
3. Upsert every scanned enchantment:
   - `NamespaceKey`, `DisplayName` (scanned, else derived from the key), `MaxLevel` and `IsCustom`;
   - `Category` (the scanned one; null keeps the row's legacy category such as `Weapon`);
   - `CatalogStatus = Active`, the versions and `LastScanId`;
   - the icon per E5.
4. Unseen refs: deleted when no `EnchantmentDefinition` references them, else marked `Missing`.
5. Definitions (E3), for each scanned enchantment:
   - A vanilla definition linked to the ref whose `MaxLevel` equals the ref's level before this scan
     takes the scanned max level. The seeds leave ref and definition at the same level, so seeded
     definitions get the vanilla maximum; a level set by staff stays.
   - Every unlinked definition matching per §12.3 and of the same kind (custom/vanilla) is linked.
   - If no definition is linked after that, a new one is created:
   - `Key`: the vanilla key, or the custom id;
   - `DisplayName` and `MaxLevel` from the scan;
   - `IsCustom` from the scan;
   - linked to the ref.

   On the next startup, the AbilityDefinition seed attaches abilities to new custom definitions it
   knows.

### 12.5 API surface

- **Picker search.** `POST api/MinecraftEnchantmentRefs/search` with `Picker=true` runs on the
  database:
  - `origin` = `vanilla` | `custom` | all, plus the legacy `category` filter;
  - Missing rows hidden;
  - sorted by display name;
  - search over key, display name, legacy name and category.

  Without `Picker` it is the admin table: every row, sortable, with `isCustom`, `catalogStatus` and
  `lastSeenVersion` in the list DTO.
- **No catalogue lookups when creating.**
  - `POST get-or-create` creates an `Unverified` ref from the normalised key.
  - `EnchantmentDefinitionService` does the same for an unknown `enchantmentNamespaceKey`
    (bare custom ids become `knk:<id>` when the definition is custom).
  - The V1 and lootbox seeds create `Unverified` refs. Ref and definition start at the highest
    level the lootbox seed rolls or gives (at least 1), and the first scan raises them to the vanilla
    maximum.
- **Audit.** `GET api/MinecraftCatalog/audit` adds `enchantmentCount`, `unverifiedEnchantmentCount`
  and `missingEnchantmentsReferenced` (each with the definitions that use it).

### 12.6 Plugin

- `CatalogSource` also returns the enchantments.
  - Vanilla ones come from `RegistryAccess.registryAccess().getRegistry(RegistryKey.ENCHANTMENT)`,
    on the main thread.
  - Custom ones come from `EnchantmentRegistry.getInstance().getAll()`.
- knk-core `CatalogSnapshot`/`CatalogEnchantment` carry schema 2 and the v2 hash.
- The api-client DTO adds `enchantments`.
- Tests pin both v2 vectors.

### 12.7 Web app

- **Picker.** `HybridEnchantmentPicker` becomes `MinecraftEnchantmentPicker` (the field type
  `HybridMinecraftEnchantmentRefPicker` stays):
  - a database search with `Picker: 'true'`;
  - a Custom badge;
  - an all / vanilla / custom filter;
  - the settings JSON `originFilter` sets the initial filter, and `categoryFilter` still works.
- **`PagedEntityTable`** loses the hybrid mode entirely: `isHybridCatalogEntity`, the New badge,
  `persistUnsavedRow`, `handleCreateAndSelect`, the unused `handleSelectAll` and `SearchHybrid`.
- **Clients and types.** The client loses `getHybrid` and `persistFromCatalog`, and the
  `MinecraftHybridEnchantmentOptionDto` type goes.
- **Row keys.** `sessionPinnedRows` keys enchantment refs by id like other entities.
- **Admin page.** The catalogue page shows the enchantment counters of a scan and the
  Missing-but-referenced enchantments.

### 12.8 Upgrade

1. Run the additive migration `MinecraftEnchantmentCatalogFields`.
2. Deploy the plugin and the API together, then scan. An older plugin still sends schema 1,
   which is accepted and leaves enchantments alone.
3. After the scan, check "Needs attention" for Missing enchantments that definitions still use.

### 12.9 Implementation status (merged 2026-10-23)

Live-tested by the developer on 2026-10-23 ("all work") and merged `--no-ff` without PR: knk-web-api `master`
`a1f8838`, knk-web-app `main` `f9ee73c` (after merging KNG-263's category filter into the branch), knk-plugin `main`
`c7806b87`. Feature-branch commits:

| Repo | Commit | What |
|---|---|---|
| knk-web-api | `f265e16` | schema 2 validation and hash; enchantment ingest (§12.3-12.4); migration `MinecraftEnchantmentCatalogFields`; database picker search; audit section (skipped while the migration is pending); static catalogue, hybrid route and the `SearchHybrid` alias removed; seeds without catalogue |
| knk-web-app | `13c31bd` | `MinecraftEnchantmentPicker` (Custom badge, All/Vanilla/Custom, `originFilter` setting, also in the field editor's settings JSON); hybrid mode removed from `PagedEntityTable`, so a pick never creates anything (KNG-243); id-based row keys; Kind/Status columns; enchantment counters and "Missing enchantments still used" on the catalogue page |
| knk-plugin | `ca189a88` | `CatalogEnchantment`, schema 2 `CatalogSnapshot` (v2 hash only), `CustomEnchantmentCatalog` from `EnchantmentRegistry`, `BukkitCatalogSource` (renamed) reads `RegistryKey.ENCHANTMENT`; the translation key comes from the translatable `description()` because `Enchantment.translationKey()` is deprecated for removal in 26.3; `outputJson` adds `enchantmentCount` |

Tests:
- API: 2,991 tests with MySQL; 4 fail identically on `master` (unrelated, [KNG-252](https://linear.app/kngpandi/issue/KNG-252)).
- Web: 168 suites and 1,048 tests (170 and 1,060 after merging main with KNG-263).
- Plugin: knk-core 2,211, knk-api-client 268, knk-paper 1,982 (2,215, 268 and 1,994 after merging main).

The live test covered the scan with enchantments, the custom `knk:<id>` rows, the merge of old rows and the
pickers.
