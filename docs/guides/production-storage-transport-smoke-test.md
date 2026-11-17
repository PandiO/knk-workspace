# Production, storage and transport — smoke test

**Status:** Draft from the design (2026-11-16); no steps run. Steps not yet automated (the links tag them).
**Last updated:** 2026-11-16 (draft from the design, territory and phases P1-P12)
**Design:** [specs/production-storage-transport/DESIGN.md](../specs/production-storage-transport/DESIGN.md) (§17
acceptance A01-A27, §18 links) · [territory](../specs/territory/DESIGN.md) · [shops](../specs/shops/DESIGN.md) ·
**Issue:** [PandiO/knk-workspace#22](https://github.com/PandiO/knk-workspace/issues/22)

Common preconditions for every section:

1. Deployed from `next`: knk-web-api with the phase's migrations applied, knk-web-app, the knk-plugin build.
2. Flags on for the test: API game setting `Production:Enabled = true`; plugin `config.yml` `production.enabled: true`.
3. Accounts: **Admin** (holds `*`), **Staff** (holds `knk.admin.world` and `knk.admin.content`), **Member** (a member
   of the test town, no staff nodes), **Visitor** (no town, no staff nodes).
4. Test data: town **Phoenix** with at least two districts, one marked capital; a second town **Rivertown**; a kingdom
   that holds both.

## 1. Territory V1 (#326 API, #689 plugin, #690 web app; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 1.0 Preconditions

1. Game settings: base range 100, power factor 2, capital multiplier 1.5. Phoenix power 50, Rivertown power 10.
2. BlueMap running (in-game maps, #224).

### 1.1 Steps

1. As Admin, open the web app's Phoenix page. **Expected:** effective range shown as (100 + 50 × 2) = 200 for normal
   districts and 300 for the capital district. (A05)
2. Stand 150 blocks outside the nearest edge of a normal Phoenix district region, then cross a chunk border.
   **Expected:** the territory lookup (`/knk territory here`, or the debug line) says Phoenix. At 250 blocks from a
   normal district but 250 from the capital's edge: Phoenix (capital range). At 350 blocks from every district: no
   holder. (A05, G11)
3. Walk along a border that runs diagonally. **Expected:** the holder changes per block column inside the split
   chunk, not at the 16-block chunk edge. (A05)
4. As Admin, create crown land for the kingdom: region captured with the world task, range 80. Stand inside its range
   where Phoenix territory also reaches. **Expected:** the lookup says crown land, and no conflict is created. (G10)
5. Raise Rivertown's power until its territory overlaps Phoenix's (both towns, equal rank). **Expected:** the overlap
   has no holder (contested); one `TerritoryConflict` lists Phoenix, Rivertown and the area. (A05)
6. As Admin, resolve the conflict by awarding the area to Phoenix. **Expected:** the conflict is resolved; the lookup in
   the area says Phoenix.
7. Open BlueMap. **Expected:** outlines for Phoenix, Rivertown and the crown land match the lookup; contested land is
   shown as contested.
8. As Admin, change Phoenix's power to 20. **Expected:** the cache rebuilds (log line); BlueMap and the lookup show the
   smaller territory within a minute.
9. As Visitor, try to change town power or crown land in the web app. **Expected:** refused (403); nothing changes.

## 2. Phase P1: stock core (#97 API, #675 web app; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 2.0 Preconditions

1. Item identity (#141) deployed; the "Uncurated" category holds the generated vanilla blueprints. (A04)
2. Two domain storages for Phoenix, **S1** (capacity 100) and **S2** (capacity 50).

### 2.1 Steps

1. As Staff, open the create form for a storage in the web app on a fresh database. **Expected:** the form comes from
   the seed and saves. (A23)
2. Adjust S1 by +64 oak logs with the adjust dialog. **Expected:** S1 shows 64; the ledger explorer shows one
   `AdminAdjust` move with the staff account. (A01)
3. Move 30 oak logs S1 → S2. **Expected:** S1 34, S2 30; one ledger transaction with a debit and a credit. (A01)
4. Repeat the same move request with the same idempotency key (dev tool or retry). **Expected:** applied once only.
   (A01)
5. Move 40 oak logs S1 → S2 (S2 has room for 20). **Expected:** refused in strict mode; in `Partial` mode 20 move and
   20 are reported as rejected. (A02)
6. Deposit an enchanted sword into S1, move it to S2, withdraw it. **Expected:** the same unit (same id, same
   enchantments) at every step. (A03)
7. Run the reconciler. **Expected:** no differences. (A01)
8. With the clock moved 31 days on a test database, run the roll-up. **Expected:** `Production` moves older than 30
   days are summed per line per day; storage totals are unchanged; other move kinds keep every row. (A22)
9. As Visitor, call a stock move endpoint. **Expected:** refused (403).

## 3. Phase P2: world: rural structures, warehouse, production structure (#91 API, #676 web app, #677 plugin; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 3.0 Preconditions

1. Territory (§ 1) deployed. Placement rules P-1 to P-3 seeded as warnings.

### 3.1 Steps

1. As Staff, create a warehouse inside a Phoenix district with the web app form and region capture. **Expected:** saved
   with `DistrictId` set and `TownId` empty; effective town Phoenix. (A06)
2. Create a rural quarry outside the districts but inside Phoenix territory, picking Phoenix as its town. **Expected:**
   saved with `TownId` set and `DistrictId` empty. (A06)
3. Try to save a structure with both a district and a town. **Expected:** refused with a validation message. (A06)
4. Create a rural structure outside any Phoenix territory. **Expected:** a warning (P-1), saved. (A06)
5. As Admin, set that rule to blocking and try again. **Expected:** refused with the rule's message. (A06)
6. Make the quarry's land contested (§ 1 step 5). **Expected:** the quarry keeps Phoenix as its town, is flagged on its
   page and listed on the conflict. (A07)
7. In game, check the quarry's WorldGuard region. **Expected:** managed kind `RESOURCE_PRODUCTION`, no parent; PvP
   allowed inside. (P2c)

## 4. Phase P3: production engine (#86 API, #678 web app; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 4.0 Preconditions

1. The quarry from § 3 with yield source `Configured`: 60 cobblestone per hour at level 1, output storage capacity 100.
   Two workers.

### 4.1 Steps

1. Wait one sweep interval (or run the sweep from the staff tools). **Expected:** cobblestone accrues at the configured
   rate; the cycle trace lists the base rate and each modifier (additions first, then multiplications). (A08)
2. Raise the quarry to level 2. **Expected:** the trace shows the level multiplier; the area cap grows. (A09)
3. Try to set level 11. **Expected:** refused; levels are 1-10. (A09)
4. Let the output storage fill to 100. **Expected:** the line stalls without accruing; the dashboard shows "full". (A08)
5. Empty the storage. **Expected:** production resumes from that moment, with no catch-up for the stalled time. (A08)
6. Turn `Production:Enabled` off and wait one interval. **Expected:** nothing accrues. (A21)

## 5. Phase P4: yield areas and surveys (#138 API, #679 plugin, #680 web app; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 5.0 Preconditions

1. A logger with a captured radius area over a forest, yield source `Hybrid`; a second logger whose area overlaps the
   first one's; the quarry from § 4 left on `Configured`.

### 5.1 Steps

1. Create the logger. **Expected:** a survey runs on creation; the survey viewer lists trees by species and size; the
   production lines come from the survey. (A10)
2. As Staff, run `/knk production survey <logger>` and the web app "survey now" button. **Expected:** a new survey row
   each time. (A10)
3. Check the quarry (`Configured`). **Expected:** no survey has ever run for it. (A10, G5)
4. Leave the server running over the daily survey time with the logger's chunks loaded. **Expected:** one scheduled
   survey that day. (A10)
5. Cut down a large part of the forest. **Expected:** a resurvey after the notable-change threshold; lower rates. (A10)
6. Check a tree inside both loggers' areas. **Expected:** each logger counts half of it. (A11)
7. Try to capture an area larger than the level 1 maximum for the kind. **Expected:** refused with the maximum. (A11)
8. Add a Hybrid pin (always produce apples at 5 per hour). **Expected:** the line exists after the next materialization
   whatever the survey says. (A10)
9. Watch the tick metrics during a survey. **Expected:** no main-thread spike from block reads.

## 6. Phase P5: transport core, simulated (#79 API, #681 plugin, #682 web app; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 6.0 Preconditions

1. The quarry connected by road to the Phoenix warehouse; lanes measured with `/knk logistics lanes measure`. A second
   producer with no road.

### 6.1 Steps

1. As Staff, create a manual order of 40 cobblestone from the quarry to the warehouse. **Expected:** the order goes
   through its lifecycle; the goods sit in transit storage while carried; the ledger balances at every step. (A12)
2. While one of the two workers carries the order, read the quarry's trace. **Expected:** output at 50%. (A12)
3. Create two orders at once. **Expected:** both workers away; output 0% until one returns. (A12)
4. Compare the trip time with the measured route length ÷ walking speed. **Expected:** they match. (A12, G14)
5. Fill the producer without a road. **Expected:** it stops when full; no automatic transport; warnings for the missing
   road and the full storage. (A13)
6. Cancel an order midway. **Expected:** goods return to the sender; ledger balanced. (A12)

## 7. Phase P6: terminals, displays, menus, commands (#683 API, #74 plugin; tier:2)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 7.1 Steps

1. As Staff, bind a chest in the warehouse as a terminal and another as a display. Open the terminal as Member.
   **Expected:** a paged menu of the storage; taking and putting items are ledger moves; the chest stays empty. Open
   the display: a read-only sample with the fill level. (A14)
2. As Member standing in Phoenix, open the main menu and click "Structures". **Expected:** the overview lists
   structures with search and filters; the town filter is set to Phoenix. Clear it: all structures. In the wilderness
   the filter starts empty. (A24)
3. Click the quarry in the overview, and right-click a quarry worker NPC. **Expected:** both open the structure menu
   with exact rates, storage contents, workers and warnings, and a transport orders entry. (A25, A26)
4. As Visitor, open the same structure menu. **Expected:** only name, kind, town, level, products and status; no
   orders entry. (A25)
5. As Member, look for action buttons. **Expected:** none. As Staff: survey now, dry run, cancel or retry an order,
   show the area outline; each works. (A26)
6. On a fresh database, open all three menus. **Expected:** they open from the seeded menu content. (A27)

## 8. Phase P7: item delivery, reward inbox, deposit/withdraw (#60 API, #684 plugin; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 8.1 Steps

1. As Admin, grant a kit to Member while Member is offline. **Expected:** at login the kit is in `/inbox`, not on the
   ground. (A15)
2. Grant a lootbox reward to Member with a full inventory. **Expected:** it goes to the inbox with a message. (A15)
3. Claim from the inbox with room for half the items. **Expected:** half claimed, the rest stays. (A15)
4. Fill the inbox to the hard cap, then grant one more item. **Expected:** the overflow is logged as `InboxOverflow` to
   `SYS_LOSS`, and Member gets a loss notification and a near-cap warning before that. (A15)
5. As a premium-tier player, check the cap. **Expected:** higher than for Member. (A15)
6. Move the clock 30 days on a test database. **Expected:** reminders were sent; expired items are moved out as
   `InboxExpired`. (A15)
7. Turn `production.enabled` off and grant a kit. **Expected:** today's delivery path (#261) still works.

## 9. Phase P8: player harvesting and block regeneration (#685 API, #134 plugin; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 9.1 Steps

1. As Member, mine iron ore inside the quarry's yield area. **Expected:** the ore drops; the block becomes the neutral
   placeholder (stone); the harvest is reported and the pool drops. (A16)
2. Wait for the regeneration time. **Expected:** the ore comes back. (A16)
3. Cut a tree inside the logger's area. **Expected:** a sapling placeholder, then the exact tree restored. (A16)
4. Harvest until the pool reaches its floor (0.5). **Expected:** further breaks are refused with a message. (A16)
5. Check the ledger. **Expected:** `PlayerHarvest` moves with the worker's share to Output; the town's net output is
   positive. (A16)
6. As Visitor, break blocks where the rules deny it. **Expected:** refused, nothing reported.

## 10. Phase P9: town logistics (#127 API, #686 web app; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 10.1 Steps

1. As Staff, apply the town policy template for Phoenix's size. **Expected:** rules shown in the editor. (A17)
2. Run a planner dry run. **Expected:** a plan with an explanation per decision; nothing moves. (A17)
3. Wait for the 10-minute planner run. **Expected:** warehouses reserve stock; a consumer collects with its own worker
   (worker away, as in § 6). (A17)
4. Try to collect the same reservation twice. **Expected:** refused. (A17)
5. Make a good scarce. **Expected:** higher-priority consumers are served first. (A17)

## 11. Phase P10: shops (#248 API, #687 plugin menus, #688 web app; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 11.0 Preconditions

1. A Phoenix shop with a static catalogue; the developer's V1 shop menu templates imported; Phoenix's town account.

### 11.1 Steps

1. As Member, open the shop menu (`/knk shop <id>` until P11). **Expected:** info header and paged catalogue; prices at
   the midpoint base price with the shop's modifiers. (A18)
2. Buy an item. **Expected:** a confirmation first; then coins and stock move together; the coins go to Phoenix's town
   account. (A18)
3. Buy with too few coins. **Expected:** refused; nothing moves. (A18)
4. Sell items in the sell menu. **Expected:** the buy-back price per item and the total; confirmation; coins paid. (A18)
5. Open the web app trade stats after an hour. **Expected:** hourly stats per shop and blueprint match the ledger.
   (A18)

## 12. Phase P11: shopkeepers (#249; tier:2)

*Draft from the design (2026-11-16); the link updates it to what was built and tags the automated steps.*

### 12.1 Steps

1. Walk towards the shop. **Expected:** the shopkeeper spawns within 48 blocks, looks at you and greets you (with a
   cooldown). Right-click: the shop menu for that shop. (A19)
2. Walk more than 64 blocks away and wait 10 s. **Expected:** the shopkeeper despawns. (A19)
3. Restart the server, then kill the server process and start it. **Expected:** exactly one shopkeeper each time. (A19)
4. Try to hurt the shopkeeper. **Expected:** invulnerable. (R5)

## 13. Phase P12: display stalls (#250; tier:2)

*Draft from the design (2026-11-16); the link updates it to what was built and tags the automated steps.*

### 13.1 Steps

1. Stand at a display stall. **Expected:** items shown as item display entities. (A20)
2. Right-click an item. **Expected:** the shop item information menu, no purchase. (A20)
3. Shift-right-click. **Expected:** quick buy with a confirmation. (A20)
4. Sell out an item. **Expected:** greyed out. (A20)
5. Reload the chunk. **Expected:** no duplicate display entities. (A20)
