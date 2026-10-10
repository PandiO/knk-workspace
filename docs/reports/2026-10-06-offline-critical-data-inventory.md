# Offline-critical data on the game server — what needs a disk-backed, refreshable cache

**Status:** analysis (read-only); follow-up work is Linear [KNG-58](https://linear.app/kngpandi/issue/KNG-58)
**Last updated:** 2026-10-06
**Linear:** [KNG-58](https://linear.app/kngpandi/issue/KNG-58) (this work), [KNG-56](https://linear.app/kngpandi/issue/KNG-56) (domain access, solved separately), [KNG-57](https://linear.app/kngpandi/issue/KNG-57) (SignalR push)
**Code inspected:** knk-plugin `claude/worldguard-entry-deny-bypass-sj1j7g` @ `9ab1f5d` (= `main` `74607a9` + KNG-55); knk-web-api `master`. Paths below are relative to `knk-paper/src/main/java/net/knightsandkings/knk/paper/` (P) and `knk-core/src/main/java/net/knightsandkings/knk/core/` (C).

## Question

The developer asked (2026-10-06): domain entry/exit rules must hold without the API. Which other sensitive, high-priority data needs the same refreshable, disk-stored cache?

## How every gateway behaves today

- **Nothing is written to disk.** Every API-backed cache is in memory and empty after a restart. No generic "persist cache" helper exists.
- **`CACHE_FIRST` never serves stale data on error** (`C/dataaccess/DataAccessExecutor.java:190-218`), and neither does `API_THEN_CACHE_REFRESH`. `allow-stale: true` in config.yml has no effect unless a caller explicitly asks for `STALE_OK` (only siege does).
- **Effective TTL is 60 s** (`cache.ttl-seconds`) for most entities. Permissions use 30 s and siege 30 min; the other per-entity `ttl-minutes` values are dead config (`DataAccessFactory.java:262-270`).
- **Ops bypass every in-house permission check** (`KnkPermissible.java:74, :103`). `ops.json` is local, so ops keep full power during an outage.
- **Two `CacheManager` instances** (`KnKPlugin.java:385` and `:497`). The first one's `UserCache` is orphaned in `UserManager`. A third user map lives in `UserManager.userCache`. Fix this before persisting anything.

## Join with the API down

- **Login is never blocked.** `PlayerListener.onValidateLogin` only logs.
- **The join hold is released.** `JoinLoadingGuard` releases the player after at most 15 s with `PlayerUserData.minimal(userId=null)` (`UserManager.java:121-133`).
- **No user id after a restart.** Every `KnkPermissible` check is then DENY/UNAVAILABLE, siege join is refused, discovery is spooled without a user, and lootbox lookups return null.

## Inventory

| # | Data | On API failure today | Risk | Priority |
|---|---|---|---|---|
| 1 | **Permissions** (in-house groups/grants; `PermissionsDataAccess`, `GET /api/users/{id}/permissions/check`) | **Fail-closed.** The cache-only sync check returns false once the 30 s entry expires; async checks say "can't be checked right now". | Within 30 s every non-op staff member loses /freeze, /unfreeze, /staffchat, /tp, /fly, /heal, /inventory, /knk subcommands, `knk.region.bypass`, modes, socialspy, kit/lootbox/siege/teleport nodes. Non-op owners are forced to SURVIVAL and teleported to spawn on join (`PlayerListener.java:178-188`). **Already flaky with the API up:** the first check after each expiry fails closed. | **P0** |
| 2 | **User record** (uuid→userId, activeMode, isFrozen, title, tier, colours) | Login and join go ahead with minimal data; `UserCache` is memory-only. | Without the userId after a restart, all permission checks are UNAVAILABLE (row 1). | **P0** (userId, activeMode, isFrozen); P1 display fields |
| 3 | **Freeze** (`AdminFreezeManager.restoreOnJoin`, always calls the API) | **Fail-open:** an error is treated as "not frozen". | A frozen player who relogs during an outage, or after a restart, is free. | **P0** |
| 4 | **Active mode / vanish** | A cold cache gives NONE; an UNAVAILABLE check clears the mode and persists NONE (`ModeListener.java:69-71`). | Vanished staff are revealed. | **P0/P1** (comes with rows 1 and 2) |
| 5 | **Domain AllowEntry/AllowExit** | Fail-open on a cold cache. | No entry/exit enforcement. | **P0: solved by KNG-56** (WorldGuard flags on disk) |
| 6 | Combat safezones (`WorldGuardCombatSafezones`) | Fail-open on a cold cache. | Custom enchantment effects apply in towns (vanilla PvP is still WorldGuard's `pvp`). | P1. Could read the KNG-56 flags or a persisted domain-type snapshot. |
| 7 | Respawn town (town 4) | `townsDataAccess...join()` **on the main thread** (`PlayerListener.java:375`), so it can stall the server. Vanilla respawn on error. | Server stalls; wrong respawn. | **P1** (also remove the `.join()`) |
| 8 | /spawn destination | Falls back to world spawn (5 min TTL). | Wrong spawn only. | P2 |
| 9 | Warps / teleport destinations | The API authorises and charges, so warps fail closed. | None. | Not needed |
| 10 | Gate structures and doors | Zero gates load at a startup without the API; blocks stay as they were. | Gate and siege gameplay broken; a gate left open at a crash stays open. | **P1** (persist the last snapshot; spool state writes) |
| 11 | Siege runtime config | No lobbies after a startup without the API; mid-session keeps the stale config. | No sieges. | P1/P2 |
| 12-14 | Title brackets, permission groups list, menus, material refs, blueprints, kits, tags, categories | Stale or "unavailable". | Inconvenience. | P2 / not needed |
| 15 | Grades | Seeded defaults. | None. | Not needed |
| 16 | Lootbox runtime | Keeps the last boxes; none after a restart. | No boxes spawn. | P2 |
| 17 | Currency (balances, /pay, salary) | Refused as "unavailable". | None if refused. | **Not needed:** writes must stay API-authoritative (double-spend risk). |
| 18 | Ignore lists | **Fail-open:** the list stays unloaded. | Ignored players' chat, /msg and /tpa get through. | P2 (P1 if anti-harassment matters) |
| 19 | Player notifications | Delivered later (server-side queue). | Delay only. | Not needed |
| 20 | Managed regions, temp-region retention | Skip or keep; WorldGuard keeps its own data. | None. | Not needed |
| 21 | Bans | Paper's own banlist (disk). Mutes: not found. | None. | Not needed |
| 22 | Writes: discovery, siege results, PM log | **Already spooled to disk.** | None. | Not needed |

## Recommendation (for KNG-58)

1. **P0 as one piece:** a per-player security snapshot on disk, with a max age and refreshed on every successful API read and on push (KNG-57). It holds:
   - uuid → userId;
   - activeMode and isFrozen;
   - the permission decisions the server uses.
   
   Two points matter:
   - **Applying it:** use it when the API is unreachable, before failing open or closed.
   - **What to cache:** either the (userId, node) check results or a new API endpoint returning the resolved holder chain with expiries. `/permissions/effective` lacks the holder order and expiries, so it can't reproduce `CheckAsync` locally.
2. **Bound and invalidate.** A revoked staff member must not keep grants during an outage forever. Use a max age (for example 24 h), deny-wins merges, and a `PermissionsChanged` push.
3. **Make the stale-on-error layer part of the gateways** (`DataAccessExecutor`), so the disk copy is actually served after the memory TTL.
4. **Reuse the spool pattern:** `DiscoverySpool`/`SiegeResultSpool` (Jackson, versioned, temp file + `ATOMIC_MOVE`).
5. **Fix first:** the duplicate `CacheManager`.
6. **P1 after P0:** gates snapshot, respawn town without `.join()`, siege runtime config, safezones from the KNG-56 flags.

## Existing disk persistence to reuse

| Class | What it writes |
|---|---|
| `C/discovery/DiscoverySpool` | per-player JSON, atomic move |
| `C/siege/SiegeResultSpool` | per-match JSON |
| `C/messaging/PrivateMessageLogShipper` | JSONL spool |
| `P/siege/SiegePlayerVault` | YAML per player, temp file + move |
| `P/inventory/OfflinePlayerStorage` | sha256 compare-and-swap, `.dat_old` backup |
