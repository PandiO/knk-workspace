# Shops — Admin Guide

**Status:** Current · **Last updated:** 2026-11-21 (display stalls: § 1 items 1-2 and 6, § 2, new § 3.6, § 4.2, new § 7.2, § 8, § 9; production P12 #250, docs PandiO/knk-workspace#970); 2026-11-21 (the shop menus in game: § 1 items 6-7, § 7.1, § 9; production P10b #687, docs PandiO/knk-workspace#966); 2026-11-21 (first version, production P10 #248/#688, docs PandiO/knk-workspace#939)
**Checked against:** knk-web-api `next` `289f4d4b` and `7c6dd7f5` (the menu seeds), knk-web-app `next` `11832d6b`,
knk-plugin `next` `c349a53c`; display stalls against knk-web-api `next` `d86d6e1a` and knk-plugin `next` `b31fceb6`
(not released; the manual steps of
the [smoke test § 11](../production-storage-transport-smoke-test.md#11-phase-p10-shops-248-api-687-plugin-menus-688-web-app-tier3)
have not been run live yet)
**Related:** [shops architecture](../../architecture/shops.md) (pricing, the purchase and sale transactions, the town
account, the stats, recovery), [API contract](../../specs/api/API_CONTRACT_SHOPS.md), [town logistics admin
guide](town-logistics-admin-guide.md) (restocking), [production engine admin guide](production-engine-admin-guide.md)
(processing lines), [warehouses and production structures admin guide](production-world-admin-guide.md) (placement,
workers), [stock admin guide](stock-admin-guide.md) (storages, Adjust, the ledger), [currency admin
guide](economy-admin-guide.md) (the currency ledger), [Game Settings](../game-settings.md), [shops
DESIGN](../../specs/shops/DESIGN.md) (the design)

A **shop** is a structure in a town that sells goods to players for coins and buys goods back from them. Its **shop
type** (bakery, weaponsmith, …) decides which item categories it buys and which **levels** it has; its **kind** says
whether it sells goods as they are (**Trading**) or makes them first from inputs (**Processing**). You fill each shop's
**catalogue** with the items it sells and, if you want, a fixed price. The coins players pay go to the **town
account** of the shop's town; buy-backs are paid from it. The town's warehouses **restock** the shop through the town
planner, and the shop's sales are counted per hour in **trade stats**. This guide covers the set-up, the screens, the
settings, a safe test and what to do when a shop misbehaves.

**What players see.** In game a shop has a **shop menu** (its catalogue), an **item information** menu, a **purchase
confirmation** and a **sell menu** ([#687](https://github.com/PandiO/knk-workspace/issues/687); how players use them:
[menus player guide § Shops](../users/menus-player-guide.md#shops)). **Display stalls**
([#250](https://github.com/PandiO/knk-workspace/issues/250), § 3.6) show the shop's items on shelves and stalls you
register; any player can right-click one for the item information or shift-right-click it to buy, always through the
confirmation ([menus player guide § Display stalls](../users/menus-player-guide.md#display-stalls)). The full shop menu
and the sell menu are opened only by staff, with `/knk shop <shop id>` (§ 7.1), until shopkeepers arrive
([#249](https://github.com/PandiO/knk-workspace/issues/249)); the purchase and sale routes can also be called with a
REST client (§ 7).

## 1. What you need

1. **The migration** `AddShops` on the API's database (seven new tables, one new column on the currency ledger, the
   ledger's account check widened; additive, no data written; [production installation § 5.3](../production-installation.md)
   item 17). For display stalls also `AddShopDisplaySpots` (one new table, additive; item 20).
2. **The seeds**, imported with "make default" in this order (Admin → Forms and Displays): form and display
   `ShopType`, `ShopTypeLevel`, `Shop`, `ShopCatalogueEntry`, `ShopTradeStat`, `TownAccount`. The trade stats and town
   account forms are read only. For display stalls also form and display `ShopDisplaySpot`.
3. **The API's switch**, the game setting **Production enabled** (`Production:Enabled`; Admin → Settings, the
   **Production and territory** card, see [Game Settings](../game-settings.md#production-and-territory)):

   | With it off | With it on, also |
   |---|---|
   | Shop types, levels, shops and catalogues can be written; players can buy from the catalogue (to their inventory) | Players can sell to shops; purchases can go to the player's inbox; the planner restocks shops; Processing shops run their lines; the hourly trade stats are written |

   The game server's `production.enabled` is not needed by shops themselves; the transport trips that restocking uses
   are ([production transport admin guide](production-transport-admin-guide.md)).
4. **Permissions** (staff web app):

   | What | Node |
   |---|---|
   | See the shop panels and the dashboard types | `knk.admin.world` (the panels are hidden without it) |
   | Create and edit shop types, levels, shops and catalogue entries | `knk.admin.world` **and** `knk.admin.content` (the buttons are off with "Requires knk.admin.content") |
   | Rebuild the trade stats | `knk.admin.world` |
   | Delete a shop type, level, shop or catalogue entry | also `knk.admin.delete` |
   | Change `production.shops` (§ 6) | `knk.admin.config` |

   Buying and selling take the game server's plugin key only: staff can't buy or sell for a player from the web app.
5. **The world**, for a shop that sells:
   1. A **town** with a district for the shop (or a rural shop with the town set). A shop without a town can't sell.
   2. **Categories** on the blueprints the shop should buy back, and **base prices** (min and max) on the blueprints
      it sells at the formula price (the item blueprint form: **Lowest price** and **Highest price**, and its category). A blueprint without a base price and without a static
      price is not on sale.
   3. For restocking: a **warehouse** in the town with stock, and a lane or measured road connection between the shop
      and the warehouse ([town logistics admin guide § 1](town-logistics-admin-guide.md#1-what-you-need)).
6. **The game server, for the shop menus** (knk-plugin `next` `c349a53c`, #687):
   1. `production.enabled: true` in the plugin's `config.yml` (default false). Off, `/knk shop` answers "Production is
      off on this server (production.enabled: false)." and the three shop menus are blocked.
   2. `items.identity.enabled: true` for selling: the sell menu resolves each stack through item identity.
   3. The API's **Production enabled** for selling and for purchases into the reward inbox (item 3); buying into the
      inventory works without it.
   4. The shop menus need no new `config.yml` key, no API environment key and no migration (the display stalls do,
      item 6).
   5. `knk.admin.world.production` (also matched by `knk.admin.world.*`) for the staff who open shops with
      `/knk shop` and register display stalls with `/knk shop display` ([commands](../users/commands.md#server-tools-knk)).
   6. For display stalls (knk-plugin `next` `b31fceb6`, #250): the `production.shops.displays` block in `config.yml`
      (restart; the keys are in § 3.6 and the [plugin configuration § 4.31](plugin-configuration.md#431-production)).
      With WorldGuard installed nothing else: players who aren't members of the town region can still click stalls.
7. **The menu templates** `shops.shop`, `shops.item` and `shops.confirm` (knk-web-api `next` `7c6dd7f5`). The API
   creates them on start when they are missing, like every menu seed; nothing to import by hand. **Deploy the plugin
   first, then the API**: a game server without the shop menu ids fails the new templates' validation. To change a
   layout or text later: the [menu authoring admin guide](menus-admin-guide.md) (the seed is create-only, so an edited
   template is kept). The sell menu is built in the plugin and has no template.

## 2. Where things are

1. **Dashboard** (World group), types **ShopType**, **ShopTypeLevel**, **Shop**, **ShopCatalogueEntry**,
   **ShopTradeStat**, **TownAccount** and **ShopDisplaySpot** (§ 3.6). Shops are also listed under **ProductionStructure**: a shop is a production
   structure underneath (it has a worker and can run lines).
2. **A shop type's page**, panel **Accepted categories and levels** (§ 3.1, § 3.2).
3. **A shop's page**, panel **Shop**: the summary, **Offer now**, **Catalogue**, **Sales and buy-backs** and **Trade
   stats per hour** (§ 4, § 5). Below it the production view (lines, § 3.4) and **Supply (as a consumer)** (restocking,
   § 3.5).
4. **A town account's page**, panel **Balance and ledger** (§ 5.3). Reach it from a shop's **Town account** link or the
   **TownAccount** dashboard type.
5. **Admin → Settings**: no shops card yet; see § 6.

## 3. Setting up a shop

### 3.1 Shop types and accepted categories

1. **Dashboard → ShopType → Create**: **Name** (unique), **Description**, **Default kind** (the kind a new shop of this
   type gets: Trading or Processing), **Active**.
2. On the type's page, **Accepted categories**: type in **Add a category**, pick it, remove one with its ×, then **Save
   the categories** (off until the list changed; **Undo** puts the saved list back). A category also accepts its
   sub-categories: a weaponsmith that accepts **Weapons** buys swords filed under **Swords** with Weapons as parent.
3. A type without categories shows "None: its shops buy nothing from players." Its shops still sell.
4. A type in use by a shop can't be deleted: give the shops another type first.

### 3.2 Levels

1. On the type's page, **Levels**, press **Add a level** (the next free level is offered, every multiplier 1), or
   **Dashboard → ShopTypeLevel → Create**. The fields:

   | Field | Effect |
   |---|---|
   | **Level** | 1-100, once per type |
   | **Price** multiplier | The level's share of the sell price (§ 4.1) |
   | **Speed**, **Yield**, **Input cost** | Processing at this level: cycle speed, output, inputs used (Processing shops only) |
   | **Merchandise cap**, **Input cap** | The shop's storage caps in units; empty = no cap |
   | **Units per slot** | Units per slot of a bound storage container; empty = leave as is |
   | **Default min**, **Default max** | What the planner restocks each stocked catalogue item to (§ 3.5); empty = no default |

   Each multiplier is above 0 and at most 100; the max can't be below the min. The panel lists the problems ("Level
   problems") before it sends anything.
2. **Saving a level applies its caps to every shop of that type at that level** at once ("Level 3 saved; shops of this
   type at that level use it now."). An empty cap leaves a shop's storage cap as it was.
3. A type without levels shows "No levels yet: its shops use × 1 and no caps." Deleting a level does not check the
   shops at it: they then use × 1 and no default min/max, and keep their caps. Move them to another level first.
4. Levels are set by admins; there are no upgrade costs in V1.

### 3.3 Shops

1. **Dashboard → Shop → Create**. The form has the steps of any structure (General information, Placement, Region and
   access, Spawn point, Sub-regions; see the [warehouses and production structures admin
   guide](production-world-admin-guide.md)) and a **Shop** step:

   | Field | Default | Notes |
   |---|---|---|
   | **Shop type** | none | Without a type the shop buys nothing and uses × 1 |
   | **Kind** | the type's default kind | **Trading** sells goods as they are; **Processing** turns Input into Merchandise on its lines, then sells |
   | **Level** | 1 | A level the type has; changing it applies the level's caps |
   | **Tax modifier** | 1 | A stand-in for a town tax: the formula price × this (above 0, at most 100) |
   | **Buy-back %** | 50 | What the shop pays players: the sell price × this % (0-100) |
   | **Workers** | 1 | The shop's own worker collects restocks (§ 3.5) |
   | **Processing on** | on | The shop's own processing switch |
   | **Hide sold-out items** | off | Leave sold-out items out of the offer instead of greying them out |
   | **Shopkeeper spawn** | none | Stored for the shopkeeper NPC (P11); does nothing yet |

2. On create the shop gets two storages: **Merchandise** (what it sells) and **Input** (what it processes), capped by its
   level. A shop is created with automatic transport off (its worker only collects; it never ships goods away) and its
   rates are never surveyed.
3. **Its town.** The shop's income goes to its district's town (a rural shop: the town you set). The shop page names it
   under **Town account**.
4. **Deleting a shop** is refused while its storages hold stock or have ledger history, or while its worker is out
   collecting. Empty the storages with **Adjust** ([stock admin guide](stock-admin-guide.md)) only on a shop that never
   traded; a shop with history stays.

### 3.4 Processing (Processing shops)

A Processing shop makes its goods on **production lines**, like any production structure, but the output goes into its
**Merchandise** storage. Add lines in the production view below the shop panel ([production engine admin
guide](production-engine-admin-guide.md)): for a bakery, Bread from Flour. The level's **Speed**, **Yield** and **Input
cost** apply; while the worker is away collecting, processing slows (selling goes on). A **Trading** shop's lines are
paused ("A trading shop doesn't process").

### 3.5 Restocking

The town planner keeps a shop stocked from the town's warehouses, the same way it supplies a bakery with flour
([town logistics admin guide](town-logistics-admin-guide.md)):

1. Every enabled catalogue entry for a stackable item in **Stocked** mode is restocked into Merchandise up to the
   level's **Default max** once it drops to the **Default min**. The consumer panel lists it with **Min and max from**
   "Shop level".
2. A **replenishment setting** on the shop's Merchandise storage, or a **Replenishment rule** of the town's policy, wins
   over the level default. **Unlimited** entries, unique items and goods without an entry are not restocked.
3. The shop's worker walks to the warehouse and back; while it is away the shop page says "0 of 1 present: away
   restocking, processing is lowered (selling goes on)".
4. A Processing shop's Input storage is restocked from its lines' inputs, as for any production structure.

### 3.6 Display stalls

A **display spot** is one block of a shop (a shelf, a barrel, a slab, a counter) where the game server shows one of the
shop's items floating on top, with its name and price. Players right-click it for the item information and
shift-right-click it to buy (the purchase confirmation always opens first). Spots are registered by you, one per block;
the plugin never looks for them. Needs § 1 items 1, 2 and 6 and the plugin's `production.enabled: true`.

**Registering a spot in game** (node `knk.admin.world.production`):

1. Stand in front of the stall, where customers will stand, and look at the block (within 6 blocks).
2. `/knk shop display add <shop id> [label]`, for example `/knk shop display add 12 Front shelf left`. The answer:
   "Display spot #<id> "Front shelf left" (<world> <x> <y> <z>) registered for shop #12, facing <direction>." The item
   faces you, the way you looked when you registered it. Within a second an item floats on the block.
3. Repeat for each block. Spots are filled in the order you register them: register the most visible ones first.
4. Refusals: "Look at the shelf or stall block (within 6 blocks)." (air or too far), "Not registered: That block is
   already display spot #<id> … of shop #<id>.", "Not registered: A shop has at most 100 display spots.", "Not
   registered: shopId must name an existing shop.", from the console "Only players can register a display spot (look at
   the block)."

**In the web app:** **Dashboard → ShopDisplaySpot → Create**: **Shop**, **World**, **X**, **Y** (-64 to 320), **Z**,
**Facing** (North, East, South or West: the way the item faces, towards the customer), **Pinned entry** (optional, an
entry of the same shop), **Order** (empty: after the shop's last spot), **Label**, **Enabled**. The game server picks a
change up within `refresh-minutes` (5), or at once with `/knk shop display reload` ("Display spots re-read: <n>."). A
spot keeps its shop: to move it to another shop, remove it and register it again. A page with the shop's spots is
planned ([#968](https://github.com/PandiO/knk-workspace/issues/968)).

**What a spot shows.** The plugin fills a shop's spots in their order:

1. a spot's own **pin** (below);
2. then the catalogue's **Pinned** entries (§ 4.2), in catalogue order;
3. then the rest: items in stock before sold-out items, then the **best sellers** (most units sold in the last 7 days,
   `best-seller-hours`, from the trade stats, § 5.2), then catalogue order;
4. sold-out items are shown dimmed with "Sold out", or not at all when the shop has **Hide sold-out items**.

Each item is on one spot at most. A shop with more spots than items leaves the last spots empty; a switched-off spot
shows nothing. The choice is made again every 30 seconds (`selection-refresh-seconds`), when the chunk loads, and right
after a purchase at the shop. Price and stock changes show within that time.

**Pins.** `/knk shop display pin <spot id> <catalogue entry id>` makes a spot always show that entry ("Display spot
#<id> … now shows catalogue entry <id>."); `… pin <spot id> none` gives it back to the shop ("… is filled by the shop
again."). The entry must be one of the spot's own shop ("pinnedCatalogueEntryId must be an entry of the spot's own
shop."). The entry ids are in the shop page's **Catalogue** or the ShopCatalogueEntry dashboard. **If the pinned item
can't be shown** (the entry was switched off or deleted, the item is sold out and the shop hides sold-out items, or an
earlier spot already shows it), the spot is not left empty: the shop fills it like an unpinned spot. Deleting the
entry clears the pin.

**Listing and removing.**

1. `/knk shop display list <shop id>`: "Display spots of shop #<id>:" and per spot its id, label, block, facing, pin
   and what it shows now ("Bread", "Flour (sold out)", "nothing", "off"). With no spots: "Shop #<id> has no display
   spots (last read: <when>)."
2. `/knk shop display remove` while looking at the spot's block, or `/knk shop display remove <spot id>`: "Display spot
   #<id> … removed."; its item and label vanish at once. Or delete it on the dashboard (needs `knk.admin.delete`), then
   `/knk shop display reload`.
3. To hide a spot for a while, switch **Enabled** off in the web app (then reload).

**What players see** ([menus player guide § Display stalls](../users/menus-player-guide.md#display-stalls)): the item on
top of the block, not turning, at half a block's size (`item-scale`), and above it the name, "<price> coins each" (or
"Sold out") and "Right-click: information · Shift: buy". They can't take, push, turn or break it; a left-click does
nothing. Right-click opens the item information menu (no purchase); shift-right-click opens the purchase confirmation
for the amount they last chose for that item (1 at first). During a siege the stalls answer "Shops are closed to you
during a siege." The blocks themselves are untouched and stay protected by their region as before.

**The plugin's keys** (`production.shops.displays`, restart):

| Key | Default | Effect |
|---|---|---|
| `refresh-minutes` | 5 | How often the spots are read from the API (a spot made in the web app shows after this) |
| `selection-refresh-seconds` | 30 | How often what the stalls show is chosen again (stock, prices, best sellers) |
| `best-seller-hours` | 168 | The best sellers' window (7 days) |
| `item-scale` | 0.5 | Size of the shown item |
| `label` | true | The floating name and price |
| `hints` | true | The label's line with the two clicks |

## 4. The catalogue and prices

### 4.1 How a price is made

1. An entry's **Static price** wins when you set one.
2. Otherwise the **formula**: the blueprint's base price (the midpoint of its min and max) × the shop's **tax
   modifier** × the level's **price multiplier**, rounded to whole coins (at least 1). A unique item adds 10% of the
   base price per enchantment level (`production.shops.enchantmentPercentPerLevel`, § 6).
3. **Buy-back** = the sell price × the shop's buy-back % (default half), rounded down.

Example: Iron ore with base price 18-22 sells at 20; at level 2 (price × 1.5) with tax modifier 1.1 it sells at 33 and
is bought back for 16. A diamond sword with base price 100, Sharpness 2 and Unbreaking 1 sells at 130 and is bought
back for 65.

These are interim prices; supply and demand pricing comes later
([#120](https://github.com/PandiO/knk-workspace/issues/120)).

### 4.2 Catalogue entries

1. On the shop's page, **Catalogue**: pinned entries first, then by **Order**, with Item, Static price ("9 coins" or
   "Formula"), Stock (Stocked or Unlimited), Pinned, Order and On. **Add an entry**, **Edit the entry for …**,
   **Delete the entry for …**. Or **Dashboard → ShopCatalogueEntry**.
2. An entry is either an **item** (a blueprint, once per shop) or **one unique item** (its instance id, once across all
   shops).
3. **Stock**: **Stocked** sells from Merchandise and is sold out at 0; **Unlimited** never sells out (for a catalogue
   that should sell before the supply chain runs; stackable items only).
4. **Pinned** and **Order** set the order in the offer; pinned entries also go first on the display stalls (§ 3.6),
   after the spots' own pins.
   **Enabled** off takes the entry off the offer.
5. An entry keeps its shop and item: to change the item, delete the entry and add another.
6. Goods in Merchandise without an entry (restocked or processed goods, items bought back) are also on sale, at the
   formula price.

### 4.3 What the shop offers now

**Offer now** on the shop's page is what players will see in the shop menu: each item's price in coins and where it
comes from (static price, formula), its stock ("Unlimited" for an Unlimited entry) and notes: "Pinned", "Sold out" (the
row struck through), "In stock, no entry", "Bought back, resold as this item" with its enchantments. Items without a
price are not listed. The line under the heading says whether the shop buys from players (Production enabled and a type
with categories).

## 5. Watching trade

### 5.1 Sales and buy-backs

On the shop's page, **Sales and buy-backs**: the shop's stock ledger, newest first, pages of 20: Transaction (linked to
the ledger), When, What ("Sale" or "Buy-back"), Units and Note (who, for how many coins).

### 5.2 Trade stats per hour

1. **Trade stats per hour** on the shop's page: pick the **Range** (last 24 hours, 7 days, 30 days) and the **Item**
   (all or one). A line with the totals ("<n> sold for <n> coins, <n> bought back for <n> coins, <n> supplied"), a bar
   chart per UTC hour (hover a bar for its numbers) and the rows per hour and item: Sold, Revenue, Bought back, Paid,
   Supplied (restocked and processed goods into Merchandise), Stock at end.
2. The API rolls up the last completed hours every 10 minutes while Production enabled is on. An hour without trade has
   no row.
3. **Rebuild from the ledger** recomputes the range from the ledger; it gives the same rows each time and also works
   with Production enabled off. Use it after a gap or when a row looks wrong.
4. V1 prices don't use the stats yet.

### 5.3 The town account

1. A town has one account; it opens with the first sale in one of its shops (until then the shop page says "No account
   yet: it opens with the first sale").
2. **Balance and ledger**: Town, Balance, **Ledger check** ("Matches the last ledger entry", or "Does not match: the
   ledger says <n> coins" in warning colour), and the **Ledger** newest first, pages of 25: When, Reason ("Shop
   purchase", "Shop buyback"), Amount, Balance after, Player ("User #<id>"), Source (the shop) and the transaction id.
3. The balance changes only through shop purchases (in) and buy-backs (out). It never goes below 0: a town whose
   account can't pay refuses buy-backs until its shops have sold enough.
4. **No corrections yet.** A shop purchase or buy-back can't be reversed from the transaction page (the API refuses with
   `NotReversible`), and there is no staff adjustment of a town account
   ([#934](https://github.com/PandiO/knk-workspace/issues/934)). A player's own balance can still be corrected as usual
   ([currency admin guide § 2.2](economy-admin-guide.md#22-correcting-a-balance)), but that doesn't touch the town's.
5. Taxes and spending from town accounts come later ([#124](https://github.com/PandiO/knk-workspace/issues/124)).

## 6. Settings

The game settings section `production.shops`. There is no settings card yet: change it through the API. `GET
api/GameSettings` as a staff member with `knk.admin.config`, change `production.shops`, and send the whole production
section back with `PUT api/GameSettings` (the other parts as they came). Saving another production card in the web app
keeps this section.

| Key | Default | Allowed | Effect |
|---|---|---|---|
| `enchantmentPercentPerLevel` | 10 | 0-1000 | A unique item's price rises by this % of the base price per enchantment level |
| `statsLookbackHours` | 2 | 0-168 | The stats job also recomputes this many earlier hours |

No API environment key; the display stalls' `config.yml` keys are in § 3.6.

## 7. A safe test

Run it on a dev server or a test town; it takes about 20 minutes with a REST client (Swagger) for the steps the game
server will make later. The full checklist is the [smoke test § 11](../production-storage-transport-smoke-test.md#11-phase-p10-shops-248-api-687-plugin-menus-688-web-app-tier3).

1. Import the seeds (§ 1). Give two blueprints a base price and a category (for example Bread 18-22 in Food).
2. Create a shop type **Test bakery** with Food as accepted category and a level 1 with Merchandise cap 200, default
   min 10, default max 40.
3. Create a shop **Test bakery shop** of that type in a test district. Check its page: kind, "level 1", two storages,
   the town named under Town account.
4. Add a catalogue entry Bread (Stocked). Put 10 Bread into its Merchandise storage with **Adjust** (stock admin guide).
   **Offer now** shows Bread at 20 coins with stock 10.
5. As the game server (plugin key), buy 3 Bread for a test player: `POST api/Shops/<id>/quote`, then `…/purchase` with
   `confirmed: true`, the `expectedUnitPrice` from the quote and an `idempotencyKey`. The player loses 60 coins,
   Merchandise holds 7, and the town account opens with 60 coins and "Matches the last ledger entry".
6. With Production enabled on, sell 2 Bread back (`sell-quote`, then `sell` with `expectedTotal`): the player gets 20,
   the town account goes to 40, Merchandise holds 9.
7. Press **Rebuild from the ledger** under Trade stats: the hour shows 3 sold for 60, 2 bought back for 20.
8. Clean up: switch the entry off. A shop with ledger history can't be deleted; keep test shops in a test town.

### 7.1 In game (shop menus)

With the game server set up (§ 1 items 6-7) and the shop from steps 1-4 (give **Bread** an Unlimited entry too, or keep
Merchandise stock), as a staff member with `knk.admin.world.production` and some coins:

1. `/knk shop <shop id>`: "Opening shop #<id>...", then the shop menu: your coins, the anvil with type, kind, level,
   town and "Buys items from players", the Sell chest, and Bread as the real item with its price and stock.
2. Click Bread, click the Amount chest to 8, click the name tag, then **Confirm** (green): 8 Bread land in your
   inventory, the chat says what you paid, and the shop page's **Sales and buy-backs** and the town account show the
   sale.
3. Buy again with **Confirm: to your reward inbox**: nothing lands in the inventory; `/inbox` shows it (needs
   Production enabled).
4. Back in the shop menu click the Sell chest, click the Bread stack in your inventory, then the Sell chest: you get
   the buy-back price, the bread is gone, and Merchandise holds it again.

The full in-game checklist (paging, sold out, a changed price, refusals, the flag off) is
[smoke test § 11.2](../production-storage-transport-smoke-test.md#112-steps-plugin-687); the layouts and flows are in
the [shops architecture § 13](../../architecture/shops.md#13-the-game-server-shop-menus-l26-687).

### 7.2 In game (display stalls)

With § 7.1 working and the plugin's `production.shops.displays` block in place (§ 1 item 6), in the test shop with two
or three free blocks (a barrel, a slab), as a staff member with `knk.admin.world.production`; about 10 minutes:

1. Look at the first block and type `/knk shop display add <shop id> Test shelf`: the answer names the spot, and Bread
   floats on the block with "Bread", "20 coins each" and "Right-click: information · Shift: buy".
2. Register a second block; it shows the next item, or nothing when the catalogue has only Bread.
3. Right-click the Bread: the item information menu opens; nothing is bought. Sneak and right-click: the confirmation
   for 1 Bread opens; **Cancel** buys nothing, **Confirm** buys it.
4. `/knk shop display list <shop id>` lists both spots and what they show. Left-click the item: nothing happens.
5. Clean up: look at each block and type `/knk shop display remove`; the items vanish.

The full checklist (pins, sold out and hidden, best sellers, WorldGuard, respawn after a restart, the API, the flag
off) is [smoke test § 11.4](../production-storage-transport-smoke-test.md#114-steps-display-stalls-plugin-and-api-250);
the mechanics are in the [shops architecture § 14](../../architecture/shops.md#14-the-game-server-display-stalls-l29-250).

## 8. Effects on existing data and limits

1. The migration adds tables and one column only; no existing currency posting, balance or stock line changes. The
   ledger's account check accepts the new town legs and every old row.
2. Shops appear in the **ProductionStructure** list and in the town logistics views as consumers (structure type
   "Shop").
3. Switching Production enabled on with Stocked entries and level defaults starts restocking at the next planner run:
   check the town's **Dry run** first ([town logistics admin guide § 5.2](town-logistics-admin-guide.md#52-dry-run-and-run-now)).
4. Limits: a sale has at most 54 lines; up to 100,000 units per line or purchase; a static price up to 1,000,000,000
   coins; a stats rebuild up to 31 days at a time.
5. A sale from the sell menu has at most 7 stacks, and a purchase from the menu at most 64 at a time (the Amount
   steps 1, 8, 16, 32, 64).
6. Unique items are listed in the shop menu but can't be bought in game until
   [#897](https://github.com/PandiO/knk-workspace/issues/897); buy them for a player through the REST client.
7. `AddShopDisplaySpots` adds one table only. Display stall entities are never saved with the world: they go with
   their chunk or a restart and are spawned again by the plugin; the blocks are never changed. At most 100 spots per
   shop, one per block.
8. Not in V1: shopkeepers, upgrade costs for levels, corrections of town accounts, a
   settings card, the town account on the town's page, the shop's kind and type in the shop list.

## 9. Troubleshooting

| What you see | Why | What to do |
|---|---|---|
| An item is missing from **Offer now** | No base price and no static price; the entry is switched off; sold out with **Hide sold-out items** | Give the blueprint a base price or the entry a static price; switch it on |
| A purchase is refused `NoTown` | The shop has no district and no town | Place it in a district, or set the town of a rural shop |
| A purchase is refused `PriceChanged` | The price changed after the quote (level, tax, static price, base price) | Quote again; the player confirms the new price |
| A purchase is refused `ProductionDisabled` | Delivery to the inbox with Production enabled off | Switch it on, or deliver to the inventory |
| A sale is refused `ProductionDisabled` | Selling needs Production enabled | Switch it on |
| A sale is refused `CategoryNotAccepted` | The item's category (or a parent) is not in the shop type's list | Add the category to the type |
| A sale is refused `TownFundsInsufficient` | The town's account holds less than the total | Wait for sales; there is no staff top-up yet (#934) |
| A sale is refused `NoRoom` | Merchandise is full at its cap | Raise the level's Merchandise cap, or let it sell first |
| A sale is refused `InStorage` or `Soulbound` | The unique item is in a storage, not in the player's hands, or it is soulbound | — |
| The shop is never restocked | Production enabled off; the entry is Unlimited or switched off; the level has no **Default max**; no warehouse, stock or road connection; no worker | Check the consumer panel and the town's dry run ([town logistics admin guide § 9](town-logistics-admin-guide.md#9-troubleshooting)) |
| A Processing shop's line says Paused | The shop is Trading | Set **Kind** to Processing |
| Trade stats are empty | Production enabled off (the job doesn't run), or no trade in that range | Press **Rebuild from the ledger** |
| The town account says "Does not match" | The balance and the last ledger entry differ | Don't change data; report it with the account id (there is no correction route yet, #934) |
| `/knk shop` says "Production is off on this server" | The plugin's `production.enabled` is off | Switch it on and restart |
| `/knk shop` says "There is no shop #<id>." | Wrong id | Use the id of the shop's page (`/display/Shop/<id>`) |
| The shop menus fail to load after an update, or a menu says it is unavailable | The API with the shop menu seeds started before the plugin that knows their ids | Deploy the plugin, then restart the API (§ 1 item 7) |
| The shop menu has no Sell chest | The type accepts no categories, or Production enabled is off | Add categories; switch it on |
| The sell menu says "Item identity is off on this server" | `items.identity.enabled` is off | Switch it on in the plugin's `config.yml` |
| A player shows a code from "The shop didn't answer" | The purchase or sale got no answer, even after one retry | Look the key up in the town account ledger (source the shop) and the server log; a sale's items went back to the player |
| The log says a player "left before purchase … was placed" | The player logged out between paying and placing | Give the item back by hand ([stock admin guide](stock-admin-guide.md) or the player's inventory tools) |
| A display spot shows nothing | It is switched off; the shop has fewer items on offer than spots; its items are sold out and the shop hides them; the game server couldn't read the shop | `/knk shop display list <shop id>` says what it should show ("nothing", "off"); check **Offer now** |
| A spot made in the web app doesn't show | The game server reads the spots every 5 minutes | `/knk shop display reload` |
| A stall shows another item than its pin | The pinned entry is switched off, deleted, hidden (sold out with Hide sold-out items) or already shown on an earlier spot | Switch the entry on, or pin another entry; `/knk shop display list` shows the pin |
| `/knk shop display pin` says "must be an entry of the spot's own shop" | The entry belongs to another shop | Use an id from this shop's Catalogue |
| A stall's item faces the wrong way | The facing comes from where you looked when you registered it | Change **Facing** in the web app and reload, or remove the spot and register it again from the front |
| Players in a town region can't click a stall | Stall entities are allowed for everyone in WorldGuard regions, so another plugin is cancelling the click | Check the server log and the other protection plugins; report it with the spot id |
| Two items float on one spot | A stray copy from before a crash or a reload | Walk away and back (the chunk reload removes strays) or restart; report it if it stays |
| A shift-right-click says "This item is sold out." or "Unique items can't be bought in game yet." | The quick buy opens only for items that can be bought | Restock the item; unique items wait for #897 |
| A shop type or shop can't be deleted | The type is used by shops; the shop has stock or ledger history, or its worker is out | Give the shops another type; keep the shop |
