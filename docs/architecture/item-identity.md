# Item identity (knk-web-api and knk-plugin)

**Status:** Current · **Last updated:** 2026-11-19 (first version, item identity #141, docs PandiO/knk-workspace#796)
**Checked against:** knk-web-api `next` `7d213fd6` (PR PandiO/knk-web-api#51), knk-plugin `next` `2ef256e7` (PR
PandiO/knk-plugin#89). Not released; the plugin part is off by default.
**Related:** [production DESIGN § 8](../specs/production-storage-transport/DESIGN.md#8-item-identity-note-9) (rules and
the retag rule), [admin guide](../guides/admin/item-identity-admin-guide.md), [plugin configuration § 4.30](../guides/admin/plugin-configuration.md#430-items),
[smoke test § 0](../guides/production-storage-transport-smoke-test.md#0-item-identity-141-api-and-plugin-tier3),
[item render pipeline](item-render-pipeline.md) (how `BlueprintItemAssembler` builds items)

Every item a player obtains resolves to one `ItemBlueprint`, so later production phases can count stock per blueprint.
The API owns the material → blueprint match and the counts; the plugin owns the resolver, the blueprint tag and the
conversion hooks.

## 1. Ownership

| Part | Repo | Where |
|---|---|---|
| `ItemBlueprint.VanillaMaterialMatchRefId` (unique), shadow generation, moving a match, the report, the count table | knk-web-api | `Models/Item/ItemBlueprint.cs`, `Models/Item/ItemConversionStat.cs`, `Services/ItemIdentity/`, `Controllers/ItemIdentityController.cs`, `Dtos/ItemIdentityDtos.cs` |
| Shadow generation after a catalogue scan | knk-web-api | `Services/MinecraftCatalog/MinecraftCatalogScanService.cs` (`GenerateVanillaShadowsAsync`) |
| Resolver, retag rule, material map, conversion log (Bukkit-free) | knk-plugin `knk-core` | `core/items/identity/` |
| API port and client | knk-plugin `knk-core`, `knk-api-client` | `core/ports/api/ItemIdentityApi.java`, `api/impl/ItemIdentityApiImpl.java` |
| Game server service, hooks, settings, tag | knk-plugin `knk-paper` | `paper/items/identity/` (`ItemIdentityService`, `ItemConversionListener`, `ItemIdentityFactsReader`, `ItemIdentitySettings`), `paper/mapper/BlueprintTag.java`, `paper/item/BlueprintItemAssembler.java` |

## 2. Data

1. `item_blueprints.VanillaMaterialMatchRefId` (nullable int, FK to `minecraftmaterialrefs`, `ON DELETE RESTRICT`,
   unique index `IX_item_blueprints_VanillaMaterialMatchRefId`): at most one blueprint per material and one material
   per blueprint. Many blueprints may have none.
2. `item_conversion_stats` (`Id`, `Day` UTC date, `Source` ≤ 32, `Outcome` ≤ 32, `MaterialKey` ≤ 191, `Count`
   bigint), unique on (`Day`, `Source`, `Outcome`, `MaterialKey`). An aggregate counter: no form, display or dashboard
   type.
3. Migration `20261119090845_AddItemIdentity`: additive only; `Down` drops both. Covered by `AddItemIdentityTests`
   and `ItemIdentityMySqlTests`.
4. The match is **not** in the item blueprint create and update DTOs (AutoMapper ignores it), so a form can't clear it.
   Only `PUT api/ItemIdentity/matches/{id}` and shadow generation set it. Read DTOs carry
   `vanillaMaterialMatchRefId` and the `vanillaMaterialMatch` navigation DTO.

## 3. API contract (`api/ItemIdentity`)

| Method and route | Access | Body / query | Answer |
|---|---|---|---|
| `GET material-map` | Any signed-in caller or the plugin key | — | `ItemIdentityMapDto`: `generatedAt`, `entries[]` of `{ materialKey, blueprintId, shadow }`, sorted by key; `shadow` = the blueprint is in the top-level "Uncurated" category |
| `GET report` | `knk.admin.content` | `days` (clamped 1–90, default 7) | `ItemIdentityReportDto`: `obtainableMaterials`, `matchedMaterials`, `shadowMatches`, `curatedMatches`, `uncuratedCategoryId`, `unmatchedMaterials[]` `{ id, namespaceKey, displayName }`, `days`, `conversions[]` per source and outcome, `topUnresolved[]` (50 largest `unresolved*` material/outcome pairs, `source: "all"`) |
| `POST shadows/generate` | Plugin key or `knk.admin.content` | — | `ItemShadowGenerationResultDto`: `obtainableMaterials`, `alreadyMatched`, `created`, `uncuratedCategoryId`, `categoryCreated`. 409 `ConcurrentGeneration` when another run inserted the same shadow (unique index) |
| `PUT matches/{materialRefId}` | Plugin key or `knk.admin.content` | `{ "itemBlueprintId": int \| null }` | `ItemIdentityMatchResultDto`: `materialRefId`, `materialKey`, `previousBlueprintId`, `blueprintId`, `releasedMaterialRefId` (the material the new blueprint matched before, now unmatched). 404 for an unknown material or blueprint |
| `POST conversion-counts` | Plugin key only | `{ day?: UTC date (null = today, at most 90 days back, not in the future), counts[]: { source, outcome, materialKey, count } }`, ≤ 5,000 lines; `source` and `outcome` match `^[a-z][a-z0-9_]{0,31}$`; `materialKey` normalised to `minecraft:…`; `count` ≥ 0 | `{ applied: <distinct lines> }`, added to that day's rows in one transaction; 400 with the reason otherwise |

Access is pinned in `ReadAccessRulesTests`, `EndpointAccessRulesTests` and `ItemIdentityControllerAccessTests`.

**Obtainable** (`VanillaShadowBlueprints.IsObtainable`): `IsItem == true`, catalogue status `Active`, not in the fixed
`NotObtainable` set (air variants, barrier, bedrock, light, command and structure blocks, debug items, spawners, vault,
farmland, dirt path, frogspawn and similar) and not a `*_spawn_egg`.

**Shadow generation** (`VanillaShadowBlueprints.GenerateAsync`): one transaction; creates the "Uncurated" category if
needed and one blueprint per obtainable unmatched material (name from the display name, empty display name and lore,
`DefaultQuantity` 1, `MaxStackSize` from the catalogue or 64, icon and match = the material). It only adds. It runs after
every completed catalogue scan; a failure there is logged and does not fail the scan.

**Moving a match** (`ItemIdentityService.SetMatchAsync`): in one transaction, clears the old holder and saves before it
sets the new one, so the unique index never sees two holders.

## 4. Resolver (`ItemIdentityResolver.resolve`)

The single resolver later phases use: on the game server call `ItemIdentityService.resolve(ItemStack)`
(`KnKPlugin.getItemIdentityService()`, null while `items.identity.enabled` is off); it never changes the item. Input is
`ItemIdentityFacts` (read by `ItemIdentityFactsReader`): material key, instance tag, blueprint tag, custom name, lore,
other persistent data, and whether the item is plain apart from a blueprint tag.

1. Instance tag → `INSTANCE` (blueprint id from the blueprint tag when present).
2. Blueprint tag → `BLUEPRINT_TAG`, unless the item is plain apart from the tag: then `VANILLA_MATCH` with the
   material's match (or the tag's id when the material has none) and `stripBlueprintTag = true` (the retag rule).
3. No tag: custom name → `UNRESOLVED(CUSTOM_NAME)`, lore → `CUSTOM_LORE`, other persistent data → `OTHER_DATA`;
   otherwise the material's match → `VANILLA_MATCH`, or `UNRESOLVED(NO_MATCH)`. Damage, enchantments and other vanilla
   state don't stop a vanilla match.
4. Air or no material → `UNRESOLVED(NO_MATERIAL)`.

`ItemIdentityResolution.outcome()` gives the count outcome: `instance_tag`, `blueprint_tag`, `vanilla_match`,
`normalized` (a stale tag was removed) or `unresolved_<reason>`.

**Retag rule:** the plain vanilla item is canonical and never tagged. `BlueprintTag.stampIfEnabled` (called by
`BlueprintItemAssembler`) stamps `knk_blueprint` only when stamping is on and the built item is not plain
(`BlueprintTag.isPlainWithoutBlueprintTag`: the item without the tag `isSimilar` to `new ItemStack(type)`). See
[DESIGN § 8](../specs/production-storage-transport/DESIGN.md#8-item-identity-note-9).

## 5. Game server

1. `ItemIdentitySettings` reads `items.identity` (both switches `false` by default; `convert-on-obtain` counts only with
   `enabled`; minutes at least 1). Restart to apply. Keys: [plugin configuration § 4.30](../guides/admin/plugin-configuration.md#430-items).
2. `ItemIdentityService.start()` turns stamping on and schedules two async timers: the map refresh (immediately, then
   every `map-refresh-minutes`; a failure keeps the previous map) and the report (every `report-interval-minutes`:
   drain the log, write a summary line, `POST conversion-counts`; on failure the counts go back into the log). `stop()`
   sends what is left (5 s wait) and turns stamping off.
3. `ItemConversionListener` is registered only with `convert-on-obtain`. Hooks: `EntityPickupItemEvent` (players),
   `BlockDropItemEvent`, `EntityDeathEvent` drops, `PlayerFishEvent`, `PrepareItemCraftEvent` (normalises the shown
   result without counting) and `CraftItemEvent` (counts), `PlayerPurchaseEvent` (villager and wandering trader trades,
   counted), `InventoryOpenEvent` (the first open of a container block since start; remembered in memory only, up to
   50,000 containers, then cleared). Each handler reads only the cached map, never the API.
4. `ItemIdentityService.convert` resolves, removes a stale tag in place, and counts (only once the map has been loaded,
   so a cold start doesn't count everything as `no_match`). Unresolved items are logged once per reason and material
   (up to 10,000 keys).

## 6. Tests

1. knk-web-api: `Services/ItemIdentity/ItemIdentityServiceTests`, `VanillaShadowBlueprintsTests`,
   `VanillaMatchMergeTests`, `MySql/ItemIdentityMySqlTests`, `Api/ItemIdentityControllerAccessTests`,
   `MinecraftCatalogScanServiceTests` (shadows after a scan), `AddItemIdentityTests`, the pinned access tests.
2. knk-plugin: `knk-core` `ItemIdentityResolverTest`, `ItemConversionLogTest`; `knk-api-client`
   `ItemIdentityApiImplTest`; `knk-paper` `ItemIdentityServiceTest`, `ItemConversionListenerTest`,
   `BlueprintItemAssemblerIdentityTest`, `BlueprintTagTest`.
3. Manual: [smoke test § 0](../guides/production-storage-transport-smoke-test.md#0-item-identity-141-api-and-plugin-tier3),
   each step tagged with the tests above.

## 7. Limitations and follow-ups

1. Items handed out before `items.identity.enabled` was on carry no blueprint tag; customised ones read as
   `unresolved_custom_name` and don't stack with new tagged copies ([#791](https://github.com/PandiO/knk-workspace/issues/791)).
2. No web app page for the report, unmatched materials or moving a match; use the API
   ([#792](https://github.com/PandiO/knk-workspace/issues/792)).
3. Existing curated blueprints are not matched to their materials automatically; generation only fills gaps with
   shadows. Moving a match is a staff action.
4. The resolver identifies items; refusing unresolvable items at a deposit belongs to the stock phases (P1 on).
5. The `container_open` hook remembers opened containers only until restart, so a container is scanned again once
   after each restart (harmless: plain items are not changed).
