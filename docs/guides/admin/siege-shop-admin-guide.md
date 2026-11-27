# Siege Shop — Admin Guide

**Status:** Current · **Last updated:** 2026-11-21 (first version, siege shop chain #611 with #356 and #859, links L1–L6 #866–#871, docs PandiO/knk-workspace#908)
**Checked against:** knk-web-api `next` `fc1a5143`, knk-plugin `next` `ec02a64a`, knk-web-app `next` `acff2134` (not
released; siege points and the shop work only with `siege.points.enabled` and `siege.shop.enabled` on in the plugin's
`config.yml`; none of the manual steps of the [siege shop smoke test](../siege-shop-smoke-test.md) have been run live
yet)
**Related:** [siege shop DESIGN](../../specs/siege-shop/DESIGN.md) (the rules and decisions),
[siege shop architecture](../../architecture/siege-shop.md) (ownership, API contract, telemetry, tests),
[siege player guide § Siege points, the siege shop and weapon unlocks](../users/siege-player-guide.md#siege-points-the-siege-shop-and-weapon-unlocks)
(what players see), [authoring a siege scenario](../authoring-a-siege-scenario.md),
[game settings § Menu item](../game-settings.md#menu-item), [menus admin guide](menus-admin-guide.md),
[plugin configuration § 4.13](plugin-configuration.md#413-siege), [economy admin guide](economy-admin-guide.md)

The siege shop chain adds four things to PvP Siege:

1. **Siege points:** a balance per player and match, earned by playing and spent in the shop. Gone at the match end.
2. **The siege shop:** categories of offers, bought with siege points during a running match, with prices that rise
   per purchase, growing cooldowns and a cap per match. Staff edit a default catalogue per game mode and change it
   per scenario.
3. **Siege weapon unlocks:** players unlock a siege weapon type once, with coins and optionally a minimum title,
   before the shop sells it to them.
4. **Menu item settings:** the menu item's look and what each click does, with overrides in a siege, on the game
   settings page (see [game settings § Menu item](../game-settings.md#menu-item)).

Player-facing behaviour is in the [player guide](../users/siege-player-guide.md#siege-points-the-siege-shop-and-weapon-unlocks);
this guide does not repeat it.

## 1. What you need

1. **knk-web-api** with the migrations below applied (all additive) and restarted once after them, so the startup
   seeds run: the default shop catalogue (`SiegeShopSeed`), the menus `siege.shop`, `siege.shop.category` and
   `siege.unlocks`, the **Shop** button in `siege.information` and the **Siege unlocks** button in `siege.overview`
   (both buttons are also added once to databases seeded before).
   1. `20261120131558_AddSiegePointsEarning` (#866): the earn settings and `PointTransfersEnabled` on
      `siege_configurations` (an existing row gets the defaults), `SiegePointsEarned` and `SiegePointsSpent` on
      `siege_match_participants`.
   2. `20261120183543_AddSiegeShopCatalogue` (#867): the tables `siege_shop_categories` (with the three categories),
      `siege_shop_entries` and `siege_scenario_shop_overrides`, and `item_blueprints.PotionType`.
   3. `20261120193455_AddMenuItemSettings` (#870): the nullable `game_settings.MenuItemSettingsJson` (null reads the
      defaults).
   4. `20261120231505_AddSiegeWeaponUnlockMinTitle` (#869): the nullable `siege_weapon_templates.UnlockMinTitleLevel`
      with a foreign key to the title brackets.
2. **Form seeds** imported in the web app (form configuration list → **Import / seeds**), in this order:
   `SiegeShopCategory`, `SiegeShopEntry`, `SiegeScenarioShopOverride` (seed v1 each), then the current `SiegeScenario`
   (it has the "Siege shop" step) and `ItemBlueprint` (it has the "Potion type" field), and **SiegeWeaponTemplate -
   Default (seed v2)** as the default (it has "Minimum title to unlock"). A database that imported `SiegeScenario` or
   `ItemBlueprint` earlier doesn't get the step and field from a new import (import never overwrites): add them in the
   form designer as the seeds README in knk-web-api `Data/FormConfigurationSeeds/` describes.
3. **knk-plugin** from the same `next`. **Deploy order:** the plugin **before** the API's restart with the shop
   menus (#868): a plugin without the shop blocks `siege.information` at its menu validation once the API has added the
   Shop button. The Siege unlocks button needs no order (it hides until the plugin has validated `siege.unlocks`), and
   the menu item settings work with either order (the plugin falls back to `config.yml`).
4. **Plugin `config.yml`** (both default `false`; Restart):

   ```yaml
   siege:
     points:
       enabled: true
     shop:
       enabled: true
   ```

   Turn them on together: the shop needs siege points (with `shop.enabled: true` and `points.enabled: false` the log
   says `siege.shop.enabled is on but siege.points.enabled is off: the siege shop needs siege points, so it stays off`).
   Weapon entries also need `siege.weapons.enabled: true`. Weapon unlocks and the menu item settings have no switch.
   Every key: [plugin configuration § 4.13](plugin-configuration.md#413-siege) and § 4.14 (`menus.menu-item.*`).
5. **Permissions:** `knk.siege.admin.manage` for the siege settings, shop categories, entries, overrides, weapon
   templates and staff grants of unlocks; deleting also needs `knk.admin.delete`. `knk.admin.config` for the game
   settings page. Players need nothing new (`knk.siege.play`, which every player has).

## 2. Siege points: the Siege settings page

**Admin** → **Settings** → **Siege settings** (`/admin/siege-configuration`) → section **Siege points**. These apply
to every PvP Siege match; a match reads them when it starts, so a change counts from the next match.

| Field | Default | What it does |
|---|---|---|
| Points per kill | 100 | The killing blow on an enemy member, weapon kills included. |
| Kill streak step | 0.1 | The n-th kill of a streak pays the kill points × (1 + step × (n − 1)) … |
| Kill streak cap | 1.5 | … up to this multiplier (1–100). 1 turns streaks off. A death resets the streak. |
| Points per assist | 40 | To each member, except the killer, who did enough damage to the victim in the window. |
| Assist minimum damage | 4 (half hearts) | Damage that counts as an assist (4 = 2 hearts). |
| Assist window | 10 s | How long before the death damage counts. |
| Points per death | 15 | Catch-up for each own death by an enemy or the environment. Friendly fire and suicide pay nobody. |
| Gate HP per point | 5 | One point per this many gate HP removed; 0 = gate damage pays nothing. |
| Points per capture percent | 3 | Per percent an objective moves towards a side, to each living member of that side in the radius. |
| Points per capture | 100 | To the capturing side's members in the radius at the capture. |
| Trickle amount / interval | 10 per 60 s | To each member who was active in the interval (walked 10 blocks, fought, hit a gate or stood in a capture radius); AFK players get nothing. |
| Allow teammate transfers | off | Lets members send points to a teammate in the same match with `/siege pay`. |

Save sends only the changed fields; a value the API refuses (for example a streak cap below 1) shows its reason. The
same fields are on `GET`/`PUT api/SiegeConfiguration`. The design's numbers aim at about 100 points a minute for a
good player; tune them in the alpha balance runs ([#651](https://github.com/PandiO/knk-workspace/issues/651)).

## 3. The shop catalogue

A match sells its game mode's **default entries**, changed by its scenario's **overrides**, plus the scenario's own
**scenario-only entries**. The plugin reads this catalogue **once at the match start**, so every edit applies from the
next match.

### 3.1 Categories

Dashboard → **SiegeShopCategory** (form `SiegeShopCategory`). The migration creates three: **Siege weapons**
(`siege-weapons`), **Consumables** (`consumables`) and **Magic** (`magic`, empty for now). A category has a unique key
(lower-case letters, digits and dashes; keep it stable, the seeds find categories by it), a name, an optional icon
material (`minecraft:golden_apple`) and a sort order. A category
with entries can't be deleted ("has N shop entries"); an empty one can. A category with nothing visible in a match is
not shown in that match's shop.

### 3.2 Entries

Dashboard → **SiegeShopEntry** (form `SiegeShopEntry`, steps General, Item or Siege weapon, Price, Cooldown and cap).

1. **General:** game mode (**Siege** for PvP Siege, or **SiegeSurvival**), category, **Kind** (`Item` or
   `SiegeWeapon`), display name and icon (empty = from the item or weapon), sort order and **Enabled**. The Scenario
   field is empty for a default entry and set for a scenario-only entry (§ 3.3).
2. **Item** (Kind Item): an item blueprint and the quantity per purchase. **Siege weapon** (Kind SiegeWeapon): a
   weapon template; one weapon per purchase. An entry whose target doesn't match its kind is refused ("An Item entry
   sells an item blueprint, not a siege weapon template.").
3. **Price:** the first price in siege points; empty on a weapon entry = the template's **Match price** (200 by
   default). **Price step** with its growth (**None**, **Linear**, **Logarithmic**, **Exponential** with a growth
   factor, 1.5 when empty) and an optional **maximum price**.
4. **Cooldown and cap:** a cooldown in seconds after each purchase (empty = none), a cooldown step with the same growth
   choices and an optional maximum, and **Max per match** (empty = no cap).

**How the brakes grow.** Purchase number *i* (1, 2, 3, …) adds a step to the price before it: None adds the step
every time, Linear adds step × *i*, Logarithmic step × (1 + ln *i*), Exponential step × factor^(*i* − 1). Example
(the seeded ender pearl): price 300, step 50 Linear → 300, 350, 450, 600, 800, …; cooldown 20 s, step 10 s
Exponential ×1.5 → 20, 30, 45, 67.5 s. The maximum price or cooldown caps the growth. The API refuses an exponential
factor of 1 or less, a cooldown step without a cooldown, and a maximum price below the price.

**The default catalogue.** At API start, a game mode with **no** default entry at all gets the seeded catalogue, so
your edits and deletions are never overwritten later:

| Entry (Consumables) | PvP Siege price, step | Cooldown | Max per match | Siege Survival |
|---|---|---|---|---|
| Ender Pearl ×1 | 300, +50 Linear | 20 s, +10 s Exponential ×1.5 | 8 | prices and steps ×10 |
| Splash Potion of Healing II ×1 | 150, +25 Linear | 10 s | 10 | ×10 |
| Golden Apple ×1 | 200, +50 Linear | none | 6 | ×10 |
| Potion of Regeneration ×1 | 250 | none | 4 | ×10 |

The four item blueprints are created if no blueprint of that name exists (reused, never changed, if it does); the
potions carry a **Potion type** (`minecraft:strong_healing`, `minecraft:regeneration`; a value that isn't a vanilla
potion type is refused). PvP Siege also gets one Siege weapons entry per weapon template that **already exists** at
that first start, at the template's price. A fresh database has no templates then: add weapon entries by hand after
creating templates (the seed doesn't run again). Siege Survival gets no weapon entries; its shop is used once Siege
Survival is merged.

### 3.3 Per scenario: overrides and scenario-only entries

Open the scenario in the form wizard (`/forms/siegescenario`, dashboard → Edit) → step **Siege shop**:

1. **Shop overrides** (Create New): pick a default entry of the scenario's mode, then **Hide in this scenario**, or
   change the price, quantity, max per match, cooldown, price step, cooldown step or sort order. An empty field keeps
   the default. One override per entry and scenario ("This scenario already overrides that entry").
2. **Scenario-only entries** (Create New): a full entry (§ 3.2) whose Scenario is this one; only this scenario's
   matches sell it.

To see what a match will sell, open `GET api/SiegeShop/catalogue?mode=Siege&scenarioId=<id>` (signed in with a
staff account that may read shop entries): each entry with its effective fields and `source` (`Default`,
`Overridden`, `Scenario`), and only the categories with something visible. Without `scenarioId` it lists the mode's
defaults.

## 4. Siege weapon unlocks

On each **SiegeWeaponTemplate** (form seed v2): **Unlock price** (coins, 1000 by default) and **Minimum title to
unlock** (optional; empty = none). Players unlock in game (`/menu` → Siege Minigame → Siege unlocks) or on their
account page; the API checks the title, then the coins, then charges the unlock price once and writes the unlock in
the same transaction. A price or title change applies to the next unlock; existing unlocks stay.

- **In the balance log** an unlock is one `SIEGE_UNLOCK` posting with the key `siege-unlock:<template id>:<user id>`,
  so a double click or a retry never charges twice. Reverse it like any transaction
  ([economy admin guide](economy-admin-guide.md)); the unlock row stays until you delete it.
- **Granting or removing an unlock by hand:** dashboard → **UserSiegeWeaponUnlock** (create or delete a row). This
  charges nothing.
- A match reads its members' unlocks at its start: a new unlock counts from the next match.
- Until siege weapons phase 3 ([#784](https://github.com/PandiO/knk-workspace/issues/784)) an unlocked weapon entry
  in the shop says "Siege weapons can't be bought yet." and charges nothing.

## 5. The menus and the menu item

- The shop and unlock menus are API menu seeds (create-only, like every menu seed; see the
  [menus admin guide](menus-admin-guide.md)): `siege.shop` (3 rows, Dynamic, min 2: a header with the balance and the
  categories), `siege.shop.category` (6 rows, Dynamic, min 2: one category's offers, `ctx.categoryId`) and
  `siege.unlocks` (6 rows, Dynamic, min 3). The Shop button (slot 0 of `siege.information`'s header) shows only while
  the viewer is a member of a running match with the shop on; the Siege unlocks button (slot 0 of `siege.overview`'s
  header) hides until the plugin has validated `siege.unlocks`.
- The menu item's clicks in a siege (`siege.hub`, `siege.match`, `siege.survival.match`) are set on the game settings
  page: [game settings § Menu item](../game-settings.md#menu-item).

## 6. A safe test

On the dev server, never first on the alpha:

1. Deploy as in § 1 (plugin first), with both switches off. Check that `/siege menu` looks as before and `/siege shop`
   says "The siege shop is not enabled on this server."
2. Check the Siege settings page's Siege points section and the shop dashboards (three categories, eight consumable
   entries).
3. Turn on `siege.points.enabled` and `siege.shop.enabled`, restart, and play one PvP match with two or three
   players: earn points, buy an ender pearl, check the price, cooldown and "Bought: 1/8", and the
   `Siege points this match: earned E, spent S.` line at the end.
4. Unlock one weapon type in game for a test player with spare coins and check the `SIEGE_UNLOCK` posting.
5. The full checklist is the [siege shop smoke test](../siege-shop-smoke-test.md) §§ 1–5.

To turn the shop off again: `siege.shop.enabled: false` and restart; siege points can stay on without it.

## 7. Effects on existing data

1. All four migrations are additive. Existing siege settings get the default earn amounts; existing match results
   read 0 siege points earned and spent.
2. The catalogue seed adds four item blueprints (if missing) and the default entries; it never changes existing
   blueprints or entries.
3. Existing weapon templates keep their unlock price and get no minimum title; existing unlocks stay.
4. The menu item keeps today's look until someone saves the Menu item card: the seeded defaults match the old
   `menus.menu-item.*` defaults, with the siege overrides added.
5. Siege points never touch coins; only unlocks spend coins.

## 8. Troubleshooting

| Symptom | Likely cause |
|---|---|
| No "Siege points" line on the sidebar | `siege.points.enabled` is off, or the server wasn't restarted after changing it. |
| `/siege shop` says it is not enabled | `siege.shop.enabled` is off, or it is on while `siege.points.enabled` is off (see the log line in § 1). |
| `/siege menu` blocked ("That menu is unavailable right now.") after the deploy | The API added the Shop button before the plugin with the shop ran: deploy the plugin, restart it. `/knk menu broken` shows the reason. |
| "The siege shop isn't available in this match." | The API didn't answer the catalogue read at the match start (two retries 5 s apart); the next match tries again. One warning in the log. |
| An edit to an entry doesn't show | The catalogue is read once per match; it shows in the next match. |
| No Siege weapons category | `siege.weapons.enabled` is off, or the mode has no enabled weapon entry (a fresh database seeds none). |
| A weapon entry says Locked for a player who just unlocked it | Unlocks are read at the match start; it counts from the next match. |
| No Siege unlocks button in the siege overview | The plugin hasn't validated `siege.unlocks` yet (a plugin without #869, or the API was down at startup). |

## Changes

1. 2026-11-21: first version; siege shop chain #611 (L1–L6, #866–#871), docs #908
