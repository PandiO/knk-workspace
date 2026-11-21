# Item delivery, the reward inbox and the stash (knk-web-api and knk-plugin)

**Status:** Current · **Last updated:** 2026-11-21 (first version, production P7 #60/#684, docs PandiO/knk-workspace#915)
**Checked against:** knk-web-api `next` `2952d0c7` (PR PandiO/knk-web-api#70), knk-plugin `next` `bdd8b463` (PR
PandiO/knk-plugin#113). Not released; the manual steps of the
[smoke test § 8](../guides/production-storage-transport-smoke-test.md#8-phase-p7-item-delivery-reward-inbox-depositwithdraw-60-api-684-plugin-tier3)
have not been run live yet.
**Related:** [production DESIGN § 4.6](../specs/production-storage-transport/DESIGN.md) (item delivery), decision
record § 2.4 and D7 ([DECISIONS_2026-11-05](../specs/production-storage-transport/DECISIONS_2026-11-05.md)),
[API contract](../specs/api/API_CONTRACT_ITEM_DELIVERY.md), [reward inbox admin guide](../guides/admin/reward-inbox-admin-guide.md),
[menus player guide § Reward inbox](../guides/users/menus-player-guide.md#reward-inbox), [stock core](stock-core.md)
(storages, the ledger, capacity), [item identity](item-identity.md), [plugin configuration § 4.31](../guides/admin/plugin-configuration.md#431-production)
(`production.inbox.join-summary`)

Phase P7 gives every reward one way to reach a player. The game server **places what fits** in the player's inventory
right away; those items never touch the stock ledger. Everything else (the player is offline, the inventory is full)
is a **delivery**: the items move from the world into the player's **reward inbox**, a Player storage of the stock core,
and wait there until the player claims them with `/inbox`. The inbox has a hard cap (what doesn't fit is lost, with a
message), a near-cap warning and a 30-day expiry with reminders. Next to it, a **premium stash** is a second Player
storage with its own cap, for deposit and withdraw.

Kits (`/kit get|give`, kits granted from the web app, starter kits) and lootboxes use the inbox since L20. Everything
here needs both switches on: the game server's `production.enabled` and the API's game setting **Production enabled**
(`Production:Enabled`). With either off, kits and lootboxes deliver exactly as before (#261, A21).

## 1. Ownership

| Part | Where | Owns |
|---|---|---|
| `IItemDeliveryService` / `ItemDeliveryService` | knk-web-api `Services/Stock/ItemDeliveryService.cs` | Deliveries, the inbox lots, claims, stash moves, reminders and expiry; every stock move goes through `IStockService` |
| `InboxMaintenanceService` | same file | The hourly sweep (reminders, expiry) |
| `ItemDeliveriesController`, `InboxController` | knk-web-api `Controllers/ItemDeliveriesController.cs` | `api/ItemDeliveries`, `api/Inbox` ([API contract](../specs/api/API_CONTRACT_ITEM_DELIVERY.md)) |
| `ProductionSettings.ValidateDelivery` | knk-web-api `Services/Territory/ProductionSettings.cs` | The game settings section `production.delivery` |
| `ItemDelivery`, `ItemDeliveryLine` | knk-web-api `Models/Stock/ItemDelivery.cs` | The delivery record and its lots |
| `RewardInbox` | knk-plugin knk-paper `production/inbox/RewardInbox.java` | Place first, send the rest, retry, fall back |
| `InboxModule`, `InboxScreen`, `InboxCommand` | knk-paper `production/inbox/`, `commands/InboxCommand.java` | `/inbox`, the paged view, claims, notices, the join summary |
| `InboxText`, `InboxView`, `InboxLayout`, `RewardKeys` | knk-plugin knk-core `production/inbox/` | Texts, the view model, slots, idempotency keys (no Bukkit) |
| `ItemDeliveryApi` / `ItemDeliveryApiImpl` | knk-core port, knk-api-client | The HTTP calls; the `inbox` payload of `PlayerNotification` |
| Kit and lootbox hooks | knk-paper `KitGrantPlacer`, `KitGrantFlow`, `KitGrantDelivery`, first-join kits, `LootboxDelivery` | Hand their leftovers to `RewardInbox` |

The API is the only truth for what waits in an inbox. The plugin keeps no inbox state of its own: it holds leftovers
only while the API answers a delivery (a server stop in that moment loses them, logged with the key).

## 2. A delivery (DESIGN § 4.6, A15)

1. **The game server places first.** `RewardInbox.place` (kits) and `RewardInbox.route` (lootboxes) put what fits in
   the inventory and collect the leftovers. Each leftover is resolved to a blueprint with item identity (#141: instance
   tag, blueprint tag, vanilla match); when item identity is off or can't resolve it, the blueprint the item was built
   from is used.
2. **It sends the rest** with `POST api/ItemDeliveries`: the user, a reason (`Kit`, `Lootbox`, `Quest`, `Gift`, `Admin`,
   `Other`), a source (`Kit <name>`, `LootboxClaim <id>`), the lines and an idempotency key (§ 4).
3. **The API moves it.** Under one transaction it locks the user row, finds or makes the player's Inbox storage (Player,
   purpose Inbox, `Inbox of user <id>`), locks `SYS_WORLD`, `SYS_LOSS` and the inbox in id order, writes the player's
   current cap to the inbox (§ 3.1), then moves the lines `SYS_WORLD` → inbox as **RewardInbox** in partial mode. What the
   cap refuses moves `SYS_WORLD` → `SYS_LOSS` as **InboxOverflow**. Both transactions are in the ledger, so the
   reconciler stays clean.
4. **It records the delivery** (`ItemDelivery`, status Inboxed, PartlyLost or Lost) with one `ItemDeliveryLine` per line,
   and queues an **`InboxUpdated`** player notification (event Delivered: inboxed and lost units, fill percent, the
   warning level passed).
5. **The plugin tells the player** where the items went: `25 items didn't fit and went to your reward inbox (/inbox).`,
   with the loss line first (`Your reward inbox is full: 3 items were lost.`) and the warning after it. It remembers the
   delivery id, so the matching `InboxUpdated` notice only repeats the warning (`RewardInbox.wasReported`).

A locked inbox refuses the whole delivery (409; nothing moves, no delivery is recorded). A unique item that is already
in a storage is refused (400): a delivery brings items from the world.

### 2.1 Fungible lines and unique units

A line is either an amount of a blueprint (`itemBlueprintId` + `amount`, a stock line in the inbox) or one unique item
(`itemInstanceId`, amount 1, a `StockUnit` that keeps the instance's name and enchantments). A unique item can be in
one line only; at most 100 lines per call.

The API accepts and claims unique units. **The game server does not send them yet**: it can't rebuild an instance from
the inbox in game (#897), so `RewardInbox` keeps unique items and items without a blueprint out of the delivery and
gives them to the fallback (kits drop at the feet, lootbox items drop owner-locked). A unique item staff deliver through
the API shows in `/inbox` with `Unique items can't be claimed in game yet` and can't be claimed there.

### 2.2 The lots

The `ItemDeliveryLine` rows are the inbox lots: `requested` = `inboxed` + `lost`, and `remaining` = `inboxed` − `claimed`
− `expired`. Each lot carries the delivery's `expiresAt` and how many reminders went out. The stock line in the inbox
storage stays the truth for amounts: claims and expiry never move more than the storage holds, and when staff moved
stock out of an inbox by hand, expiry closes the lot with what was there.

## 3. Caps, the warning and the premium stash (D7, decision record § 2.4)

### 3.1 Caps

Caps count raw units × `ItemBlueprint.StorageWeight`, like every storage cap ([stock core](stock-core.md)). A player's
cap is the higher of the base (`inboxBaseCapUnits`, default 2304 = 36 stacks of 64; `stashBaseCapUnits`, default 0) and
their active premium tier's entry in `production.delivery.premiumTiers` (by permission group id, the tier
`UserPermissionGroupService.SelectPremiumTier` picks). The cap is written to the storage's `MaxUnits` on each delivery
or stash move, so a tier that starts raises it and a tier that ended lowers it on the next move. Nothing already in the
inbox is trimmed when the cap drops; new deliveries then lose what doesn't fit.

### 3.2 The near-cap warning

`warnAtPercent` (default 80 and 95) are fill levels. A delivery that takes the inbox past one of them carries
`warningPercent` in its notice (the highest level passed), and the inbox view reports the highest level reached.
The plugin says `Your reward inbox is 80% full. Claim items with /inbox before new rewards are lost.` after the
delivery, when `/inbox` opens and in the join summary.

### 3.3 The premium stash

The stash is a separate Player storage (purpose Stash, `Stash of user <id>`, made on the first deposit) with its own cap.
With the default base of 0 only a premium tier with `stashCapUnits` can deposit; others get `CapacityFull`. Deposit moves
`SYS_WORLD` → stash (**Deposit**), withdraw stash → `SYS_WORLD` (**Withdraw**), both partial and idempotent. The game
server calls them for the player it names; staff with `knk.economy.admin` for admin use. **No game-server or web screen
calls them yet**: the in-game stash and the web pages come later (#901 for the web app).

## 4. Idempotency keys

Every delivery, claim and stash move needs a key of 1 to 80 characters of letters, digits and `: _ . -`. A retry with
the same key and the same request applies once and answers the stored result (`replayed` true for a delivery); the
same key with another request is 409 `IdempotencyKeyReuse` (the API hashes the request). The keys of the game server
(`RewardKeys`):

| Key | For | Stable because |
|---|---|---|
| `kit-claim-<claimId>` | A kit granted from the web app (#261) | The API's claim row |
| `lootbox-claim-<claimId>` | A lootbox opening or redelivery | The lootbox claim row |
| `kit-first-join-u<userId>` | The starter kits | The API grants them once per player |
| `kit-<kitId>-u<userId>-<random>` | `/kit get` and `/kit give` in game | Made once per grant; the plugin has no claim id for these |
| `inbox-claim-u<userId>-<random>` | One claim click | Made once per click |

The API prefixes them for the ledger (`delivery:<key>`, `delivery:<key>:overflow`, `inbox-claim:<key>`,
`stash-deposit:<key>`, `stash-withdraw:<key>`, `inbox-expire:<lot id>`), so a key in this table is unique per kind of
move. **Retries:** when the API gives no answer or a 5xx, `RewardInbox` sends the same request once more after 3 seconds.
A refusal (409 `ProductionDisabled`, any other 4xx) goes to the fallback at once.

## 5. Claim, reminders and expiry

### 5.1 Claim

`/inbox` opens `InboxScreen` (a double chest titled `Reward inbox`; 45 entries per page, arrows, an ender chest with the
fill). Left click asks for a stack, right click for one, shift-click for as much as fits. The plugin works out the room
first and refuses without calling the API on a full inventory, a unique entry or during a siege. Otherwise it sends
`POST api/Inbox/{userId}/claim` with the plugin key, `X-Acting-User-Id` = the player and a new key per click, and
places **exactly what the API accepted** (`result.lines[].accepted`). If the inventory filled up in the meantime, the
rest drops at the player's feet (`Your inventory filled up meanwhile: the rest was dropped at your feet.`).

In the API the claim moves inbox → `SYS_WORLD` as **InboxClaim** (partial: `NotEnoughStock` for what the inbox doesn't
hold) and books the accepted amounts on the lots that expire first. The answer carries the inbox view after the claim.

### 5.2 Reminders and expiry

`InboxMaintenanceService` runs `SweepAsync` every hour; staff with `knk.economy.admin` can run it now with
`POST api/Inbox/sweep`. It does nothing while `Production:Enabled` is off (expiry waits).

1. **Reminders.** For each `reminderDaysBefore` value (default 7 and 1) a lot gets one reminder when its expiry comes
   within that many days. Reminders due in one run are summed per player into one `InboxUpdated` ExpiryReminder
   (`expiringUnits`, the first `expiresAt`): `24 items in your reward inbox expire in 6 days. Claim them with /inbox.`
2. **Expiry.** Each lot past `expiresAt` (default 30 days after the delivery, `expiryDays`) moves what is still there
   inbox → `SYS_LOSS` as **InboxExpired**, one transaction per lot under the key `inbox-expire:<lot id>` (a rerun is
   safe). One `InboxUpdated` Expired per player: `24 items in your reward inbox expired and are gone.`

The notices reach the game server through the player notification queue (`PlayerNotificationPoller`); a player who is
offline sees them on the next join. With `production.inbox.join-summary` (default true) the plugin also reads the inbox
about five seconds after a join and says what waits (`You have 24 items in your reward inbox (/inbox).`, plus
`Some of them expire in 3 days.` when something expires within 7 days, and the warning).

## 6. The kit and lootbox paths (A21, #261)

| Path | `production.enabled: true` and the API's flag on | `production.enabled: false` (or the API refuses) |
|---|---|---|
| `/kit get`, `/kit give` (`KitGrantFlow`) | Place what fits; leftovers to the inbox (key `kit-<kitId>-u<userId>-…`) | Leftovers drop at the feet, as before |
| Kit granted from the web app (`KitGrantDelivery`, #261) | Same, key `kit-claim-<claimId>`; a player who left before the kit was placed gets it whole in the inbox | Handed over when the player is online, leftovers at the feet; a player who left is as before |
| Starter kits (first join) | Same, key `kit-first-join-u<userId>`; a new player who leaves first finds it in the inbox | As before (lost when the player left before it was placed) |
| Lootbox opening and redelivery (`LootboxDelivery`) | Stackable leftovers to the inbox (key `lootbox-claim-<claimId>`); the claim is confirmed after the inbox answered: Inventory or Redelivered with the note `N to the reward inbox (delivery #<id>)` | Leftovers drop owner-locked; the claim is DroppedOwned |
| Unique items (any path) | Not sent (#897): kits drop them at the feet, lootboxes owner-locked | As before |

While the plugin flag is off `KnKPlugin.kitRewardRouter()` is null and no code path calls `api/ItemDeliveries` or
`api/Inbox`; `/inbox` answers `The reward inbox is not switched on on this server.` When the API's flag is off but the
plugin's is on, every delivery is refused with 409 `ProductionDisabled` and falls back to today's delivery (logged with
the key); `/inbox` still opens (reads work), and a claim says `The reward inbox is switched off on the server right now.`

Lootboxes only overflow when they can open with a full inventory: with `lootboxes.full-inventory: refuse` (the default)
a full inventory can't open a box, so the inbox gets lootbox items only with `drop-owned` or on a redelivery.

Other rewards can use the same path: `RewardInbox.send(player, userId, reason, sourceType, sourceRef, key, leftovers,
fallback)` with a stable key, for example a quest reward with `Reason.QUEST`.

## 7. Schema, migration and access

1. **Migration** `20261120234819_AddItemDelivery` (additive, after `AddSiegeWeaponUnlockMinTitle`): tables
   `item_deliveries` (unique `IdempotencyKey` with a binary collation; indexes on `(UserId, CreatedAt)`,
   `(SourceType, SourceRef)`, `InboxStorageId`) and `item_delivery_lines` (unique `(ItemDeliveryId, LineNo)`, cascade
   delete with the delivery). The Inbox and Stash storages are ordinary `storages` rows (no schema change). `KnKDbContext`
   has no DbSet for them (one contiguous model block; `Set<ItemDelivery>()`).
2. **Seeds:** form and display seeds `ItemDelivery` (view only, with its lines; G17).
3. **Game settings:** `production.delivery` inside the production section (§ 3; validation and ranges in the
   [API contract § 5](../specs/api/API_CONTRACT_ITEM_DELIVERY.md#5-game-settings-productiondelivery)).
4. **Access:** reads of deliveries for the World area or `knk.economy.admin` (dashboard type `ItemDelivery`) and the
   plugin key; a delivery from the plugin key or `knk.economy.admin`; the inbox and stash views for the plugin key, the
   player themself and `knk.economy.admin`; the claim for the plugin key only, as the named player; stash moves for the
   plugin key as that player or `knk.economy.admin`; the sweep for `knk.economy.admin`. The rules are pinned in
   `ReadAccessRulesTests` and `EndpointAccessRulesTests`. `/inbox` has no permission node: everyone opens their own.
5. **Concurrency:** the user row is locked before the inbox or stash is found or made (one inbox per player without a
   unique index), then the storages in id order, as everywhere in the stock core.

## 8. Tests, recovery and limitations

### 8.1 Tests

1. knk-web-api: `ItemDeliveryServiceTests` (deliveries, cap and overflow, premium tiers, claims oldest lot first,
   unique units, reminders and expiry, the stash, a locked inbox, the flag), `InboxControllersTests` (actors, the named
   player, routes and their rules, the flag), `AddItemDeliveryTests` (the migration), and with `KNK_TEST_MYSQL`
   `ItemDeliveryMySqlTests` (one inbox per player, one delivery per key and the cap under concurrent deliveries).
2. knk-plugin: knk-core `InboxLogicTest`; knk-api-client `ItemDeliveryApiImplTest`; knk-paper `RewardInboxTest`,
   `InboxModuleTest` and the inbox tests in `KitGrantDeliveryTest`, `KitGrantFlowTest` and `LootboxDeliveryTest` (both
   flag paths).
3. Plugin scenarios on a real Paper server: `player-kit-overflow-inbox` and `player-inbox-claim-partial`
   ([plugin scenarios § 1](../guides/developer/plugin-scenarios.md#1-a-scenario-in-under-30-lines)).
4. The manual steps: [smoke test § 8](../guides/production-storage-transport-smoke-test.md#8-phase-p7-item-delivery-reward-inbox-depositwithdraw-60-api-684-plugin-tier3)
   (§ 8.1 API, § 8.2 game server).

### 8.2 Recovery

1. **A delivery the plugin couldn't send** (a refusal, or no answer twice): the fallback ran (dropped at the feet or
   owner-locked); the server log names the key. Items of an offline kit that couldn't go to the inbox are logged as
   lost (`... could not go to the reward inbox and are lost: ...`); staff can deliver them again with
   `POST api/ItemDeliveries` (reason `Admin`, a new key) once the cause is fixed.
2. **A player lost items at the cap or by expiry:** the InboxOverflow or InboxExpired transaction in the Stock ledger
   says what and when; staff deliver them again (reason `Admin` or `Gift`).
3. **Stock moved out of an inbox by hand:** the lots stay open until expiry, which closes them with what is there;
   claims never take more than the storage holds.
4. **Reminders or expiry didn't run:** check `Production:Enabled`; run `POST api/Inbox/sweep` as staff.

### 8.3 Limitations

1. Unique items aren't sent to the inbox by the game server and can't be claimed in game (#897).
2. No claim all, no main-menu tile, no lootbox delivery method `Inbox` (the lootbox claim shows Inventory with a note);
   leftover lootbox tokens are not routed (#912).
3. No web app pages for deliveries, a player's inbox and stash, gifting or the `production.delivery` card (#901); staff
   use the REST API ([admin guide](../guides/admin/reward-inbox-admin-guide.md)).
4. No in-game stash yet; deposit and withdraw exist only in the API.
5. The inbox view's info item always says `Items expire 30 days after they arrive`, also when `expiryDays` is set
   differently (#916).

## Changes

1. 2026-11-21: first version (docs PandiO/knk-workspace#915), checked against knk-web-api `next` `2952d0c7` and
   knk-plugin `next` `bdd8b463`.
