# Domain Discovery — Design

**Status:** Decided — implementation in progress (branch `claude/domain-discovery`)
**Last updated:** 2026-09-26
**Linear:** [KNG-20](https://linear.app/kngpandi/issue/KNG-20/domain-discovery-first-entry-rewards-for-townsdistrictsstructures)
**Sources:** `knk-v1-archive` (`src/Towns/TownEvents.java`, `src/Towns/Town.java`, `src/DataManager/Towns.java`,
`src/Users/User.java`, `src/Titles/Title.java`, `src/Main/Main.java`, `src/Menu/Menu.java`, `src/DataManager/Worldguard.java`);
`knk-v2-archive` (`model/dominion/Dominion.java`, `listeners/RegionListener.java`); v3 checkouts on branch
`claude/intelligent-newton-73pcsl` (knk-web-api `cd95dd1`, knk-plugin `0fa6d06`, knk-web-app `9a6f347`);
docs `specs/legacy/events-v1.md` §2, `specs/legacy/inventory-menu-screens.md` §3.1, `specs/user-features/DESIGN.md`,
`specs/inventory-menu/CONTENT_PORT_PLAN.md`.

Path shorthand: `v1:` = `knk-v1-archive/src/`, `v2:` = `knk-v2-archive/src/main/java/net/knightsandkings/`,
`api:` = `knk-web-api/`, `plugin:` = `knk-plugin/`, `paper:` = `plugin:knk-paper/src/main/java/net/knightsandkings/knk/paper/`,
`core:` = `plugin:knk-core/src/main/java/net/knightsandkings/knk/core/`, `app:` = `knk-web-app/src/`.

---

## 0. Scope

**In:**
- First entry into any discoverable `Domain` (Town, District, Structure; GateStructure configurable, off by default)
  records a permanent `UserDomainDiscovery` row and grants coins + gems + XP exactly once per (user, domain).
- Rewards computed server-side: per-domain-type rule (+ optional per-domain override), scaled by the player's
  title bracket using v1's scaling (§1.1.3), then multiplied by the personal + premium-rank multipliers that
  salary already uses (shared service, not a copy).
- Sound + particle + chat on the discovery moment; the existing promotion moment if the XP crosses a bracket.
- Players already inside a region at join; teleports; nested regions; exclusions; batching/rate limiting;
  API-down spool & replay; per-player discovered-set cache.
- In-game `discoveries.main` menu (new — see §1.1.5, there is no legacy screen to port) + hub tile + `/discoveries`.
- Web-app: player's own discoveries (account page), admin player-profile section, reward-rule/override editor
  with a per-title preview, discovery statistics.

**Out:**
- v1 title-gated town entry (`leveledTownEnter` + `Town.RequiredTitleID`) — an access-gating feature, not discovery.
- v1 treasure chests (`TreasureDiscovered`, `v1:Treasure/`) — separate feature (closest sibling: `specs/lootboxes/`).
- v1 travel assignments that react to town entry (`AssignmentTravelRandom/Specific.enterTown`) — quests, not ported.
- Teleport-to-discovered-place actions or spawn gating on discovery — belongs to `specs/teleport/` (see §3.9).
- Currency ledger / idempotency-key infrastructure and plugin→API authentication — owned by
  `specs/currency-payments/` and inventory-menu CP7; this design adopts them when they land (§3.8, §4 D10).
- v1's Friday `eventMultiplier` (buggy, §1.1.6) — not ported; a future "global event multiplier" would be its own feature.

---

## 1. Legacy design

### 1.1 v1 (Bukkit, flat JDBC)

#### 1.1.1 Trigger — `TownEvents.onEnter` (`v1:Towns/TownEvents.java:53-154`), live
- Event: `com.mewin.WGRegionEvents.events.RegionEnterEvent` (third-party WG events plugin), default priority. Fires on
  walking and on teleport.
- Only **town** regions: `Worldguard.isTownRegion` = region id prefix `town_` (`v1:DataManager/Worldguard.java:291-303`);
  town id parsed from `town_<id>` or `town_<id>,<subId>` (`:229-249`) — sub-regions (`TownRegion(TownID, SubID)`) all map
  to the same town. **v1 had no Districts or Structures in discovery** (the task premise "Town or one of its Districts"
  is not what the code does; Districts arrived in v2).
- Guard `!inTown.containsKey(user) || inTown.get(user) != townID` (`:87`), then the optional title gate
  (`main.leveledTownEnter`, default `false`, `v1:Main/Main.java:257`; message "Halt! We do not want scum like you in this
  town! Come back when you are a <male title> or a <female title>", `:93`).
- On allowed entry: action bar "Entering the town of <name>" + `DOOR_OPEN` 0.5/1.0 (`:104-106`), `inTown.put`.
- **Discovery** (`:109-122`): `if (!town.getUserIDListbyTown(townID).contains(user.getID()))` →
  `town.saveDiscoveredTown(townID, userID)` then reward (below), chat, `LEVEL_UP` sound vol 0.6 pitch 1.0.
- Every uncancelled entry (not just first) also advances travel assignments and despawns chasing bandits (`:127-152`).

#### 1.1.2 Storage
- Table `DiscoveredTowns(TownID, UserID)`; read `SELECT * FROM DiscoveredTowns WHERE TownID=?` (whole discoverer list per
  entry, `v1:Towns/Town.java:362-383`); insert `:385-399` (console log "User with ID … has succesfully discovered a town…");
  delete `:401-414` (`removeDiscoveredTown`, no caller found).
- `DataManager/Towns.java:258-265` (`Models/Town.DiscoveredUserIDs`) saves by `DELETE FROM DiscoveredTowns WHERE TownID=?`
  then re-inserting the in-memory list — a concurrent `saveDiscoveredTown` between load and save is silently lost.
- No schema file in the repo; no evidence of a unique key on `(TownID, UserID)`.
- Only other consumer: `User.TeleportSpawn` (`v1:Users/User.java:3448-3470`) sends a player to spawn `"spawn"` only if they
  have discovered `kardenna`, else to spawn `"new"` (Dutch comment: "add the discover check for kardenna later").

#### 1.1.3 Reward amounts and title scaling (the part the developer asked about)
```java
Integer part  = user.getExpPart(4);                                            // TownEvents.java:112
Integer exp   = user.getMultipliedInt(main.getRandom(part/4, part));           // :113
Integer coins = user.getMultipliedInt(main.getRandom(1000, 50000));           // :115
Integer gems  = user.getMultipliedInt(main.getRandom(5, 15));                 // :116
```
- `getRandom(lo, hi)` is inclusive uniform (`v1:Main/Main.java:958-973`).
- **Title scaling = `User.getExpPart(part)` (`v1:Users/User.java:2736-2756`)** — XP only:
  - title < 18: `unit = (MinExp[title+1] − MinExp[title]) / 100` (int division), result `unit × part`.
  - title 18 (top): `unit = (MaxExp[18] − MinExp[18]) / 1000`.
  - With `part = 4`: discovery XP = uniform `[unit, 4·unit]` → **1 %–4 % of the width of the player's current title bracket**.
- **Coins (1 000–50 000) and gems (5–15) were flat — not title-scaled.**
- `getMultipliedInt(x)` (`v1:Users/User.java:2725-2734`) = `(int)(x × Main.eventMultiplier)` then `× Donator.Multiplier`
  (`v1:Donator/Donator.java:118-138`, v1 `Donator` table; v3 imported the real values Noble 1.10 / Royal 1.20 /
  Dragon Blood 1.50). Applied to **all three** currencies.
- The "5/10/12/15" thresholds are unrelated: they are v1 **title-ID** slot-unlock tiers in `TitleChangeEvents`
  (`specs/user-features/DESIGN.md` §3.1 already corrects this). v1 had no other per-title reward scaling; the per-title
  `Titles.Salary/CoinBonus/GemBonus/ExpBonus` columns are salary and promotion bonuses.
- Worked examples of the v1 XP range with the real v3 `title_brackets` data
  (`api:Migrations/20260925112304_AddUserFeaturesPhase6RealTitleDataAndFreeze.cs:111-131`):

  | Title (id) | Bracket width | unit | v1 town XP |
  |---|---|---|---|
  | Serf (0) | 2 500 | 25 | 25–100 |
  | Peasant (1) | 700 | 7 | 7–28 |
  | Reeve (4) | 5 500 | 55 | 55–220 |
  | Knight (5) | 1 500 | 15 | 15–60 |
  | Count (9) | 10 000 | 100 | 100–400 |
  | Prince (15) | 17 500 | 175 | 175–700 |
  | One of the Seven (18) | n/a (v1 used MaxExp/1000; v3 has no MaxExp) | — | — |

  Note the non-monotonic result (Knight < Reeve) — inherited from v1's uneven bracket widths.

#### 1.1.4 Message / effects
- Chat (`TownEvents.java:120`): `§b"You discovered a new town and received "§a<coins>§b" coins, "§a<gems>§b" gems and "§a<exp>§b" experience!"`
  (`ColorOptions.messageachievement` = AQUA, `messagesubjects` = GREEN, `v1:Handlers/ColorOptions.java:67-68`).
- Sound `SoundHandler.LEVEL_UP` (`Sound.LEVEL_UP`, 1.8 enum; modern `ENTITY_PLAYER_LEVELUP`) vol 0.6 pitch 1.0. No particles.

#### 1.1.5 Menus — there is no v1 "discoveries" menu
Searched all of `v1:` for `discover|visited|explor`: the only menu reference is the Personal Menu tile
**slot 14, BOOK, name `ColorOptions.stats + "Knowledge"`, lore `§7"See all discovered Knowledge"`, `stats + "Latest discovered Knowledge:"`,
`§a""` (always empty)**, `v1:Menu/Menu.java:103,223`; it has **no click handler** (`specs/legacy/inventory-menu-screens.md`
§3.1 row 14, "Dead"). The closest real list screen is the spawnpoint teleport menu (COMPASS rows, "Locked! Reach title X to
unlock", §3.6 of that doc). The `discoveries.main` menu in §3.6 below is therefore new content, with the Knowledge tile's
copy reused for its header/hub tile.

#### 1.1.6 Known bugs / exploits
| # | Bug | Where |
|---|---|---|
| L1 | Check-then-insert with no unique key: two near-simultaneous enter events (overlapping `town_<id>,<sub>` sub-regions, lag) can both pass the `contains` check → double reward. | `TownEvents.java:109-111` |
| L2 | `inTown.get(user) != townID` compares boxed `Integer`s by reference; false for ids > 127, so the "already in this town" guard never holds there. | `TownEvents.java:87` |
| L3 | Every town entry loads the town's entire discoverer list from the DB. | `Town.java:362-383` |
| L4 | `DataManager.Towns` save path deletes-and-reinserts all discoveries of a town (lost-update race). | `DataManager/Towns.java:258-265` |
| L5 | Friday event multiplier: an hourly task adds +0.5 **every hour** on Friday (up to ×13.0) and decays 0.5/h afterwards — unbounded stacking, applied to discovery rewards via `getMultipliedInt`. | `Main.java:1372-1390` |
| L6 | `townID`/`requiredTitleID` unboxed without null checks (NPE if region/town tables disagree); `getDonatorMultiplier` returns `null` for an unknown donator id → NPE in `getMultipliedInt`. | `TownEvents.java:62-63,91`; `Donator.java:118-138` |
| L7 | Title 18 XP uses `getExpmax` (nullable `Integer`) — NPE risk at max title. | `User.java:2748-2752` |

### 1.2 v2 (MySQL/Hibernate)
- Only remnant: a commented-out `// TODO: To be made into an interface … (Discoverable)` + `@JoinTable(name = "discovered_TestModels")`
  stub on `Dominion` (`v2:model/dominion/Dominion.java:198-203`). No listener, table, reward, or menu.
- Region entry is handled by `RegionListener.onEntered` (`v2:listeners/RegionListener.java:19-35`) → `Dominion/Town/District.onRegionEntered`
  (action-bar enter/deny messages only). Bug: the handler runs **asynchronously** (`runTaskAsynchronously`) and then calls
  `e.setCancelled(...)` after the event has already completed — entry denial never worked in v2.

### 1.3 v3 today
**Nothing discovery-related exists** (grep for `discover` across the three v3 repos: only unrelated hits). What exists to build on:

- **Domain hierarchy** (EF Core TPT): `Domain` (`Id, Name, Description, CreatedAt, AllowEntry, AllowExit, WgRegionId, LocationId`,
  `api:Models/Domain.cs`) → `Town`, `District` (`TownId`), `Structure` (`StreetId, HouseNumber, DistrictId`) → `GateStructure`.
  Tables `domains/towns/districts/structures/gate_structures` (`api:Properties/KnKDbContext.cs:128-132,894-938`).
  Domain type string = CLR type name (`api:Mapping/DomainMappingProfile.cs:19,50`): `Town|District|Structure|GateStructure`.
  `WgRegionId` has **no unique index**; lookups are case-insensitive (`api:Repositories/DomainRepository.cs:28-40`).
- **Region tracking (plugin)**: `paper:listeners/WorldGuardRegionListener.java` (move/teleport/join/quit) →
  `paper:regions/WorldGuardRegionTracker.java`. `handleMove` fires `OnRegionEnterEvent(player, regionId)` for every raw WG region
  entered (`fireRegionEvents`, `:412-434`) **before** the allow/deny decision is applied, then runs
  `core:regions/SimpleRegionTransitionService.java` (entry/exit policy, "You are now entering …" action bar, and an
  `onDomainsEntered` callback — currently `Consumer<Set<DomainSnapshot>>` with **no player id**, used only for
  `DistrictGateLoader`, `paper:KnKPlugin.java:664-681`). `handleJoin` does **not** fire `OnRegionEnterEvent` (`:162-200`).
  When a region's domain isn't cached yet, the transition is re-run only if the player is still in exactly the same region set
  after the async fetch (`revalidatePlayerLocation`, `:345-372`) — a player who walks on is never "entered".
- **Region → domain resolution**: `core:regions/RegionDomainResolver.java` via `POST api/Domains/search-region-decisions`
  (`api:Services/DomainService.cs:119-175`), which keeps **at most one Town, one District and one Structure** per request and
  **drops GateStructures** (`FirstOrDefault` per type name).
- **Balance mutation**: `UserService.AdjustBalancesAsync(userId, coins, gems, xp, reason, metadata, actorUserId, notifyPlayer)`
  (`api:Services/UserService.cs:618-716`) — underflow checks, `TitleProgression.ApplyExperienceChange` (consolidated promotion
  bonuses), `AuditAction.BalanceAdjusted` (+ `TitleChanged`) audit rows, optional `PlayerNotifications` queue entry. No
  transaction/row lock of its own (read-modify-write on `users`). Siege rewards use the stronger pattern: transaction +
  `SELECT … FOR UPDATE` + `TitleProgression` (`api:Services/SiegeMatchService.cs:164-266`, `Repositories/SiegeMatchRepository.cs:100-122`).
- **Multipliers**: `SalaryService.PayOutAsync` = `GlobalMultiplier × User.PersonalSalaryMultiplier × rank × hours`, rank = product
  of `PermissionGroup.SalaryMultiplier` over active memberships (`api:Services/SalaryService.cs:41-121`); rank part is exposed as
  `ISalaryService.GetCurrentRankMultiplierAsync` (used by `UserProfileSummaryService`). `SalaryConfiguration.GlobalMultiplier`
  is documented as doubling as the hourly base rate (`api:Dtos/SalaryDtos.cs:12-20`), so it is not a reward multiplier.
- **Titles**: `TitleBracket(MinExperience, Salary, CoinBonus, GemBonus, ExpBonus)`, 19 real v1 brackets; `ITitleService.GetAllOrderedAsync`.
- **Exclusion signals (plugin)**: `ModeService.getActiveMode/isVanished` (`paper:modes/ModeService.java:85-90`, `User.ActiveMode`
  None/Staff/Owner), `AdminFreezeManager`, `JoinLoadingGuard.isLoading` (`paper:user/JoinLoadingGuard.java:111`), game mode.
- **Menu engine**: fully present — `core:menu/*`, `paper:menu/*`, content features `paper:menu/content/*`
  (`ProfileMenuFeature`, `HubMenuFeature`, …), server-seeded templates `api:Models/Menu/MenuTemplateSeed*.cs` (create-only seed),
  `/menu` hub `main` with tiles at slots 4, 8, 10, 12, 14, 16, 22.
- **Delivery precedents**: `PromotionEffects` (`paper:commands/support/PromotionEffects.java`), `PlayerNotificationPoller`
  (`paper:tasks/PlayerNotificationPoller.java`), crash-safe spool + replay (`core:siege/SiegeMatchRecorder.java`, `SiegeResultSpool.java`).

---

## 2. Gap analysis

| Capability | v1/v2 behaviour | v3 today | Reusable v3 component (path) | Work |
|---|---|---|---|---|
| Discovered-state storage | `DiscoveredTowns(TownID,UserID)`, no unique key | none | EF TPT `Domain`; `KitPurchase` unique `(KitId,UserId)` precedent (`api:Properties/KnKDbContext.cs:686`) | M |
| Discoverable types | towns (+ sub-regions) only | — | `Domain` subclasses | S |
| First-entry detection | WG events plugin, live | raw `OnRegionEnterEvent` fired, no consumer; join doesn't fire it | `WorldGuardRegionTracker`, `OnRegionEnterEvent` | M |
| Region → domain | parse `town_<id>` | `search-region-decisions` (one per type; no gates) | `DomainRepository.GetByWgRegionNameAsync` | S (server resolves by region id) |
| Reward calc | random ranges, XP via `getExpPart`, × event × donator | — | `TitleBracket`, `ITitleService`, `SiegeRewardCalculator` (pure calc precedent) | M |
| Personal + premium multipliers | donator multiplier on all currencies | salary-only, rank calc inside `SalaryService` | `SalaryService.ComputeRankMultiplierAsync`, `User.PersonalSalaryMultiplier` | S (extract shared service) |
| Grant once, atomically | none (L1) | — | `AdjustBalancesAsync`, `TitleProgression`, siege lock pattern | M |
| Reward config | hard-coded | — | `SiegeConfiguration` singleton/page pattern | M |
| Effects/chat | chat + LEVEL_UP | — | `PromotionEffects` | S |
| Discoveries menu | dead "Knowledge" tile only | — | menu engine, `ProfileMenuFeature`/`TitleRow` pattern, seeds | M |
| Offline/API-down | n/a (sync DB) | — | `SiegeResultSpool`/`SiegeMatchRecorder`, `RetryPolicy` | M |
| Exclusions | none | — | `ModeService`, `AdminFreezeManager`, `JoinLoadingGuard` | S |
| Web views | none | — | `PlayerProfilePage`, `AccountManagementPage`, `SiegeConfigurationPage` | M |
| Admin stats | none | — | — | S |

Reuse as-is: `OnRegionEnterEvent`, WG region query, `ModeService`, `TitleProgression`/`AdjustBalancesAsync`, `PromotionEffects`,
menu engine + `FreshViewers`, spool pattern. Extend: `SalaryService` (extract multipliers), `UserAccountListener` (fire a
"user loaded" event), hub seed. New: discovery entities/service/controller, plugin discovery module, menu feature, web pages.

---

## 3. v3 design

### 3.1 Data model (knk-web-api, EF Core, one migration `AddDomainDiscovery`)

**`UserDomainDiscovery`** → table `user_domain_discoveries`
| Column | Type | Notes |
|---|---|---|
| `Id` | int PK | |
| `UserId` | int FK `users.Id` | `Restrict` (users are soft-deleted; matches `KitPurchase`) |
| `DomainId` | int FK `domains.Id` | `Cascade` (review D8) |
| `DiscoveredAt` | datetime (UTC) | server time |
| `Source` | enum `DiscoverySource` | `RegionEnter`, `JoinInside`, `Ancestor`, `Replay`, `Admin` |
| `CoinsAwarded`, `GemsAwarded`, `ExpAwarded` | int | what this discovery contributed (pre-title-bonus) |
| `TitleBracketId` | int? | bracket used for scaling |
| `MultiplierApplied` | decimal(8,4) | personal × rank at grant time |

Indexes: **unique `(UserId, DomainId)`** (the idempotency guarantee), `(DomainId)` for stats, `(UserId, DiscoveredAt)` for "latest".

**`DiscoveryRewardRule`** → table `discovery_reward_rules`, one row per domain type, PK `DomainType` (varchar(32): `Town`,
`District`, `Structure`, `GateStructure`), seeded by the migration:

| Field | Town | District | Structure | GateStructure |
|---|---|---|---|---|
| `IsEnabled` | true | true | true | true (was false; developer 2026-09-26) |
| `ExpUnitsMin/Max` (decimal, × title unit, §3.3) | 1 / 4 (v1) | 0.5 / 2 | 0.05 / 0.25 | 0.05 / 0.25 |
| `CoinSalaryHoursMin/Max` (decimal, × title `Salary`) | 2 / 8 | 0.5 / 2 | 0.05 / 0.25 | 0.05 / 0.25 |
| `GemsMin/Max` (int, flat) | 5 / 15 (v1) | 1 / 3 | 0 / 0 | 0 / 0 |
| `IncludeAncestors` (bool) | – | true | true | true |
| `UpdatedAt` | | | | |

All non-v1 numbers are placeholders (review D3).

**`DomainDiscoveryOverride`** → table `domain_discovery_overrides`, PK/FK `DomainId` (`Cascade`): every field of the rule,
nullable = inherit from the type rule (`IsEnabled` nullable too, so a single structure can be made undiscoverable or a
landmark structure worth more).

No change to `Domain`/`User`.

### 3.2 Shared multiplier service (reuse, not duplicate)
Extract `SalaryService.ComputeRankMultiplierAsync` into **`RewardMultiplierService : IRewardMultiplierService`**
(`api:Services/RewardMultiplierService.cs`):
```csharp
Task<RewardMultipliers> GetAsync(int userId, DateTime asOfUtc);  // Personal = User.PersonalSalaryMultiplier,
                                                                  // Rank = Π active PermissionGroup.SalaryMultiplier
```
`SalaryService` and `ISalaryService.GetCurrentRankMultiplierAsync` delegate to it (behaviour unchanged, existing
`SalaryServiceTests` must stay green). Discovery applies `Personal × Rank`; **not** `SalaryConfiguration.GlobalMultiplier`
(it is the salary base rate). The fields keep their salary names for now (Q3).

### 3.3 Reward formula (`DiscoveryRewardCalculator`, pure static, injected `Random` — `SiegeRewardCalculator` style)
For user XP `x`, ordered brackets `B`, current bracket `b = max{ MinExperience ≤ x }`:
- `unit = floor((next(b).MinExperience − b.MinExperience) / 100)`; top bracket: `floor((b.MinExperience − prev(b).MinExperience) / 100)`
  (v3 has no `MaxExp`; review D4). No brackets → unit 25 (Serf).
- `exp   = round(uniform(ExpUnitsMin, ExpUnitsMax) × unit)` — **exactly v1's `getExpPart` scaling** (Town 1–4 = v1 `part/4..part`).
- `coins = round(uniform(CoinSalaryHoursMin, CoinSalaryHoursMax) × b.Salary)` — title scaling for coins via the v1 per-title
  salary (v1 coins were flat; Q1).
- `gems  = uniformInt(GemsMin, GemsMax)` — flat like v1 (Q1).
- Each × `m = Personal × Rank`, `MidpointRounding.AwayFromZero`, clamped ≥ 0 (same defensive clamp as `SalaryService:70-74`).

Town examples at `m = 1.0`: Serf XP 25–100, coins 1 300–5 200; Knight XP 15–60, coins 9 600–38 400; Count XP 100–400,
coins 20 000–80 000; One of the Seven XP 300–1 200, coins 160 000–640 000; gems 5–15 everywhere. Dragon Blood (1.5) ×1.5.
Amounts are **only** computed on the server; the plugin never sends amounts.

### 3.4 Grant algorithm (`DiscoveryService.DiscoverAsync`)
Input: `userId`, `wgRegionIds[]` and/or `domainIds[]` (≤ 50 total), `source`.
1. Resolve region ids → domains (`GetByWgRegionNameAsync`, case-insensitive; unknown ids → `skipped: NotADomain`).
2. Expand ancestors when the domain's rule has `IncludeAncestors`: Structure → District → Town, District → Town (source
   `Ancestor`). Order the set **top-down** (Town, District, Structure, then by id) — this is the message order.
3. Drop disabled domains (`skipped: Disabled`).
4. Transaction (ReadCommitted) + `SELECT Id FROM users WHERE Id = @id FOR UPDATE` (serialises concurrent grants for one user,
   same as siege `LockUsersAsync`); read already-discovered ids for the candidate set → `alreadyDiscovered`.
5. Per-user server cap: at most `MaxNewPerHour` (default 120) new discoveries in the trailing hour; excess → `skipped: RateLimited`.
6. Load brackets + multipliers once; compute each remaining domain's reward (§3.3); insert rows; `SaveChanges` — a unique-index
   violation (race the lock didn't cover, e.g. non-relational test DB) rolls back and returns everything as `alreadyDiscovered`.
7. One `AdjustBalancesAsync(userId, Σcoins, Σgems, Σexp, reason: "domain-discovery", metadata: {domainIds, source}, actorUserId: null,
   notifyPlayer: false)` on the **same scoped `KnKDbContext`** inside the transaction → one `BalanceAdjusted` audit row, consolidated
   `TitleChanged`. Commit.
8. After commit: increment metrics; return the result (the plugin shows effects directly from the response; `notifyPlayer:false`
   avoids a duplicate promotion moment via the poller).

Idempotent by construction: any retry/replay of the same request grants nothing new and returns `alreadyDiscovered`.

### 3.5 API (knk-web-api) — `Controllers/DiscoveriesController.cs`, DTOs in `Dtos/DiscoveryDtos.cs`
| Method & route | Caller | Purpose |
|---|---|---|
| `POST api/users/{userId}/discoveries` | plugin | Grant. Body `{ wgRegionIds?: string[], domainIds?: int[], source: "RegionEnter"\|"JoinInside"\|"Replay" }`. 200 → `{ granted: [{domainId, name, domainType, parentName, coins, gems, exp}], alreadyDiscovered: int[], skipped: [{key, reason}], totalCoins, totalGems, totalExp, newCoins, newGems, newExperiencePoints, titleChange? }`. 400 (empty/over 50), 404 user. |
| `GET api/users/{userId}/discoveries/known` | plugin | `[{domainId, wgRegionId}]` for the plugin cache. |
| `POST api/users/{userId}/discoveries/progress` | plugin menu, web | `PagedQueryDto` (filters `domainType`, `status` = discovered/undiscovered, search) → rows `{domainId, name, domainType, parentName, discovered, discoveredAt, coins, gems, exp}` over all enabled domains. |
| `GET api/users/{userId}/discoveries/summary` | plugin menu, web | per type `{discovered, total}`, latest discovery, lifetime totals. |
| `DELETE api/users/{userId}/discoveries/{domainId}` | web admin, `/knk discovery reset` | Reset one discovery (no claw-back; audited as `DiscoveryReset`). |
| `GET api/discovery-rewards` / `PUT api/discovery-rewards/{domainType}` | web admin | Type rules. Validation: min ≤ max, all ≥ 0. |
| `GET api/discovery-rewards/overrides`, `PUT`/`DELETE api/discovery-rewards/overrides/{domainId}` | web admin | Per-domain overrides. |
| `GET api/discovery-rewards/preview?domainType=&domainId=` | web admin | min/max coins/gems/XP per title bracket at multiplier 1.0 (computed by the same calculator). |
| `GET api/discoveries/stats` (paged) | web admin | per domain: discoverers, % of users with a linked MC account, first discoverer + date; top explorers. |

Kebab routes follow the existing `api/title-brackets`, `api/audit-log` precedent. New `AuditAction` value `DiscoveryReset = 12`
(grants are covered by the `BalanceAdjusted` row with reason `domain-discovery`).

**Auth:** knk-web-api has no plugin authentication today (plugin `config.yml` `auth.type: none`; `RequireAdmin` can't pass
because `TokenService` issues no role claim; `PUT api/users/{id}/balances` is already anonymous — see `CONTENT_PORT_PLAN.md` CP7).
The grant endpoint follows the codebase convention and is gated the same way as `/balances` until plugin auth lands (Q4); the
unique `(UserId, DomainId)` bounds abuse to one reward per domain per account.

### 3.6 Plugin (knk-plugin)

**Detection** — new `paper:discovery/DomainDiscoveryListener`:
- `OnRegionEnterEvent` (MONITOR): if eligible (below) and the region id isn't in the player's known-discovered or
  known-non-domain set, schedule a **next-tick confirmation**: the region is still in the WG applicable set at the player's
  current location. This drops entries whose move was cancelled (the event fires before `AllowEntry` is enforced) while still
  counting a player who runs through a small structure. Confirmed ids go into the player's pending batch.
- Join: new Bukkit event `paper:events/UserDataLoadedEvent` fired by `UserAccountListener` right after `joinLoadingGuard.release`
  (`paper:listeners/UserAccountListener.java:104`). On it: load the known set (`GET …/known`), then add every WG region at the
  player's location as `JoinInside` candidates (covers "already inside at login"; `handleJoin` fires no enter events).
- Teleport: covered — `PlayerTeleportEvent` goes through `handleMove` and fires enter events for every region at the destination.
- Nested regions: WG reports all overlapping regions, so a District inside a Town yields both ids in one batch; the server also
  expands ancestors and returns grants ordered Town → District → Structure.
- Quit: flush the player's pending batch to the spool, evict caches.

Not wired through `SimpleRegionTransitionService.onDomainsEntered`: it has no player id, only fires when every region's
domain is already cached, and its source query drops overlapping structures and gates (§1.3). Resolution happens on the server
from raw region ids instead.

**Eligibility** (`paper:discovery/DiscoveryEligibility`), all must hold: `discovery.enabled`; knk user id resolved (cached
`UserSummary`); not `JoinLoadingGuard.isLoading`; `ModeService.getActiveMode == NONE` (staff/owner mode = vanished); game mode
not in `discovery.excluded-game-modes` (default CREATIVE, SPECTATOR); not frozen (`AdminFreezeManager`); not a siege participant
(new `SiegeService.isParticipant(UUID)` over the lobby runtimes' `isMember`). Excluded players simply don't discover — they will
when they next enter as an eligible player. No permission node for eligibility: `KnkPermissible` short-circuits ops to `true`
(so an "exempt" node would exempt every op) and fails closed on a cold cache (a positive node would silently drop join discoveries).

**Batching, rate limit, caching** — `core:discovery/DiscoveryTracker` (no Bukkit types, unit-testable):
- Per player: `known` (discovered region ids + domain ids), `notDomain` (region ids the server said aren't domains; TTL 10 min),
  `pending` (ordered set), `inFlight` flag.
- A repeating task (`discovery.batch-window-ticks`, default 20) sends one request per player with pending ids and nothing in flight;
  max 50 ids per request, max `discovery.max-requests-per-minute` (default 12) per player; the rest wait.
- Before the known set has loaded, candidates queue; they are filtered once it arrives. If loading fails, candidates are still
  sent (server dedups) but at the rate limit.
- Response: `granted` → add to `known`, show effects; `alreadyDiscovered` → add to `known`; `NotADomain` → `notDomain`;
  `Disabled` → `known` (stop re-sending this session); `RateLimited` → back to pending with a 60 s delay.

**API down** — `core:discovery/DiscoverySpool` (one JSON file per player UUID under `plugins/KnK/discovery-spool/`, atomic
temp+move like `SiegeResultSpool`): a request that fails transiently (network/5xx, after `RetryPolicy`) is spooled; 4xx is logged
and dropped. Replayed on enable, every 60 s while non-empty, and on the player's next join (source `Replay`). Server idempotency
makes replays safe. If the replay's player is online and the original discovery was < 30 s ago, full effects; otherwise a single
chat summary ("While the server was busy you discovered N places: +X coins, +Y gems, +Z XP"); offline → silent (the menu shows it).

**Effects** — `paper:discovery/DiscoveryEffects` (main thread), one per granted domain, in response order, 10 ticks apart:
- Sound `discovery.effects.sound` (default `UI_TOAST_CHALLENGE_COMPLETE`, vol 0.8, pitch 1.0; v1 used LEVEL_UP 0.6/1.0).
- Particles `discovery.effects.particle` (default `HAPPY_VILLAGER`, 30, spread 0.6) at the player + a `FIREWORK` burst for Towns.
- Chat (v1 colours): `&bYou discovered {type} &a{name}&b{parent} and received &a{coins}&b coins, &a{gems}&b gems and &a{exp}&b experience!`
  where `{parent}` = ` in &a{town}` for Districts/Structures; zero amounts are omitted from the sentence.
- If the response has `titleChange` → `PromotionEffects.show` once after the last discovery line.
- Update the cached `UserSummary` balances from `newCoins/newGems/newExperiencePoints`.

**config.yml** (new block):
```yaml
discovery:
  enabled: true
  batch-window-ticks: 20
  max-requests-per-minute: 12
  excluded-game-modes: [CREATIVE, SPECTATOR]
  exclude-siege-participants: true
  spool-directory: discovery-spool
  replay-interval-seconds: 60
  effects:
    sound: UI_TOAST_CHALLENGE_COMPLETE
    sound-volume: 0.8
    sound-pitch: 1.0
    particle: HAPPY_VILLAGER
    particle-count: 30
    town-firework: true
  messages:
    discovered: "&bYou discovered {type} &a{name}&b{parent} and received {rewards}!"
    replay-summary: "&bWhile the server was busy you discovered &a{count}&b places: {rewards}"
```

**Commands** (v3 conventions, `COMMAND_CATALOG_V3.md` §0/§8):
- `/discoveries` (alias `/disc`) — player; opens `discoveries.main`. `plugin.yml` permission `knk.discoveries`, `default: true`
  (same model as `/menu`'s `knk.menu`). Registered with `registerSimpleCommand`.
- `/knk discovery list <player>` / `reset <player> <domainId>` / `status` — admin subcommand in `KnkAdminCommand`'s registry,
  node `knk.admin.discovery` via `KnkPermissible` (per-subcommand `knk.admin.*` nodes, user-features DESIGN §2.3). `status` prints
  tracker/spool sizes. Reset uses `UsersCommandApi.withActor`-style actor header for when CP7's server half lands.

### 3.7 Menu — `discoveries.main` (new; seed `api:Models/Menu/MenuTemplateSeed.Discovery.cs`, feature `paper:menu/content/DiscoveriesMenuFeature.java`)
Height 6, `Growth = Dynamic`, `MinHeight = 3` (profile precedent).
| Slot | Item | Binding / action |
|---|---|---|
| 0 | viewer head | `&f$player.getName$`, lore `$discoveries.getSummaryLines$` ("Towns 3/5", "Districts 7/20", "Structures 12/140") |
| 4 | BOOK `&eKnowledge` (v1 tile copy) | `&7See all discovered places`, `&7Latest discovered: &f$discoveries.getLatestName$` |
| 8 | Back/Exit | `menu.back` |
| 18–44 | content grid over row source `discoveries.rows` (`Overflow = Scroll`) | row template: `Material`/`Name`/`Lore`/`DisplayMode` from `$row.*$` |
| 45 / 53 | pager | `menu.page.prev` / `menu.page.next` |
| 47 | HOPPER `&eType: …` | `menu.filter.cycle {facetKey: DomainType, values: "Town,District,Structure"}` |
| 49 | ENDER_EYE `&eShow: …` | `menu.filter.cycle {facetKey: Status, values: "Discovered,Undiscovered"}` |
| 51 | BARRIER `&cClear filters` | `menu.filter.clear` |

Rows (`DiscoveryRow`): discovered → material by type (Town `FILLED_MAP`, District `OAK_SIGN`, Structure `BRICKS`), name
`&a{name}`, lore `&7{type}{ in parent}`, `&7Discovered: &f{date}`, `&7Reward: &6+{coins} &b+{gems} &d+{exp} XP`, `DisplayMode`
`HIGHLIGHT` for the latest, else `NORMAL`. Undiscovered → `GRAY_DYE`, `DISABLED`; Towns show their name (`&7{name}`, "&8Not yet
discovered"), Districts/Structures show `&8???` with `&7Somewhere in &f{town}` (D6). Read-only (no click actions; a future
teleport action belongs to `specs/teleport/`).

Data: the row source forwards engine page/filters to `POST …/discoveries/progress`; the root `discoveries` reads
`…/summary` fetched in the same async step (the `FreshViewers` pattern from `ProfileMenuFeature`, providers never do I/O).

Hub tile: `main` slot **20**: BOOK `&eDiscoveries`, lore `&7See all discovered places`, `&7$discoveries.getCountLine$`,
action `menu.open {key: discoveries.main}`, Render `menu-available discoveries.main`. Seeds are create-only
(`MenuTemplateSeed.cs:18-35`), so an existing `main` row doesn't get the tile automatically (implementation plan Phase 3 has the step).

### 3.8 Anti-exploit & concurrency
- Double grant: impossible — unique `(UserId, DomainId)` + per-user row lock + the insert and balance update share one transaction.
- Client-supplied amounts: none; server computes.
- Region-id spoofing / farming via the anonymous API: bounded to one reward per domain per account; per-user hourly cap;
  full fix = plugin auth (Q4). Alt-account farming then transferring coins is a transfer-limit concern for `specs/currency-payments/`.
- Cancelled moves (`AllowEntry=false`) don't count (next-tick confirmation).
- Staff tools (vanish/creative/freeze) can't farm (eligibility). Admin reset re-enables a reward — admin-only and audited.
- Ledger: once `specs/currency-payments/` lands, step 7 of §3.4 switches to its ledger-backed mutation with idempotency key
  `discovery:{userId}:{domainId}` (per-domain entries, or `discovery:{userId}:{sorted ids hash}` if it takes one key per call).

### 3.9 Web-app (knk-web-app)
- `app:apiClients/discoveryClient.ts`, types `app:types/dtos/discovery/`.
- **Player (self)**: "Discoveries" section on `app:pages/AccountManagementPage.tsx` — per-type progress bars (`summary`) +
  most recent 10 (`progress` filtered to discovered); only when the account is linked to Minecraft.
- **Admin player profile**: "Discoveries" section on `app:pages/admin/PlayerProfilePage.tsx` — table (name, type, parent, date,
  rewards), reset button per row (confirm dialog).
- **Admin config** `app:pages/admin/DiscoveryAdminPage.tsx`, route `/admin/discovery` (nav link next to Siege configuration):
  (1) type rules grid with inline edit; (2) per-title preview table for the selected type/domain; (3) overrides list + add via a
  domain `SearchableDropdown`; (4) statistics table (discoverers per domain, least/most discovered, top explorers).
  A dedicated page (like `SiegeConfigurationPage`) rather than FormConfig, because the preview is computed.

### 3.10 Observability
- API: `ILogger` info line per grant (`userId`, granted count, totals); `System.Diagnostics.Metrics` meter `knk.discovery`
  with counters `discoveries_granted{domain_type}`, `discoveries_duplicate`, `discoveries_rate_limited` (register the meter in
  `DependencyInjection/ObservabilityServiceCollectionExtensions.cs`). Note: no Prometheus `/metrics` endpoint is mapped today
  (`api:Program.cs:186` TODO) despite `knk-web-api/CLAUDE.md` saying so — metrics reach OTLP only.
- Plugin: FINE logs per candidate/flush, WARNING on spool writes, `/knk discovery status`.
- Audit: `BalanceAdjusted` (reason `domain-discovery`, metadata domain ids) and `DiscoveryReset`.

---

## 4. Decisions taken by default (each: review)

- **D1 (review)** All `Domain` subtypes discoverable; GateStructure seeded disabled (gates are parts of walls, and there can be
  many). Per-domain override can flip any single domain.
- **D2 (review)** Ancestors are discovered with a child (entering a District in an undiscovered Town discovers and rewards both),
  granted and messaged Town → District → Structure.
- **D3 (review)** Placeholder reward table in §3.1; only Town XP units (1–4) and Town gems (5–15) come from v1.
- **D4 (review)** Top title bracket XP unit = previous bracket width / 100 (v3 dropped v1's `MaxExp`).
- **D5 (review)** Multiplier = `PersonalSalaryMultiplier × Π rank SalaryMultiplier` via a shared service; salary's global
  multiplier not applied. v1's Friday event multiplier not ported.
- **D6 (review)** Undiscovered Towns shown by name; undiscovered Districts/Structures masked as "???" with their town.
- **D7 (review)** Excluded: staff/owner mode, CREATIVE/SPECTATOR, frozen, loading, siege participants. No permission node.
- **D8 (review)** Deleting a Domain cascades its discovery rows (history kept in the audit log); a reset doesn't claw back.
- **D9 (review)** API down → spool & replay (not drop), because rewards are permanent one-offs the player would otherwise lose.
- **D10 (review)** Server resolves WG region ids (plugin sends raw ids) instead of fixing `search-region-decisions`; that endpoint's
  one-per-type/no-gates limitation is left to a separate fix.
- **D11 (review)** Effects fire from the grant response (not the notification poller); promotion shown once after the discovery lines.
- **D12 (review)** Existing hub `main` row gets the tile via a documented one-time step, not by changing the create-only seed policy.

## 5. Open questions for the developer

### Resolved 2026-09-26 (developer)

1. **Scaling (Q1):** XP by title as v1, coins = salary-hours × title `Salary`, gems flat — agreed. **Change:** Structure
   *and* GateStructure rewards smaller than the §3.1 placeholders, and GateStructure discovery **enabled**. New seeds:
   Structure and GateStructure `ExpUnits 0.05/0.25`, `CoinSalaryHours 0.05/0.25`, `Gems 0/0`, `IsEnabled true`.
2. **Structures (Q2):** all discoverable with small rewards — agreed.
3. **Existing players (Q5):** treated as new — no backfill, nobody starts with discoveries.
4. **Q3 (multiplier names) / Q4 (ship before plugin auth):** defaults taken — keep names; the grant endpoint ships behind
   the KNG-22 `RequireServiceOrPermission` attribute (plugin API key), so Q4's exposure concern is resolved by Phase 0.

Original questions below, kept for the record.

1. **Coin and gem scaling.** v1 only title-scaled XP; coins (1 000–50 000) and gems (5–15) were flat.
   Options: (a) coins = salary-hours × title `Salary`, gems flat; (b) all flat (pure v1); (c) coins and gems both × a per-title
   factor (e.g. `Salary / 650`). **Recommended: (a)** — it's the v1 per-title salary table, keeps gems (premium currency) stable.
2. **Structure discovery volume.** Every house is a Structure; with hundreds, discovery chat could be spammy and cumulatively large.
   Options: (a) all structures discoverable with small rewards (D1/D3 defaults); (b) structures only when an override enables them
   (landmarks); (c) structures discoverable but silent (no chat/effects, just menu + rewards). **Recommended: (a)** with the
   10-tick spacing, revisit after playtest.
3. **Multiplier field names.** `User.PersonalSalaryMultiplier` / `PermissionGroup.SalaryMultiplier` now drive discovery too.
   Options: (a) keep names, document the wider use; (b) rename to `PersonalRewardMultiplier`/`RewardMultiplier` (migration +
   web-app FormConfig/labels); (c) separate discovery multipliers. **Recommended: (a)** now, (b) when a third consumer appears.
4. **Ship the grant endpoint before plugin auth exists?** Today it would be as open as `PUT /balances`.
   Options: (a) ship now, one-reward-per-domain + hourly cap as mitigation; (b) wait for CP7 option 1 / currency-payments auth.
   **Recommended: (a)** — no new exposure class, and it doesn't block on another feature.
5. **Existing players.** Should current players get retroactive "discoveries" for places they have obviously visited (no data
   exists to know that)? Options: (a) no — everyone starts empty and earns rewards on next entry; (b) backfill discovered-without-
   reward for all domains for pre-launch accounts. **Recommended: (a).**
