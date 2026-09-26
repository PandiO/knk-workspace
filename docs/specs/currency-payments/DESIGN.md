# Currency Payments & Ledger (coins/gems) — Design

**Status:** Decided — implementation in progress (branch `claude/currency-payments`)
**Last updated:** 2026-09-26
**Linear:** [KNG-21](https://linear.app/kngpandi/issue/KNG-21/currency-ledger-and-secure-player-payments-pay-balance-baltop-for) (Phase 0 split out as [KNG-22](https://linear.app/kngpandi/issue/KNG-22/security-coingem-write-endpoints-are-anonymous-phase-0-currency), urgent)
**Sources:** `knk-v1-archive` (`src/Currency/*`, `src/Users/User.java`, `src/Main/Main.java`, `src/Listeners/PlayerListener.java`, `src/Menu/{PlayerManagerClick,DuelSetupClick}.java`, `src/Skills/PickpocketSkill.java`, `src/Events/FridayLottery.java`, `plugin.yml`); `knk-v2-archive` (`model/user/{User,KnKUser}.java`, `model/minigame/siege/Siege.java`); knk-web-api `claude/siege-minigame` @ `cd95dd1` (contains `master` up to the KNG-7/8 merge minus the chat-color diff) plus `origin/master` `a102eea` and the KNG-16 branch `claude/practical-clarke-od321q` `1d3f198` where they differ; knk-plugin `claude/siege-minigame` @ `0fa6d06`; knk-web-app `claude/siege-minigame` @ `9a6f347`. Docs: `specs/legacy/{commands-v1,commands-v2,user-system,events-v2,inventory-menu-screens}.md`, `specs/user-features/{DESIGN,COMMAND_CATALOG_V3}.md`, `specs/user-management/DESIGN.md`, `specs/kits/DESIGN.md`, `specs/inventory-menu/CONTENT_PORT_PLAN.md`, `architecture/web-api-architecture.md`, Linear KNG-15/KNG-16.

---

## 0. Scope

**In scope**
- Player-to-player transfers (`/pay`), balance lookup (`/balance`), leaderboard (`/baltop`), personal
  transaction history, in-game and web.
- A **double-entry, append-only currency ledger** as the single source of truth for coins and gems,
  exposed as one internal `ICurrencyService` that every other feature must use (§3.3).
- Hardening **every existing** coin/gem mutation path in v3: admin adjustments, salary, siege rewards,
  title-promotion bonuses, kit claim costs/purchases, starting balances, account merges.
- API authentication/authorization **for currency-affecting endpoints** (the minimum needed; general
  API auth for everything else stays its own effort).
- Transfer policy (limits, caps, cooldowns, confirmation, new-account rules), admin grant/take/set
  with mandatory reasons, reversals, reconciliation, anomaly alerts, observability.

**Explicitly out**
- Real-money top-up / payment gateway (Kits DESIGN §5.2 already defers it). The ledger reserves a
  `PREMIUM_TOPUP` reason code and `SYS_STORE` account so it can plug in later.
- Shops, trades, auctions, player-run markets, item-for-coin trades (v1 had none as a generic system;
  house/property/room purchases belong to their own future features and will call `SpendAsync`).
- XP. XP stays on `User.ExperiencePoints` and in `UserService`; only the coin/gem *bonuses* a title
  change grants go through the ledger.
- Designing lootboxes, domain discovery, teleport costs (sibling specs); this spec only defines the
  API they call.
- v1's gold/diamond pickup-to-currency conversion, death coin drops, pickpocket, duel bets, lottery
  (catalogued in §1.1 as exploit history, not ported).

---

## 1. Legacy design and v3 today

### 1.1 v1 (Bukkit, raw JDBC)

**Commands** (`v1:plugin.yml:29-39`, wired `v1:src/Main/Main.java:589-593`, all in
`v1:src/Currency/CoinCommands.java` except `/gems`):

| Command | Permission | Behaviour |
|---|---|---|
| `/pay <coins\|gems> <name> <amount>` | **none** | Transfers from sender to target, online or offline (`CoinCommands.java:27-105`) |
| `/balance [name]`, alias `/bal` | none | `"<name> has <coins> Coins and <gems> Gems"` / `"You have X Coins and Y Gems"` (`:211-231`) |
| `/coins <set\|add\|remove\|delete\|del> <amount\|all> [name]` | `k&k.coins` | Admin edit; 2-arg form targets self (`:106-210`, helpers `:235-352`) |
| `/gems <set\|add\|remove\|delete\|del> <amount\|all> [name]` | `k&k.gems` | Same for gems (`v1:src/Currency/GemCommands.java:38-148`) |
| Player Manager menu (owner mode) | menu-gated | Coin/gem/XP steppers "Steps of 1/50/100/250/500/5000/20000" (`v1:src/Menu/PlayerManagerClick.java:563-689`) |

No `/baltop` existed in v1 or v2 (grep `baltop|richest|ORDER BY Coins` → nothing).

**Messages** (verbatim, typos included): `"Use /pay <coins/gems> <name> <amount>"`, `"Your balance is too
low: "`, `"Succesfully sent <name> <n> Coins."`, `"You recived <n> Coins from <sender>."`
(`CoinCommands.java:31,51,57,61`). Amounts formatted with `NumberFormat.getCurrencyInstance(Locale.GERMANY)`
split at `,` → `"1.234.567"` (`v1:src/Handlers/ColorOptions.java:155-160`).

**Data model / mutation.** `User` holds `int coins`, `int gems` loaded from the `Player` table
(`v1:src/Users/User.java:114,130,272,284`). `addCoins` has no upper bound; `removeCoins`/`removeGems`
**clamp to 0** (`:1440-1451`, `:1480-1489`). Persistence is a string-concatenated full-row
`UPDATE Player SET … Coins=…, Gems=…` (`getSaveQuery`, `:373-440`) run asynchronously on `destroy()`
(`:579-618`, `:752-766`) and in the batch `saveUsers` on reload/disable (`v1:src/Main/Main.java:1628-1640`,
`:490`, `:1952`). There is no transaction, lock, or log other than one console line per payment
(`User.java:1460`).

**Mint/burn sources** (47 call sites; grep `addCoins|removeCoins|addGems|removeGems|sendCoins`): salary and
property income (`SalaryPayout.java:37`, `IncomePayout.java:40`), rent (`RentPayment.java:51`), title
promotion bonus (`Titles/TitleChangeEvents.java:185-186`), votes (`Votes/VoteEvent.java:132-133`),
assignments/quests/tutorials, kills (`KillsDeaths/KillDeathStat.java:264-282`), minigames (siege
`Sieges/Siege.java:817`, hide-and-seek, bandits, transport, duels), lottery, pickups, gem-shop and
teleport spend (`Menu/GemShopClick.java:61`, `Teleport/TeleportDelay.java:255`), house/property/room buy/sell.

**Known bugs and exploits (verified in source)**

| # | Exploit / bug | Evidence |
|---|---|---|
| L1 | **Negative-amount `/pay` steals from the target and mints for the sender.** The "negative" guard checks the *name* (`args[1].contains("-")`), not the amount. `/pay coins Bob -5000`: `getCoins() < -5000` is false, `sendCoins` → `target.addCoins(-5000)` (no clamp, target can go negative) and `this.removeCoins(-5000)` → sender +5000. Same for gems. `commands-v1.md:190` notes the misplaced check but not this consequence. | `CoinCommands.java:29,49,58,73,90`; `User.java:1432-1466,1491-1504` |
| L2 | **Lost updates and crash dupes.** `sendCoins` always builds a *second* `new User(targetUUID)` even when the target is online and cached, credits and saves it; the online instance keeps the old balance and overwrites the payment on its next full-row save. The sender's debit exists only in memory until *their* save, so a crash after paying an offline alt duplicates the coins. | `User.java:1455-1465`, `:205-213`, `:579-618` |
| L3 | **Pay-to-farm XP.** Every coin `/pay` fires `PlayerPayEventHandler`; the listener gives the *payer* `coinamount/100` XP (message names the payer as the trading partner). Ping-pong between alts farms XP and, through titles, coin/gem bonuses. | `CoinCommands.java:66`; `v1:src/Currency/PlayerPayEvent.java:28-32` |
| L4 | No input validation: unparsed `Integer.valueOf` (NumberFormatException), unchecked `(Player) sender` cast (console crash), self-pay and 0 allowed, "This player does not exist!" printed *after* sending to an offline player. | `CoinCommands.java:34,49,56,64,73` |
| L5 | **Any gold/diamond item converts to currency on pickup**: nugget 100–10,000, ingot 10,000–25,000, block 25,000–80,000 coins each (× personal multiplier); diamond 1–15 gems, 80% chance. Items with lore are paid `Integer.valueOf(lore[0].split(": ")[1])`, so a gold item with a forged lore line (e.g. via `/lore`) mints any amount. Death drops use lore `"Coins: 10.000"`, which fails that parse after the item is already removed, so the coins are destroyed. | `CoinsPickupEvent.java:35-69`; `GemPickupEvent.java:36-64`; `Listeners/PlayerListener.java:1113-1114` |
| L6 | Death deducts `coins/dropPercentage` (`dropPercentage = 10`) **twice** when killed by a player. | `PlayerListener.java:1030-1031,1111`; `Main.java:254` |
| L7 | Clamp-to-zero spends mint money: duel approval `removeCoins(coins)` for both players (a broke player pays 0) but the pot is `coins*2`. | `Menu/DuelSetupClick.java:257-260`; `Arenas/Duel.java:311` |
| L8 | Admin tooling bugs: "instant salary payout" pays the **admin** (`user.SalaryPayout(utarget)`); `/coins set` on an online player calls `target.destroy()`, evicting the live player from the `Users2` cache; `/coins <typo>` is a silent no-op. | `PlayerManagerClick.java:315`; `CoinCommands.java:250-251,110-201` |
| L9 | Pickpocket skill and the "generous mood" effect move coins via `sendCoins`, so they inherit L2. | `Skills/PickpocketSkill.java:77,97`; `Effects/Effect.java:161` |
| L10 | Only alt control anywhere: lottery entry refused when `getAddressMatches(address) >= 3` (same IP). | `Events/FridayLottery.java:169` |

### 1.2 v2 (Hibernate)

- The live `User` entity has a single `int cash` (default `CASH_DEF = 100`); no gems
  (`v2:model/user/User.java:81,102-103`). No `/pay`, `/balance`, `/cash` or admin command exists
  (`commands-v2.md:483-484`).
- `login()` credits **+1 cash on every login**, so relogging farms it (`User.java:507`).
- `removeCash` *adds* the amount and then sets the balance to 0 (`User.java:257-263`). It has no
  callers.
- Siege rewards: `member.getUser().addCash(totalCoinReward)` (`model/minigame/siege/Siege.java:958`).
- The abandoned `KnKUser` draft is the only place with caps: `CASH_MAX = 999_999_999`, `GEMS_MAX = 999_999`,
  defaults 1000/100 (`model/user/KnKUser.java:29-44`). They are never enforced. There is no `@Version`
  or optimistic locking anywhere in v2.

### 1.3 v3 today

- **Fields:** `User.Coins int = 250`, `User.Gems int = 50`, `ExperiencePoints int` (`knk-web-api:Models/User.cs:53,61,69`).
  MySQL `INT`, no CHECK constraint, no concurrency token (`Properties/KnKDbContext.cs`; the only
  `[Timestamp]` in the model is `WorkflowSession`). The doc comments say "Coins: premium, tied to real
  money" and "Gems: free-to-play". The Kits design (§5.2) and vision treat **Gems** as premium, so the
  comments are wrong or the docs are (§5 Q1).
- **Write paths:** `UserService.AdjustBalancesAsync` (`Services/UserService.cs:618-718`), the generic
  `UpdateAsync` (`:177-252`), `UpdateCoinsAsync`/`ByUuid` (`:254-270`), `SalaryService.PayOutAsync`
  (`Services/SalaryService.cs:42-104`), `SiegeMatchService.CompleteAsync` (`:156-270`),
  `TitleProgression.ApplyExperienceChange` (`Services/TitleProgression.cs:21-58`; on `master`/KNG-16 the
  same logic is inline in `AdjustBalancesAsync`), and `KitService.ClaimKitAsync`/`PurchaseKitAsync`
  (`Services/KitService.cs:233-236,262-273,413-417`).
- **Endpoints:** `PUT api/Users/{id}/coins` and `PUT api/Users/{uuid}/coins` set an absolute value;
  `PUT api/Users/{id}/balances` takes signed deltas plus a reason; `PUT api/Users/{id}` is the generic
  FormWizard edit; `POST api/Users/{id}/salary/payout`; `POST api/Kits/{id}/claim|purchase?userId=`;
  `POST api/SiegeMatches/…` (`Controllers/UsersController.cs:508-590,758-815`; `Controllers/KitsController.cs:118-155`).
- **Audit:** `AuditLogEntry` (append-only by convention, `Models/AuditLogEntry.cs`) records
  `BalanceAdjusted` and `SalaryPayout` with deltas in JSON. `RetentionPolicyService` purges it after
  `RetentionDays` (default 180) (`Services/RetentionPolicyService.cs:114`,
  `Models/AuditLogRetentionConfiguration.cs`).
- **Plugin:** `/knk user <p> coins|gems|xp set|add|remove <amount> [reason…]` (nodes
  `knk.admin.user.coins|gems|xp`, `plugin.yml:157-160`) → `UserAdminService.changeBalance`
  (`knk-paper/.../user/UserAdminService.java:185-234`). The Player Manager menu has a `users.adjust`
  stepper action (`menu/content/UserManagerMenuFeature.java:299-315`). Salary is triggered on join
  (`listeners/PlayerListener.java:182,243-264`; KNG-16 adds an hourly scheduler). Balances are displayed
  from the cached `UserSummary` (users cache TTL 15 min, `allow-stale: true`, `config.yml:202-208`).
  There is no `/pay`, `/balance` or `/baltop`.
- **Web app:** read-only balance on `AccountManagementPage.tsx:198-203`. `PlayerProfilePage.tsx:237-262,413-478`
  has an adjust quick action (reason required in the UI) that calls `PUT /balances`. The generic User
  FormWizard can edit coins and gems.
- **Good precedent:** siege rewards run in one transaction under a match row lock
  (`SELECT … FOR UPDATE`), lock user rows in ascending id order, and are idempotent by match status
  (`Repositories/SiegeMatchRepository.cs:107-123,161-170`; `SiegeMatchService.cs:170-174,234-262`).
  Scenario rewards are validated non-negative (`SiegeScenarioService.cs:383-385`).

### 1.4 v3 currency exploit audit

Severity is for a public server: **Critical** means anyone can mint or steal now; **High** means dupes or
mints reachable through normal play or admin tooling; **Medium** means integrity or forensics gaps;
**Low** means hygiene.

| ID | Sev | Finding | Evidence |
|---|---|---|---|
| A1 | **Critical** | **Every currency-mutating endpoint is anonymous.** `UsersController` has no class-level `[Authorize]` (only `LinkMinecraftAccount`, `:1240`) and there is no fallback policy (`Program.cs:148-157` registers only a placeholder `RequireAdmin` that no issued JWT can satisfy, since `TokenService.cs:61-64` never adds role claims). No endpoint checks the caller's permission nodes (`PermissionResolutionService` is only consulted *about* a target user). Anyone who can reach the API can: set any balance (`PUT {id}/coins`, which also accepts negatives and writes no audit entry), apply any delta (`PUT {id}/balances`), or PUT the whole user with `coins`/`gems`, because `UserMappingProfile` maps them (`UserService.cs:190-196` documents this). They can also spend another player's gems on kits (`POST Kits/{id}/purchase?userId=`) and mint siege rewards by creating and completing a fabricated match (`[RequirePluginServiceKey]` is open while `Security:PluginServiceKey` is `""`, `appsettings.json:31`, `Attributes/RequirePluginServiceKeyAttribute.cs:34`). **So yes: a web user can set their own or anyone's balance, and so can an unauthenticated caller. The plugin has no service token at all**: `api.auth.type: none` ships as default (`knk-paper/src/main/resources/config.yml:13-15`), and the `X-Acting-User-Id` header it sends (`UsersCommandApiImpl.java:47,82-87`) is read nowhere in knk-web-api, so in-game admin edits are audited as actor `null`. The web app's `/admin/users/:id` route is guarded only by "logged in" (`knk-web-app:src/components/ProtectedRoute.tsx`). | cited inline |
| A2 | **High** | **Lost updates and dupes from full-row writes.** Every `UserRepository` write calls `_context.Users.Update(user)`, which marks *all* columns modified, so `Coins`/`Gems` are rewritten from whatever snapshot the request loaded (`Repositories/UserRepository.cs:44,54,65,76,87,99,258,270`). The balance paths read, modify and write with no lock or token (`UserService.cs:633-664`, `SalaryService.cs:46-88`, `KitService.cs:262-273`). Concrete races: (a) `onJoin` fires presence and salary concurrently (`PlayerListener.java:159,182`), so the presence write can erase the payout; (b) a kit purchase racing any other user write restores the spent gems while the `KitPurchase` row persists, which is a gem dupe; (c) two concurrent `/balances` calls lose one delta. This is the same class of bug as v1 L2. | cited |
| A3 | **High** | **No idempotency.** A timed-out `PUT /balances` or salary payout that the client retries applies twice. OkHttp's default `retryOnConnectionFailure=true` is left on (`knk-api-client/.../client/KnkApiClient.java:381-384`). Two overlapping salary calls both see `elapsed ≥ 1h` and both pay (`SalaryService.cs:52-78`); KNG-16's hourly scheduler makes overlaps more frequent. | cited |
| A4 | **High** | **Negative prices mint gems.** `Kit.PremiumPriceGems` and `CostAmount` are never validated as non-negative (`KitService.cs:101,104`). `PurchaseKitAsync` does `if (user.Gems < price) … user.Gems -= price`, so a negative price credits gems (`:262-266`). Kit CRUD is anonymous (A1). | cited |
| A5 | **High** | **Title-bonus re-grant loop.** Promotion credits `CoinBonus`/`GemBonus` for every crossed bracket; demotion never claws back, and nothing records that a bracket was already paid (`TitleProgression.cs:21-58`). Taking XP down and back up re-pays. A full 0→160,000 XP cycle re-grants **4,028,210 coins + 600 gems** from the seeded brackets (`Migrations/20260925112304_…RealTitleDataAndFreeze.cs:111-130`), and more once KNG-16's bonus multipliers apply. Reachable via the admin "set title" action (`UserAdminService.setTitle`), an XP penalty followed by re-earning, or A1. | cited |
| A6 | Medium | **Admin "set" uses client-side arithmetic.** `changeBalance` computes `delta = amount - cachedValue` from a possibly 15-minute-stale `UserSummary` and prints `"(now current+delta)"` without reading the server's `NewCoins` (`UserAdminService.java:185-219,251-256`). The in-game reason is optional and defaults to `"/knk user command by <name>"` (`UserManagementCommand.java:120-122`). Menu steppers write `"Player manager (<name>)"` (`UserManagerMenuFeature.java:314`). | cited |
| A7 | Medium | **The audit trail is not atomic, complete or durable.** The audit row is saved in a separate `SaveChanges` after the balance commit (`UserService.cs:669-685`, `AuditLogRepository.cs:19-23`). Kit costs, kit purchases, siege rewards (kept only on `SiegeMatchParticipant.CoinsAwarded`) and `PUT {id}/coins` write no audit entry. Entries record deltas but no before/after balance, are purged after 180 days, and the retention setting can be lowered to 1 day anonymously. | cited |
| A8 | Medium | **Unchecked `int` arithmetic, no ceiling.** `AdjustBalancesAsync` rejects overflow only by accident: a wrapped value is negative, so the check fails as "Insufficient coins" (`UserService.cs:637-645`). The `+=` in title/siege/salary paths has no upper bound (`TitleProgression.cs:57-58`, `SiegeMatchService.cs:244-245`, `SalaryService.cs:76`). The salary `(int)Math.Round(decimal)` throws `OverflowException` for huge multipliers; `PersonalSalaryMultiplier` is only checked non-negative and is editable through the generic PUT. | cited |
| A9 | Medium | **No DB-level invariants.** No `CHECK (Coins >= 0)`, no row version. `PUT {id}/coins` writes negatives straight through (`UserRepository.cs:48-57`). | cited |
| A10 | Medium | **Account merge orphans balances.** The secondary account's coins/gems stay on a soft-deleted row with no record (`UserRepository.cs:283-310`); the player picks A/B in chat (`AccountLinkCommand.java:201-250`). `POST api/Users/merge` is anonymous. | cited |
| A11 | Medium | Salary accrued the full offline gap without limit (`SalaryService.cs:65-74`), with `LastSalaryPayoutAt` defaulting to account creation (`User.cs:130`). That made every idle alt a salary farm once `/pay` exists. **KNG-16 (`8bf0946`, unmerged) adds log decay and `OfflinePayoutMaxHours = 720`**, which bounds but does not remove the incentive. | cited |
| A12 | Low | Dead attack surface: the plugin's `setCoinsById/ByUuid` sends `{"cash":N}` (`CoinsUpdateDto.java`) while the API expects a bare `int` body, so it's broken and has no callers. The endpoints still exist server-side. | cited |
| A13 | Low | Balance-sensitive UX reads the cache: the welcome message and profile read cached balances (`UserAccountListener.java:164-168`). Harmless today, but any future client-side affordability check would be exploitable. | cited |
| A14 | Low | Test gap: every API test uses EF InMemory (`Tests/.../Integration/*.cs`), which silently skips `FOR UPDATE` (`SiegeMatchRepository.cs:164`) and transactions, so no concurrency guarantee is tested today. | cited |

---

## 2. Gap analysis

| Capability | v1/v2 behaviour | v3 today | Reusable v3 component (path) | Work |
|---|---|---|---|---|
| Player transfer | v1 `/pay <coins\|gems> <name> <amt>`, no perm, L1–L4; v2 none | none | `CommandRegistry`, `KnkPermissible`, async `UserAdminService` pattern, `ChatCaptureManager` (plugin) | L |
| Balance lookup | v1 `/balance [name]` | welcome line; web `AccountManagementPage` | `UsersDataAccess`, `UserSummary` | S |
| Leaderboard | none | none; `UserRepository.SearchAsync` supports sort `"coins"` (`:192`) | `SearchAsync` | S |
| Admin grant/take/set | v1 `/coins`,`/gems`, menu steppers | `/knk user … coins\|gems`, `PUT /balances`, web quick action, generic PUT, `PUT /coins` | `UserAdminService`, `PlayerProfilePage.tsx`, `userManagementClient.ts` | M (retarget, reason codes) |
| Ledger / history | console line only | partial `AuditLogEntry`, purged | `AuditLogService` for cross-links | L |
| Atomic, locked mutation | none | siege path only | `SiegeMatchRepository.RunLockedAsync`/`LockUsersAsync` | M |
| Idempotency | none | siege match status | same | M |
| Limits/caps/cooldowns/confirmation | none | none | `SalaryConfiguration` singleton + web form pattern | M |
| Gem transferability | allowed | n/a | — | S (policy flag) |
| Alt / new-account rules | lottery IP < 3 | none; `User.CreatedAt`, title/XP available | `TitleService.ResolveAsync` | S |
| Reversal / refund | none | none | — | M |
| Anomaly detection, reconciliation | none | none | `RetentionPolicyService` hosted-service pattern, OpenTelemetry | M |
| Offline notification | message lost | `IPlayerNotificationQueue` (title changes only) | `Services/Interfaces/IPlayerNotificationQueue.cs`, plugin poller | S |
| Web views | none | balance display, audit log viewer | `PlayerProfilePage`, audit log UI | M |
| API authZ on currency writes | n/a | none | `RequirePluginServiceKeyAttribute`, `PermissionResolutionService.CheckAsync` | M |
| Migrate existing mutation paths | — | 6 services write `Coins`/`Gems` directly | — | M |

**Reuse as-is:** siege's lock-ordering and transaction helper (generalize it into the ledger repository),
`PermissionResolutionService.CheckAsync` for server-side node checks, `IPlayerNotificationQueue` + the plugin
poller (new notification types), the `SalaryConfiguration`-style singleton pattern for policy,
`KnkPermissible`/`CommandRegistry` for commands. **Extend:** `RequirePluginServiceKeyAttribute` (make it
mandatory for currency routes and honour `X-Acting-User-Id` only behind it), `UserAdminService`,
`PlayerProfilePage`, `AccountManagementPage`. **Build new:** ledger tables and `CurrencyService`, the
transfer/pending/policy/alert entities, `CurrencyController`, plugin `CurrencyApi` and commands,
anomaly monitor, web ledger/policy/history pages.

---

## 3. v3 design

### 3.1 Principles (invariants every path must satisfy)

1. **Ledger is the truth.** No code outside `CurrencyService` writes `users.Coins`/`users.Gems`. The
   columns remain as a *materialized balance* (existing DTOs, sorting and plugin reads keep working) and
   are updated only inside the ledger transaction. A reconciler proves `balance == Σ entries` (§3.9).
2. **Double entry.** Every transaction's entries sum to zero per currency. Mints are debits of a system
   account; burns are credits to one.
3. **Atomic and locked.** One DB transaction per posting. User rows are locked
   `SELECT … FOR UPDATE` in ascending id order (the siege precedent) before balances are read.
4. **Idempotent.** Every posting carries an idempotency key, unique per `(Scope, Key)`. A retry returns
   the stored result and never posts twice.
5. **Integers only, bounded.** Amounts are positive `long` in `[1, MaxPerTransaction]`, arithmetic is
   `checked`, user balances stay within `[0, MaxBalance]`, enforced in code **and** by DB CHECK.
6. **Append-only.** No update or delete of ledger rows. Corrections are reversals. The ledger is exempt
   from `RetentionPolicyService`.
7. **Server authority.** The plugin never computes a resulting balance. It shows what the API returns.

### 3.2 Data model (knk-web-api, EF Core, one migration per phase)

```
currency_transactions                         -- header, one per posting
  Id                BIGINT PK AUTO_INCREMENT
  PublicId          CHAR(26) UNIQUE           -- ULID shown to players/admins ("TX 01J…")
  Kind              TINYINT                   -- Grant | Spend | Transfer | AdminAdjust | Reversal | Migration | Merge
  Reason            VARCHAR(40)               -- CurrencyReason code (§3.3), stored as string
  SourceType        VARCHAR(40) NULL          -- e.g. "SiegeMatch", "Kit", "Lootbox"
  SourceRef         VARCHAR(64) NULL          -- e.g. "123"
  IdempotencyScope  VARCHAR(40)               -- "plugin" | "web" | "system"
  IdempotencyKey    VARCHAR(100)              -- UNIQUE (IdempotencyScope, IdempotencyKey)
  RequestHash       CHAR(64)                  -- SHA-256 of canonical request; key reuse with a different body → 422
  Initiator         TINYINT                   -- Player | Admin | System | PluginService
  ActorUserId       INT NULL                  -- verified actor (never a client-claimed value without service auth)
  FromUserId        INT NULL, ToUserId INT NULL   -- denormalized for transfer queries
  Note              VARCHAR(500) NULL         -- admin reason text / player memo
  MetadataJson      JSON NULL
  ReversesTransactionId BIGINT NULL UNIQUE    -- a transaction can be reversed at most once
  CreatedAt         DATETIME(6)
  INDEX (FromUserId, CreatedAt), (ToUserId, CreatedAt), (Reason, CreatedAt)

currency_entries                              -- legs; ≥2 per transaction, Σ Amount = 0 per currency
  Id BIGINT PK, TransactionId BIGINT FK
  Currency       TINYINT                      -- Coins | Gems
  AccountKind    TINYINT                      -- User | System
  UserId         INT NULL                     -- when AccountKind = User
  SystemAccount  VARCHAR(30) NULL             -- when AccountKind = System (§3.3)
  Amount         BIGINT                       -- signed
  BalanceAfter   BIGINT NULL                  -- user legs only: enables statements + reconciliation
  INDEX (UserId, Currency, Id), (SystemAccount, Currency, TransactionId)

currency_pending_transfers                    -- confirmation step (§3.6)
  Id BIGINT PK, PublicId CHAR(26) UNIQUE, SenderUserId, RecipientUserId, Currency, Amount BIGINT,
  IdempotencyKey VARCHAR(100) UNIQUE, Status (Pending|Confirmed|Cancelled|Expired),
  CreatedAt, ExpiresAt, ResultTransactionId BIGINT NULL

currency_policies                             -- one row per currency, admin-editable (§3.5)
currency_alerts                               -- anomaly findings (§3.9): Id, Rule, Severity, UserId NULL,
                                              --   TransactionId NULL, DetailsJson, CreatedAt, AckedByUserId, AckedAt
users: + TransferLockReason VARCHAR(200) NULL, + TransferLockedAt DATETIME NULL
       + CHECK (Coins BETWEEN 0 AND 999999999), CHECK (Gems BETWEEN 0 AND 999999)
```

EF configuration: set `Coins` and `Gems` to `PropertySaveBehavior.Ignore` for both before- and after-save
(`Metadata.SetBeforeSaveBehavior`/`SetAfterSaveBehavior`). Then no `Users.Update(user)` anywhere can write
them, which closes A2 for every existing repository method at once. `CurrencyService` writes them with
`ExecuteUpdateAsync` inside the locked transaction. New users are inserted at DB default `0` and receive
their starting balance as a `SIGNUP_GRANT` posting. Immutability is enforced by the repository (no
update/delete methods) plus MySQL `BEFORE UPDATE`/`BEFORE DELETE` triggers on the two ledger tables that
`SIGNAL SQLSTATE '45000'` (§4 D7). MySQL enforces CHECK only from 8.0.16; verify the server version
(§5 Q7).

The `users.Coins/Gems` columns stay `INT`. The caps are v2's `KnKUser.CASH_MAX`/`GEMS_MAX`
(999,999,999 / 999,999), which fit `INT` with headroom. Ledger amounts are `BIGINT` so system-account
aggregates cannot overflow.

### 3.3 `ICurrencyService` — the internal API siblings depend on

`Services/Interfaces/ICurrencyService.cs` (scoped, uses the request's `KnKDbContext`):

```csharp
public enum Currency { Coins = 0, Gems = 1 }
public enum Initiator { Player, Admin, System, PluginService }

public sealed record CurrencyContext(
    string IdempotencyKey,          // required; deterministic for system sources (table below)
    CurrencyReason Reason,          // decides Kind + counter system account
    string? SourceType = null, string? SourceRef = null,
    int? ActorUserId = null, Initiator Initiator = Initiator.System,
    string? Note = null, string? MetadataJson = null,
    string IdempotencyScope = "system");

public sealed record CurrencyLeg(int UserId, Currency Currency, long Amount); // signed, ≠ 0

public interface ICurrencyService
{
    // Multi-leg posting; each leg's counter-entry goes to Reason's system account.
    // Used directly by batch sources (siege: all participants, one key "siege-match:{id}").
    Task<PostingResult> PostAsync(IReadOnlyList<CurrencyLeg> legs, CurrencyContext ctx, CancellationToken ct = default);

    Task<PostingResult> GrantAsync(int userId, Currency c, long amount, CurrencyContext ctx, CancellationToken ct = default); // mint
    Task<PostingResult> SpendAsync(int userId, Currency c, long amount, CurrencyContext ctx, CancellationToken ct = default); // burn
    Task<TransferResult> TransferAsync(TransferRequest req, CurrencyContext ctx, CancellationToken ct = default);          // user→user, policy-checked
    Task<PostingResult> AdminAdjustAsync(AdminAdjustRequest req, CurrencyContext ctx, CancellationToken ct = default);   // grant|take|set
    Task<PostingResult> ReverseAsync(long transactionId, ReversalOptions opts, CurrencyContext ctx, CancellationToken ct = default);

    Task<BalancesDto> GetBalancesAsync(int userId, CancellationToken ct = default);
    Task<PagedResultDto<LedgerLineDto>> GetHistoryAsync(LedgerQuery q, CancellationToken ct = default);
}

public sealed record PostingResult(long TransactionId, string PublicId, bool Replayed,
    IReadOnlyDictionary<int, BalancesDto> BalancesAfter);
```

- **Errors:** `CurrencyException(CurrencyErrorCode code, …)`. Codes: `InsufficientFunds`,
  `BalanceCapExceeded`, `AmountOutOfRange`, `NotTransferable`, `SelfTransfer`, `RecipientNotFound`,
  `AccountLocked`, `CooldownActive`, `DailyCapExceeded`, `NewAccountRestricted`, `ConfirmationRequired`,
  `IdempotencyKeyReuse`, `AlreadyReversed`, `ReversalWouldGoNegative`, `TransfersDisabled`. The
  controller maps them to 409/422 with `{ code, message, details }`.
- **Ambient transactions:** if `Database.CurrentTransaction` is set (siege `RunLockedAsync`, salary,
  kits), `CurrencyService` enlists and does not commit. Otherwise it opens a `ReadCommitted` transaction.
  Either way it locks the involved user rows ascending. Re-locking a row the caller already holds is a
  no-op in InnoDB.
- **Idempotency flow:** inside the transaction, after taking the locks, look up `(Scope, Key)`. If it
  exists with the same `RequestHash`, return the stored result with `Replayed = true`; with a different
  hash, throw `IdempotencyKeyReuse`. Otherwise post. The unique index is the final guard against two
  first attempts racing: the loser gets a duplicate-key error, rolls back, and re-reads the committed row.
  Denied attempts (for example insufficient funds) are **not** stored, so a retry re-evaluates.

**Reason codes and system accounts** (`Services/Currency/CurrencyReasons.cs`, a single table in code;
siblings add rows here):

| Reason | Kind | System account | Idempotency key (system sources) | Owner |
|---|---|---|---|---|
| `SIGNUP_GRANT` | Grant | `SYS_SIGNUP` | `signup:{userId}` | this spec |
| `SALARY` | Grant | `SYS_SALARY` | `salary:{userId}:{previousLastSalaryPayoutAt:O}` | user-features / KNG-16 |
| `SIEGE_REWARD` | Grant (multi-leg) | `SYS_SIEGE` | `siege-match:{matchId}` | siege |
| `TITLE_BONUS` | Grant | `SYS_TITLE` | `title-bonus:{userId}:{bracketId}` (**once ever**, fixes A5) | user-features |
| `KIT_CLAIM_COST` | Spend | `SYS_KITS` | `kit-claim:{clientKey}` | kits |
| `KIT_PURCHASE` | Spend | `SYS_KITS` | `kit-purchase:{kitId}:{userId}` | kits |
| `LOOTBOX_PURCHASE` / `LOOTBOX_REWARD` | Spend / Grant | `SYS_LOOTBOX` | `lootbox-open:{openingId}` | lootboxes |
| `DISCOVERY_REWARD` | Grant | `SYS_DISCOVERY` | `discovery:{userId}:{domainId}` | domain-discovery |
| `TELEPORT_FEE` | Spend | `SYS_TELEPORT` | client key | teleport |
| `EVENT_REWARD` | Grant | `SYS_EVENT` | `event:{eventId}:{userId}` | future |
| `PREMIUM_TOPUP` | Grant | `SYS_STORE` | provider payment id | future |
| `PLAYER_TRANSFER` | Transfer | — (user↔user) | client key | this spec |
| `TRANSFER_FEE` | Spend | `SYS_FEES` | `{transferKey}:fee` | this spec |
| `ADMIN_GRANT` / `ADMIN_TAKE` / `ADMIN_SET` | AdminAdjust | `SYS_ADMIN` | client key | this spec |
| `REVERSAL` | Reversal | mirror of original | `reverse:{transactionId}` | this spec |
| `MIGRATION_OPENING` | Migration | `SYS_MIGRATION` | `migration-opening:{userId}:{currency}` | this spec |
| `MERGE_FORFEIT` | Merge | `SYS_MERGE` | `merge:{secondaryUserId}` | this spec |

Rules for siblings: always pass a deterministic key when the source event has an identity; never catch
`InsufficientFunds` and retry with a smaller amount; call inside your own transaction when you also
write domain rows (for example a lootbox opening row), so both commit or neither does.

### 3.4 API (`Controllers/CurrencyController.cs`, route `api/currency`)

All mutating routes require an `Idempotency-Key` header (1–100 chars, `[A-Za-z0-9:_-]`); a missing key
returns 400. Callers:
- **PluginService:** a valid `X-API-Key` equal to `Security:PluginServiceKey`. It is mandatory on
  these routes and they fail closed when the key isn't configured. The only opt-out is
  `Security:AllowUnauthenticatedCurrencyWrites=true`, honoured only when `IsDevelopment()`.
  `X-Acting-User-Id` is trusted **only** on requests carrying a valid key.
- **Web:** JWT. Admin routes also run `[RequireKnkPermission("<node>")]`, a new filter that calls
  `PermissionResolutionService.CheckAsync(uid, node)`. For plugin calls that same filter checks the
  acting user's node, so revoking a node in the web app is enforced server-side.

| Method & route | Caller / node | Body → result |
|---|---|---|
| `GET api/currency/balances/{userId}` | service; JWT self; JWT `knk.admin.currency.history` | `{coins, gems}` |
| `GET api/currency/leaderboard?currency=coins&page=` | anonymous OK (public data) | top N; excludes locked accounts and holders of `knk.baltop.exempt`; cached 60 s |
| `GET api/currency/limits/{userId}?currency=` | service; JWT self | min/max, remaining daily send, cooldown end, `requiresConfirmationAbove` |
| `POST api/currency/transfers` | service (acting = sender); JWT self only if Q4 = yes | `{senderUserId, recipientUserId, currency, amount, note?}` → **200** `TransferResultDto` or **202** `{pendingTransferId, expiresAt, …}` when `amount ≥ ConfirmThreshold` |
| `POST api/currency/transfers/pending/{publicId}/confirm` / `/cancel` | same principal as creator | 200 result / 204. Confirm re-runs every check at confirm time |
| `GET api/currency/users/{userId}/transactions?page=` | service (acting = same user, or `knk.transactions.others`); JWT self | `LedgerLineDto[]`: time, reason, counterparty name, ±amount, balanceAfter, publicId, note |
| `POST api/currency/admin/adjustments` | service/JWT + `knk.admin.user.coins` or `.gems` | `{targetUserId, currency, mode: grant\|take\|set, amount, expectedCurrent?, reasonCode, note}`; `note` required, ≥ 10 chars; `set` is computed **server-side** under lock; `expectedCurrent` mismatch → 409 |
| `POST api/currency/admin/transactions/{publicId}/reverse` | `knk.admin.currency.reverse` | `{note, allowPartial=false}` |
| `GET api/currency/admin/transactions?…` / `{publicId}` | `knk.admin.currency.history` | filters: user, reason, kind, source, actor, date range, min amount |
| `PUT api/currency/admin/users/{id}/transfer-lock` / `DELETE` | `knk.admin.currency.lock` | `{reason}` |
| `GET` / `PUT api/currency/admin/policy/{currency}` | `.policy` | policy DTO; every change is audit-logged |
| `GET api/currency/admin/alerts`, `POST …/{id}/ack` | `.alerts` | |
| `GET api/currency/admin/reconciliation` | `.history` | last run + mismatches |

**Removed:** `PUT api/Users/{id}/coins`, `PUT api/Users/{uuid}/coins`. **Changed:** `PUT api/Users/{id}/balances`
keeps XP. Its coin/gem deltas delegate to `AdminAdjustAsync` in the same transaction and now require
`Idempotency-Key` + auth; it's deprecated in favour of the admin adjustments route. `UserMappingProfile`
ignores `Coins`/`Gems` on `UserDto → User`, so the generic PUT can't touch balances; `UserDto` still
carries them read-only. `POST api/Users/{id}/salary/payout`, Kits claim/purchase, `SiegeMatches` writes,
`merge`, and the currency-lever config writes (`TitleBrackets`, `SalaryConfiguration`,
`PermissionGroups` multipliers, `SiegeScenarios` rewards, `AuditLogRetentionConfiguration`) all get the
service-or-permission filter.

### 3.5 Transfer policy (`currency_policies`, defaults flagged §4 D3)

| Field | Coins | Gems | Notes |
|---|---|---|---|
| `TransfersEnabled` (kill switch) | true | — | auto-flipped off by a critical reconciliation alert (§3.9) |
| `Transferable` | true | **false** | §5 Q2 |
| `MinTransfer` / `MaxTransfer` | 10 / 1,000,000 | 1 / 100 | the scale follows title salaries 650–80,000 and bonuses 13,500–800,000 |
| `DailySendCap` / `DailyReceiveCap` (rolling 24 h) | 2,000,000 / 4,000,000 | 500 / 500 | computed from the ledger under the sender's lock, so it can't be raced |
| `ConfirmThreshold` | 100,000 | 10 | server-side pending transfer, 60 s TTL |
| `CooldownSeconds` / `MaxTransfersPerHour` | 5 / 20 | 5 / 10 | per sender |
| `MinSenderAccountAgeHours` | 48 | 48 | receiving is never restricted |
| `MinSenderTitleBracketId` | 1 (Peasant, 2,500 XP) | 1 | §5 Q5 |
| `TransferFeeBasisPoints` | 0 | 0 | coin-sink knob; fee leg → `SYS_FEES` |
| `MaxBalance` | 999,999,999 | 999,999 | v2 `KnKUser` caps; mirrored in the DB CHECK |
| `AdminDailyGrantCapPerActor` | 5,000,000 | 1,000 | bypassed by `knk.admin.currency.unlimited` |

Always-on rules, not configurable: no self-transfer; recipient must be an active, non-deleted user;
neither side transfer-locked (`TransferLockReason`) or `IsFrozen`; amount a positive integer; the sender
debit and recipient credit happen in the same transaction; the recipient crossing `MaxBalance` rejects
the whole transfer. `knk.pay.bypass` (staff, for events) skips caps, cooldown and age rules only, never
balance, cap-at-max or lock checks.

### 3.6 Plugin

**Commands** (new top-level Bukkit commands in `plugin.yml`, gated inside the executor through
`KnkPermissible` like `/kit` and `/msg`; see `COMMAND_CATALOG_V3.md` §0):

| Command | Node | Behaviour |
|---|---|---|
| `/pay <player> <amount> [coins\|gems]` | `knk.pay` (+`knk.pay.gems`) | Currency defaults to coins. Amount must match `^[1-9][0-9]{0,9}$` (no signs, decimals or separators); the player name tab-completes. Generates one `Idempotency-Key` (UUID) per invocation, reused across retries. On 202 it shows a clickable `[Confirm] [Cancel]` that runs `/pay confirm <id>` / `/pay cancel <id>`. |
| `/pay confirm\|cancel <id>` | `knk.pay` | pending-transfer confirm/cancel |
| `/balance [player]`, aliases `/bal`, `/money` | `knk.balance`, `knk.balance.others` | fetched with `API_ONLY`, never cache |
| `/baltop [coins\|gems] [page]` | `knk.baltop` | 10 per page |
| `/transactions [page]`, alias `/tx`; `/transactions <player> [page]` | `knk.transactions`, `.others` | from `GET …/transactions` |
| `/knk user <p> coins\|gems set\|add\|remove <amount> <reason…>` | existing `knk.admin.user.coins\|gems` | **reason now mandatory**; mode sent to the server (no client-side delta); prints the server's resulting balance |
| `/knk currency reverse <txId> <reason…>` / `history <player>` / `lock <player> <reason…>` / `unlock <player>` / `alerts` | `knk.admin.currency.reverse\|history\|lock\|alerts` | |

Player Manager steppers stage a pending delta in menu state; an **Apply** button asks for the reason
through `ChatCaptureManager` and posts one `ADMIN_GRANT`/`ADMIN_TAKE` (§4 D9).

**Code** (paths under knk-plugin):
- `knk-core/.../ports/api/CurrencyApi.java` (port) and `knk-core/.../domain/currency/*` (records:
  `Balances`, `TransferOutcome`, `PendingTransfer`, `LedgerLine`, `CurrencyError`).
- `knk-api-client/.../impl/CurrencyApiImpl.java`: sets `Idempotency-Key` and `X-Acting-User-Id`.
  Retries **only** with the same key on `IOException`/5xx (3 tries: 250 ms, 1 s, 3 s). Returns a typed
  `CurrencyError` for 409/422 codes.
- `knk-paper/.../commands/PayCommand.java`, `BalanceCommand.java`, `BaltopCommand.java`,
  `TransactionsCommand.java`, `CurrencyAdminSubcommand.java` (registered under `/knk`).
- `knk-paper/.../currency/CurrencyService.java` (plugin-side orchestration, main-thread hand-off, message
  rendering) and `PaymentNotificationHandler` (new `PaymentReceived`/`AdminAdjusted`/`TransferReversed`
  types on the existing `PlayerNotificationPoller`).
- Every response carries balances. Update the cached `UserSummary` from it
  (`UserCache.updateBalances(uuid, coins, gems)`) and redraw the scoreboard (KNG-16 hook). There is no
  local arithmetic anywhere.
- Remove `UsersCommandApi.setCoinsById/ByUuid`, `CoinsUpdateDto`. `adjustBalancesById` keeps XP only.
- `config.yml`: set `api.auth.type: apikey` as the shipped default (§4 D1). New `currency:` block:
  `client-cooldown-seconds: 3` (UX only; the server is authoritative), `baltop-page-size: 10`,
  `number-locale: en-US`, `http-retry-attempts: 3`, and `messages.currency.*`.

**Messages** (defaults, `&` codes):
`pay-sent: "&aSent &6{amount} {currency} &ato &e{player}&a. Balance: &6{balance}"`;
`pay-received: "&aYou received &6{amount} {currency} &afrom &e{player}&a."`;
`pay-confirm: "&eSend &6{amount} {currency} &eto &e{player}&e? {confirm} {cancel} &7(expires in {seconds}s)"`;
`pay-insufficient: "&cYou only have &6{balance} {currency}&c."`;
`pay-cap: "&cDaily limit reached — you can send &6{remaining} &cmore {currency} (resets {when})."`;
`pay-new-account: "&cYour account must be {hours}h old and reach {title} before sending {currency}."`;
`pay-not-transferable: "&cGems can't be transferred."`; `pay-self: "&cYou can't pay yourself."`;
`pay-unknown: "&cWe couldn't confirm the payment. Check &e/transactions &cbefore trying again."` (after
retries are exhausted; honest about the ambiguity);
`balance-self: "&7Balance: &6{coins} coins &7| &b{gems} gems"`.
Numbers use `NumberFormat.getIntegerInstance(Locale.US)` (`1,234,567`), not v1's German format (§4 D6).

### 3.7 Web app

- **Player:** `src/pages/AccountTransactionsPage.tsx` (route `/account/transactions`, linked from
  `AccountManagementPage`) — paged ledger lines, own account only.
- **Admin `/admin/economy`** (`src/pages/admin/economy/`): `LedgerExplorerPage` (filters from §3.4, CSV
  export), `TransactionDetailPage` (entries, linked source, **Reverse** with note + allow-partial),
  `CurrencyPolicyPage` (policy form per currency), `CurrencyAlertsPage` (list + ack),
  `EconomyOverviewPage` (mint/burn per reason per day, top receivers; last in priority).
- `PlayerProfilePage.tsx`: the balance quick action switches to `POST admin/adjustments` with mode, reason
  code dropdown and note; it shows the last 20 ledger lines and a transfer-lock toggle.
- API client: `src/apiClients/currencyClient.ts` (one file per resource, on `objectManager.ts`); types in
  `src/types/dtos/currency/`. Every mutating call sends `Idempotency-Key: crypto.randomUUID()`, generated
  once per form submission and kept while the button is disabled.
- Pages hide actions by the viewer's effective nodes (`GET api/Users/{id}/permissions/effective`). That's
  cosmetic; the API filter is the enforcement.
- Remove `coins`/`gems` from the User FormWizard config, or make them read-only (DB-stored config, a manual
  step).

### 3.8 Permission nodes (in-house permission system)

Player (granted to the `Default` group by migration): `knk.pay`, `knk.balance`, `knk.balance.others`,
`knk.baltop`, `knk.transactions`. Conditional: `knk.pay.gems` (only if Q2 = transferable). Staff:
`knk.pay.bypass`, `knk.transactions.others`, `knk.baltop.exempt`. Admin (children of `knk.admin`, `default: false`):
existing `knk.admin.user.coins`, `knk.admin.user.gems`, plus a new `knk.admin.currency` umbrella with
`.reverse`, `.history`, `.lock`, `.policy`, `.alerts`, `.unlimited`. The same strings are checked in the
plugin (`KnkPermissible`) and in the API (`RequireKnkPermission`).

### 3.9 Anomaly detection, reconciliation, observability

`Services/Currency/CurrencyMonitorService.cs` (`BackgroundService`, same registration pattern as
`RetentionPolicyService`):

| Rule | Trigger | Severity / action |
|---|---|---|
| R1 Reconciliation (hourly) | `users.Coins/Gems ≠ Σ entries` or a user's last `BalanceAfter` | **Critical**: alert and set `TransfersEnabled=false` (§4 D8) |
| R2 Unbalanced transaction | Σ legs ≠ 0 (defensive) | Critical |
| R3 Funnel | recipient gets transfers from ≥ 5 distinct senders with accounts < 7 days old within 24 h | High |
| R4 Ping-pong | ≥ 3 A→B→A cycles within 1 h | Medium |
| R5 Velocity | net inflow in 1 h > max(500,000 coins, 10× the user's 30-day hourly mean) | High |
| R6 Admin | single adjustment > 1,000,000 coins / 500 gems, or > 10 adjustments per actor per hour | High |
| R7 Mint rate | a reason's daily mint > 3× its trailing 7-day mean | Medium |
| R8 Cap hit | a posting rejected by `BalanceCapExceeded` | Medium |
| R9 Probing | > 20 denied transfer attempts per sender per hour (counted in-memory at the controller) | Low |

Alerts go to `currency_alerts`, `ILogger.LogWarning`, the web alerts page, and an in-game staff
notification (`CurrencyAlert` type) to online holders of `knk.admin.currency.alerts`. OpenTelemetry
metrics (existing wiring, `Program.cs`): counters `knk.currency.postings{reason,currency}`,
`knk.currency.amount{reason,currency}`, `knk.currency.denials{code}`, `knk.currency.replays`, and a
histogram `knk.currency.lock_wait_ms`.

### 3.10 Migration path (every existing mutation routed through the ledger)

1. **Opening balances:** one migration inserts, per user and per non-zero currency, a
   `MIGRATION_OPENING` transaction (`SYS_MIGRATION → user`, `BalanceAfter = current`). Afterwards
   R1 must report zero mismatches.
2. `UserService.CreateAsync` → `GrantAsync(SIGNUP_GRANT)` for the configured start balance
   (250 coins / 50 gems today, `User.cs:53,61`) in the same transaction as the insert.
3. `AdjustBalancesAsync` → XP stays; coin/gem deltas → `AdminAdjustAsync`; title bonus → `TITLE_BONUS`
   postings keyed per bracket.
4. `SalaryService.PayOutAsync` (after KNG-16 lands) → lock the user, compute, `GrantAsync(SALARY)` +
   update `LastSalaryPayoutAt` in one transaction.
5. `SiegeMatchService.CompleteAsync` → one `PostAsync` with a leg per grantee inside `RunLockedAsync`.
   `SiegeMatchParticipant.CoinsAwarded` stays as the display copy.
6. `KitService` → `SpendAsync(KIT_CLAIM_COST|KIT_PURCHASE)` in the claim/purchase transaction; the kit
   purchase unique index remains the one-time guard.
7. `MergeUsersAsync` → `MERGE_FORFEIT` legs zeroing the secondary account (§5 Q6).
8. Delete `UpdateCoinsAsync`/`ByUuid` and their repository methods. Add an architecture test
   (reflection over IL, or a source-scan test) that fails if any type other than `CurrencyService`
   assigns `User.Coins`/`User.Gems`.
9. Siblings (lootboxes, domain discovery, teleport) ship against `ICurrencyService` from day one. Until
   it lands they use `AdjustBalancesAsync` as their contract says, and switch in the same PR as their
   first currency code if Phase 2 has merged by then.

### 3.11 Threat model

| Threat | Mitigation |
|---|---|
| Anonymous or forged API calls set balances (A1) | Mandatory service key or JWT + node filter on every currency route; balance-set endpoints removed; generic PUT ignores balances |
| Negative / zero / huge / overflowing amounts (L1, A8) | Positive-integer validation at plugin regex, DTO and service; `checked` long math; `MaxPerTransaction`; `MaxBalance` in code and DB CHECK |
| Negative prices or rewards mint currency (A4) | Price/reward validators ≥ 0 on Kit (and every sibling config); `SpendAsync` rejects amount ≤ 0 |
| Double spend by concurrent requests (A2) | Ordered `FOR UPDATE` locks in one transaction; balance columns unwritable by EF `Update` |
| Lost update from unrelated writes (A2, L2) | `PropertySaveBehavior.Ignore` on `Coins`/`Gems`; only `ExecuteUpdateAsync` in the ledger transaction |
| Retry / replay double-post (A3) | `Idempotency-Key` unique per scope + request hash; deterministic keys for system sources |
| Crash between debit and credit (L2) | Single DB transaction; no in-memory balances on the plugin |
| Title-bonus / reward re-farming (A5, L3) | Once-ever keys (`title-bonus:{user}:{bracket}`, `discovery:{user}:{domain}`, `siege-match:{id}`); transfers grant no XP |
| Alt farming funnel (A11) | Sender age + title gate, daily send/receive caps, R3/R5 alerts, KNG-16 offline decay, optional IP-hash signal (§5 Q8) |
| Premium-currency laundering / chargeback abuse | Gems non-transferable by default (Q2) |
| Admin abuse or mistakes (A6, L8) | Node-checked server-side; mandatory reason code + note; server-side `set` with `expectedCurrent`; per-actor daily cap; R6 alert; everything in the ledger with a verified actor |
| Irreversible mistakes | `ReverseAsync` with a once-only unique constraint; partial reversal is explicit |
| Tampering with history | Append-only repository, DB triggers, no retention purge; reconciliation proves integrity |
| Stale client state (A13) | The plugin shows only server-returned balances; `/balance` is `API_ONLY` |
| Probing or spamming transfers | Cooldown + per-hour cap server-side; R9 |
| Social engineering / fat-finger large sends | Server-side confirmation over `ConfirmThreshold`; 60 s expiry |
| Compromised web credentials draining an account | Transfers are in-game only (Q4 default); admin routes need nodes; R5 velocity alert |
| Economy-wide bug discovered live | `TransfersEnabled` kill switch per currency; auto-off on R1 |

---

## 4. Decisions taken by default (all flagged **review**)

- **D1 (review)** Currency routes require the plugin service key and fail closed. The plugin ships with
  `api.auth.type: apikey`, and the developer sets the same key in `appsettings` and `config.yml` once
  (a one-time deploy step). This also fixes the class of KNG-15 (plugin sends no credentials).
- **D2 (review)** Keep `users.Coins/Gems` as a lock-protected materialized balance rather than moving it
  into a separate accounts table. That's one fewer table, reuses the siege locking precedent, and leaves
  every existing reader untouched.
- **D3 (review)** Policy numbers in §3.5 are starting values sized to the seeded title economy. All are
  runtime-editable.
- **D4 (review)** `/pay <player> <amount> [coins|gems]` (Essentials-style order) replaces v1's
  `/pay <coins|gems> <name> <amount>`. The legacy order is not accepted, which keeps parsing unambiguous.
- **D5 (review)** Transfers grant **no** XP (v1 L3 is not ported).
- **D6 (review)** Display format `1,234,567` (US grouping).
- **D7 (review)** DB-level immutability triggers on the ledger tables. If the MySQL user lacks `TRIGGER`
  privilege, fall back to repository-only immutability plus the reconciler.
- **D8 (review)** R1 reconciliation mismatch auto-disables transfers (not grants or spends) until an
  admin re-enables them.
- **D9 (review)** Player Manager steppers become staged-delta + Apply-with-reason rather than one posting
  per click.
- **D10 (review)** A promotion bonus is paid once per user per bracket, ever. A demote/re-promote cycle
  (including admin "set title") re-pays nothing.
- **D11 (review)** Reversal never drives a balance negative. It is rejected unless `allowPartial`, which
  reverses what's there and records the shortfall in metadata.
- **D12 (review)** Frozen players (`IsFrozen`) and transfer-locked players cannot send or receive
  transfers. System grants (salary, siege) still credit them.
- **D13 (review)** Offline recipients are notified on next join via `IPlayerNotificationQueue`. The queue
  is in-memory, so an API restart loses the *message*, never the money (the ledger history shows it).

## 5. Open questions for the developer

### Resolved 2026-09-26 (developer)

1. **Gems premium, coins gameplay** — agreed (Q1). `User.cs` comments get corrected in Phase 0.
2. **Gems never transferable** (policy switch kept) — agreed (Q2).
3. **Transfer fee 0%**, setting exists — agreed (Q3).
4. **In-game transfers only** — agreed (Q4).
5. **Sender eligibility: account ≥ 48 h old and Peasant title** — agreed (Q5).
6. **Merge: secondary balance forfeited, recorded in the ledger** — agreed (Q6).
7. **No second-admin approval; alerts + per-admin daily cap** — agreed (Q9).
8. **MySQL version (Q7):** not yet confirmed. Build proceeds with both app-level checks and DB CHECK constraints /
   immutability triggers; the API logs the detected server version at startup and warns when < 8.0.16 (CHECKs are
   silently ignored there, app-level checks still hold). If the migration fails on missing `TRIGGER` privilege, grant it
   or drop the trigger step (reconciler still detects tampering).
9. **Hashed-IP alt signal (Q8):** default taken — later phase, flag-only.

Original questions below, kept for the record.

1. **Which currency is premium?** `User.cs:47-60` calls Coins premium and Gems free; the Kits design §5.2,
   vision and v1 gem-shop treat Gems as premium. Options: (a) Gems premium, Coins gameplay; (b) Coins
   premium. **Recommended: (a).** The fix is to correct the `User.cs` comments, `specs/users/REQUIREMENTS_USER.md:23,40`
   and `guides/users/PLAYER_GUIDE_ACCOUNT_MANAGEMENT.md:65`.
2. **Can gems be transferred between players?** (a) never; (b) yes, with tight caps; (c) only gems earned
   in-game, tracked per lot. **Recommended: (a)** — the policy flag exists, so it can be turned on later
   without code.
3. **Transfer fee (coin sink)?** (a) 0%; (b) a flat % such as 2%; (c) tiered by amount. **Recommended: (a)
   now**, with the knob in place.
4. **Transfers from the web app?** (a) in-game only; (b) web too, with a JWT and the same policy.
   **Recommended: (a)** — it keeps web credential compromise from draining accounts, and the route
   already exists behind a flag.
5. **New-account gate for sending.** (a) age ≥ 48 h + title ≥ Peasant (2,500 XP); (b) age only;
   (c) playtime ≥ N hours (needs KNG-14 playtime counters). **Recommended: (a)**, switching to (c)
   when KNG-14 lands.
6. **Account merge balances.** (a) forfeit the secondary account's balance (current behaviour, now
   recorded); (b) add it to the primary as a `MERGE_TRANSFER`. **Recommended: (a)**, since merge exists to
   resolve duplicates rather than pool funds, and (b) turns alt accounts into a funnel.
7. **MySQL server version** on dev/prod: CHECK constraints need ≥ 8.0.16 and the triggers need the
   `TRIGGER` privilege. If older or unprivileged → code-only enforcement + reconciler. **Recommended:**
   confirm ≥ 8.0.16 and keep both.
8. **Alt signal from IP.** (a) none; (b) store an HMAC of the last login IP (never the raw IP) and use it
   only to *flag* transfers between accounts sharing it (R3 input); (c) block same-IP transfers.
   **Recommended: (b)** as a later phase (Phase 5b).
9. **Two-person rule for large admin grants?** (a) none: alert + per-actor cap; (b) second-admin
   approval above N. **Recommended: (a)** for a single-developer project.
