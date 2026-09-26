# Lootboxes — Implementation Plan

**Status:** Decided — implementation in progress (branch `claude/lootboxes`)
**Last updated:** 2026-09-26
**Linear:** [KNG-19](https://linear.app/kngpandi/issue/KNG-19/lootboxes-per-category-world-lootboxes-with-grade-weighted-rolls-v1)
**Sources:** [DESIGN.md](DESIGN.md); `docs/ACTIVE_SESSIONS.md` (branch convention); `specs/kits/IMPLEMENTATION_PLAN.md`,
`specs/siege-minigame/IMPLEMENTATION_PLAN.md` (phase/test conventions); Linear KNG-15.

**Branches:** one standing branch per repo, `claude/lootboxes`, cut from trunk (web-api `master`, plugin `main`, web-app `main`).
Don't fork per phase (ACTIVE_SESSIONS "Branch convention"). The siege-branch patterns (`EnchantDropPlanner`, `SiegeWorldPresenter`)
are **re-implemented** in `core/lootbox`, not merged in, so this feature doesn't depend on siege reaching trunk.

**Gotchas carried over:**
- New web-api test files go under `tests/` on disk but `Tests/` in the git index: use `git add Tests/...`.
- `./gradlew build` runs `deployToDevServer`. Use `-x deployToDevServer` until you mean to deploy.
- Every new `[FormConfigurableEntity]` needs web-app client + `entityApiMapping.ts` + `objectConfigs.tsx` wiring.
- Migrations are checked by the fresh-MySQL CI workflow (`.github/workflows/migrations.yml`).

| Phase | Scope | Repos | Size | Depends on |
|---|---|---|---|---|
| 0 | Plugin service auth + `BlueprintItemAssembler` extraction | web-api, plugin | M | KNG-15 / currency-payments (coordinate) |
| 1 | Minimal `ItemInstance` (own migration), lootbox schema, config CRUD, roll engine, odds preview, seeds (incl. Flaming Samurai) | web-api | L | — |
| 2 | Runtime API: spawn / claim (+ instance mint, UTC daily cap) / deliver / pending, in-game area endpoints, metrics | web-api | M | 0 (auth), 1 |
| 3 | Plugin runtime: presenter, scheduler, listeners, delivery (instance PDC), `/lootbox`, `/knk lootbox` incl. `area` | plugin | L | 0, 2 |
| 4 | Web-app admin: forms + `/admin/lootboxes` | web-app | M | 1 (config), 2 (log/active) |
| 5 | Lootbox token items: premium/kit/PvP/referral (decided, Q5; after world boxes ship) | all | M | 3 |

Phases 1 and 4 (config only) ship without 0/2/3: admins can author types while nothing spawns yet.

---

## Phase 0 — Prerequisites (shared)

**knk-web-api**
- New `Authentication/ApiKeyAuthenticationHandler.cs`: scheme `ApiKey`, header `X-API-Key`, keys from
  `Security:PluginApiKeys` (array), principal claim `client=paper-plugin`.
- `Program.cs`: `.AddScheme<…>("ApiKey", …)` and policy `PluginService` (ApiKey scheme, `client` claim).
- *Only if currency-payments or the KNG-15 fix hasn't already defined service auth.* If they have, adopt theirs and skip this.
- Tests `tests/.../Authentication/ApiKeyAuthenticationHandlerTests.cs`: missing key, wrong key and good key → 401/401/200 on a probe
  endpoint.

**knk-plugin**
- `knk-paper/src/main/resources/config.yml`: document `api.auth.type: apikey` (the value itself is set per server).
- New `knk-paper/.../item/BlueprintItemAssembler.java`: the enchantment application moved out of
  `commands/ItemBlueprintsDebugCommand.java:233-320`. Input is a blueprint + `List<(definition, level)>` + material. It applies vanilla
  via `addUnsafeEnchantment`, custom via `EnchantmentRepository.applyEnchantment`, reorders lore, skips on
  `!canEnchantItem`/`conflictsWith`, and returns `(ItemStack, skipped[])`. `ItemBlueprintsDebugCommand` calls it.
- Tests `knk-paper/src/test/.../item/BlueprintItemAssemblerTest.java`: vanilla + custom, over-max custom skipped, book blueprint gets
  no enchants, conflicting pair skipped.

**Acceptance:** `/knk itemblueprints give` behaves exactly as before. With `apikey` configured, KNG-15's `/knk kit give` no longer
401s if that fix reuses this scheme.

---

### Phase 0 status — plugin part done 2026-09-26 (knk-plugin `claude/lootboxes`)

Commits `9157242` (extract `item/BlueprintItemAssembler`; `/knk itemblueprints give` uses it, behaviour unchanged),
`fb8f5a8` (kits now grant items with their blueprint default enchantments via `KitGrantPlacer`), `56f73b0` (config.yml
documents `api.auth.type: apikey`), `24ee2b2` (air check without the Paper registry). CI green:
https://github.com/PandiO/knk-plugin/actions/runs/36252001060 (11 new tests). The API-side ApiKey scheme from this phase
was **dropped** (orchestrator decision): service auth is unified by KNG-22 on `Security:PluginApiKey`.

Deviations: vanilla `canEnchantItem`/`conflictsWith` checks are opt-in (`Options.withVanillaRules(true)`, Phase 3 turns
them on; give command and kits keep the old unchecked behaviour); `Options.metaStamp` hook runs last for Phase 3's
`knk_item_instance` + grade tags; kits skip enchantments with non-`minecraft:` keys lacking a base key (logged); catalog
menu previews still unenchanted. Risk: enchanted kit items no longer stack with older unenchanted ones.
Smoke test: `/knk itemblueprints give <id>` unchanged; book blueprint unenchanted; `/kit` items now enchanted.

## Phase 1 — ItemInstance, schema, configuration, roll engine (knk-web-api)

**Step 1: minimal `ItemInstance`** (DESIGN §3.2, D16). It goes first in this phase, with its own migration, rather than in a phase
of its own: `LootboxClaim.ItemInstanceId` needs the table to exist, and on its own it has no runtime behaviour to ship or test
end to end (the only writer is the Phase 2 claim). The separate migration keeps it reviewable and reusable by kits later
without being named after lootboxes.
- `Models/Item/ItemInstance.cs` (`long Id`), `Models/Item/ItemInstanceEnchantment.cs`, `Enums/ItemInstanceOrigin.cs`
  (`Unknown=0, Lootbox=1, Kit=2, Admin=3, Shop=4`).
- `Properties/KnKDbContext.cs`: PK `(ItemInstanceId, EnchantmentDefinitionId)`; indexes `(OwnerUserId)`, `(ItemBlueprintId)`,
  `(Origin, OriginRef)`; **Restrict** to `ItemBlueprint`/`Grade`/`EnchantmentDefinition`, **SetNull** to `User`, **Cascade** from
  an instance to its own enchantment rows. `EnchantmentDefinition.cs:38`: replace the TODO with the `AppliedToInstances` collection.
- Migration `AddItemInstances`.
- `Repositories/ItemInstanceRepository.cs` (+ interface), `Services/ItemInstanceService.cs`: `BuildAsync(blueprint, gradeId,
  ownerUserId, origin, enchantments)` returns an unsaved entity so the caller's transaction owns the save; `GetAsync(id)`.
- `Controllers/ItemInstancesController.cs`: `GET {id}` only; `Dtos/ItemInstanceDtos.cs`.
- Tests `ItemInstanceServiceTests`: builds with enchantments, `OwnerCount`=1, flags false, the Restrict rule refuses a
  blueprint delete while an instance references it.

**Step 2: lootbox schema and configuration**
- `Models/Lootbox/`: `LootboxType.cs`, `LootboxTypeGradeWeight.cs`, `LootboxPoolEntry.cs`, `LootboxEnchantRoll.cs`,
  `LootboxSpecialEntry.cs`, `LootboxSpawnArea.cs`, `LootboxSpawnAreaType.cs`, `LootboxConfiguration.cs`, `LootboxSpawn.cs`,
  `LootboxClaim.cs`, `LootboxSeed.cs` (no claim-enchantment table: the enchantments live on the instance); `Enums/LootboxEnums.cs` (`LootboxSpawnStatus`,
  `LootboxPoolMode`, `LootboxDeliveryMethod`).
- `Properties/KnKDbContext.cs`: DbSets and config:
  - unique `LootboxType.CategoryId`, `LootboxSpawnArea.Name`, `LootboxSpawn.Token`, `LootboxClaim.LootboxSpawnId`,
    `LootboxClaim.ItemInstanceId`, `LootboxClaim.IdempotencyKey`;
  - indexes `(Status, ExpiresAt)`, `(SpawnAreaId, Status)`, `(UserId, ClaimedAt)`;
  - `[ConcurrencyCheck]` on `LootboxSpawn.Status`;
  - **`DeleteBehavior.Restrict`** on every FK to `ItemBlueprint`/`Category`/`Grade`/`EnchantmentDefinition`/`ItemInstance` (vision
    §9.2 no-cascade rule); **SetNull** on `LootboxSpawn.SpawnAreaId` (deleting an area keeps spawn history).
- Migration `AddLootboxes` (+ four `AuditAction` values `LootboxSpawnedByAdmin`, `LootboxGranted`, `LootboxAreaCreated`,
  `LootboxAreaDeleted`, the next free numbers at merge time, 12-15 on `master` today; no column change).
- `Dtos/LootboxDtos.cs`, `Mapping/LootboxMappingProfile.cs`, `Repositories/Lootbox*Repository.cs` (+ interfaces).
- `Services/Lootbox/LootboxRollEngine.cs` (pure: inputs = type config, grades, pool, rolls, specials; injected `ILootRandom`),
  `Services/Lootbox/CryptoLootRandom.cs`, `Services/LootboxTypeService.cs` (CRUD + validation + `GetOddsAsync`),
  `LootboxSpecialEntryService.cs`, `LootboxSpawnAreaService.cs`, `LootboxConfigurationService.cs` (singleton upsert, like
  `SiegeConfigurationService`).
- Controllers: `LootboxTypesController.cs` (CRUD, `search`, `GET {id}/odds`), `LootboxSpecialEntriesController.cs`,
  `LootboxSpawnAreasController.cs`, `LootboxConfigurationController.cs`.
- `Program.cs`: DI, and `LootboxSeed.SeedCanonicalAsync` after `EnchantBookSeed`. Create-only, natural keys. The seed creates:
  - one disabled type per category;
  - the `Lootbox Special` tag;
  - special entries for the DESIGN §1.4 items (minus Donator pickaxe), 0.2% each;
  - the **Flaming Samurai** blueprint (DESIGN §3.5: `&cFlaming Samurai`, `minecraft:netherite_sword`, Weapons, ★5, the two lore
    lines, Sharpness 5 / Fire Aspect 2 / Sweeping Edge 3 / Unbreaking 3 / custom `strength` 2, tag `Lootbox Special`, **no**
    `Legacy v1` tag) and its Weapons-box special entry (`ChancePerMillion=500`, `MinBoxStars=5`, `SortOrder=0`). Missing vanilla
    definitions (`fire_aspect`, `sweeping_edge`) and the `netherite_sword` material ref are created from the `Data/` catalogs the
    way `ItemBlueprintV1Seed` does; a missing `strength` definition is skipped with a warning;
  - Weapons/Armor/Tools enchant rolls (DESIGN §3.5).

**Validation (service):**
- `MinBoxStars ≤ MaxBoxStars` within **1-5** (DESIGN Q3); `ItemStarSpread` 0-9; `ChancePercent` 0-100; `1 ≤ MinLevel ≤ MaxLevel ≤ definition MaxLevel`.
- `ChancePerMillion` 0-1,000,000; `SpawnIntervalSeconds ≥ 60`; `MaxActive ≥ 0`; `MaxClaimsPerPlayerPerDay` null or ≥ 1 (global and
  per type).
- `LootboxSpawnArea.Name` matches `[A-Za-z0-9_-]{1,32}` and is unique (409 `NameTaken`).
- Duplicate category → 409. Deleting an `ItemBlueprint` referenced by a pool/special entry or an `ItemInstance` → 409 (add the guard in
  `ItemBlueprintService`).

**Tests** (`tests/knkwebapi_v2.Tests/Services/`)
- `LootboxRollEngineTests`:
  - box-grade weights (defaults from `GradeDefaults`, then overrides);
  - window clamping at ★1; empty-window fallback down, then up;
  - two-stage distribution with a scripted RNG;
  - pool Include/Exclude/`GradeIdOverride`, `Lootbox Special` tag excluded;
  - specials first-hit order and `MinBoxStars`;
  - enchant clamp per grade: cap 0 drops the roll, ★6+ capped at definition max, custom only at definition max;
  - merge with defaults; book and stackable blueprints get no rolls.
- `LootboxTypeServiceTests`: validation, unique category, odds endpoint numbers match the engine (same code path).
- `LootboxSeedTests`: idempotent, one type per category, specials only when blueprints exist, no cascade; Flaming Samurai created
  once with its five enchantments, tagged `Lootbox Special` but not `Legacy v1`, its special entry at 500 per million.

**Acceptance:** both migrations pass fresh-DB CI. `GET /api/LootboxTypes/{weapons}/odds?boxStars=5` on the dev DB shows ★3/★4/★5 at
50/31.25/18.75 % with default grades, and specials Flaming Samurai 0.05%, Skull splitter 0.2%, Lavonian Bow 0.2%. The Flaming
Samurai shows up in the web app's ItemBlueprint list. Suite = baseline + new tests, same 5 known failures.

---

### Phase 1 status — done 2026-09-26 (knk-web-api `claude/lootboxes`)

Commits `9f013af` (minimal `ItemInstance` + `ItemInstanceEnchantment`, migration `AddItemInstances`,
`ItemInstanceService.BuildAsync` returns an unsaved row for the caller's transaction, `GET api/ItemInstances/{id}`, blueprint
delete refused 409 when instances exist), `30b8b12` (10 lootbox tables, migration `AddLootboxes`, `AuditAction`
`LootboxSpawnedByAdmin = 13` / `LootboxGranted = 14`), `ae9e291` (`LootboxRollEngine`, `ILootRandom`/`CryptoLootRandom`,
`LootboxRollInputBuilder`, 30 engine tests incl. a 200k-roll statistical check), `321df07` (DTOs, services, 4 controllers,
odds preview, `LootboxSeed`). Tests 693 (688 pass, the 5 baseline failures; 58 new). Migrations CI green:
https://github.com/PandiO/knk-web-api/actions/runs/36254107623; on local MySQL 8.0 both migrations up/down/up, seed idempotent,
Weapons ★5 odds ★3/★4/★5 = 50/31.25/18.75 %, Flaming Samurai 0.05 %, Skull splitter / Lavonian Bow 0.2 % own chance.

Seed: 7 disabled types (one per category), 13 enchant rolls (Weapons/Armor/Tools), `Lootbox Special` tag, Flaming Samurai
blueprint, 10 special entries (Flaming Samurai 500/M; v1 one-offs minus the Donator pickaxe 2000/M, each in its category's
box), settings row. Deviations: admin endpoints use `[RequirePermission(StaffPermissions.ManageLootboxes)]` (new node
`knk.admin.lootbox.manage`); join entities are `[FormConfigurableEntity]` like `KitContent`; saving a special entry tags its
blueprint; deleting a referenced type → 409 `InUse` (disable instead); odds show specials' own and first-hit chance;
books/stackables keep blueprint defaults without rolled enchants; `LootboxConfiguration.Enabled` defaults true (all types
disabled). Developer to-do: apply `AddItemInstances` + `AddLootboxes` (seed runs on startup); grant
`knk.admin.lootbox.manage` to web admins.

## Phase 2 — Runtime API (knk-web-api)

**New/changed**
- `Services/LootboxRuntimeService.cs`:
  - `GetRuntimeConfigAsync` and `GetActiveAsync`, both with the lazy expiry sweep;
  - `SpawnAsync` (caps, then type/grade roll);
  - `AdminSpawnAsync` + audit `LootboxSpawnedByAdmin`;
  - `DespawnAsync`;
  - `ClaimAsync` (transaction per DESIGN §3.3: idempotent replay, 409/429, `DbUpdateConcurrencyException` → `AlreadyClaimed`;
    mints the `ItemInstance` + enchantment rows through `ItemInstanceService.BuildAsync` for non-stackable items, then fills
    `OriginRef` with the claim id in the same transaction);
  - the **daily cap per UTC calendar day** (DESIGN §3.3 step 3): global count across all types, then the per-type count; the day
    boundary comes from an injected `TimeProvider` so tests can pin it;
  - `MarkDeliveredAsync`, `GetPendingAsync`, `AdminGiveAsync` (roll + mint without a spawn, `LootboxSpawnId=null`, audit
    `LootboxGranted`, not counted against the cap).
- `Services/LootboxSpawnAreaService.cs` (from Phase 1) gains `CreateInGameAsync` (name/region uniqueness → 409 `NameTaken` /
  `RegionInUse`, enabled with default limits, audit `LootboxAreaCreated`) and `DeleteInGameAsync` (active spawns → Removed, row
  deleted, audit `LootboxAreaDeleted`, returns the `WgRegionId`).
- `Controllers/LootboxSpawnsController.cs` (`runtime-config`, `active`, `POST`, `admin`, `{id}/despawn`, `{id}/claim`) and
  `Controllers/LootboxClaimsController.cs` (`{id}/delivered`, `pending`, `search`, `admin-give`), plus `in-game` and
  `{id}/in-game-delete` on `LootboxSpawnAreasController`. Runtime and in-game actions are `[Authorize(Policy="PluginService")]`.
  `runtime-config` returns all areas with their `enabled` flag.
- `Services/Lootbox/LootboxMetrics.cs`: `Meter("Knk.Lootboxes")` counters/histogram. Register the meter in `Program.cs`'s
  `WithMetrics(m => m.AddMeter("Knk.Lootboxes"))`.

**Tests**
- `LootboxRuntimeServiceTests`:
  - area/global caps; disabled config → 409;
  - claim happy path writes the claim, one `ItemInstance` (Origin=Lootbox, `OriginRef` = claim id, owner = claimer) and its
    enchantment rows; a stackable claim has `ItemInstanceId=null`;
  - same idempotency key → `replay=true`, identical payload (same `itemInstanceId`), no second roll or instance (RNG mock called once);
  - second user → 409 `AlreadyClaimed`; expired → 409; token mismatch → 409;
  - daily cap: the 11th claim on one UTC day → 429 `scope=Global`; a claim at 23:59:59 UTC counts for that day and 00:00:00 UTC
    starts a fresh count; a per-type limit of 2 → the 3rd box of that type is 429 `scope=Type` while other types still open;
    admin gives are not counted; `resetsAt` = next 00:00 UTC;
  - in-game area create: duplicate name → 409 `NameTaken`, region already used by another area → 409 `RegionInUse`; delete
    removes the row, marks active spawns Removed and keeps their `LootboxSpawn` rows with `SpawnAreaId=null`;
  - pending lists only undelivered claims older than 30 s; delivered is idempotent.
- Concurrency: InMemory doesn't enforce unique indexes. Test the `[ConcurrencyCheck]` path with two contexts on the same InMemory
  store, and **verify the unique index manually on local MySQL 8** (two parallel `curl` claims → one 200, one 409). Record the result
  in this plan.
- `Api/LootboxSpawnsControllerAuthTests` (WebApplicationFactory): runtime endpoints return 401 without the key.

**Acceptance:** a full claim round-trip via Swagger with the API key, and `GET /api/ItemInstances/{itemInstanceId}` returns the
minted instance with the same enchantments as the claim result. Metrics are visible through the OTLP exporter when enabled.

---

### Phase 2 status — done 2026-09-26 (knk-web-api `claude/lootboxes`)

`a0da5c2` merges KNG-22 `7d441be`; `46b1692` runtime API: runtime-config, active, spawn (caps → type/box-grade roll), admin
spawn, despawn, claim (rolls via `BuildRollInputAsync`, mints `ItemInstance` in the same transaction), admin-give,
delivered, pending, claim by id, drop-log search, lazy expiry sweep, in-game area create/delete, `Knk.Lootboxes` metrics.
Daily cap 10/player/UTC day (global then per type; admin gives excluded). Gates: `[RequirePluginService]` runtime-config,
spawn, admin spawn, claim, delivered, pending, admin-give, in-game, in-game-delete; `[RequireServiceOrPermission(
knk.admin.lootbox.manage)]` active, despawn, `LootboxTypes/{id}/odds`; web-only claim by id + search. Audit: area
create/delete and admin spawns → `LootboxSpawnedByAdmin` (13) with `Details.event` = Spawned|AreaCreated|AreaDeleted;
`LootboxGranted` (14) = a player received an item. Tests 823 (818 pass, 5 baseline; 44 new). Local MySQL 8: 2–5 concurrent
claimers → exactly one 200; held-row `[ConcurrencyCheck]` → 409, no rows; unique index 1062; same key ×5 → 1 fresh + 4
replays; 12 boxes vs cap 10 → ten 200 + two 429; expiry, area create/delete, admin give audit, delivered idempotent.
Deviations: actor from `X-Acting-User-Id` (never the body); extra 409 codes `Removed`, `Disabled`, `Frozen`, `UserInactive`,
`EmptyPool`, `IdempotencyKeyReused`, `NoBoxGrade`, `WrongUser`; `in-game-delete` returns `removedSpawnIds`; admin-give takes
an optional `idempotencyKey`, admin spawn an optional `lifetimeMinutes` (30); stored times truncated to seconds (MySQL
datetime rounding across midnight). Known: seeded Weapons rolls could put Sharpness on a bow (addressed in Phase 3);
claims briefly lock the player's `users` row; web-app area delete not audited.

## Phase 3 — Plugin runtime (knk-plugin)

**knk-core** (`core/lootbox/`, Bukkit-free)
- `KnkLootboxType`, `KnkLootboxSpawn`, `KnkLootboxArea`, `KnkLootboxRuntimeConfig`, `KnkLootboxClaimResult` records.
- Ports `ports/api/LootboxesQueryApi`, `LootboxesCommandApi` (claim, deliver, spawn/despawn, admin give, and the in-game area
  create/delete). `KnkLootboxClaimResult` carries `itemInstanceId` (nullable); `KnkLootboxArea` carries `enabled`.
- `LootboxSpawnPlanner`, `ActiveLootboxCache` (chunk-keyed), `ClaimGuard`.
- Tests: `LootboxSpawnPlannerTest` (interval, min players, cap, chance, uniform point in bounds), `ActiveLootboxCacheTest`,
  `ClaimGuardTest`.

**knk-api-client**
- `dto/LootboxDtos.java`, `mapper/LootboxMapper.java`, `impl/LootboxesQueryApiImpl.java`, `impl/LootboxesCommandApiImpl.java`.
- Tests `LootboxMapperTest`.

**knk-paper**
- `lootbox/LootboxPresenter.java` (`ItemDisplay` + `Interaction` + `TextDisplay`, `setPersistent(false)`, PDC
  `knightsandkings:knk_lootbox`, particles/sound every 4 s within 15 blocks).
- `lootbox/LootboxSpawnScheduler.java` (async `getChunkAtAsync(x, z, false)`, surface rules, WG containment via
  `WorldGuardRegionLookup`, min player distance).
- `mapper/ItemInstanceTag.java` (new, like `ItemGradeTag`): PDC `knightsandkings:knk_item_instance` (LONG), `stamp`/`read`.
- `lootbox/LootboxDelivery.java` (uses `BlueprintItemAssembler` + `ItemGradeTag`, stamps `ItemInstanceTag` when the claim has an
  `itemInstanceId`, owner-locked drop fallback, ACK).
- `lootbox/LootboxAnnouncer.java` (Adventure `showItem` hover, templates from runtime config).
- Listeners: `listeners/LootboxInteractListener.java`, `LootboxChunkListener.java` (`ChunkLoadEvent`, `EntitiesLoadEvent` orphan
  purge), `LootboxJoinListener.java` (pending delivery with an instance-id dedupe scan of inventory + ender chest; stackables
  are re-delivered without a scan).
- `commands/LootboxCommand.java` (`/lootbox`, `/lb`, **player-only**: help, `odds`) + `plugin.yml` command. Wire it in
  `KnKPlugin.java` via `registerSimpleCommand`, plus a `DataAccessFactory` entry.
- `commands/LootboxAdminCommand.java` (`/knk lootbox`), registered in `KnkAdminCommand` through `CommandRegistry` with a
  `CommandMetadata`: `spawn`, `despawn`, `list`, `tp`, `give`, `reload`, and `area create|list|info|delete` (DESIGN §3.4).
  `plugin.yml` declares the `knk.lootbox.*` nodes, including `knk.lootbox.admin.area`.
- `integration/WorldGuardIntegration.java`: new public `createRegionFromSelection(Region selection, String id, int priority)`,
  moved from `tasks/WgRegionIdTaskHandler.java:583-606` (which now calls it), plus `createFullHeightRegion(...)` (stretches the
  region to the world's min/max build height) and `removeRegion(id, world)` for the area command's rollback and `delete`.
- `config.yml` `lootboxes:` section (DESIGN §3.4).
- Tests, in the existing Bukkit-mock style of knk-paper tests:
  - `LootboxDeliveryTest`: full inventory → refuse; leftovers → owned drop; instance id stamped on a sword, no tag on a food stack;
  - `ItemInstanceTagTest`: stamp/read round trip, missing tag → empty;
  - `LootboxCommandTest` / `LootboxAdminCommandTest`: permission gating, arg parsing, admin subcommands absent from `/lootbox`;
  - `LootboxAreaCommandTest`: invalid name, no selection, existing `lootbox_<slug>` region → refused without an API call; API 409
    → the new region is removed again; `delete` removes only `lootbox_`-prefixed regions and only after the confirm repeat;
  - `LootboxInteractListenerTest` (staff mode, distance, guard).

**Web-api follow-up in the same phase:** seed `knk.lootbox.open` and `knk.lootbox.odds` grants on the Default `PermissionGroup`
(create-only). Admin nodes are not seeded.

**Acceptance (live, developer checklist):**
1. Select an area around spawn with WorldEdit and run `/knk lootbox area create spawn` → WG region `lootbox_spawn` exists (full
   height) and the area appears in the web app. Set `MinOnlinePlayers=1` and interval 60 s there, enable the Weapons type → a box
   appears with a label.
2. Two accounts click at once → one item, one "Someone else got there first".
3. Kill the server right after a click (before the ACK) → on rejoin the item arrives once, not twice.
4. Full inventory → refused, box stays.
5. Reload chunks and relog repeatedly → no new boxes beyond the cap, and no re-roll.
6. A ★5+/special drop broadcasts once with a hoverable item.
7. Box expires after `LifetimeMinutes`.
8. `/knk lootbox give` writes an audit row.
9. A delivered sword carries `knightsandkings:knk_item_instance`; `GET /api/ItemInstances/{id}` shows the same enchantments and the
   claimer as owner. A food stack from a Food box stacks with ordinary food of the same blueprint.
10. With the cap lowered to 2 in the web app, the 3rd box that UTC day is refused with the "resets at 00:00 UTC" message.
11. `/knk lootbox area info spawn` and `list` show the area; `/knk lootbox area delete spawn` (repeated to confirm) removes the
    row, its active boxes and the `lootbox_spawn` region.

---

### Phase 3 status — done 2026-09-26 (knk-plugin + knk-web-api `claude/lootboxes`)

knk-web-api `f21799c`: **enchant applicability fix** — `Services/Lootbox/VanillaEnchantmentRules.cs` (which items each vanilla
enchantment fits + mutual exclusions); rolled vanilla enchants that don't fit or conflict are skipped, custom/defaults
never filtered; odds preview adds `applicableItemCount` + `landPercent` per roll (checked against a 200k-roll simulation).
`81f8071`: seed grants `knk.lootbox.open` + `knk.lootbox.odds` to the Default group if missing. knk-plugin: `fb2496f` (trunk
merge), `da13ca5` (KNG-22 `be0cfc3`), `3bc60a0` (knk-core `core/lootbox`: records, `LootboxRejectedException`,
`LootboxSpawnPlanner`, `ActiveLootboxCache`, `ClaimGuard` with key `{token}:{userId}`, ports; api-client impls with service
key + `X-Acting-User-Id`), `e6cf0bd` (`WorldGuardIntegration.createRegionFromSelection`/`createFullHeightRegion`/
`addRegion`/`removeRegion`), `af40c7b` (knk-paper `LootboxPresenter`, `LootboxRuntime`, `LootboxSpawnScheduler`,
`LootboxRegions`, `LootboxDelivery`, `LootboxAnnouncer`, `ItemInstanceTag`, interact/chunk/join listeners, `/lootbox` | `/lb`,
`/knk lootbox`, plugin.yml nodes, `lootboxes:` config). API 850 (845 pass, 5 baseline); plugin CI green
https://github.com/PandiO/knk-plugin/actions/runs/36262963984; 35 new core/api-client tests pass locally.
Deviations: delivery in two passes (blueprint defaults as authored, rolled enchants with vanilla rules; any skip logged +
written to the claim's `deliveryNote`); conservative table (Fire Aspect on swords/maces only); `LootboxRuntime` refreshes on
its own timer; `/knk lootbox` actions check `knk.lootbox.admin.<action>` via `KnkPermissible`; left-click also opens; new key
`lootboxes.server-id`. Developer to-do: API key on both sides; restart the API (seed adds Default grants); run the 11-step
in-game checklist above. Known: Paper-specific parts (display entities, interpolation, `getChunkAtAsync`, WE selection)
untested live; first click can be refused until the permission cache warms; stackables can double-deliver after a crash
(accepted); join redelivery only picks up claims older than 30 s.

## Phase 4 — Web-app admin (knk-web-app)

- `src/apiClients/`: `lootboxTypeClient.ts`, `lootboxSpecialEntryClient.ts`, `lootboxSpawnAreaClient.ts`,
  `lootboxConfigurationClient.ts`, `lootboxClaimClient.ts`, `lootboxSpawnClient.ts` (admin reads/despawn only).
- `src/types/dtos/lootbox.ts`; register in `entityApiMapping.ts` and `objectConfigs.tsx`.
- FormConfigurations authored in FormConfigBuilder on the dev DB, recorded in a new `docs/specs/lootboxes/PHASE_4_FORMCONFIGS.md`
  (same as kits/siege Phase 3): `LootboxType` (basics → box grade weights → pool entries → enchant rolls), `LootboxSpecialEntry`,
  `LootboxSpawnArea` (WgRegionId picker + WorldTask; areas created in game appear here and are tuned with the same form).
- `src/pages/admin/LootboxesPage.tsx` + route `/admin/lootboxes` + nav entry: tabs Settings / Types / Odds / Active boxes / Drop log.
- Tests `src/pages/admin/__tests__/LootboxesPage.test.tsx` (renders the odds table from a mocked response, despawn calls the client,
  drop-log paging).

**Acceptance:** an admin can enable a category box, tune weights, see the odds change, define an area, watch active boxes and page the
drop log without touching the DB. `tsc` is clean; test failures don't exceed the known baseline.

---

## Phase 5 — Lootbox token items (decided, Q5)

- web-api: `LootboxToken` (`Token`, `LootboxTypeId`, `BoxGradeId`, `IssuedToUserId?`, `IssuedReason`, `RedeemedClaimId?`).
  `POST LootboxTokens/issue` (PluginService/admin) and `POST LootboxTokens/{token}/redeem` (same roll engine and claim table;
  `LootboxClaim.LootboxSpawnId` null, `LootboxTokenId` set).
- plugin: a token item (PDC `knightsandkings:knk_lootbox_token`, never matched by name, which fixes the v1 rename exploit).
  Right-click to redeem, and the item is consumed only after a 200. Issue hooks: kit contents, premium tier grants (user-features),
  PvP kill drops (future), referral (future).
- A redeem is a claim like any other: same UTC daily cap, same `ItemInstance` mint.
- Tests: redeem twice → second 409; a renamed non-token item does nothing.

---

## Cross-feature dependencies

- **KNG-15** (plugin sends no bearer token → 401 on Kits give): same root cause as Phase 0. Fix once, and share the scheme.
- **currency-payments** (`docs/specs/currency-payments/`): its service-auth/idempotency conventions supersede Phase 0 and the claim
  idempotency key format if they land first. Lootboxes grant no currency now. Any later coin/gem reward uses
  `UserService.AdjustBalancesAsync` plus that ledger.
- **KNG-6** grades: boxes are ★1-5 only (DESIGN Q3, D5); allowing ★6+ later needs grades 6-10 renamed and stocked first.
- **KNG-12** (no WG flags on town/district regions): affects PvP safety around boxes in towns.
- **KNG-14** (gameplay statistics): add a `LootboxesOpened` counter fed from `LootboxClaim` when that lands.
- **Kits**: can adopt `BlueprintItemAssembler` to finally apply blueprint default enchantments (open owner item in ACTIVE_SESSIONS),
  and later mint `ItemInstance`s with `Origin=Kit`.
- **ItemInstance follow-ups** (vision §9.1, not scheduled): ownership transfer / `OwnerCount`, Soulbound/Ghosted semantics and
  rolls, cascade tooling, instances for other item sources.
- **Siege**: only the pattern is reused. Nothing depends on `claude/siege-minigame` merging.
- **domain-discovery** (`docs/specs/domain-discovery/`): spawn areas can reference the same `Domain` regions. No coupling.
