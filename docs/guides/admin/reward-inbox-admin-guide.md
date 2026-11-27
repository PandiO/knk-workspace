# Reward Inbox, Item Delivery and Stash — Admin Guide

**Status:** Current · **Last updated:** 2026-11-21 (first version, production P7 #60/#684, docs PandiO/knk-workspace#915)
**Checked against:** knk-web-api `next` `2952d0c7`, knk-plugin `next` `bdd8b463` (not released; the manual steps of the
[smoke test § 8](../production-storage-transport-smoke-test.md#8-phase-p7-item-delivery-reward-inbox-depositwithdraw-60-api-684-plugin-tier3)
have not been run live yet)
**Related:** [menus player guide § Reward inbox](../users/menus-player-guide.md#reward-inbox) (what players see; not
repeated here), [item delivery architecture](../../architecture/production-item-delivery.md) (flows, keys, recovery),
[API contract](../../specs/api/API_CONTRACT_ITEM_DELIVERY.md), [stock admin guide](stock-admin-guide.md) (storages, the
Stock ledger), [economy admin guide](economy-admin-guide.md) (kits and lootboxes), [Game Settings](../game-settings.md),
[plugin configuration § 4.31](plugin-configuration.md#431-production)

Kit and lootbox items that don't fit in a player's inventory go to the player's **reward inbox** instead of the ground;
players claim them with `/inbox`. This guide covers what you set up (the switches, the inbox and stash rules, premium
caps), gifting items to a player, looking a delivery up, and what to do when something goes wrong.

## 1. What you need

1. **Both switches on.**
   1. The API's game setting **Production enabled** (`Production:Enabled`; Admin → Settings, the **Production and
      territory** card, see [Game Settings](../game-settings.md#production-and-territory)).
   2. The game server's `production.enabled: true` in the plugin `config.yml`, with the `production.inbox` block
      (restart):
      ```yaml
      production:
        inbox:
          join-summary: true
      ```
   With either off, kits and lootboxes deliver exactly as before (#261): leftovers at the player's feet, lootbox
   leftovers owner-locked.
2. **The migration** `AddItemDelivery` on the API's database (two new tables; additive).
3. **The seeds** `ItemDelivery` (form and display, view only) imported with "make default". The web app has no Item
   Delivery page yet (#901); the seeds are ready for it.
4. **Item identity** (`items.identity.enabled: true`, [item identity admin guide](item-identity-admin-guide.md)) is
   recommended: kit and lootbox items are then matched to their blueprint reliably. Without it the blueprint the item was
   built from is used.
5. **Nodes:**

   | Task | Node |
   |---|---|
   | Open your own inbox in game (`/inbox`) | none: every player |
   | List and read deliveries (`api/ItemDeliveries`) | `knk.admin.world` **or** `knk.economy.admin` |
   | Gift items, see any player's inbox and stash, deposit to and withdraw from a stash, run the sweep now | `knk.economy.admin` |

   `knk.economy.admin` is **not** under `knk.admin`: `knk.admin.*` doesn't give it, only `*` or an explicit grant
   ([ranks and permissions admin guide](ranks-permissions-moderation-admin-guide.md)).

## 2. The inbox and stash rules (`production.delivery`)

There is no settings card for these yet (#901). Change them through the API: `GET api/GameSettings` as a staff member
with `knk.admin.config`, edit the `delivery` part of the `production` section, and send the whole `production`
section back with `PUT api/GameSettings` (the other sections as they came). Without a `delivery` part the API uses the
defaults.

```json
"delivery": {
  "inboxBaseCapUnits": 2304,
  "stashBaseCapUnits": 0,
  "expiryDays": 30,
  "reminderDaysBefore": [7, 1],
  "warnAtPercent": [80, 95],
  "premiumTiers": [
    { "permissionGroupId": 7, "inboxCapUnits": 6912, "stashCapUnits": 2304 }
  ]
}
```

| Setting | Default | What it does |
|---|---|---|
| `inboxBaseCapUnits` | 2304 (36 stacks of 64) | The inbox cap for everyone. Counts amount × the item blueprint's **Storage weight**, like every storage. A reward that arrives at the cap is **lost** (the player is told) |
| `stashBaseCapUnits` | 0 | The stash cap for everyone; 0 makes the stash a premium perk |
| `expiryDays` | 30 | Days an item waits in the inbox before it is gone (1 to 365) |
| `reminderDaysBefore` | 7 and 1 | A reminder this many days before expiry (up to 5 values, each below `expiryDays`) |
| `warnAtPercent` | 80 and 95 | The player is warned when a reward takes their inbox past one of these fill levels (up to 5 values) |
| `premiumTiers` | none | Per premium-tier permission group (`isPremiumTier`; the group's id): bigger inbox and stash caps. A player gets the higher of the base and their active tier's value |

A wrong value is refused with the field name (for example `production.delivery.expiryDays must be 1 to 365.`) and
nothing is saved. **When it applies:** right away for new deliveries; a player's cap is updated on their next delivery or
stash move. A smaller cap or a tier that ended trims nothing already in an inbox; new rewards are then lost until the
player claims. A new `expiryDays` applies to new deliveries only; what is waiting keeps its date.

Known issue: the info item of the `/inbox` view always says `Items expire 30 days after they arrive`, also when you set
`expiryDays` differently (#916). Each entry's own line (`24 expire in 6 days`) is right.

## 3. Gifting items to a player

There is no gifting page in the web app yet (#901). Use the API (Swagger or a REST client) with your web login and
`knk.economy.admin`:

```http
POST api/ItemDeliveries
{
  "userId": 12,
  "reason": "Gift",
  "note": "Thanks for the bug report",
  "idempotencyKey": "gift-2026-11-21-bugreport-12",
  "lines": [ { "itemBlueprintId": 5, "amount": 64 } ]
}
```

1. **`userId`** is the player's user id (the player's page in the web app); **`itemBlueprintId`** the item blueprint's id
   (Admin → Items).
2. **`reason`**: `Gift` for a present, `Admin` for a correction (giving back lost items); the delivery's actor is you.
3. **`idempotencyKey`**: a new one per gift (letters, digits and `: _ . -`, up to 80). Sending the same request again
   with the same key gives nothing twice; the same key with other contents is refused (409).
4. The items arrive in the player's inbox, not their inventory; they claim them with `/inbox`. They are told in game
   (`64 items arrived in your reward inbox (/inbox).`), at once when online, otherwise at their next join.
5. **Unique items** (an item instance with its own name and enchantments): send `{ "itemInstanceId": <id> }` as a line.
   The instance must be in no storage. Players can't claim unique items in game yet (#897), so don't gift them until
   that is done.
6. The answer says what happened: `status` Inboxed, PartlyLost or Lost (the player's inbox was full; `lostUnits`).

## 4. Looking things up

1. **Deliveries:** until the web app has its pages (#901), use the API with your web login: `POST
   api/ItemDeliveries/search` lists deliveries newest first with the player, reason, status, source and the units
   inboxed, lost and remaining. Its search term finds a player, a key or a source (for example the lootbox claim id);
   the filters are `userId`, `reason`, `status`, `sourceType`, `sourceRef` and `open` (`"true"`: still something in the
   inbox). `GET api/ItemDeliveries/<id>` shows a delivery's lines: requested, inboxed, lost, claimed, expired, remaining,
   and when it expires.
2. **Which reward is which:** the key and source say where a delivery came from:

   | Key | Source | From |
   |---|---|---|
   | `kit-claim-<claim id>` | `Kit <name>` | A kit granted on the web player profile |
   | `kit-first-join-u<user id>` | `Kit <name>` | The starter kit |
   | `kit-<kit id>-u<user id>-…` | `Kit <name>` | `/kit get` or `/kit give` in game |
   | `lootbox-claim-<claim id>` | `LootboxClaim <id>` | A lootbox opening or redelivery; the lootbox claim shows `N to the reward inbox (delivery #<id>)` |

3. **A player's inbox and stash:** `GET api/Inbox/<user id>` and `GET api/Inbox/<user id>/stash` (with
   `knk.economy.admin`): what waits, the cap, how full, and when each entry first expires. The storages themselves are
   ordinary Player storages (`Inbox of user <id>`, `Stash of user <id>`) on the Storage dashboard
   ([stock admin guide](stock-admin-guide.md)).
4. **The ledger:** every arrival (RewardInbox), claim (InboxClaim), loss at the cap (InboxOverflow), expiry
   (InboxExpired) and stash move (Deposit, Withdraw) is a transaction in the Stock ledger with the reason.

## 5. The stash

The stash is a second storage per player, separate from the inbox, with its own cap (`stashBaseCapUnits` and the
premium tiers). **Players can't use it in game yet**; only the API offers deposit and withdraw:
`POST api/Inbox/<user id>/stash/deposit` and `.../withdraw` with your web login and `knk.economy.admin`, the same body as
a gift without `userId`, `reason` and `note` (`{ "idempotencyKey": "...", "lines": [ ... ] }`). A deposit beyond the
cap is refused for the rest (`CapacityFull`); without a premium tier with a stash cap nothing fits.

## 6. Reminders and expiry

The API checks every hour: it sends the reminders that are due and removes expired items (they move to `SYS_LOSS` as
InboxExpired and the player is told). To run it now, `POST api/Inbox/sweep` with `knk.economy.admin`; the answer says
how many players were reminded and how many items expired. Nothing expires while **Production enabled** is off; it
catches up when you switch it back on.

## 7. A safe test

On a test server, with the switches of § 1 on:

1. Set `inboxBaseCapUnits` to 100 (§ 2) so the cap is easy to reach.
2. As a test player with a full inventory (all 36 slots dirt), claim a kit with `/kit get <kit>`. **Expected:** nothing on
   the ground; `<n> items didn't fit and went to your reward inbox (/inbox).`; the delivery in `POST
   api/ItemDeliveries/search` with reason Kit.
3. Make room for a few items and shift-click the entry in `/inbox`. **Expected:** exactly what fits lands in the
   inventory; the delivery's line shows it claimed.
4. Gift the test player 90 units (§ 3). **Expected:** the 80% warning; one more gift beyond the cap is partly lost with
   `Your reward inbox is full: <n> items were lost.`
5. Set the cap back. The full test list is the [smoke test § 8](../production-storage-transport-smoke-test.md#8-phase-p7-item-delivery-reward-inbox-depositwithdraw-60-api-684-plugin-tier3).

## 8. Effects on existing data

1. Nothing is moved or rewritten when you switch the inbox on: inboxes and stashes are made on a player's first
   delivery or deposit.
2. Kits and lootboxes keep their own records (kit claims, lootbox claims); a lootbox claim whose leftovers went to the
   inbox shows delivery method Inventory (or Redelivered) with the note, not DroppedOwned.
3. Switching the inbox off again (either switch) leaves what waits in the inboxes: players can still see it with
   `/inbox` while the game server's switch is on, and claim it once the API's is on again. Expiry waits while the API's
   switch is off.

## 9. Troubleshooting

| What you see | Why | What to do |
|---|---|---|
| `/inbox` says `The reward inbox is not switched on on this server.` | `production.enabled` is false on that game server | § 1 item 1 |
| A claim says `The reward inbox is switched off on the server right now.`; kits drop at the feet with `Some of it didn't fit and was dropped at your feet.` | The API's **Production enabled** is off (the server log says the API's flag is off) | Switch it on (§ 1) |
| A sword or other unique item still drops at the feet (kits) or owner-locked (lootboxes) | Unique items don't go to the inbox yet (#897) | As designed for now |
| A lootbox with a full inventory doesn't open at all | `lootboxes.full-inventory: refuse` (the default) | Expected; with `drop-owned` the leftovers go to the inbox |
| A player says rewards were lost | Their inbox was at its cap | The InboxOverflow transaction in the Stock ledger says what; gift it back (§ 3, reason `Admin`) and raise the cap or ask them to claim |
| Items expired that the player wanted | 30 days (or `expiryDays`) passed | The InboxExpired transaction says what; gift it back |
| A gift is refused with 409 `IdempotencyKeyReuse` | That key was used for another gift | Use a new key |
| A gift or claim is refused with `The inbox is locked: ...` | Someone locked the player's Inbox storage | Unlock it on the storage page ([stock admin guide](stock-admin-guide.md)) |
| The server log has `... could not go to the reward inbox and are lost: ...` | A kit for an offline player was refused by the API | Fix the cause, then gift the listed items (§ 3, reason `Admin`) |
| No reminders or expiry | **Production enabled** is off, or the API was down at the hourly check | Switch it on; run the sweep (§ 6) |

## Changes

1. 2026-11-21: first version (docs PandiO/knk-workspace#915), checked against knk-web-api `next` `2952d0c7` and
   knk-plugin `next` `bdd8b463`.
