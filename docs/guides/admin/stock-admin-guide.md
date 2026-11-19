# Stock — Admin Guide

**Status:** Current · **Last updated:** 2026-11-19 (§ 2.2: the default storages of warehouses and production structures, P2 #91, docs #830); 2026-11-19 (first version, stock core P1 #97/#675, docs PandiO/knk-workspace#820)
**Checked against:** knk-web-api `next` `2e7d4e81`, knk-web-app `next` `9f46cb49` (not released; the manual steps of the
[smoke test § 2](../production-storage-transport-smoke-test.md#2-phase-p1-stock-core-97-api-675-web-app-tier3) have
not been run live yet)
**Related:** [production DESIGN § 4](../../specs/production-storage-transport/DESIGN.md#4-stock-model) (the rules),
[stock core architecture](../../architecture/stock-core.md) (ledger, locking, reconciler, recovery),
[stock API contract](../../specs/api/API_CONTRACT_STOCK.md), [staff web app guide](staff-web-app-guide.md) (the
dashboard and forms in general), [dashboard access](dashboard-access-admin-guide.md), [item identity](item-identity-admin-guide.md)
(the blueprints stock is counted in)

The stock core counts the game's goods. Every item lives in a **storage** (a warehouse of a structure, a town's stock,
a player's or a clan's storage), and stock only ever **moves** from one storage to another; every move is written to
the **stock ledger**. Five system storages stand for the outside world: `SYS_PRODUCTION` (made), `SYS_CONSUMPTION`
(used up), `SYS_LOSS` (lost), `SYS_ADJUSTMENT` (staff corrections) and `SYS_WORLD` (in a player's hands). Nothing in
game uses stock yet; for now staff set up storages and correct stock in the web app, and later production phases
(production, transport, the inbox, shops) will move stock on their own.

## 1. What you need

1. **knk-web-api** with migration `AddStockCore` applied ([production installation § 5.3](../production-installation.md)
   item 6). It creates the stock tables, gives every item blueprint a storage weight of 1 and creates the five system
   storages.
2. **knk-web-app** of the same `next` (or later).
3. **Seeds.** As content staff, import the form seeds `Storage` and `StockTransaction` and the display seeds `Storage`
   and `StockTransaction` from the form and display configuration lists (Import / seeds) and make them the default
   ("make default").
4. **Item identity** deployed ([item identity admin guide](item-identity-admin-guide.md)): stock is counted per item
   blueprint, so the blueprints must exist (the "Uncurated" category holds the vanilla ones).
5. **Nodes:**

   | To | Node(s) |
   |---|---|
   | See storages and their stock, open the Stock ledger, run the reconciler | `knk.admin.world` **or** `knk.economy.admin` |
   | Create and edit storages | `knk.admin.world` and `knk.admin.content` |
   | Delete a storage | `knk.admin.world` and `knk.admin.delete` |
   | Adjust stock, move stock, reverse a transaction, roll up the ledger | `knk.economy.admin` |

   `knk.economy.admin` is **not** under `knk.admin`: `knk.admin.*` doesn't give it, only `*` or an explicit grant
   (player profile → **Permissions** tab → **Grant/deny node**, or a group's permissions; see the
   [ranks and permissions guide](ranks-permissions-moderation-admin-guide.md)). Give it only to the staff who may change
   stock.
6. **No switch.** Storages, the dialogs and the ledger work whether `production.enabled` is on or off. The switch
   (Game settings, section `production`) only starts the scheduled reconciler and roll-up (§ 6).

## 2. Storages

### 2.1 The storage list

Admin → **Dashboard**, type **Storage**. Columns: Kind, Purpose, Holder, Total units (against the cap, "0 / 100"),
Distinct items and Locked. The five system storages show kind Virtual and their key as holder; they can't be edited
or deleted.

### 2.2 Creating a storage

On the Storage dashboard press **Create** (the seeded form, two steps):

1. Step **Storage**: **Name**; **Kind**: Domain (a structure, town or district), Player, Clan or Transit (a transport
   order's cargo, for later phases); **Purpose** (General, Output, Input, Delivery, Merchandise, Inbox, Stash, Vault;
   a label for now); and the holder that matches the kind: **Domain**, **Player** or **Clan** (Transit has none).
   Fill in only that one; a holder that doesn't match the kind is refused ("A Domain storage has only DomainId; remove
   UserId.").
2. Step **Capacity and lock**: **Max units** (raw units, empty = no cap), **Max distinct items** (how many different
   items it may hold, empty = no cap), **Units per container slot** (stored for later; no effect yet), **Locked
   until** and **Lock reason**. Transit storages take no cap.
3. **Submit.**

Warehouses and production structures (production P2, in `next`) get their storages without this form: a warehouse
its "<name> - deliveries" storage, a production structure its "<name> - output" storage, both Domain storages held by
the structure; their pages list every storage they hold. See the [warehouses and production structures admin
guide](production-world-admin-guide.md).

A storage's kind and holder can only change while it has no stock and no ledger history. A storage with stock or
history can't be deleted either: the ledger keeps every storage it names. If someone else saved the storage (or stock
moved) since you opened the form, saving says the storage changed: reload and try again.

### 2.3 The storage page and its Stock panel

View a storage (dashboard row → View). Below the details is the **Stock** panel:

1. **Holder** ("Phoenix (Domain, General)", the holder a link to its page).
2. **Capacity used**: "64 of 100 raw units (64 %)". Capacity counts **raw units × storage weight**: 10 stone with weight
   2 use 20. With no cap it reads "… raw units; no cap"; a system storage "System storage: no cap". When a cap was
   lowered below what is stored it adds "(over its cap: removals only)": nothing is thrown away, but nothing more goes
   in until it is under the cap.
3. **Total units** and **Distinct items** (stackable lines plus unique items).
4. **Lock**: "Not locked", or "Locked until <time>: <reason>" with "A locked storage refuses moves in and out (result
   Locked) until the lock ends."
5. **Stock lines**: per blueprint the Amount, its Storage weight, the Capacity used and when it was Updated. The amount
   is a link ("The moves that made this number") to the Stock ledger, § 4. Each line has **Adjust** and **Move**.
6. **Unique items**: items that keep their identity (an enchanted sword), as "#<item instance id>" with blueprint and
   name; the id links to the item's moves in the ledger. Each has **Take out**.
7. Buttons **Ledger** (this storage's moves), **Adjust stock** and **Move stock**.

Without `knk.economy.admin` you see the same page, but Adjust stock, Move stock and each line's Adjust, Move and Take
out are off, with the title "Requires knk.economy.admin".

**Storage weight.** Every item blueprint has a storage weight (default 1); the blueprint list on the dashboard shows it
in a Storage weight column. The seeded ItemBlueprint form has no field for it yet: set it through the API
(`PUT api/ItemBlueprints/<id>` with the blueprint's current body plus `"storageWeight": 2`). Changing a weight changes
the capacity use of every storage holding that blueprint at once; a storage that ends up over its cap takes removals
only.

## 3. Changing stock: the Adjust and Move dialogs

Both dialogs show the result in place and leave the dialog open until you press **Close**, which reloads the page.
A refusal is a normal result, not an error: the dialog says what moved and, for the rest, why.

### 3.1 Adjust stock

Use it to correct a count: stock comes from or goes back to `SYS_ADJUSTMENT`, reason "Admin adjust".

1. **Adjust stock** (or a line's **Adjust**, which fills in the blueprint; a unique item's **Take out** fills in its id
   and −1).
2. **Item**: "Stackable item (blueprint)" → search and pick the **Blueprint**; or "Unique item (item instance)" → type
   the **Item instance id**.
3. **Change (raw units)**: "+64" puts 64 in, "-10" takes 10 out. A unique item is +1 (into this storage) or −1 (out).
4. **Note** (required: say why). **Adjust** stays off without it.
5. **Adjust.**

### 3.2 Move stock

Use it to move stock between two real storages (or to and from a system storage, for example a deposit from
`SYS_WORLD`).

1. **Move stock** (or a line's **Move**, which fills in this storage as From and the blueprint).
2. **Reason**: every reason of the ledger except "Admin adjust" (the Adjust dialog) and "Correction" (Reverse);
   default Distribution.
3. **Mode**: **All or nothing** (default: every line in full or nothing at all) or **Partial** (each line moves what
   fits; the rest stays where it was).
4. **Lines**: per line **From storage**, **To storage** and either **Blueprint** with **Amount (raw units)**, or tick
   "Unique item (by item instance id)" and type the **Item instance id**. **Add line** for more; **Remove line n**.
   All lines are one ledger transaction.
5. **Note** (optional). **Move.**

### 3.3 Reading the result

| Result | Meaning |
|---|---|
| "Applied (transaction #…): 64 moved." | everything moved; the transaction id links to it |
| "Partially applied (transaction #…): 18 moved, the rest refused." | Partial mode: some moved, the rest stayed in the source |
| "Rejected: nothing moved and no transaction was written." | nothing changed |

Under each line: "requested 40, accepted 18, refused 22" and the reason for the refused part:

| Reason | What it means | What to do |
|---|---|---|
| Capacity full: the storage is full (capacity in raw units × storage weight) | the target has no room for that many raw units | move less, use Partial, raise Max units, or move something out first |
| Distinct cap reached: the storage holds its maximum number of distinct items | the target already holds Max distinct items different items and this one is new there | raise Max distinct items or empty a line |
| Not enough stock: not enough stock in the source | the source holds less than asked (or the unique item isn't there) | check the source's lines |
| Locked: a storage is locked | the source or the target is locked; a lock stops moves out as well as in | wait, or clear Locked until in the storage's edit form |
| Other line rejected: another line of this all-or-nothing request was refused | this line was fine, another one wasn't | fix the other line, or use Partial |

**Pressing again after a lost answer is safe.** Each dialog sends one key with its request; if the network dropped the
answer and you press again, the API recognises the key and shows the first result ("This key was used before: the
first result is shown and nothing moved again.") instead of moving twice. If you change the request and the key was
already used, the dialog says the key was used for a different request: close the dialog and start again.

Errors (red, not a result) mean the request itself was wrong: no lines, the same storage on both sides, an unknown
blueprint or item instance, an adjustment without a note. Nothing moved.

## 4. The Stock ledger

Admin → Economy → **Stock ledger** (`/admin/stock/ledger`). Three views, chosen at the top:

1. **Transactions**: one row per request: id, reason, actor ("User #12 (web)"), move count, amount, note, time.
2. **Moves**: one row per line: transaction, from and to storage (links), item, amount.
3. **Roll-ups**: old production moves summed per day (§ 6): day, reason, from → to, item, Amount, Moves, Rolled up.

**Filters**: Storage id, Blueprint id, Item instance id, Transaction id, Reason, Actor user id, Source type, Source
reference, From (date) and Until (date, inclusive); each view uses the ones that apply to it. Press **Apply filters**;
**Clear** removes them. The filters are kept in the page address, so you can reload, bookmark or share a filtered view.
The filters take ids, not names: a storage's id is on its page and in the dashboard.

**Drill-down from a line.** Click a stock line's amount on a storage page: the ledger opens on Moves for that storage
and blueprint, and above the table: "Oak log in S1: line amount 15" and "Moves in 65 − moves out 50 = 15 (matches the
line)" (plus "+ roll-ups …" when old production moves were rolled up). The column "Amount (± this storage)" shows each
move as + (in) or − (out). If the summary does not say it matches, run the reconciler (§ 4.2).

**Unique items.** Clicking a unique item's "#<id>" opens Moves filtered by that item instance id: every storage the
item has been in.

### 4.1 A transaction's page and Reverse

Open a transaction by its "#" link. The **Ledger entry** panel shows Reason, Mode, Actor, When, Source, Note,
"Reverses" (for a correction) and **Reversed by** ("Not reversed" or the correction's link), and the **Moves** table
(line, from, to, item, amount).

**Reverse** undoes a transaction without editing it: type a note and press **Write the correction**. It writes a new
transaction, reason Correction, that moves every move back, all or nothing. A transaction is reversed once; after that
the button is gone. If the stock has moved on (the target no longer holds it, or a storage is locked) the correction is
"Rejected" with the reason, and nothing changes: correct the count with Adjust stock instead. Reverse needs
`knk.economy.admin` (off with "Requires knk.economy.admin" otherwise).

### 4.2 Ledger health

At the bottom of the Stock ledger:

1. **Run the reconciler** checks that every item's amounts over all storages add up to zero, that every stock line
   equals the moves that made it, that every unique item is where its last move took it, and that every storage's
   totals match its lines. "Clean: <n> lines and <m> unique items match the ledger." is good. "Differences found: the
   ledger and the stock disagree." lists what is off; this only happens when someone changed stock outside the ledger
   (SQL by hand, a partial restore). See the [architecture § 11](../../architecture/stock-core.md#11-recovery) for the
   fix; don't edit stock tables by hand.
2. **Roll up old production moves now** (needs `knk.economy.admin`): "Roll-up done: <x> transactions and <y> moves from
   before <cutoff> became <z> roll-up rows. Totals are unchanged."

## 5. Effects on existing data

1. The migration adds tables and one column; it changes no existing record except giving every item blueprint a
   storage weight of 1.
2. Nothing in game reads or writes stock yet; players see nothing.
3. Ledger rows are never edited or deleted, except production moves older than 30 days, which the roll-up replaces by
   day totals (§ 6). Storages named in the ledger can't be deleted.

## 6. Scheduled work and the roll-up

With `production.enabled` on (Game settings, section `production`), the API checks the ledger by itself: the
reconciler every 6 hours and the roll-up once a day, the first time about an hour after the API starts. A difference is
logged as a warning ("Stock reconciler: …"); a roll-up that did something as information ("Stock roll-up: …"). With
the switch off nothing runs on its own; the buttons in § 4.2 work either way.

The **roll-up** keeps the ledger small: Production and Production input moves from whole days more than 30 days ago are
summed per day, reason, storage pair and item into one roll-up row, and those transactions and moves are removed.
Every other reason keeps every row. Stock amounts don't change and the drill-down still adds up (it counts the roll-up
rows). A rolled-up transaction can no longer be opened or reversed.

## 7. A safe test

On a test database, with the seeds imported:

1. Create two Domain storages S1 (Max units 100) and S2 (Max units 50) for one town.
2. On S1, **Adjust stock** +64 oak log with a note. Expected: Applied; S1 Oak log 64, "64 of 100 raw units (64 %)".
3. On the Oak log line, **Move** 30 to S2. Expected: Applied; S1 34.
4. Move 40 more to S2, All or nothing. Expected: Rejected, Capacity full. Again with Partial. Expected: Partially
   applied, 20 moved.
5. Click S1's Oak log amount. Expected: the ledger's Moves view says the moves match the line.
6. Open the first move's transaction and **Reverse** it. Expected: a Correction; if S2 no longer holds the stock, it is
   Rejected and nothing changes.
7. **Run the reconciler.** Expected: Clean.

The full check, every step tagged with its automated test, is [smoke test § 2](../production-storage-transport-smoke-test.md#2-phase-p1-stock-core-97-api-675-web-app-tier3)
(§ 2.1 through the API, § 2.2 in the web app).

## 8. Troubleshooting

| You see | Cause | Fix |
|---|---|---|
| No Storage type on the dashboard, or no Stock ledger in the sidebar | you have neither `knk.admin.world` nor `knk.economy.admin` | § 1 item 5 |
| Adjust stock and Move stock are off ("Requires knk.economy.admin") | you can read stock but not change it | grant `knk.economy.admin` (`knk.admin.*` doesn't include it) |
| Create or Edit on the Storage dashboard is refused | create and edit need `knk.admin.world` **and** `knk.admin.content` | grant the missing node |
| Create on the Storage dashboard has no two-step form | the `Storage` form seed is not imported or not the default | § 1 item 3 |
| "Kind and holder can't change once the storage has stock or ledger history." | the storage has been used | create a new storage and move the stock over |
| "This storage can't be deleted: it holds stock or has ledger history …" | the ledger keeps every storage it names | leave it; lock it if it should not be used |
| "System storages can't be edited." | you opened a `SYS_…` storage | system storages are fixed |
| "The storage changed …; reload it and try again." | someone saved it or stock moved since you opened it | reload |
| Every move into and out of a storage is Rejected with Locked | Locked until is in the future | edit the storage, clear Locked until |
| A storage takes nothing even though Total units is below Max units | capacity counts raw units × storage weight, or Max distinct items is reached | look at Capacity used and Distinct items on its page |
| Reverse is Rejected with Not enough stock | the stock moved on since | Adjust stock instead |
| The ledger page shows no transactions for an old production run | it was rolled up after 30 days | Roll-ups view |
| "Differences found" in Ledger health | stock changed outside the ledger | [architecture § 11](../../architecture/stock-core.md#11-recovery) |

## Changes

1. 2026-11-19: first version (docs PandiO/knk-workspace#820).
