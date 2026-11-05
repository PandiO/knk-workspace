# Shops, shopkeepers and display stalls — Design

**Status:** Draft. Written from the developer's voice design review of 2026-11-05
([decision record](../production-storage-transport/DECISIONS_2026-11-05.md) §6-8). Shops, shopkeepers and display
stalls are **[V1]** of the production, storage and transport feature. Nothing is implemented. Tags: **[V1]**,
**[Later]**, **[Open]** (as in the production [DESIGN](../production-storage-transport/DESIGN.md) header).
**Last updated:** 2026-11-05
**Issues:** parent [#22](https://github.com/PandiO/knk-workspace/issues/22) (`[KNG-83]`); phases
[#248](https://github.com/PandiO/knk-workspace/issues/248) (P10 Shops),
[#249](https://github.com/PandiO/knk-workspace/issues/249) (P11 Shopkeepers),
[#250](https://github.com/PandiO/knk-workspace/issues/250) (P12 Display stalls). Shops were deferred to
[#56](https://github.com/PandiO/knk-workspace/issues/56) (`[KNG-91]`) before rev. 3.
**Related:**
- [production DESIGN](../production-storage-transport/DESIGN.md) §4 (stock model), §10 (shops summary);
- [PRODUCTION_KINDS](../production-storage-transport/PRODUCTION_KINDS.md) §5 (level pattern);
- [TOWN_LOGISTICS](../production-storage-transport/TOWN_LOGISTICS.md) §5 (reserve and collect), §7 (pricing hook);
- [NPC platform](../npc-platform/DESIGN.md) (NPC lifecycle and reliability);
- [lootboxes DESIGN](../lootboxes/DESIGN.md) (display entities, non-persistent);
- [legacy inventory menu screens](../legacy/inventory-menu-screens.md) (V1 shopkeeper "Products of X", sell menu).

**Revision history**

- **Draft (2026-11-05):** first version, from the decision record §6-8.

## 1. Purpose and scope

A shop is where players buy goods, and where they can sell goods back. Shops sit at the end of the supply chain:
producers → warehouses → shops. They are in the first version of the feature, so the supply chain has a player-facing
end from the start.

This design covers:

- the shop model, kinds and storages (§2);
- buying from and selling to shops (§3);
- interim pricing (§4) and shop levels (§5);
- the shopkeeper NPC (§6);
- display stalls (§7);
- menus (§8).

## 2. Shop model [V1]

### 2.1 Shape

- **`Shop : Structure`** (TPT subtype, production DESIGN §3.3).
- Storages (production DESIGN §4.1, kind `Domain`):
  - **Input** (purpose `Input`): raw goods for processing.
  - **Merchandise** (purpose `Merchandise`): goods for sale.
- Fields:
  - `Kind`: `Processing` or `Trading` (§2.2);
  - `ShopType`: a catalogue row (bakery, blacksmith, weaponsmith, general store, market stall, …) with its
    **accepted categories** (§3.2);
  - `Level` (§5);
  - `TaxModifier` (§4);
  - `BuyBackPercent` (default 50%, §4);
  - its own **worker** (§2.4);
  - **shopkeeper spawn location** (§6);
  - registered **display spots** (§7).

### 2.2 Kinds

- **Processing shops** (bakery, blacksmith): turn inputs into goods on production lines, then sell them. A processing
  line is a production line with inputs (production DESIGN §10). It reads from Input and writes to Merchandise.
- **Trading shops** (general store, market stall): sell goods as they are.
- **Every shop can also buy from players and resell**, processing shops included (§3.2).

### 2.3 Build order inside the same update

1. **Static admin catalogue first.** Admins add blueprints or item instances to a shop at a **static price**. This is
   a fallback, and a new gameplay mechanic before the supply chain is live.
2. Then, in the same update:
   - **restocking** from the warehouse by the shop's own worker (§2.4);
   - **processing** (for example flour → bread);
   - **players selling** to shops (§3.2).

### 2.4 Shop worker and restocking

- A shop has its **own worker**, like a producer (production DESIGN §7.7).
- The town's planner **reserves** stock at the warehouse when the shop's Merchandise or Input falls to its reorder
  point. The worker **collects** it (TOWN_LOGISTICS §5).
- While the worker is away, the shop's own output (processing) is lowered. Selling to players continues.
  Proposed; the decision record says "output or service is lowered" without detail for shops.
- Shop levels set default reorder points and target levels; admins can override them.

## 3. Buying and selling

### 3.1 Players buy [V1]

- A purchase is **one database transaction** with a currency transaction (player → shop or town account) and a
  stock transaction (`Merchandise → SYS_WORLD`, reason `Trade` or a new `ShopSale`), while the plugin places the item
  (production DESIGN §4.3).
- **Every purchase requires a confirmation**, whatever the channel: shop menu, display stall quick buy, or any
  later channel.
- A purchase fails cleanly when stock, coins or inventory space run out. Nothing is taken without the item.
- Who receives the coins (a town account, a system account, a later owner) follows the currency design. Town accounts
  are [Later] (TOWN_LOGISTICS D-L5). Until then: a system account. **[Open]**

### 3.2 Players sell [V1]

- **Accepted categories per shop type.** A weaponsmith buys weapons only. Items outside the categories are refused
  with a reason.
- Items must resolve to a blueprint or an item instance (production DESIGN §8).
- A sold stackable item enters Merchandise as a `StockLine` (`SYS_WORLD → Merchandise`).
- A sold **unique item** becomes a `StockUnit` in Merchandise, with its enchantments intact, and goes back on sale as
  that exact item. Example: a player sells an enchanted diamond sword to the weaponsmith; it is resold as that sword.
- The player is paid the buy-back price (§4) in the same database transaction.
- Merchandise capacity applies (raw units, production DESIGN §4.4). A full shop refuses the sale.
- **[Open/Later]** whether selling to a shop should be more or less attractive than selling to a marketplace vendor.
  The developer is unsure.

## 4. Interim pricing [V1]

Until the supply-and-demand pricing model (TOWN_LOGISTICS §7, [#120](https://github.com/PandiO/knk-workspace/issues/120)):

```
sell price    = static catalogue price, when an admin set one
              | blueprint base price × shop tax modifier × shop level modifier
buy-back      = sell price formula × BuyBackPercent             (default 50%)
unique items  = base price + a value per enchantment, then the same modifiers
```

- A static catalogue price always wins.
- **Blueprint base price:** `ItemBlueprint` has `BasePriceMin` and `BasePriceMax` today. Proposed: the midpoint, as in
  the TOWN_LOGISTICS §7 placeholder. **[Open]**
- **Shop tax modifier:** a per-shop value in V1. A town-wide tax rule is [Later] (TOWN_LOGISTICS §4). **[Open]**
  whether the later town tax replaces or multiplies the shop value.
- **Shop level modifier:** the level's price multiplier (§5).
- **Value per enchantment** for unique items: a value per enchantment and level, set by admins. Detail to design in
  P10. **[Open]**

## 5. Shop levels [V1]

Shop levels use the **same level-definition pattern and admin UI** as production kinds
([PRODUCTION_KINDS §5](../production-storage-transport/PRODUCTION_KINDS.md#5-levels-note-11-v1)). A `ShopTypeLevel`
row sets:

- processing speed (cycle length multiplier);
- yield;
- input cost per cycle;
- the price multiplier (§4);
- storage caps (including `UnitsPerSlot` for bound containers);
- default reorder points and target levels.

The number of levels per shop type is free (concept v0.2 had 20 per shop; production kinds have 10).

## 6. Shopkeeper NPC [V1]

- A **human or villager NPC** on the [NPC platform](../npc-platform/DESIGN.md).
- Its **spawn location is stored on the shop** model.
- **Default:** it **stays in place** and **looks at nearby players** inside the shop.
- **Option:** it roams within the shop region.
- **Greeting:** it greets players who enter the shop region ("Hello there, <username>"), with a cooldown per player.
  Cosmetic only.
- **Right-click** opens the shop menu (§8).
- **Lifecycle** (NPC platform, "NPC lifecycle and reliability"): a non-persistent entity, spawned on demand when a
  player is near and despawned when nobody is; one live entity per NPC id; orphans removed on chunk load. V1 suffered
  from disappearing and duplicated shopkeepers; this is the fix.

## 7. Display stalls [V1]

- Display spots (shelves, stalls) are **registered explicitly**, like containers (production DESIGN §6.2). They are
  never found by scanning. Admins register them in the web app with a world capture, or in game while looking at a
  block.
- Each spot is rendered as a **Paper item display entity** (`ItemDisplay`). Preferred over item frames: no rotation,
  can't be knocked down, can carry a floating price label (`TextDisplay`). This is the same technique as lootbox
  boxes ([lootboxes DESIGN](../lootboxes/DESIGN.md) D3): non-persistent, with an `Interaction` entity for clicks.
- **Selection.** Not every shop can show its whole catalogue:
  1. **admin pins** first;
  2. remaining spots filled by the system: in-stock items and best sellers first;
  3. sold-out items are hidden or greyed out (admin setting per shop; proposed default: greyed out). **[Open]**
- **Right-click** a displayed item → the **shop item information** menu (no purchase).
- **Shift-right-click** → **quick buy**, **always with a confirmation**.

## 8. Menus [V1]

- Built on the inventory menu engine (`knk-paper/.../paper/menu/`).
- **The developer will supply V1 inventory menu templates** for the shop menus. Build on those; don't design the
  layouts from scratch.
- **Shop menu:** a header with shop info (name, level, owner) and the catalogue, paged, below. Clicking an item opens
  its information menu or the purchase confirmation.
- **Shop item information menu:** item details, price, stock; a buy button that opens the confirmation.
- **Purchase confirmation:** item, amount, price; confirm or cancel.
- **Sell menu:** put items in, see the buy-back price per item and the total, confirm.

## 9. Admin and insight (web app first)

- FormConfig CRUD: shop types (accepted categories, levels), shops, catalogue entries (static price, pin), display
  spots, shopkeeper spawn location.
- Shop detail: storages, catalogue, sales and buy-backs (ledger filtered by the shop), worker state, reservations.

## 10. Later

- Supply-and-demand pricing ([#120](https://github.com/PandiO/knk-workspace/issues/120)).
- Ownership and payouts: player-owned shops ([#56](https://github.com/PandiO/knk-workspace/issues/56)).
- Town treasury accounts and town tax ([#124](https://github.com/PandiO/knk-workspace/issues/124)).
- Marketplace vendors and how they compare with selling to shops (§3.2).

## 11. Open questions

| # | Question | Proposal |
|---|---|---|
| S-1 | Selling to a shop vs a marketplace vendor: more or less attractive? | Open (developer unsure). |
| S-2 | Which base price: `BasePriceMin`, `BasePriceMax` or the midpoint? | Midpoint. |
| S-3 | Who receives purchase coins before town accounts exist? | A system account. |
| S-4 | Value per enchantment for unique items | Admin table per enchantment and level. |
| S-5 | Sold-out items on display stalls | Greyed out by default, hidden as an option. |
| S-6 | What a shop's absent worker lowers | Processing output only; sales go on. |
| S-7 | Shop tax modifier vs the later town tax rule | Keep the shop value; the town tax multiplies it. |
