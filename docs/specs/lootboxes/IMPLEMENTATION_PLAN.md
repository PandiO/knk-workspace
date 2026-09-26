# Lootboxes — Implementation Plan

**Status:** Draft — awaiting developer review (open questions in DESIGN.md §5)
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
| 1 | Schema, config CRUD, roll engine, odds preview, seeds | web-api | L | — |
| 2 | Runtime API: spawn / claim / deliver / pending, metrics | web-api | M | 0 (auth), 1 |
| 3 | Plugin runtime: presenter, scheduler, listeners, delivery, `/lootbox` | plugin | L | 0, 2 |
| 4 | Web-app admin: forms + `/admin/lootboxes` | web-app | M | 1 (config), 2 (log/active) |
| 5 | (optional, Q5) Lootbox token items: premium/kit/PvP/referral | all | M | 3 |

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

## Phase 1 — Schema, configuration, roll engine (knk-web-api)

**New files**
- `Models/Lootbox/`: `LootboxType.cs`, `LootboxTypeGradeWeight.cs`, `LootboxPoolEntry.cs`, `LootboxEnchantRoll.cs`,
  `LootboxSpecialEntry.cs`, `LootboxSpawnArea.cs`, `LootboxSpawnAreaType.cs`, `LootboxConfiguration.cs`, `LootboxSpawn.cs`,
  `LootboxClaim.cs`, `LootboxClaimEnchantment.cs`, `LootboxSeed.cs`; `Enums/LootboxEnums.cs` (`LootboxSpawnStatus`,
  `LootboxPoolMode`, `LootboxDeliveryMethod`).
- `Properties/KnKDbContext.cs`: DbSets and config:
  - unique `LootboxType.CategoryId`, `LootboxSpawn.Token`, `LootboxClaim.LootboxSpawnId`, `LootboxClaim.IdempotencyKey`;
  - indexes `(Status, ExpiresAt)`, `(SpawnAreaId, Status)`, `(UserId, ClaimedAt)`;
  - `[ConcurrencyCheck]` on `LootboxSpawn.Status`;
  - **`DeleteBehavior.Restrict`** on every FK to `ItemBlueprint`/`Category`/`Grade`/`EnchantmentDefinition` (vision §9.2 no-cascade rule).
- Migration `AddLootboxes` (+ `AuditAction` 12/13 enum values; no column change).
- `Dtos/LootboxDtos.cs`, `Mapping/LootboxMappingProfile.cs`, `Repositories/Lootbox*Repository.cs` (+ interfaces).
- `Services/Lootbox/LootboxRollEngine.cs` (pure: inputs = type config, grades, pool, rolls, specials; injected `ILootRandom`),
  `Services/Lootbox/CryptoLootRandom.cs`, `Services/LootboxTypeService.cs` (CRUD + validation + `GetOddsAsync`),
  `LootboxSpecialEntryService.cs`, `LootboxSpawnAreaService.cs`, `LootboxConfigurationService.cs` (singleton upsert, like
  `SiegeConfigurationService`).
- Controllers: `LootboxTypesController.cs` (CRUD, `search`, `GET {id}/odds`), `LootboxSpecialEntriesController.cs`,
  `LootboxSpawnAreasController.cs`, `LootboxConfigurationController.cs`.
- `Program.cs`: DI, and `LootboxSeed.SeedCanonicalAsync` after `EnchantBookSeed`. The seed creates one disabled type per category,
  the `Lootbox Special` tag, special entries for the DESIGN §1.4 items (minus Donator pickaxe), and Weapons/Armor/Tools enchant rolls
  (DESIGN §3.5). Create-only, natural keys.

**Validation (service):**
- `MinBoxStars ≤ MaxBoxStars` within 1-10; `ItemStarSpread` 0-9; `ChancePercent` 0-100; `1 ≤ MinLevel ≤ MaxLevel ≤ definition MaxLevel`.
- `ChancePerMillion` 0-1,000,000; `SpawnIntervalSeconds ≥ 60`; `MaxActive ≥ 0`.
- Duplicate category → 409. Deleting an `ItemBlueprint` referenced by a pool/special entry → 409 (add the guard in `ItemBlueprintService`).

