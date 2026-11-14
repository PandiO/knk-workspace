# Currency, kits, lootboxes and discoveries — Admin Guide

**Status:** Current · **Last updated:** 2026-11-13 (first version, PandiO/knk-workspace#300)
**Checked against:** knk-plugin `main` `57884e9`, knk-web-api `master` `75b5a00`, knk-web-app `main` `3ba747d` (desk
check of the code, not a live test; the settings pages of #26 are not live-tested either)
**Related:** [economy player guide](../users/economy-player-guide.md) (what players see; not repeated here),
[staff web app guide](staff-web-app-guide.md), [plugin configuration](plugin-configuration.md),
[Game Settings](../game-settings.md), [commands reference § staff](../users/commands.md#money-kits-and-lootboxes-staff),
[dashboard access](dashboard-access-admin-guide.md), designs: [currency](../../specs/currency-payments/DESIGN.md),
[kits](../../specs/kits/DESIGN.md), [lootboxes](../../specs/lootboxes/DESIGN.md),
[domain discovery](../../specs/domain-discovery/DESIGN.md)

This guide is for staff who set up and look after the economy: the currency policy and balance corrections, kits,
lootboxes and discovery rewards, plus `/knk item more`. Siege rewards are set per scenario; see
[authoring a siege scenario](../authoring-a-siege-scenario.md) and the [Siege player guide](../users/siege-player-guide.md).

## Contents

1. [Before you start](#1-before-you-start)
2. [Currency](#2-currency)
3. [Kits](#3-kits)
4. [Lootboxes](#4-lootboxes)
5. [Discoveries](#5-discoveries)
6. [`/knk item more`](#6-knk-item-more)
7. [Safe test procedure](#7-safe-test-procedure)
8. [Common problems](#8-common-problems)

## 1. Before you start

**Where things are.** In the web app's admin sidebar:

| Page | Route | Node |
|---|---|---|
| Currency policy | `/admin/economy/policy` | `knk.admin.currency.policy` |
| Currency alerts | `/admin/economy/alerts` | `knk.admin.currency.alerts` |
| Balance event log | `/admin/users/balance-log` | `knk.admin.currency.history` |
| A transaction | `/admin/economy/transactions/<id>` (from the log) | `knk.admin.currency.history`; **Reverse** needs `knk.admin.currency.reverse` |
| A player's profile (balances, payments lock, kits, discoveries) | `/admin/users/<id>` | `knk.admin.user.manage`, plus the node of each card below |
| Kits (dashboard and the Kit form) | Dashboard → Kit, `/forms/kit` | `knk.kit.manage` (delete also `knk.admin.delete`) |
| Lootboxes | `/admin/lootboxes` | `knk.admin.lootbox.manage` (types, specials and areas also `knk.admin.content`) |
| Domain discovery | `/admin/discovery` | `knk.admin.discovery` |

The settings pages share one header (Last saved, "n unsaved changes", **Reload**, **Discard**, **Save (n)**, "Leave
without saving?"); see [staff web app guide § 9](staff-web-app-guide.md#9-settings-pages). Which rank holds which
node: [dashboard access](dashboard-access-admin-guide.md).

**Player nodes.** Players need these on the Default group (they are `default: op` in `plugin.yml`, so the database
grant is what counts):

1. Currency: `knk.pay`, `knk.balance`, `knk.balance.others`, `knk.baltop`, `knk.transactions` (seeded by a migration).
   `knk.pay.gems` (send gems) is off and not seeded; gems are also not transferable by policy.
2. Lootboxes: `knk.lootbox.open`, `knk.lootbox.odds` (seeded).
3. Kits: `knk.kit.list`, `knk.kit.get`, `knk.kit.purchase`. **No migration grants these**; the alpha database has
   them from its hand-made seed. On a fresh database grant them to Default yourself
   ([#456](https://github.com/PandiO/knk-workspace/issues/456)).
4. Discoveries: `knk.discoveries` (`default: true`). Discovering itself needs no node.

**Ops** pass every in-house node check, so test player rules with a non-op account.

## 2. Currency

Every change of coins, gems or XP is a **ledger** transaction with a reason code (`SALARY`, `PLAYER_TRANSFER`,
`DISCOVERY_REWARD`, `SIEGE_REWARD`, `KIT_CLAIM_COST`, `KIT_PURCHASE`, `TELEPORT_FEE`, `ADMIN_GRANT`, …). Balances are
never edited directly.

### 2.1 Currency policy

**Currency policy** has a section for **coins** and one for **gems**, saved together with one **Save**. Each section
says its database cap and when it was last changed.

| Group | Field | Seed (coins / gems) | Notes |
|---|---|---|---|
| Switches | **Payments switched on (kill switch)** | on / on | Off stops every `/pay` in that currency at once. Saving a switch asks first. |
| | **Players may send {currency}** | yes / **no** | Gems are not transferable. |
| Payments | **Minimum payment**, **Maximum payment** | 10–1,000,000 / 1–100 | |
| | **Confirm from**, **Confirm window** | 100,000 and 60 s / 10 and 60 s | Window 10–600 s |
| | **Transfer fee** | 0 bp | 100 bp = 1 %, at most 5,000 bp; paid on top of the amount |
| Limits per player | **Daily send cap**, **Daily receive cap** | 2,000,000 and 4,000,000 / 500 and 500 | Rolling 24 h |
| | **Cooldown**, **Payments per hour** | 5 s and 20 / 5 s and 10 | |
| | **Sender account age** | 48 h | 0–8,760 h |
| | **Lowest sender title** | Peasant (from 2,500 XP) | "None", or a title from the title brackets |
| Balances and grants | **Maximum balance** | 999,999,999 / 999,999 | |
| | **Staff daily grant cap** | 5,000,000 / 1,000 | Per staff member, 0 = no cap; `knk.admin.currency.unlimited` skips it |
| | **Signup grant** | 250 / 50 | For new accounts only |

**When it applies:** at once, on the next `/pay` (the API reads the policy for every payment; the game server keeps
no copy). Each save writes a `CurrencyPolicyChanged` entry with the old and new values to the **audit log** (not the
Balance event log, although the page text says so: [#459](https://github.com/PandiO/knk-workspace/issues/459)).

**Kill switch:** "Switch coins payments off? … no player can send coins with /pay until they are switched on again.
Staff grants still work." The **currency monitor** can switch payments off by itself when its reconciliation finds a
mismatch (see § 2.4). If someone (or the monitor) saved the policy after you loaded it, the section says so and offers
**Reload current policy**: reload and review before saving again.

**Effect on existing data:** none on balances or past transactions. A lower maximum balance doesn't reduce anyone; it
only blocks payments that would push the receiver over it. `knk.pay.bypass` (for event payouts) skips the account
age, title, cooldown, hourly and daily caps, but never the switches, locks, the minimum, the sender's funds or the
receiver's caps.

### 2.2 Correcting a balance

On the player's profile, **Adjust balance** (needs the node of that balance, `knk.admin.user.coins`, `.gems` or
`.xp`; an XP increase needs all three, because a higher title pays title bonuses):

1. **Balance:** Coins, Gems or XP. **Action:** Add, Remove or Set to. **Amount.**
2. **Category:** Compensation, Event prize, Refund, Correction, Penalty, Testing or Other.
3. **Reason:** required, 10 to 450 characters. Players see it if they are online (`Granted by <you> … – <reason>`).
4. **Apply adjustment.**

In game: `/knk user <player> coins|gems set|add|remove <amount> <reason…>`. Your daily grant cap applies to both.

### 2.3 Looking up and reversing

1. **Balance event log:** every ledger posting, filtered by currency, player, initiator, source, reason code and
   dates. Click a transaction id to open it. In game: `/knk currency history <player> [coins|gems|xp] [page]` or
   `/knk user <player> history …`.
2. **Transaction page:** when, kind and reason code, initiator, source, what it reverses or was reversed by, and its
   entries. **Reverse this transaction:** a reason of at least 10 characters, optionally **Allow a partial reversal
   (reverse what is left)** when the player spent part of it, then **Reverse**. There is no confirm yet: check
   before you click ([#459](https://github.com/PandiO/knk-workspace/issues/459)). The player isn't notified. In game:
   `/knk currency reverse <txId> [--partial] <reason…>`.
3. **Payments lock:** the profile's **Payments** card, **Lock payments** with a reason (up to 200 characters), or
   `/knk currency lock <player> <reason…>`. A locked player can't send or receive `/pay`; staff grants still work.

### 2.4 Currency alerts

**Currency alerts** lists what the monitor found (rules every 5 minutes, a reconciliation of the ledger against the
balances every hour), filtered by status, severity and rule. **Acknowledge** an alert once handled; **Run now** starts
a reconciliation. A reconciliation mismatch switches payments off for that currency (see § 2.1). In game:
`/knk currency alerts [all] [page]`, `alerts ack <id>`.

### 2.5 Salary

Salaries come from the title brackets (salary per hour per title) times a global multiplier and the player's personal
and rank multipliers. The global multiplier and the offline cap (720 hours) are in `api/SalaryConfiguration`; there is
**no web page** for them yet ([#112](https://github.com/PandiO/knk-workspace/issues/112)).

### 2.6 Plugin `config.yml`

`currency.client-cooldown-seconds` (3), `baltop-page-size` (10), `transactions-page-size` (8), and the player texts
under `messages.currency.*`. See [plugin configuration § 4.16](plugin-configuration.md#416-currency). The limits
themselves are in the policy, not in `config.yml`.

## 3. Kits

### 3.1 Making or changing a kit

Dashboard → **Kit** → **New** (or **Edit**), or `/forms/kit`. The form has five steps:

1. **Kit:** **Name** (required), **Description** (shown in the tooltip). **Scan** with **Send to Minecraft** creates a
   world task: claim it in game with `/knk kitscan claim <code>` and your inventory is read into the next steps.
2. **Equipment:** Helmet, Chestplate, Leggings, Boots, Off-hand, Main hand (item blueprints). The menu icon is the main
   hand item, else the chestplate, else a chest.
3. **Contents:** **Inventory slots**: per entry an **Item**, a **Slot** (0–35, each slot once) and a **Quantity**.
4. **Who can claim:** **Minimum title**, **Permission group**, **Permission node** (for example `knk.kit.archer`),
   **Give on first join**. All set rules must be met.
5. **Cooldown and price:** **Cooldown (seconds)** (0 = none), **Price per claim** with **Price currency** (Coins or
   Gems), **Premium kit (buy once)** with **Premium price (Gems)** (1–999,999).

The API refuses negative prices, prices above the currency's cap, a slot outside 0–35 or used twice, and items, titles
or groups that don't exist.

**Lootbox tokens with a kit:** a grant rule on Lootboxes → **Token items** issues tokens every time the kit is claimed
or given (§ 4.6).

**Seed kits:** `Default` (iron armour, iron sword, bread, arrows, bow, axe; given on first join) and `Archer`. Both have
no cooldown and no price, so players can claim them again and again; set a cooldown if that isn't intended.

### 3.2 When changes reach the game

Claims, purchases and gives always ask the API, so a change counts from the next claim. The kits **menu** (list and
tooltip) uses the plugin's cache: up to 60 seconds (`cache.ttl-seconds`), or at once when `realtime.enabled` is on.
`/knk cache refresh` does not clear the kit cache.

### 3.3 Effect on existing data

| Change | Effect |
|---|---|
| Cooldown | Counts at once for everyone, from their last claim (of any kind: own claim, staff give, first-join). |
| Turn **Premium** on | Players who haven't bought it can no longer claim it until they buy it. |
| Turn **Premium** off | Old purchases no longer count; the cooldown and price apply again to buyers too. |
| **Give on first join** on | Only new players get it; it isn't given to existing players. |
| Gating | Counts at once. A premium kit can still be bought by someone who fails it ([#454](https://github.com/PandiO/knk-workspace/issues/454)). |
| Rename | Claims and purchases are kept (they are stored by id). |
| **Delete** | Also deletes its claims, purchases (gems paid are **not** refunded), contents and its lootbox token rules. |

### 3.4 Giving a kit

1. In game: `/kit give <player> <kit name>` (`knk.kit.give`), for an online player. It skips gating, cooldown and price
   and places the items like a claim (leftovers dropped at their feet). It starts their cooldown. The console can't
   use it.
2. Web app: the profile's **Kits** card lists each kit's status, cooldown and cost for that player. **Grant** (needs
   `knk.kit.give`) records the claim, the audit entry and the kit's lootbox tokens and starts the cooldown, but on the
   released plugin **the items never reach the player** ([#261](https://github.com/PandiO/knk-workspace/issues/261)).
   Use `/kit give` until then. In `next`, not yet released: the grant is a pending delivery that the plugin hands over
   when the player is online, on their next join, or after their siege, exactly once.

`/kit manage` only points to the web form; kits aren't edited in game.

## 4. Lootboxes

`/admin/lootboxes` has eight tabs: **Settings**, **Types**, **Specials**, **Areas**, **Odds**, **Active boxes**,
**Token items** and **Drop log** (the address keeps the tab, `?tab=`). How players pick up and open boxes: see the
[player guide § 5](../users/economy-player-guide.md#5-lootboxes).

### 4.1 How it fits together

1. A **type** is tied to one item category (one type per category, seeded **disabled**). It has a spawn weight, the box
   grades it can have (default ★1–★5 of the ★1–★10 scale), and which item grades a box of each grade draws from.
2. **Areas** are WorldGuard regions where boxes spawn, each with its own limits.
3. A box is **picked up** as a token item, then **opened** (the roll happens at the open). Tokens also come from grant
   rules (premium tiers, kits) and staff.
4. **Specials** are rare jackpot items checked before the normal roll.

### 4.2 Settings tab

"Applies to every box type and area. The game server picks changes up on its next runtime refresh."

| Field | Seed | Notes |
|---|---|---|
| **Lootboxes enabled** | on | Saving a change asks first (below) |
| **Max active boxes (all areas)** | 15 | 0 or more |
| **Boxes per player per UTC day** | 10 | Empty = "No cap". Counted separately for pickups and for opens, and the open count includes tokens from tiers, kits and staff ([#458](https://github.com/PandiO/knk-workspace/issues/458)). A type can set its own lower limit. |
| **Announce drops of items from** | ★5 and better | Or **Never**. Specials are always announced; a type can override it. |
| **Announce spawns of boxes from** | ★6 and better | Or **Never**. So off for ★1–★5 types by default. Staff spawns are never announced. |
| **Drop announcement**, **Spawn announcement** | `{player} found {item} in a {box}!`, `A {box} appeared in {area}!` | With a preview of both as the game shows them |

**Switching lootboxes off** asks "Switch lootboxes off? Nothing spawns and no box can be claimed until they are
switched on again, from the game server's next runtime refresh." What it does today: no spawns, pickups refused,
**token opens refused too**, and boxes already in the world stay visible until they expire. Grant rules still issue
tokens ([#457](https://github.com/PandiO/knk-workspace/issues/457)). Switching on asks "Switch lootboxes on? …".

### 4.3 Types, Specials and Areas

1. **Types:** columns Type, Category, **Spawns** (Enabled/Disabled chip), Weight, Box grades, Daily limit ("Global
   only" when unset) and Pool per item grade; **Odds**, **Edit**, **New type**. Toggling the chip needs
   `knk.admin.content` and asks first: "Disable {name}? No new boxes of this type spawn … Boxes already in the world are
   not removed." Today a disabled type's boxes can still be picked up and its tokens still opened; only `/lootbox odds`
   and `/knk lootbox token` stop accepting it ([#457](https://github.com/PandiO/knk-workspace/issues/457)). "Enable
   {name}? … Check its odds first."
2. **Specials:** an item given as-is, with a chance per million and a minimum box grade (default ★5), checked in their
   order before the normal roll.
3. **Areas:** per area the region, **max active** (3), interval (600 s), chance (100 %), minimum players online (3),
   minimum distance from players (24 blocks), lifetime (30 min), excluded regions and allowed types (empty = all). In
   game, `/knk lootbox area create <name>` makes a full-height region `lootbox_<name>` from your WorldEdit selection.
   An area whose region was drawn through the form's region task keeps a temporary region name, which the 14-day
   temp-region cleanup can delete. In `next`, not yet released: that region is renamed to `lootbox_area_<id>` on save
   ([#34](https://github.com/PandiO/knk-workspace/issues/34)).

**New** and **Edit** on these tabs open the form wizard and need `knk.admin.content`; without it they lead to "Staff
only" instead of being greyed out ([#380](https://github.com/PandiO/knk-workspace/issues/380)).

Where a box can land: solid ground with two air blocks above, inside the area's region and outside its excluded
regions and any running siege arena, at least the minimum distance from every player, and never on
`surface.forbidden-ground`. The game server never loads new chunks for it.

### 4.4 Odds

Pick a **Box type** and **Box grade** to see how often the type spawns as each grade, the specials in a box of that
grade ("Own chance", "Gives it", then "Normal roll: x %"), the item grades and every item with its chance and
enchantment rolls. Chances under 50 % also show as "1 in N". Check a type here before you enable it. Players see the
same with `/lootbox odds <category> [stars]` (enabled types only).

### 4.5 Active boxes and Drop log

**Active boxes** lists the boxes in the world with **Despawn** (it disappears in game within seconds). **Drop log**
lists every drop, filtered by source (World boxes, Token items, Staff gives) and more.

### 4.6 Token items

1. **Grant rules:** "Joining a premium tier (not extending it) or being granted a kit issues these tokens." Add one with
   **When a player** (joins a premium tier / gets a kit), **Box type**, **Box grade** (Rolled or ★1–★10), **How many**
   (1–64), **Add rule**. Without rules: "No rules: tokens are only issued by staff." Switching a rule off or on asks
   first (tokens already issued stay; switching on gives nothing to players who already qualified). **Deleting** a
   rule doesn't ask ([#459](https://github.com/PandiO/knk-workspace/issues/459)).
2. **Issued tokens:** filter by status (Unopened, Opened, Revoked) and who issued them. **Revoke** an unopened token:
   it is removed from online players within seconds and from offline players when they join.

Tokens can be traded between players; a revoke still finds them.

### 4.7 In-game commands

`/knk lootbox spawn <category> [stars]` (at your feet, ignoring caps), `despawn [id|nearest]`, `list [area]`,
`tp <id>`, `give <player> <category> [stars]` (opens a box for them now; not counted in their cap), `token <player>
<category> [stars|any] [1-64]`, `area create|list|info|delete <name>`, `reload`. Nodes `knk.lootbox.admin.<action>`;
see the [commands reference](../users/commands.md#money-kits-and-lootboxes-staff). `give` and `token` are refused while
the player is in a siege.

### 4.8 When changes reach the game

The game server re-reads the lootbox settings and active boxes every `lootboxes.runtime-refresh-seconds` (60). With
`realtime.enabled: true` (off by default) a save is pushed at once; a despawn or revoke always arrives within seconds.
`/knk lootbox reload` re-reads `config.yml` and refreshes from the API. The `lootboxes:` keys (display, reel, claim
distance, full inventory, staff mode) are in [plugin configuration § 4.21](plugin-configuration.md#421-lootboxes).

## 5. Discoveries

The first entry into a Town, District, Structure or GateStructure is rewarded once per account. The rewards are set
on `/admin/discovery` ("Rewards for a player's first entry into a town, district, structure or gate.").

### 5.1 Reward rules

One row per type, **Edit** then **Save** or **Cancel**:

| Column | Meaning | Seed: Town / District / Structure, Gate |
|---|---|---|
| **Enabled** | Discovery on for this type | all on |
| **XP units** (min–max) | A unit is 1 % of the player's title step (the top title uses the step below; 25 XP without brackets) | 1–4 / 0.5–2 / 0.05–0.25 |
| **Coin salary-hours** (min–max) | Times the player's salary per hour | 2–8 / 0.5–2 / 0.05–0.25 |
| **Gems** (min–max) | Flat whole number | 5–15 / 1–3 / 0 |
| **Discovers parents** | Entering also discovers (and rewards) the district and town around it | no / yes / yes |

The amount is a random value in each range; personal and rank multipliers apply on top. Values can't be negative or
above 1,000 (gems 100,000), and min can't exceed max. Switching **Structure** on or off asks whether to apply it to
gate structures too.

**Reward preview per title** shows what each title would get ("Preview for" a type or an overridden domain), before
multipliers, also for unsaved edits.

### 5.2 Per-domain overrides

**Per-domain overrides:** pick a **Domain** and **Add override**. Leave a field blank to inherit the type's rule
(shown greyed out); **Enabled** and **Discovers parents** can be Inherit, Yes or No. **Remove override** asks first.
The domain list shows the first 1,000 domains by name. A domain's sub-regions count as the domain.

### 5.3 Statistics and resets

1. **Statistics:** per place how many players discovered it and who was first, sorted most or least discovered or by
   name, and the **Top explorers**. Percentages are of active players with a linked account.
2. **Player profile → Discoveries** (needs `knk.admin.discovery`): the player's places with date and rewards, and a
   reset per row: "Reset discovery? … The player keeps the reward they got and can discover (and be rewarded for) it
   again." It is recorded in the audit log.
3. In game: `/knk discovery list <player> [page]`, `reset <player> <domainId>`, `status` (tracker and spool sizes),
   node `knk.admin.discovery`. There is no grant command ([#462](https://github.com/PandiO/knk-workspace/issues/462)).

### 5.4 When changes reach the game

Rules and overrides are read at every discovery, so they count from the next one. A reset reaches the game server as
a notification; the player can discover the place again right away, even while standing in it. Two delays
([#462](https://github.com/PandiO/knk-workspace/issues/462)): a type or domain switched back **on** is only
discoverable for online players after they rejoin, and a region that just became a domain can take up to 10 minutes
for players already standing in it.

The `discovery:` keys (detection on or off, excluded game modes, siege players, the API-down spool, sound, particles,
messages) apply after a restart; see [plugin configuration § 4.11](plugin-configuration.md#411-discovery). New
players' messages are held for `onboarding.discovery-quiet-minutes` (10). The API also caps a player at 120 new
discoveries an hour (`Discovery:MaxNewPerHour`); the rest is retried a minute later.

### 5.5 Effect on existing data

| Change | Effect |
|---|---|
| A reward rule or override | Not retroactive; past rewards stay as paid. |
| A type or domain disabled | Its past discoveries are hidden from counts, menus and statistics, not deleted; enabling shows them again. |
| A domain deleted | Its discoveries and override are deleted; the reward postings stay in the ledger. A new domain on the same region rewards again. |
| A reset | The reward isn't taken back; the next discovery pays again. |

## 6. `/knk item more`

`/knk item more [amount]` copies the item in your main hand. It needs `knk.admin.item` and `knk.admin.item.more`
(seeded for Admin; Staff have only `knk.admin.item`).

1. **No amount:** fills the held stack to its maximum (`Filled your stack to 64.`); if it is already full, puts another
   full stack in a free slot (`Gave you another stack of 64.`).
2. **An amount** (1 or more, suggestions 1, 8, 16, 32, 64): adds that many like a pickup, topping up stacks first.
   Nothing is dropped: `Gave you X of N; your inventory had no room for Y more (not given).`
3. **An item with an instance id** (a minted item, for example from a lootbox): each copy gets a **new instance id**
   from the API and is a single item, as many as you have free slots (at most 64 a call):
   `Gave you N copies with new instance ids (…).` Without the API: nothing is given.

`/knk item more 0` or extra words print `Usage: /knk item more [amount]`.

## 7. Safe test procedure

Use a test server or dev, a non-op test account and an item category nobody plays with. Leave production settings as
you found them.

1. **Currency:** two test accounts older than 48 hours with the Peasant title. Pay under and over 100,000 coins (the
   confirm), let one confirm expire, try `/pay <name> 1 gems` and paying yourself. Lock the receiver on the profile
   and pay again. **Adjust balance** with category **Testing**, then reverse that transaction. Switch coin payments off,
   try `/pay`, switch them on.
2. **Kits:** make a kit with a node such as `knk.kit.test` and a 60-second cooldown. Check `/kit list` and the menu
   tooltip as the test account without and with the node, claim it with a full inventory, then use `/kit give` on
   yourself. Delete the test kit afterwards (claims and purchases go with it).
3. **Lootboxes:** set up a small test area, or `/knk lootbox spawn <category> 6` to see a spawn announcement. Pick it
   up, open the token, and check the Drop log and Token items. `/knk lootbox token <you> <category> 5 3`, then revoke
   one while online. Try a pickup in a siege, from 6 blocks, with a full inventory and in staff mode. With the global
   switch off, try both a pickup and a token open.
4. **Discoveries:** give a test structure an override, enter it, check `/knk discovery list <you>`, reset it while you
   stand inside and see it discovered again. Check creative mode gives nothing. Stop the API, enter a place, check
   `/knk discovery status` (spool), start the API and wait for the "While the server was busy" summary.

Smoke tests: [settings pages](../settings-pages-smoke-test.md) (lootbox settings, currency policy).

## 8. Common problems

| Problem | Likely cause |
|---|---|
| Players can't use `/kit` at all | The kit nodes aren't granted to Default ([#456](https://github.com/PandiO/knk-workspace/issues/456)). |
| A kit granted on the web never arrived | [#261](https://github.com/PandiO/knk-workspace/issues/261); use `/kit give`. |
| A kit edit doesn't show in the menu | The plugin's cache (up to 60 s), see § 3.2. |
| No lootboxes spawn | Lootboxes off, the type disabled, the area disabled or its region gone, fewer players online than the area's minimum, or the caps reached. Check Active boxes and `/knk lootbox list`. |
| A lootbox setting doesn't apply | Wait for the runtime refresh (60 s) or `/knk lootbox reload`. |
| Nobody can open tokens | Lootboxes are switched off globally ([#457](https://github.com/PandiO/knk-workspace/issues/457)). |
| Players can't pay coins | The kill switch is off (maybe by the currency monitor: check Currency alerts), or the sender is too new, too low a title or locked. |
| A player didn't hear about a payment | They were offline and the API restarted ([#461](https://github.com/PandiO/knk-workspace/issues/461)); the payment is in the ledger. |
| A place gives no discovery | The type or domain is disabled, the player is excluded (creative, staff mode, siege), it was already discovered, or it was re-enabled while they were online (rejoin, [#462](https://github.com/PandiO/knk-workspace/issues/462)). |
