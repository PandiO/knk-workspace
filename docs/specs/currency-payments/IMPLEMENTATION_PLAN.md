# Currency Payments & Ledger — Implementation Plan

**Status:** Done — merged to trunk 2026-09-27 (KNG-21, KNG-22)
**Last updated:** 2026-09-26
**Linear:** [KNG-21](https://linear.app/kngpandi/issue/KNG-21/currency-ledger-and-secure-player-payments-pay-balance-baltop-for) (Phase 0 split out as [KNG-22](https://linear.app/kngpandi/issue/KNG-22/security-coingem-write-endpoints-are-anonymous-phase-0-currency), urgent)
**Sources:** [DESIGN.md](DESIGN.md) (all section references below point there); `docs/ACTIVE_SESSIONS.md`
branch convention; Linear KNG-14, KNG-15, KNG-16.

**Branches:** one standing branch per repo, `claude/currency-payments`, in knk-web-api, knk-plugin and
knk-web-app (ACTIVE_SESSIONS.md "Branch convention"). Don't fork per-phase branches. Phase 0 is urgent
and small enough to merge on its own; later phases merge when their acceptance criteria are met.

**Base-branch warning:** coin/gem write paths are currently split across three unmerged lines:
`claude/siege-minigame` (moves title bonuses into `TitleProgression`, adds `SiegeMatchService` rewards),
KNG-16 `claude/practical-clarke-od321q` (salary base = title salary, offline log-decay, bonus multipliers),
and `master`. **Phases 0–1 can start from `master`. Phase 2 must start after siege and KNG-16 are merged**
(or rebase onto both), otherwise every rerouted path conflicts.

**Test infrastructure note:** the API test suite runs on EF InMemory, which has no transactions, no
`FOR UPDATE` and no `ExecuteUpdate`. The concurrency guarantees need a real MySQL. Phase 1 adds a
`requires-mysql` xUnit trait with a Testcontainers-MySQL fixture (`Testcontainers.MySql` package),
excluded by default the way knk-paper excludes `requires-bukkit`. Run it locally; per the KNG-16 notes,
the cloud sessions can't download the .NET SDK or the Paper repo.

---

## Phase 0 — Emergency hardening (no ledger yet) — size M

**Goal:** close audit findings A1, A2, A4, A9 and A12 (DESIGN §1.4) before anything else ships.

**knk-web-api**
- `Attributes/RequireServiceOrPermissionAttribute.cs` (new). It passes if `X-API-Key` matches
  `Security:PluginServiceKey`, or if the JWT user holds the node (`IPermissionResolutionService.CheckAsync`).
  It **fails closed** when the key is unset, unless `IsDevelopment()` and
  `Security:AllowUnauthenticatedCurrencyWrites=true`. It exposes the verified acting user (from
  `X-Acting-User-Id` only when the key matched) through `HttpContext.Items["knk.actor"]`.
- Apply it to: `UsersController` `PUT {id}` (node `knk.admin.user.manage`), `PUT {id}/balances`
  (`knk.admin.user.coins|gems|xp` by delta), `POST {id}/salary/payout`, `POST merge`, `PUT {id}/freeze|unfreeze`;
  `KitsController` claim/purchase/CRUD/give (replacing `give`'s `[Authorize]`, which fixes KNG-15);
  `SiegeMatchesController` writes (the key becomes mandatory); `TitleBracketsController`,
  `SalaryConfigurationController`, `PermissionGroupsController`, `SiegeScenariosController`,
  `AuditLogRetentionConfigurationController` writes.
- Delete `PUT api/Users/{id}/coins`, `PUT api/Users/{uuid}/coins`, `UserService.UpdateCoinsAsync/ByUuidAsync`,
  and `UserRepository.UpdateUserCoinsAsync/ByUuidAsync`.
- `Mapping/UserMappingProfile.cs`: `UserDto → User` ignores `Coins`, `Gems`, `ExperiencePoints`,
  `PersonalSalaryMultiplier`. Balances and XP change only through the balance route.
  `UserService.UpdateAsync`'s "GenericProfileEdit" audit block becomes dead; remove it.
- `Repositories/UserRepository.cs`: replace every `_context.Users.Update(user)` for presence, active
  mode, gate pass-through, freeze and email with column-scoped `ExecuteUpdateAsync`. Move
  `LockUsersAsync` here from `SiegeMatchRepository` (keep a forwarding call). `AdjustBalancesAsync`,
  `SalaryService.PayOutAsync` and `KitService` claim/purchase run inside a transaction that locks the
  user row first.
- `Services/KitService.cs`: reject `CostAmount < 0` and `PremiumPriceGems < 0` on create/update; guard
  `price <= 0` in purchase.
- Use `checked` arithmetic in `AdjustBalancesAsync`, `TitleProgression`, `SalaryService` and `SiegeMatchService`;
  reject results above 999,999,999 coins / 999,999 gems with `InvalidOperationException("BalanceCapExceeded")`.

**knk-plugin**
- `config.yml`: `api.auth.type: apikey` becomes the default, with a comment pointing to the shared key.
  `KnkApiClient` sends it through the existing `knk-api-client/.../auth/ApiKeyAuthProvider.java`.
- Delete `UsersCommandApi.setCoinsById/ByUuid`, `UsersCommandApiImpl` impls, `CoinsUpdateDto`, and the test stubs
  (`knk-core/src/test/.../UsersDataAccessTest.java:248-256`).
- `UserManagementCommand`: make `[reason…]` mandatory for coins/gems (usage text + error).

**knk-web-app** — none, beyond checking that `PlayerProfilePage` still works with a logged-in admin
whose account holds the nodes.

**Tests**
- `Tests/.../Attributes/RequireServiceOrPermissionAttributeTests.cs`: key ok / key wrong / key unset →
  401 / dev bypass / JWT with node / JWT without node → 403 / acting header ignored without key.
- `UsersControllerTests`: generic PUT with `coins` leaves the balance untouched; the removed coin routes
  return 404/405.
- `KitServiceTests`: negative price rejected on create and purchase.
- `requires-mysql` (can land in Phase 1 if the fixture isn't ready): a presence update concurrent with
  `AdjustBalancesAsync` loses nothing.

**Acceptance:** an anonymous `curl` against every listed route returns 401. The plugin with the key
still works end to end (join, salary, `/knk user … coins add`, kit purchase, siege match). The in-game
admin actor appears in `AuditLogEntry.ActorUserId`.

**Deploy step (developer, one-time):** set `Security:PluginServiceKey` in appsettings and
`api.auth.api-key` in the plugin config to the same random value.

**Dependencies:** none. Resolves KNG-15.

---

### Phase 0 status (KNG-22) — done 2026-09-26 (all three repos, `claude/currency-payments`)

knk-web-api `7d441be`, knk-plugin `be0cfc3`, knk-web-app `4a3c304`. API tests 674 pass / 5 baseline failures; plugin CI
green https://github.com/PandiO/knk-plugin/actions/runs/36253374030; web-app build OK, tests 16 failed / 240 passed (= trunk).
Re-verified on post-KNG-16 trunk: A1, A2, A4, A9, A12 were all still open; KNG-16 had also added the personal multipliers
to the generic user mapping and trusted `X-Acting-User-Id` whenever the key was unset — both fixed.

- **Service auth** (`Attributes/RequireServiceOrPermissionAttribute.cs`): `[RequireServiceOrPermission(node)]` (X-API-Key =
  `Security:PluginApiKey` OR JWT user holds node) and `[RequirePluginService]`; `HttpContext.GetKnkCaller()` for actors;
  fails closed when the key is unset (Development + `Security:AllowUnauthenticatedPluginCalls=true` opt-out; startup
  warning). Protected: Users `PUT/DELETE {id}` (`knk.admin.user.manage`), `PUT {id}/balances` (+ `knk.admin.user.coins|gems|xp`
  per changed balance for web callers), new `PUT {id}/multipliers` + `POST {id}/salary/payout` (`knk.admin.user.salary`),
  merge / change-password / update-email (`knk.admin.user.manage`), freeze/unfreeze (`knk.freeze`/`knk.unfreeze`),
  plugin-only presence / active-mode / gate-passthrough-method, link-code body userId plugin-only; Kits CRUD
  (`knk.kit.manage`), give (`knk.kit.give`), plugin-only claim / purchase / grant-first-join; SalaryConfiguration
  (`knk.admin.currency.policy`), AuditLogRetentionConfiguration (`knk.admin.config`), PermissionGroups/Grants
  (`knk.admin.user.perm`), UserPermissionGroups (`knk.admin.user.group`).
- `PUT .../coins` routes + plugin client deleted; generic user PUT ignores balances/XP/multipliers; column-scoped writes;
  balance, salary payout, kit claim/purchase in one transaction with `SELECT … FOR UPDATE` (ascending ids) and the audit
  row in the same transaction; checked arithmetic + caps (999,999,999 coins / 999,999 gems, `BalanceCapExceeded`); kit
  prices ≥ 0; migration `AddBalanceAndKitPriceCheckConstraints` (clamps out-of-range rows first, then CHECKs); `User.cs`
  says gems are premium. Plugin: `/kit give` sends the key + staff actor (**KNG-15 fixed**), reason required for
  coins/gems. Web app: profile shows the API's refusal message.
- Deviations: added `PUT {id}/multipliers` (0–100, audited; no web page calls it yet); also protected grants/membership/
  password/email/link-code (otherwise self-grant of `*` or account takeover); change tracking instead of
  `ExecuteUpdateAsync` (InMemory); nodes `knk.admin.config`/`knk.admin.currency.policy` not yet in plugin.yml.
- **Developer to-do (dev server):** `openssl rand -hex 32` → API `Security:PluginApiKey`; plugin `config.yml`
  `api.auth.type: apikey` + `api.auth.api-key` (same value — existing configs still say `none`); check the DB for
  negative/over-cap rows, then `dotnet ef database update`; web admins need the nodes (`*`/`knk.admin.*` covers all);
  drop coins/gems from the User FormConfiguration (values now ignored).
- Still anonymous: `POST api/Users` (account creation), `GameSettings` PUT, Regions/WorldTasks/Gates writes. Siege merge:
  swap `RequirePluginServiceKey` → `[RequirePluginService]`, `Security:PluginServiceKey` → `PluginApiKey`, and point
  `SiegeMatchRepository.LockUsersAsync` at `IUserRepository.LockUsersAsync`. InMemory can't prove the row lock
  (MySQL fixture in Phase 1).

## Phase 1 — Ledger core — size L

**knk-web-api**
- Models (new): `Models/Currency/CurrencyTransaction.cs`, `CurrencyEntry.cs`, `CurrencyPendingTransfer.cs`,
  `CurrencyPolicy.cs`, `CurrencyAlert.cs`. Enums: `Enums/Currency.cs`, `CurrencyTransactionKind.cs`,
  `CurrencyInitiator.cs`. `Services/Currency/CurrencyReasons.cs` holds the reason → kind/system-account
  table from DESIGN §3.3.
- `Properties/KnKDbContext.cs`: configure the tables and indexes (§3.2). `Coins`/`Gems` get
  `SetBeforeSaveBehavior/SetAfterSaveBehavior(PropertySaveBehavior.Ignore)`, DB default 0, and the CHECK
  constraints. Add `User.TransferLockReason`, `User.TransferLockedAt`.
- Migration `AddCurrencyLedger`: the tables, CHECKs, immutability triggers (`migrationBuilder.Sql`,
  guarded per DESIGN §5 Q7), default policy rows (§3.5), and **opening balances** (one
  `MIGRATION_OPENING` transaction + two entries per user and non-zero currency, `BalanceAfter` = current
  value, `PublicId` from a SQL ULID-ish expression or a C# data migration step).
- `Repositories/CurrencyRepository.cs` (+ interface): `LockUsersAsync` (ascending), `FindByIdempotencyAsync`,
  `AddTransactionAsync`, `SetBalancesAsync` (`ExecuteUpdateAsync`), `SumSentSinceAsync`, `LastTransferAtAsync`,
  ledger queries. It has no update/delete methods.
- `Services/Currency/CurrencyService.cs` (+ `Services/Interfaces/ICurrencyService.cs`): `PostAsync`,
  `GrantAsync`, `SpendAsync`, `AdminAdjustAsync`, `ReverseAsync`, `GetBalancesAsync`, `GetHistoryAsync`
  (`TransferAsync` lands in Phase 3), with ambient-transaction enlistment, idempotency and request-hash,
  `checked` math, caps, `CurrencyException` codes.
- `Services/Currency/CurrencyReconciler.cs`: a query comparing `users` against Σ entries and last `BalanceAfter`,
  used by tests now and by the monitor in Phase 5.
- `DependencyInjection/ServiceCollectionExtensions.cs`: registrations.
- `RetentionPolicyService.cs`: explicit comment and test that ledger tables are never purged.

**Tests**
- Unit (InMemory, with the locking seam mocked): leg balancing, reason mapping, amount bounds, overflow,
  cap, `InsufficientFunds`, replay returns the stored result, key reuse with a different body → `IdempotencyKeyReuse`,
  reversal once-only, partial reversal.
- `requires-mysql`: 50 parallel `SpendAsync` of 10 against a balance of 100 → exactly 10 succeed and the
  balance is 0; 20 parallel identical-key grants → one posting; the migration's opening balances
  reconcile; an UPDATE on `currency_entries` is refused by the trigger.

**Acceptance:** after `dotnet ef database update` on a copy of the dev DB, the reconciler reports 0
mismatches, and `Users.Update(user)` with a changed `Coins` doesn't change the DB value.

**Dependencies:** Phase 0.

---

### Phase 1 status — done 2026-09-26 (knk-web-api `claude/currency-payments`)

Commits `f0e39be` (ledger schema; migrations `AddCurrencyLedger` + separate `AddCurrencyLedgerImmutabilityTriggers`),
`403d54f` (`ICurrencyService`/`CurrencyService`, `CurrencyReasons`, `CurrencyRepository`, `CurrencyReconciler`; ledger
excluded from retention), `546a4d0` (tests), `d5c1418` (BOM fix). Suite: 701 pass, 5 baseline failures, 10 skipped
(MySQL tests, `[Trait Category=requires-mysql]`, run when `KNK_TEST_MYSQL` is set). On local MySQL 8.0.46 all 38 currency
tests passed 3× in a row: 50 parallel spends → exactly 10 succeed, balance 0, reconciler clean; 20 parallel same-key grants
→ 1 posting + 19 replays; same key across users → `IdempotencyKeyReuse` (caught and fixed a real cleanup bug); no
deadlock with opposite lock orders; presence/profile writes racing postings lose nothing; caller-transaction rollback
leaves no trace; triggers refuse UPDATE/DELETE (SQLSTATE 45000); CHECKs reject bad rows; retention never deletes ledger rows.

API: see `Services/Interfaces/ICurrencyService.cs` (Post/Grant/Spend/AdminAdjust with native `Set`/Reverse/GetBalances/
GetHistory; `CurrencyContext.ForSystem`/`ForCaller`; replay-safe idempotency; joins the caller's transaction) and the reason
codes in `CurrencyReasons` (incl. `DISCOVERY_REWARD` `discovery:{userId}:{domainId}`, `TELEPORT_FEE`, `LOOTBOX_*`).
Deviations: no opening balances (start empty) — the reconciler checks each user's before/after chain against the users
column; `PropertySaveBehavior.Ignore` + DB default 0 for balances moved to Phase 2; locking reuses
`IUserRepository.RunWithUsersLockedAsync`; env-var MySQL fixture instead of Testcontainers; no ledger→users FKs; XP postings
don't run title progression until Phase 2.
Developer to-do: `dotnet ef database update` — the trigger migration needs `TRIGGER` plus SUPER or
`log_bin_trust_function_creators=1` when binary logging is on (MySQL 9.6 default); otherwise run with
`KNK_SKIP_LEDGER_TRIGGERS=true`. Run the reconciler against a copy of the dev DB (acceptance "0 mismatches" untested here).

## Phase 2 — Route every existing mutation path through the ledger — size M

**Precondition:** `claude/siege-minigame` and KNG-16 merged into `master`, then this branch rebased.

**knk-web-api**
- `UserService.CreateAsync` → `GrantAsync(SIGNUP_GRANT, key "signup:{id}")`; start amounts move to
  `CurrencyPolicy.SignupGrant` (250 coins / 50 gems).
- `UserService.AdjustBalancesAsync` → XP stays; coins/gems → `AdminAdjustAsync` (needs an
  `Idempotency-Key` from the controller); `TitleProgression`'s coin/gem bonus → `TITLE_BONUS` postings
  keyed `title-bonus:{userId}:{bracketId}` (a replay skips = once-ever, DESIGN D10), still scaled by the
  KNG-16 multipliers. `TitleChangeResultDto.CoinBonusGranted/GemBonusGranted` report what was actually
  posted.
- `SalaryService.PayOutAsync` → lock the user, compute (KNG-16 formula),
  `GrantAsync(SALARY, "salary:{userId}:{previousLastSalaryPayoutAt:O}")`, update `LastSalaryPayoutAt`
  column-scoped, all in one transaction.
- `SiegeMatchService.CompleteAsync` → one `PostAsync` (legs per grantee, key `siege-match:{id}`) inside
  `RunLockedAsync`; XP stays direct.
- `KitService.ClaimKitAsync` → `SpendAsync(KIT_CLAIM_COST)` with the client's key;
  `PurchaseKitAsync` → `SpendAsync(KIT_PURCHASE, "kit-purchase:{kitId}:{userId}")`, both in the same
  transaction as the claim/purchase row. `KitsController` claim/purchase read the `Idempotency-Key` header.
- `UserRepository.MergeUsersAsync` → `MERGE_FORFEIT` postings for the secondary account (or
  `MERGE_TRANSFER` per DESIGN §5 Q6) inside the existing transaction.
- `AuditLogEntry` for `BalanceAdjusted`/`SalaryPayout` stays, now carrying `ledgerTransactionId` in `Details`.
  The ledger is authoritative.
- Architecture test `Tests/.../Architecture/CurrencyWriteGuardTests.cs`: scan the web-api source for
  `\.(Coins|Gems)\s*[-+]?=` outside `Services/Currency/` and `Migrations/`; fail on any match.

**knk-plugin**
- `UsersCommandApiImpl.adjustBalancesById`, `payOutSalaryById` and `KitsCommandApi` claim/purchase send an
  `Idempotency-Key` (a UUID generated per user action and reused by retries). The KNG-16
  `SalaryPayoutScheduler` uses a key per scheduled attempt.
- Set `retryOnConnectionFailure(false)` on the OkHttp client for non-idempotent paths without a key, or
  globally once every write carries a key.

**Tests:** extend `SalaryServiceTests`, `SiegeMatchServiceTests`, `KitServiceTests`, `UserServiceTests` with
ledger assertions (entries, reason, key, replay). `requires-mysql`: salary called twice concurrently →
one payout; kit purchase concurrent with a presence update → gems correctly deducted once;
demote/re-promote → no second bonus.

**Acceptance:** the architecture test passes; the reconciler shows 0 mismatches after a scripted session
(join → salary → siege match → kit purchase → admin adjust → merge).

**Dependencies:** Phase 1, siege merge, KNG-16 merge. Tell the lootboxes / domain-discovery / teleport
sessions that `ICurrencyService` is live.

---

### Phase 2 status — done 2026-09-26 (all three repos, `claude/currency-payments`)

knk-web-api `33dd9eb` (every write path through the ledger), `46929ba` (write-guard + MySQL routing tests), `234f8f3`
(`IUserService.ApplyTitleProgressionAsync(userId, previousExperience, reason, metadata?, actorUserId?, notifyPlayer)` —
same signature as discovery's `dd43b2d`; lower level `ITitleProgressionService.ApplyForPostingAsync(posting, actor)`);
migration `RouteBalancesThroughLedger`. knk-plugin `3630436` (KNG-22 follow-up: `X-API-Key`/`Authorization`/cookies
redacted wherever headers are logged; `api.debug-logging` default false), `e785ba7` (Add/Remove/Set + `Idempotency-Key`),
`8a23e32`. knk-web-app `ad4c7ab` (profile quick actions send Add/Remove/Set + key).
- EF can no longer write `Coins`/`Gems`/`ExperiencePoints` (DB default 0); `CurrencyRepository` writes them via
  `ExecuteUpdate` inside the locked transaction. New users get `SIGNUP_GRANT` (`signup:{id}`, `CurrencyPolicy.SignupGrant`
  250 coins / 50 gems) in the insert transaction.
- `PUT /Users/{id}/balances` takes `changes:[{currency, mode Add|Remove|Set, amount, expectedCurrent?}]` + required
  `Idempotency-Key`; response has before/after + ledger id per change (old delta fields removed).
- Title bonuses via `TitleProgressionService`, once per player per bracket (`title-bonus:{userId}:{bracketId}`) — **fixes
  A5** (re-grant loop); salary `SALARY` (`salary:{userId}:{prev:O}`, KNG-16 formula/breakdown unchanged); kits
  `KIT_CLAIM_COST`/`KIT_PURCHASE`; merge forfeits the secondary's coins/gems (`MERGE_FORFEIT`, XP stays on the archived row);
  audit entries carry ledger ids. Plugin `/knk user … set`, Player-manager steppers and set-title send modes, not deltas.
- Tests: API 731 pass / 5 baseline / 18 skipped; requires-mysql 18/18 ×3 on MySQL 8.0.46 (full-row `Update()` can't write
  balances; 6 concurrent salary calls pay once; kit purchase racing presence + stale write charges once; retried claim pays
  once; stale `expectedCurrent` → 409; demote/re-promote pays the bonus once; scripted session of every path reconciles
  with **0 mismatches**). Migration up/down/up clean. Plugin CI green https://github.com/PandiO/knk-plugin/actions/runs/36263071335;
  web-app = trunk baseline.
- Deviations: salary/kit purchase use server-fixed keys (no client key); OkHttp `retryOnConnectionFailure` stays on (keyed
  writes are retry-safe); new `ICurrencyService.FindAsync`/`GetPoliciesAsync` (sibling fakes need them at merge);
  per-player history endpoint + `/knk user … history` deferred (not in the plan's Phase 2).
- **Developer to-do:** `dotnet ef database update`; **deploy API and plugin together** (old plugins get 400 without a key);
  smoke test `/knk user X coins set 1000 <reason>`, set-title, kit claim with cost, kit purchase. **Confirm:** on
  link-minecraft-account the Minecraft account is the secondary, so its in-game coins/gems are forfeited (pre-existing
  behaviour, matches Q6).
- **Siege merge instruction:** in `SiegeMatchService.CompleteAsync` delete the `user.Coins/Gems/ExperiencePoints +=` lines and
  `TitleProgression.ApplyExperienceChange` calls; build legs per grantee (scaled coins, gems, XP); inside `RunLockedAsync`
  call `_currency.PostAsync(legs, CurrencyContext.ForSystem("SiegeMatchService", CurrencyReasons.SiegeReward,
  $"siege-match:{match.Id}") with { SourceType = "SiegeMatch", SourceRef = match.Id.ToString() })`, then
  `_titleProgression.ApplyForPostingAsync(posting, null)`; keep `CoinsAwarded/…` as display copies; inject
  `ICurrencyService` + `ITitleProgressionService`, use `TitleProgressionService.ScaleBonus`, delete `Services/TitleProgression.cs`;
  point `SiegeMatchRepository.LockUsersAsync` at `IUserRepository` (or drop it); `RequirePluginServiceKey` →
  `[RequirePluginService]`; siege tests need `FakeCurrencyService` or the real service with SQL-seeded balances.

## Phase 3 — Player transfers (`/pay`, `/balance`, `/baltop`, `/transactions`) — size L

**knk-web-api**
- `CurrencyService.TransferAsync` + `Services/Currency/TransferPolicyEvaluator.cs` (§3.5 rules, evaluated
  under the sender lock; daily sums from `currency_transactions (FromUserId, CreatedAt)`).
- Pending confirmation: create, confirm and cancel. `Services/Currency/PendingTransferExpiryService` (or
  lazy expiry on read) marks expired rows.
- `Controllers/CurrencyController.cs`: `balances`, `leaderboard`, `limits`, `transfers`,
  `transfers/pending/{id}/confirm|cancel`, `users/{id}/transactions` (DESIGN §3.4); `Dtos/CurrencyDtos.cs`.
- `IPlayerNotificationQueue` / `PlayerNotificationTypes`: add `PaymentReceived`.
- Migration `SeedCurrencyPlayerNodes`: `PermissionGrant` rows granting `knk.pay`, `knk.balance`,
  `knk.balance.others`, `knk.baltop`, `knk.transactions` to the `Default` group.

**knk-plugin**
- `knk-core/.../ports/api/CurrencyApi.java`, `knk-core/.../domain/currency/*.java`.
- `knk-api-client/.../impl/CurrencyApiImpl.java`, `dto/currency/*.java`, `mapper/CurrencyMapper.java`, plus
  wiring in `KnkApiClient`.
- `knk-paper/.../commands/{PayCommand,BalanceCommand,BaltopCommand,TransactionsCommand}.java`,
  `knk-paper/.../currency/{PlayerCurrencyService,PaymentNotificationHandler,AmountParser,CurrencyFormat}.java`;
  `KnKPlugin` registration; `plugin.yml` commands + permission docs; `config.yml` `currency:` block and
  `messages.currency.*`.
- `UserCache.updateBalances(uuid, coins, gems)`; scoreboard refresh after every posting response.

**knk-web-app** — `src/pages/AccountTransactionsPage.tsx`, route in `App.tsx`, link from
`AccountManagementPage.tsx`, `src/apiClients/currencyClient.ts`, `src/types/dtos/currency/CurrencyDtos.ts`.

**Tests**
- API: policy matrix (min, max, cap, cooldown, age/title gate, self, locked, frozen, gems non-transferable,
  recipient at cap), confirmation lifecycle (expire, double confirm → same result, cancel-then-confirm → 409),
  leaderboard exclusions.
- `requires-mysql`: A→B and B→A concurrently (lock ordering, no deadlock); 10 parallel sends that together
  exceed the daily cap → cap respected exactly.
- Plugin (knk-core / knk-api-client unit tests, same style as `UsersCommandApiActorTest`): `AmountParser`
  rejects `-5`, `0`, `1.5`, `1e3`, `1,000`, `99999999999`; `CurrencyApiImpl` sends the same key on
  retries; error-code mapping.

**Acceptance (in-game):** pay an online player, an offline player (notified on join), a large amount
(confirm prompt), over the daily cap (denied, remaining shown); kill the API mid-request and retry → no
double payment; `/baltop` and `/transactions` match the web page.

**Dependencies:** Phase 2. DESIGN §5 Q2, Q3, Q4, Q5 answered (defaults are coded as policy values, so the
answers can arrive as config changes).

---

### Phase 3 status — done 2026-09-26 (all three repos, `claude/currency-payments`)

knk-web-api `7c3a1ea` (transfers through the ledger: rules, confirmation step, limits, leaderboard, migration
`SeedCurrencyPlayerNodes`), `2d4edd6` (`CurrencyController`, `PaymentReceived` notifications), `b7b5117` (tests). knk-plugin
`b4f49f6` (`CurrencyApi` port/client, amount parser), `d1718de` (`/pay`, `/balance`, `/baltop`, `/transactions`, `/knk user
<player> history`), `fce84da`. knk-web-app `574c508` (`/account/transactions`). Also covers the KNG-23 per-player history.
Rules (enforced under both users' row locks): coins only (gems refused while the policy switch is off — default), 0% fee
(fee leg to `SYS_FEES` if raised), sender ≥ 48 h + Peasant, min/max, daily caps, cooldown, confirmation for large amounts
(confirm re-checks everything; second confirm replays; cancel-then-confirm 409), one `PLAYER_TRANSFER` posting, offline
recipient told on next join via the notification queue.
Tests: API 795 pass / 5 baseline / 24 skipped; requires-mysql 24/24 ×3 on MySQL 8.0.46 (concurrent sends can't overdraw; 15
same-key retries pay once; daily cap exact across 10 concurrent sends; A→B vs B→A no deadlock; 10 concurrent confirms pay
once; cancel racing confirm never both); migration up/down/up; plugin CI green
https://github.com/PandiO/knk-plugin/actions/runs/36276610675; web-app = trunk baseline; curl walkthrough of all routes.
Deviations: separate `ICurrencyTransferService` (same implementation); error codes 404 `PendingTransferNotFound`/
`RecipientNotFound`, 409 `PendingTransferExpired`/`Closed`, 422 policy refusals; a new large `/pay` cancels the older open
prompt; confirm key derived from the pending id; recipient at cap refused without revealing balance; `knk.baltop.exempt`
exact grant only; leaderboard requires `knk.baltop` (seeded to Default); **security fix: `PlayerNotificationsController` is
now game-server only** (was anonymous and would expose payment details); amount parsing in knk-core; minimal
`currency/VisiblePlayers` (unify with private-messages' at merge); staff history node `knk.admin.user.history`.
Auth: game-server-only transfers/confirm/cancel/notifications; leaderboard key or `knk.baltop`; balances/limits/transactions
key, self, or `knk.admin.currency.history`.
Developer to-do: `dotnet ef database update`; deploy API + plugin together (plugin needs `api.auth.api-key`); optional
`currency.*`/`messages.currency.*` config; smoke test pay online/offline player, ≥ 100,000 confirm prompt, daily cap, API
stopped mid-payment + retry (single payment), `/baltop` + `/transactions` vs the web page, vanished staff absent from `/pay`
tab completion. Known: notifications are in memory (a restart loses the message, never the money); plugins without the key
stop receiving promotion notices.

## Phase 4 — Admin tooling and web ledger views — size M

**knk-web-api:** `CurrencyController` admin routes (`adjustments`, `transactions` query/detail,
`reverse`, `transfer-lock`, `policy`) with `RequireServiceOrPermission` nodes (`knk.admin.user.coins|gems`,
`knk.admin.currency.*`); per-actor daily grant cap; `PUT api/Users/{id}/balances` coin/gem path marked
`[Obsolete]` and forwarded; policy edits audit-logged (`AuditAction.CurrencyPolicyChanged`, new enum value
appended).

**knk-plugin:** `UserAdminService.changeBalance/adjustBalance` → `CurrencyApi.adminAdjust(mode, amount,
reasonCode, note)`, printing server balances (fixes A6). New `/knk currency reverse|history|lock|unlock`
subcommands. Player Manager: staged delta + Apply + reason via `ChatCaptureManager`
(`UserManagerMenuFeature.adjust`, menu seed update in knk-web-api `MenuTemplateSeed.Content.cs` if the
stepper buttons change). `plugin.yml` `knk.admin.currency.*` nodes.

**knk-web-app:** `src/pages/admin/economy/{LedgerExplorerPage,TransactionDetailPage,CurrencyPolicyPage}.tsx`,
routes under `/admin/economy`; `PlayerProfilePage.tsx` quick action → new endpoint (mode, reason-code
dropdown, note ≥ 10 chars, `Idempotency-Key`), a recent-ledger panel, a transfer-lock toggle. Remove
coins/gems from the User FormWizard config (manual DB step, listed in the handoff).

**Tests:** reversal (full, partial, already reversed, would-go-negative), `set` with a stale
`expectedCurrent` → 409, node denial for each route, admin cap and bypass node.

**Acceptance:** a mis-grant can be found in the explorer and reversed from the web; the in-game `set`
lands on the exact target value even with a stale cache.

**Dependencies:** Phase 3 (shares the controller); can run in parallel with Phase 5.

---

### Phase 4 status — done 2026-09-26 (all three repos, `claude/currency-payments`)

Trunk (incl. the **siege merge**) merged first: API `37bab02` — siege rewards now go through the ledger per the Phase 2
instruction (one `SIEGE_REWARD` posting per match, `TitleProgression.cs` + siege `LockUsersAsync` removed, siege match writes
`[RequirePluginService]`); plugin `1b1de70`; web-app `d4a1687` (+ cherry-picks `d1bdf7a`/`35d34b5` = `dceb5b3`/`1282595`).
Phase 4: API `79b53e5` — `api/currency/admin`: `GET ledger` (the KNG-23 **balance event log**: filters currency/player/
initiator name or component/initiator type/source/reason/kind/transaction/date range, 8 sortable columns, server-side
paging), `GET transactions/{id}` + `POST …/reverse` (note ≥ 10 chars, `allowPartial`, key `reverse:{id}`; reversal, audit and
title change commit together), `POST adjustments` (reason category + note ≥ 10 chars; web callers need the coins/gems/xp
node), transfer-lock GET/PUT/DELETE, policy GET/PUT (AuditAction 19–22), per-staff daily grant cap (422
`AdminDailyCapExceeded`, bypass `knk.admin.currency.unlimited`). Plugin `b1fe642` — `/knk currency reverse <txId> [--partial]
<reason> | history <player> | lock | unlock`, clickable tx ids, Player Manager steppers stage a total applied with one
reason-captured posting. Web-app `83db575` — `/admin/users/balance-log` (`knk.admin.currency.history`),
`/admin/economy/transactions/:publicId` with Reverse, `/admin/economy/policy`, profile adjustment form (category + note),
"Balance history" section, transfer-lock toggle, Moderation links.
Tests: API 1042 pass / 5 baseline / 27 skipped; requires-mysql 27/27 ×3 (racing reversals → one posts; reversal racing a
spend never below zero; staff cap exact under concurrency; every sort translates to SQL); migrations clean from empty DB;
plugin CI green https://github.com/PandiO/knk-plugin/actions/runs/36278477999; web-app 16 baseline / 278 passed.
Deviations: the balance event log doubles as the plan's LedgerExplorerPage (no CSV export); adjustment `reasonCode` is a
staff category stored in metadata (ledger code stays `ADMIN_*`); plugin staff balance changes keep using `PUT
Users/{id}/balances` (documented as deprecated); gate overrides still `RequirePluginServiceKey(AllowAdmins)` and siege config
controllers not yet switched to `RequireServiceOrPermission` (follow-up). Developer to-do: grant `knk.admin.currency.*` to
staff; smoke test `/knk currency history|reverse|lock|unlock`, Player Manager stepper + reason; web: reverse a grant from the
balance log, edit the gem policy; remove coins/gems from the User FormWizard config. Known: plugin-called staff routes trust
the plugin's in-game node check.

## Phase 5 — Reconciliation, anomaly alerts, observability — size M

**knk-web-api:** `Services/Currency/CurrencyMonitorService.cs` (`BackgroundService`, rules R1–R9 from
DESIGN §3.9); `currency_alerts` writes; auto kill switch on R1; OpenTelemetry meter `Knk.Currency`
(counters + lock-wait histogram) registered in the existing `WithMetrics`; `CurrencyAlert` notification
type for online staff; `GET api/currency/admin/alerts|reconciliation`.

**knk-plugin:** handle the `CurrencyAlert` notification (staff with `knk.admin.currency.alerts`);
`/knk currency alerts`.

**knk-web-app:** `CurrencyAlertsPage.tsx` (list + ack) and an optional `EconomyOverviewPage.tsx` (mint/burn per
reason per day — use the dataviz guidance when building it).

**Tests:** each rule on seeded ledgers; R1 flips `TransfersEnabled`; the monitor survives an empty DB.

**Phase 5b (optional, after DESIGN §5 Q8):** `User.LastLoginIpHash` (HMAC with a server secret), sent by
the plugin on presence; used as an R3 input only.

**Dependencies:** Phase 1 (reconciler), Phase 3 (transfer rules have data).

---

### Phase 5 status — done 2026-09-27 (all three repos, `claude/currency-payments`)

knk-web-api `0a242b6`: `CurrencyMonitorService` (every 60 s: R8/R9 in-memory findings → alerts; every 5 min ledger rules
R3–R7; hourly + shortly after startup the reconciler R1/R2 — report only, never fixes), **R1 kill switch** (switches off
transfers for the mismatched currency once per mismatch set; re-enabling in the policy page is respected), alerts deduped
per rule/window, logged, counted and sent to online staff as `CurrencyAlert` notifications; routes `GET/POST
api/currency/admin/alerts[/{id}/ack]`, `GET reconciliation` (`knk.admin.currency.history`), `POST reconciliation/run`
(`knk.admin.currency.alerts`, 409 while running); meter `Knk.Currency` (postings, amount, denials, replays, lock_wait_ms,
alerts, reconciliation duration, mismatches gauge — OTLP only, no Prometheus endpoint yet); migration
`AddCurrencyAlertDedupKey`. `06501ee`: siege configuration writes + gate overrides now `[RequireServiceOrPermission]`; the
`RequirePluginServiceKey` attribute and `Security:PluginServiceKey` removed. knk-plugin `bdbd9bf`: staff alert notices,
`/knk currency alerts [all] [page]`, `/knk currency alerts ack <id>`. knk-web-app `47b94f6`: `/admin/economy/alerts` with a
reconciliation panel. Tests: API 1091 pass / 5 baseline / 30 skipped; requires-mysql 30/30 ×3; migration up/down/up; live
boot with the monitor; plugin CI green https://github.com/PandiO/knk-plugin/actions/runs/36280732627; web-app 282 / 16 baseline.
Deviations: one monitor loop; R5 coins only; R7 noise floor 10,000 coins / 100 gems; R1/R2 one alert listing ≤ 50
mismatches; last reconciliation kept in memory; acks recorded on the alert row; console can't ack.
Developer to-do: `dotnet ef database update`; grant `knk.admin.currency.alerts`; **web staff editing siege setup now need
`knk.siege.admin.manage`, gate overrides need `knk.gate.admin`** (these writes used to be open); optional `CurrencyMonitor`
appsettings; smoke test (SQL-edit a balance → "Run now" → R1 alert + coin transfers off → in-game staff notice →
`/knk currency alerts` + ack → re-enable in the policy page). Known: in-game notice is best effort; hourly full-ledger scan.
Not built: optional `EconomyOverviewPage`; Phase 5b hashed-IP signal; ledger CSV export; Prometheus endpoint; plugin staff
balance changes still on the deprecated `PUT Users/{id}/balances`; anonymous GateStructures/GateDoors CRUD, GameSettings,
`POST api/Users` (outside currency scope).

### Final review — 2026-09-27 (all phases)

Fixed (knk-web-api, tip `04558d6`): (1) **High** — the reconciler read balances and ledger in separate autocommit queries,
so any payment between them looked like an R1 mismatch and tripped the server-wide transfer kill switch (anyone paying could
cause it); now one consistent REPEATABLE READ snapshot (`b5251bb`, requires-mysql test fails before the fix). (2) **High** —
`DELETE api/Users/{id}` hard-deleted balances outside the ledger, leaving a permanent R1 mismatch (every account has a
SIGNUP_GRANT); now 409 `UserHasCurrencyHistory` — merge instead (`8a7c7f2`). (3) **High** — partial reversal of a transfer
with a fee minted the difference (only with fee > 0); refused now (`04558d6`). (4) **Medium** — anonymous `POST api/Users`
accepted a `uuid`, allowing takeover of an unlinked web account or pre-registering someone's UUID; a `uuid` now requires the
plugin key (`3589a84`). (5) **Low** — idempotency fingerprint lacked the source (kit/teleport…); now included (`5008ae1`).
Checked sound: no balance write outside the locked ledger transaction (EF save behaviour Ignore; siege `SIEGE_REWARD` inside
the match lock), actor header only with a valid key, transfer actor = sender, unguessable pending ids with owner checks,
ascending lock order, checked arithmetic + caps, gems non-transferable by default, atomic audit/ledger/balance, plugin has no
client-side arithmetic and keyed retries. API 1100 pass / 5 baseline / 31 skipped; requires-mysql 31/31 ×3.
Follow-up fixes in progress: optimistic concurrency on the policy PUT (a stale form could undo the kill switch); leaderboard
page bound.
**Open for the developer:** (a) XP increases by `knk.admin.user.xp` holders can trigger title bonuses (up to ~4M coins + 600
gems per player, once per bracket) outside the per-staff daily grant cap — count bonuses against the cap, or require the
coins/gems nodes for XP increases? (b) Linking a Minecraft account to an existing web account forfeits the in-game balance
(confirm). Also noted: accounts with no ledger rows aren't reconciled; one participant at the coin cap fails a siege match's
whole payout; scenario rewards unbounded (per-payment caps + R7 limit damage); generic user edit can clear `IsFrozen`
without the unfreeze node (pre-existing). Deploy note: plugins without the key can't create accounts with a UUID.

**Feature status: Phases 0–5 complete on `claude/currency-payments`; awaiting developer smoke test + merge (merge first).**

## Cross-feature notes

- **Lootboxes / domain discovery / teleport:** consume `ICurrencyService` (`SpendAsync` / `GrantAsync`)
  with the reason codes and deterministic keys from DESIGN §3.3. Before Phase 2 merges they use
  `AdjustBalancesAsync` and switch afterwards; each adds its reason row to `CurrencyReasons.cs`.
- **KNG-16 (salary):** Phase 2 rewrites its payout write path; coordinate so KNG-16 merges first.
- **KNG-14 (playtime counters):** lets DESIGN §5 Q5 move to a playtime-based sender gate.
- **KNG-15:** closed by Phase 0.
- **Siege:** Phase 2 changes `SiegeMatchService.CompleteAsync`'s reward write only; its match-level
  idempotency and locking stay.
- **Private messages:** no dependency.

## Handoff checklist per phase

Update `docs/ACTIVE_SESSIONS.md` (feature "Currency payments & ledger") and this file's status block; record
commits per repo; list any manual DB steps (FormWizard config edits, keys in appsettings/config.yml).

## Smoke test + fixes — 2026-09-27

Developer smoke test (plan in the conversation, sections A–L): A–K passed or were fixed below; L (siege reward) untested.
Fixes on `claude/currency-payments`:
- **knk-plugin** (CI green https://github.com/PandiO/knk-plugin/actions/runs/36322662661, HEAD `7f056b3`): join balance line
  uses the `/balance` format (`216d8b6`); `&` codes in chat-capture prompts rendered (`d538c9c`); stale [Confirm] says "That
  payment was already sent." (`abdb3c0`); expiry notice for unconfirmed payments (`3f500d7`); API unreachable →
  "can't be reached … Nothing was paid" instead of "no permission" via new `PermissionDecision`/`KnkPermissible.checkAsync`
  (`b343ec1`, `2835de4`); `/knk user … history` through `KnkPermissible`, currency admin nodes `default: op` (`79693bf`);
  409 `AlreadyReversed` shown properly, replays never printed as fresh reversals (`5a6e4fe`); XP raises need xp+coins+gems
  nodes, API 4xx sentences shown instead of raw JSON (`7f056b3`).
- **knk-web-api** (tests: 5 baseline failures only; requires-mysql 34/34): XP increases need coin/gem rights and bonuses
  count against the staff cap (`de2c52c`); merge keeps the highest balance per currency with `MERGE_CARRYOVER`
  (`ae5281d`); 409 `AlreadyReversed` with details (`239a01d`, `ba92f2d`); reversed transfers stop counting toward caps
  (`bf9742a`); merge no longer re-pays a title bonus the secondary (or any account merged into it) already received,
  also on later re-promotion (`edb77e8`).
- **knk-web-app** (16 baseline failures only): "Already reversed" state on the transaction page (`05c427c`); always-visible
  "Adjust balance" card on the player profile (`6eed4a0`).
Fixed later: KNG-24 moved `/knk` subcommand gates onto Bukkit-or-in-house permission checks and was
merged to plugin `main` at `1a69ec3` on 2026-10-04.

**Merged to trunk 2026-09-27:** knk-web-api `5639a50`, knk-plugin `0d01b52`, knk-web-app `c4ed753` (trees identical to the
branch tips `edb77e8` / `7f056b3` / `6eed4a0`).