**Tests** (`tests/knkwebapi_v2.Tests/Services/`)
- `LootboxRollEngineTests`:
  - box-grade weights (defaults from `GradeDefaults`, then overrides);
  - window clamping at ★1; empty-window fallback down, then up;
  - two-stage distribution with a scripted RNG;
  - pool Include/Exclude/`GradeIdOverride`, `Lootbox Special` tag excluded;
  - specials first-hit order and `MinBoxStars`;
  - enchant clamp per grade: cap 0 drops the roll, ★6+ capped at definition max, custom only at definition max;
  - merge with defaults; book blueprint gets no rolls.
- `LootboxTypeServiceTests`: validation, unique category, odds endpoint numbers match the engine (same code path).
- `LootboxSeedTests`: idempotent, one type per category, specials only when blueprints exist, no cascade.

**Acceptance:** migration passes fresh-DB CI. `GET /api/LootboxTypes/{weapons}/odds?boxStars=5` on the dev DB shows ★3/★4/★5 at
50/31.25/18.75 % with default grades. Suite = baseline + new tests, same 5 known failures.

---

## Phase 2 — Runtime API (knk-web-api)

**New/changed**
- `Services/LootboxRuntimeService.cs`:
  - `GetRuntimeConfigAsync` and `GetActiveAsync`, both with the lazy expiry sweep;
  - `SpawnAsync` (caps, then type/grade roll);
  - `AdminSpawnAsync` + audit `LootboxSpawnedByAdmin`;
  - `DespawnAsync`;
  - `ClaimAsync` (transaction per DESIGN §3.3: idempotent replay, 409/429, `DbUpdateConcurrencyException` → `AlreadyClaimed`);
  - `MarkDeliveredAsync`, `GetPendingAsync`, `AdminGiveAsync` (roll without a spawn, `LootboxSpawnId=null`, audit `LootboxGranted`).
- `Controllers/LootboxSpawnsController.cs` (`runtime-config`, `active`, `POST`, `admin`, `{id}/despawn`, `{id}/claim`) and
  `Controllers/LootboxClaimsController.cs` (`{id}/delivered`, `pending`, `search`, `admin-give`). Runtime actions are
  `[Authorize(Policy="PluginService")]`.
- `Services/Lootbox/LootboxMetrics.cs`: `Meter("Knk.Lootboxes")` counters/histogram. Register the meter in `Program.cs`'s
  `WithMetrics(m => m.AddMeter("Knk.Lootboxes"))`.

**Tests**
- `LootboxRuntimeServiceTests`:
  - area/global caps; disabled config → 409;
  - claim happy path writes claim + enchant rows;
  - same idempotency key → `replay=true`, identical payload, no second roll (RNG mock called once);
  - second user → 409 `AlreadyClaimed`; expired → 409; token mismatch → 409; daily cap → 429;
  - pending lists only undelivered claims older than 30 s; delivered is idempotent.
- Concurrency: InMemory doesn't enforce unique indexes. Test the `[ConcurrencyCheck]` path with two contexts on the same InMemory
  store, and **verify the unique index manually on local MySQL 8** (two parallel `curl` claims → one 200, one 409). Record the result
  in this plan.
- `Api/LootboxSpawnsControllerAuthTests` (WebApplicationFactory): runtime endpoints return 401 without the key.

**Acceptance:** a full claim round-trip via Swagger with the API key. Metrics are visible through the OTLP exporter when enabled.

---

## Phase 3 — Plugin runtime (knk-plugin)

**knk-core** (`core/lootbox/`, Bukkit-free)
- `KnkLootboxType`, `KnkLootboxSpawn`, `KnkLootboxArea`, `KnkLootboxRuntimeConfig`, `KnkLootboxClaimResult` records.
- Ports `ports/api/LootboxesQueryApi`, `LootboxesCommandApi`.
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
- `lootbox/LootboxDelivery.java` (uses `BlueprintItemAssembler` + `ItemGradeTag`, stamps `knightsandkings:knk_lootbox_claim`, owner-
  locked drop fallback, ACK).
- `lootbox/LootboxAnnouncer.java` (Adventure `showItem` hover, templates from runtime config).
- Listeners: `listeners/LootboxInteractListener.java`, `LootboxChunkListener.java` (`ChunkLoadEvent`, `EntitiesLoadEvent` orphan
  purge), `LootboxJoinListener.java` (pending delivery with PDC dedupe scan of inventory + ender chest).
- `commands/LootboxCommand.java` (`/lootbox`, `/lb`) + `plugin.yml` command and `knk.lootbox.*` nodes. Wire it in `KnKPlugin.java`
  via `registerSimpleCommand`, plus a `DataAccessFactory` entry.
