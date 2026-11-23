# Siege shop: siege points, the match shop, weapon unlocks and menu item settings (knk-plugin, knk-web-api and knk-web-app)

**Status:** Current · **Last updated:** 2026-11-21 (first version, siege shop chain #611 with #356 and #859, links L1–L6 #866–#871, docs PandiO/knk-workspace#908)
**Checked against:** knk-plugin `next` `ec02a64a` (PRs PandiO/knk-plugin#107, #109, #111, #112), knk-web-api `next`
`fc1a5143` (PRs PandiO/knk-web-api#64, #66, #68, #69, #71), knk-web-app `next` `acff2134` (PRs PandiO/knk-web-app#69,
#70, #71). Not released; the manual steps of the [siege shop smoke test](../guides/siege-shop-smoke-test.md) have not
been run live yet.
**Related:** [siege shop DESIGN](../specs/siege-shop/DESIGN.md) (the rules, P-decisions and A-criteria referred to
below), [admin guide](../guides/admin/siege-shop-admin-guide.md),
[player guide](../guides/users/siege-player-guide.md#siege-points-the-siege-shop-and-weapon-unlocks),
[siege minigame design](../specs/siege-minigame/DESIGN.md), [siege survival design](../specs/siege-survival/DESIGN.md)
(the shared match ledger), [plugin architecture](plugin-architecture.md), [web API architecture](web-api-architecture.md),
chain report `docs/reports/2026-11-20-siege-shop-chain.md` § 4 on knk-workspace `main` (agent decisions per link)

## 1. Ownership

| Concern | Owner | Where |
|---|---|---|
| Siege points balance, earning, transfers (per match, in memory) | knk-plugin | knk-core `core/siege/economy/` (`MatchLedger`, `SiegePointsEconomy`, `SiegePointsEarnCalculator`, `AssistTracker`, `SiegePointsText`); knk-paper `siege/points/` (`SiegePointsService`, `SiegePointsDamageListener`, `SiegePointsTelemetry`) |
| Earn amounts, transfer switch | knk-web-api | `SiegeConfiguration` (read with the siege runtime config); web app Siege settings page, section "Siege points" |
| Match totals | knk-web-api | `SiegeMatchParticipant.SiegePointsEarned` / `SiegePointsSpent`, sent with the match result |
| Shop catalogue (categories, entries, overrides, default seed) | knk-web-api | `Models/Siege/Shop/` (`SiegeShopCategory`, `SiegeShopEntry`, `SiegeScenarioShopOverride`, `SiegeShopSeed`), `SiegeShopService` |
| Shop runtime (frozen catalogue, brakes, purchase) | knk-plugin | knk-core `core/siege/shop/` (`ShopCatalogue`, `ShopBrakes`, `ShopCurve`, `ShopPurchaseService`, `ShopPurchaseHandler`, views); knk-paper `siege/shop/` (`SiegeShopService`, `ItemPurchaseHandler`, `SiegeShopMenuFeature`, `SiegeShopTelemetry`) |
| Weapon unlocks (coins, minimum title) | knk-web-api | `SiegeWeaponTemplate.UnlockPrice` / `UnlockMinTitleLevel`, `UserSiegeWeaponUnlock`, `SiegeWeaponUnlockPurchaseService` |
| Unlocks menu | knk-plugin | knk-core `core/siege/unlocks/`; knk-paper `siege/unlocks/SiegeUnlocksMenuFeature` |
| Unlocks panel | knk-web-app | `components/siege/MySiegeUnlocksSection.tsx` on the account page |
| Menu templates | knk-web-api | `Models/Menu/MenuTemplateSeed.SiegeShop.cs`, `MenuTemplateSeed.SiegeUnlocks.cs` (create-only seeds plus a one-time button insert) |
| Menu item settings | knk-web-api (data), knk-plugin (behaviour), knk-web-app (card) | API `Services/MenuItemSettings.cs`, `GameSettings.MenuItem`; plugin knk-core `core/menu/opener/` (`MenuItemAction`, `MenuItemActionResolver`, `MenuItemSituations`, `MenuOpenerSettings`), knk-paper `menu/opener/` (`MenuItemSettingsSync`, `MenuItemActionRunner`, `MenuOpenerListener`, `MenuOpenerService`) and `siege/SiegeMenuItemSituations`; web app `components/admin/gameSettings/MenuItemCard.tsx`, `utils/menuItemSettings.ts` |

The API is never on the purchase path: the plugin reads the catalogue and the members' unlocks once at the match start
and keeps the balance in memory (P25). Only weapon unlocks, which spend coins, go through the API's currency ledger.

## 2. Siege points (L1, #866, #356)

1. **Ledger.** `MatchLedger` (moved unchanged from Siege Survival into knk-core, P11) holds one balance per member and
   match. Charges and transfers carry a retry id: the same id with the same request returns the first result, a
   conflicting reuse is rejected (`RETRY_ID_CONFLICT`). It refuses overdrafts, non-positive amounts, self-transfers,
   ghosts, players outside the match and work after the match end.
2. **Earning.** `SiegePointsEarnCalculator` is pure: kill × min(1 + step × (n − 1), cap), assists from
   `AssistTracker` (damage ≥ `AssistMinDamage` within `AssistWindowSeconds`, never to the killer), death catch-up
   (environment deaths included, friendly fire and suicide pay nobody), gate damage with kept fractions
   (`GateHpPerPoint`), capture progress per percent to the side moving it inside the radius, a capture bonus, and the
   activity trickle (active = 10 blocks walked, fought, gate hit or in a capture radius in the interval; never while
   AFK by the statistics AFK tracker). `SiegePointsService` observes the siege match events and pays.
3. **Showing.** Per-player scoreboards (each member's own board with a "Siege points: N" line under the time), the
   action bar per change (`+130 kill ×1.3 · 830`), `/siege points`, `/siege pay <player> <amount>` (only with
   `PointTransfersEnabled`, same team, same running match).
4. **End.** The result sends `siegePointsEarned` and `siegePointsSpent` per participant (only when points were
   counted), each member gets `Siege points this match: earned E, spent S.`, the balance is dropped. A `/siege leave`
   drops that member's balance; a restart ends the match without rewards and no balance comes back (P12).
5. **Off.** With `siege.points.enabled: false` nothing is registered: boards stay one per team, `points` and `pay` are
   not suggested and answer "Siege points are not enabled on this server.", and the result carries 0.

## 3. The shop catalogue (L2, #867, #878)

**Model.**

| Table | Key fields | Rules |
|---|---|---|
| `siege_shop_categories` | `Key` (unique, `^[a-z0-9][a-z0-9-]{0,49}$`), `Name`, `IconMaterial?`, `SortOrder` | Seeded by the migration (`siege-weapons`, `consumables`, `magic`). Delete refused while it has entries. |
| `siege_shop_entries` | `GameMode` (`Siege`, `SiegeSurvival`), `SiegeScenarioId?` (null = default entry), `CategoryId`, `Kind` (`Item`, `SiegeWeapon`), `ItemBlueprintId?` + `Quantity` or `SiegeWeaponTemplateId?`, `DisplayName?`, `IconMaterial?`, `Price?`, `PriceStep?`, `PriceCurve`, `PriceGrowthFactor?`, `PriceMax?`, `CooldownSeconds?`, `CooldownStepSeconds?`, `CooldownCurve`, `CooldownGrowthFactor?`, `CooldownMaxSeconds?`, `MaxPerMatch?`, `SortOrder`, `Enabled` | The target must match the kind; `Price` null only on a weapon entry (then the template's `MatchPrice`); growth factor > 1; a cooldown step needs a cooldown; `PriceMax` ≥ `Price`. Index on (`GameMode`, `SiegeScenarioId`, `SortOrder`). |
| `siege_scenario_shop_overrides` | `SiegeScenarioId`, `SiegeShopEntryId`, `Hidden`, `Price?`, `Quantity?`, `MaxPerMatch?`, `CooldownSeconds?`, `PriceStep?`, `CooldownStepSeconds?`, `SortOrder?` | Unique per (scenario, entry); only for default entries of the scenario's mode; cascade with the scenario and with the entry; null keeps the default. |
| `item_blueprints.PotionType` | `minecraft:<vanilla potion type>` | Validated against the vanilla list; the plugin sets it on the built item (`KnkItemBlueprint.potionType`). |

**Effective catalogue** (`SiegeShopService`, P05, A15): the mode's enabled default entries, minus the scenario's
hidden ones, with its overrides applied, plus its own scenario-only entries; categories without a visible entry are
left out; each entry carries `source` `Default`, `Overridden` or `Scenario` and a resolved `price`.

**Default seed** (`SiegeShopSeed.SeedCanonicalAsync`, Program.cs at startup, also with `Seeding:IncludeExamples`
false): runs per mode only while the mode has no default entry. Four blueprints by name (get or create, never
updated), the DESIGN § 12.2 consumables (Survival × 10 on price and price step), and one PvP weapon entry per existing
template.

## 4. The shop runtime (L3, #868)

1. **Freeze (P25, A23).** At the match start `SiegeShopService` reads `GET api/SiegeShop/catalogue?mode=Siege&scenarioId=`
   off the main thread (two retries 5 s apart; until then "still opening", after that "isn't available in this match"
   and one warning), drops weapon entries while `siege.weapons.enabled` is off, builds the blueprint items and the
   members' weapon unlocks, and creates one `ShopPurchaseService` for the match.
2. **Brakes (§ 5.4, A20–A22).** `ShopBrakes` computes the price and cooldown of purchase *i*: the base plus the sum of
   `ShopCurve.step(step, k, factor)` for k = 1…i − 1, with None = s, Linear = s × k, Logarithmic = s × (1 + ln k),
   Exponential = s × f^(k − 1) (f = 1.5 when unset or ≤ 1), capped by the maximum. Counters are per member, entry and
   match.
3. **Purchase (A18, A19, P22).** Check in order: match running and the member alive, the entry sold in this match,
   unlocked (weapons), cap, cooldown, room for the whole stack, balance. Then charge the ledger (retry id per
   purchase), then give through the entry kind's `ShopPurchaseHandler`; a failed give refunds ("Something went wrong;
   your siege points were given back."). Weapon entries have no handler until siege weapons phase 3 (#784) registers
   one with `SiegeShopService.registerHandler` ("Siege weapons can't be bought yet.").
4. **Items end with the match (A24).** Bought items are part of the siege inventory and go with the gear restore; no
   refund.
5. **Survival hook (P21).** A Siege Survival match offers its own `ShopPurchaseService` through `addMatchSource`, so
   `/siege shop` opens the same menus on Survival's balance once Survival is merged.
6. **Off.** With `siege.shop.enabled: false`, or on with points off (log warning), nothing of the shop is registered.

## 5. Weapon unlocks (L4, #869, #795)

`SiegeWeaponUnlockPurchaseService.PurchaseAsync(userId, templateId, ctx)`: unknown template or user → 404; already
unlocked → 200 with `alreadyUnlocked` and nothing charged; title below `UnlockMinTitleLevel` → 409 `NeedsTitle`;
otherwise a currency spend of `UnlockPrice` coins with reason **`SIEGE_UNLOCK`** and idempotency key
`siege-unlock:{templateId}:{userId}` (409 `InsufficientFunds` when short), and the `UserSiegeWeaponUnlock` row in the
same transaction, so a double click charges once. The overview lists every template with `state` `Unlocked`,
`NeedsTitle`, `NeedsCoins` or `Unlockable`. The plugin menu refuses unlocking during a running match (A28) and drops
its cached rows after a purchase; the shop reads unlocks per member at the match start.

## 6. API contract

| Endpoint | Access | Notes |
|---|---|---|
| `GET api/SiegeShop/catalogue?mode=Siege\|SiegeSurvival[&scenarioId=]` | game server, or staff who may read `SiegeShopEntry` (dashboard read nodes) | `SiegeShopCatalogueDto { gameMode, siegeScenarioId, categories[{ id, key, name, iconMaterial, sortOrder, entries[{ id, categoryId, kind, source, itemBlueprintId, itemBlueprintName, quantity, siegeWeaponTemplateId, siegeWeaponTemplateName, displayName, iconMaterial, price, priceStep, priceCurve, priceGrowthFactor, priceMax, cooldownSeconds, cooldownStepSeconds, … maxPerMatch }] }] }`; 400 without `mode` |
| `api/SiegeShopCategories` (`GET`, `GET {id}`, `POST`, `PUT {id}`, `DELETE {id}`, `POST search`) | read: dashboard read nodes; write: `knk.siege.admin.manage`; delete also `knk.admin.delete` | delete refused while entries exist |
| `api/SiegeShopEntries` (same shape) | same | validation in § 3 |
| `GET`/`POST api/SiegeScenarios/{id}/shop-overrides`, `GET`/`PUT`/`DELETE api/SiegeScenarioShopOverrides/{id}` | same | one per scenario and entry |
| `GET api/SiegeWeaponUnlocks/mine` | signed-in web user | `SiegeWeaponUnlocksOverviewDto { userId, coins, titleLevel, titleName, offers[{ templateId, name, description, kind, unlockPrice, minTitleLevel, minTitleName, unlocked, unlockedAt, meetsTitle, canAfford, state }] }` |
| `GET api/SiegeWeaponUnlocks/by-user/{userId}` | game server | the same overview |
| `POST api/SiegeWeaponUnlocks/purchase` `{ templateId, userId? }` | game server for a named `userId`, or a signed-in web user for themselves (another `userId` → 403 `NotYourAccount`) | `SiegeWeaponUnlockPurchaseResultDto { templateId, templateName, userId, coinsPaid, alreadyUnlocked, unlockedAt, coins }`; 409 `{ code, message }` |
| `api/UserSiegeWeaponUnlocks` (CRUD, `by-user/{userId}`, `search`) | write `knk.siege.admin.manage` | staff grants, no charge |
| `GET`/`PUT api/SiegeConfiguration` | `knk.siege.admin.manage` (write) | earn fields `pointsPerKill`, `pointsStreakStep`, `pointsStreakCap`, `pointsPerAssist`, `assistMinDamage`, `assistWindowSeconds`, `pointsPerDeath`, `gateHpPerPoint`, `pointsPerCapturePercent`, `pointsPerCapture`, `trickleAmount`, `trickleIntervalSeconds`, `pointTransfersEnabled` |
| `GET`/`PUT api/GameSettings` | `knk.admin.config` | section `menuItem` (§ 8); null on update keeps it |
| `GET api/siege-matches/{id}` | as before | participants carry `siegePointsEarned`, `siegePointsSpent` |

## 7. Telemetry, ledger reason and menu ids

1. **Telemetry** (baseline events in `TelemetryEventCatalog`, diagnostic telemetry on): `siege.points_earned`
   (`lobbyId`, `source`, `amount`, `count`, `factor`; kills one event each, capture progress and gate damage summed per
   minute) and `siege.shop_purchase` (`lobbyId`, `entryId`, `categoryId`, `kind`, `price`, `purchaseNo`; one per
   purchase, none for refusals).
2. **Currency ledger reason** `SIEGE_UNLOCK` (`CurrencyReasons.SiegeUnlock`), key `siege-unlock:{templateId}:{userId}`.
3. **Menu templates:** `siege.shop` (root `siegeShop`, row source `siege.shop-categories`, action `siege.shop.open`),
   `siege.shop.category` (`ctx.categoryId`, row source `siege.shop-entries`, action `siege.shop.buy`), `siege.unlocks`
   (root `siegeUnlocks`, row source `siege.unlocks`, action `siege.unlocks.buy`, condition
   `siege.unlocks.purchase-pending`). Buttons: **Shop** in `siege.information` (slot 0 of the header, action
   `siege.shop.open`, condition `siege.shop-available`); **Siege unlocks** in `siege.overview` (slot 0 of the header,
   `menu.open` + `menu-available`). Both are inserted once into databases seeded before, only when slot 0 is free. The
   seed ↔ plugin contract test is knk-api-client `SiegeMenuSeedContractTest`.
4. **Menu item situations** (`MenuItemSituations.BUILT_IN`, most specific first): `siege.survival.match` (provided by
   Siege Survival at its merge; until then never applies), `siege.match` (a member of a running PvP match),
   `siege.hub` (a member at the scenario hub: team split before the match, the result after it). Answered from memory
   on every click (`SiegeMenuItemSituations`).

## 8. Menu item settings (L5 #870, L6 #871)

- **Data.** `game_settings.MenuItemSettingsJson` (null = defaults): `enabled`, `giveTo` (`all`, or `bedrock` for Floodgate players only),
  `giveOnJoin`, `keepOnDeath`, `material`, `name`, `lore`, `slot` (0–35), `droppable`, `movable`, `clicks` (keys
  `LEFT_CLICK`, `RIGHT_CLICK`, `SHIFT_LEFT_CLICK`, `SHIFT_RIGHT_CLICK`, `INVENTORY_CLICK` → `{ type: OpenMenu|RunCommand|None, menuKey?, command? }`)
  and `overrides` (situation → partial click table). The API validates every part (`MenuItemSettingsTests`, 15 refusal cases),
  drops empty overrides and sends `GameSettingsChanged` (scope `Game`) on save.
- **Plugin.** At startup the `menus.menu-item.*` keys apply ("from config.yml until the game settings answer"); the
  first game settings answer replaces them (`MenuItemSettingsSync`, log `[MenuItem] Settings from the game settings page
  applied: …`) and every later answer (realtime event or the periodic read) is applied live: a new look in place, no
  give or move mid-play; a new slot or a first give at join or respawn. A cached section is not used when the API is
  down at startup (A31). `MenuItemActionResolver` picks the most specific applying situation, then the click's action
  (falling back to the default table); `MenuItemActionRunner` runs `main` as `/menu`, `siege.information` as
  `/siege menu`, `siege.shop` as `/siege shop`, other keys through the menu engine, and Run command as the player.

## 9. Configuration and migration

1. Plugin: `siege.points.enabled`, `siege.shop.enabled` (both `false`, Restart); `menus.menu-item.*` are the
   startup fallback ([plugin configuration § 4.13, § 4.14](../guides/admin/plugin-configuration.md#413-siege)).
2. API migrations (additive): `AddSiegePointsEarning`, `AddSiegeShopCatalogue`, `AddMenuItemSettings`,
   `AddSiegeWeaponUnlockMinTitle` ([production installation § 5.3](../guides/production-installation.md#53-apply-the-migrations)).
3. Form seeds: `SiegeShopCategory`, `SiegeShopEntry`, `SiegeScenarioShopOverride` (v1), `SiegeScenario` with the
   "Siege shop" step and `ItemBlueprint` with "Potion type" (in-place additions), `SiegeWeaponTemplate` v2.
4. Deploy order: the plugin before the API restart that adds the Shop button (an older plugin blocks
   `siege.information`); otherwise none.

## 10. Tests

| Suite | Main tests |
|---|---|
| knk-core (JUnit) | `MatchLedgerTest`, `SiegePointsEconomyTest`, `SiegePointsEarnCalculatorTest`, `SiegePointsCaptureTest`, `ShopBrakesTest`, `ShopPurchaseServiceTest`, `ShopCatalogueTest`, `SiegeUnlockRowViewTest`, `MenuItemActionResolverTest`, `MenuOpenerPlacementTest`, `MenuOpenerSettingsTest` |
| knk-paper (MockBukkit/Mockito) | `SiegePointsServiceTest`, `SiegeScoreboardPresenterPointsTest`, `SiegePointsTelemetryTest`, `SiegeCommandPointsTest`, `SiegeShopServiceTest`, `SiegeShopMenuFeatureTest`, `SiegeCommandShopTest`, `SiegeShopTelemetryTest`, `ItemPotionTypeTest`, `SiegeUnlocksMenuFeatureTest`, `MenuItemSettingsSyncTest`, `GameSettingsManagerMenuItemTest`, `MenuItemActionRunnerTest`, `MenuOpenerListenerTest`, `MenuOpenerServiceTest`, `SiegeMenuItemSituationsTest` |
| knk-api-client | `SiegeMatchesCommandApiImplTest`, `SiegeMenuSeedContractTest`, `ItemAppearanceMapperTest`, `GameSettingsMenuItemMapperTest` |
| knk-web-api (xUnit) | `SiegeShopServiceTests`, `SiegeShopSeedTests`, `AddSiegeShopCatalogueTests`, `PotionTypeKeysTests`, `MenuTemplateSiegeSeedTests`, `SiegeWeaponUnlockPurchaseServiceTests`, `SiegeMatchServiceTests`, `TelemetryEventCatalogTests`, `MenuItemSettingsTests`, `AddMenuItemSettingsTests` |
| knk-web-app | e2e `siege-shop.spec.ts`, `settings-pages.spec.ts`, `siege-unlocks.spec.ts`, `menu-item-settings.spec.ts`; Jest `siegeShopClients.test.ts`, `SiegeConfigurationPage.test.tsx`, `menuItemSettings.test.ts` |

Which smoke-test step each covers: the tags in the [siege shop smoke test](../guides/siege-shop-smoke-test.md).

## 11. Limitations and follow-ups

1. Buying and placing a siege weapon waits for siege weapons phase 3 ([#784](https://github.com/PandiO/knk-workspace/issues/784)),
   which registers the weapon `ShopPurchaseHandler`.
2. The Siege Survival shop and the `siege.survival.match` situation arrive with Siege Survival
   ([#41](https://github.com/PandiO/knk-workspace/issues/41)); the Magic category stays empty until magic items exist.
3. The earn amounts are the design's proposals, to be tuned in the alpha balance runs ([#651](https://github.com/PandiO/knk-workspace/issues/651)).
4. The menu engine's titles are fixed text, so the shop's balance is on the header item, not in the title.
5. New weapon templates are not added to the shop automatically (the seed runs once per mode).
6. No live verification yet: every smoke-test step is automated or still manual, none run by hand.