- `config.yml` `lootboxes:` section (DESIGN §3.4).
- Tests: `LootboxDeliveryTest` (full inventory → refuse; leftovers → owned drop), `LootboxCommandTest` (permission gating, arg
  parsing), `LootboxInteractListenerTest` (staff mode, distance, guard) with the existing Bukkit-mock style of knk-paper tests.

**Web-api follow-up in the same phase:** seed `knk.lootbox.open` and `knk.lootbox.odds` grants on the Default `PermissionGroup`
(create-only).

**Acceptance (live, developer checklist):**
1. Enable the Weapons type, create an area around spawn with `MinOnlinePlayers=1` and interval 60 s → a box appears with a label.
2. Two accounts click at once → one item, one "Someone else got there first".
3. Kill the server right after a click (before the ACK) → on rejoin the item arrives once, not twice.
4. Full inventory → refused, box stays.
5. Reload chunks and relog repeatedly → no new boxes beyond the cap, and no re-roll.
6. A ★5+/special drop broadcasts once with a hoverable item.
7. Box expires after `LifetimeMinutes`.
8. `/lootbox give` writes an audit row.

---

## Phase 4 — Web-app admin (knk-web-app)

- `src/apiClients/`: `lootboxTypeClient.ts`, `lootboxSpecialEntryClient.ts`, `lootboxSpawnAreaClient.ts`,
  `lootboxConfigurationClient.ts`, `lootboxClaimClient.ts`, `lootboxSpawnClient.ts` (admin reads/despawn only).
- `src/types/dtos/lootbox.ts`; register in `entityApiMapping.ts` and `objectConfigs.tsx`.
- FormConfigurations authored in FormConfigBuilder on the dev DB, recorded in a new `docs/specs/lootboxes/PHASE_4_FORMCONFIGS.md`
  (same as kits/siege Phase 3): `LootboxType` (basics → box grade weights → pool entries → enchant rolls), `LootboxSpecialEntry`,
  `LootboxSpawnArea` (WgRegionId picker + WorldTask).
- `src/pages/admin/LootboxesPage.tsx` + route `/admin/lootboxes` + nav entry: tabs Settings / Types / Odds / Active boxes / Drop log.
- Tests `src/pages/admin/__tests__/LootboxesPage.test.tsx` (renders the odds table from a mocked response, despawn calls the client,
  drop-log paging).

**Acceptance:** an admin can enable a category box, tune weights, see the odds change, define an area, watch active boxes and page the
drop log without touching the DB. `tsc` is clean; test failures don't exceed the known baseline.

---

## Phase 5 — (optional, Q5) Lootbox token items

- web-api: `LootboxToken` (`Token`, `LootboxTypeId`, `BoxGradeId`, `IssuedToUserId?`, `IssuedReason`, `RedeemedClaimId?`).
  `POST LootboxTokens/issue` (PluginService/admin) and `POST LootboxTokens/{token}/redeem` (same roll engine and claim table;
  `LootboxClaim.LootboxSpawnId` null, `LootboxTokenId` set).
- plugin: a token item (PDC `knightsandkings:knk_lootbox_token`, never matched by name, which fixes the v1 rename exploit).
  Right-click to redeem, and the item is consumed only after a 200. Issue hooks: kit contents, premium tier grants (user-features),
  PvP kill drops (future), referral (future).
- Tests: redeem twice → second 409; a renamed non-token item does nothing.

---

## Cross-feature dependencies

- **KNG-15** (plugin sends no bearer token → 401 on Kits give): same root cause as Phase 0. Fix once, and share the scheme.
- **currency-payments** (`docs/specs/currency-payments/`): its service-auth/idempotency conventions supersede Phase 0 and the claim
  idempotency key format if they land first. Lootboxes grant no currency now. Any later coin/gem reward uses
  `UserService.AdjustBalancesAsync` plus that ledger.
- **KNG-6** grades: rename grades 6-10 before enabling ★6+ boxes (DESIGN Q3).
- **KNG-12** (no WG flags on town/district regions): affects PvP safety around boxes in towns.
- **KNG-14** (gameplay statistics): add a `LootboxesOpened` counter fed from `LootboxClaim` when that lands.
- **Kits**: can adopt `BlueprintItemAssembler` to finally apply blueprint default enchantments (open owner item in ACTIVE_SESSIONS).
- **Siege**: only the pattern is reused. Nothing depends on `claude/siege-minigame` merging.
- **domain-discovery** (`docs/specs/domain-discovery/`): spawn areas can reference the same `Domain` regions. No coupling.
