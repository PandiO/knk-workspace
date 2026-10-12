# Offline security cache — permissions, freeze and modes without the API

**Status:** P0 implemented on branch `claude/worldguard-entry-deny-bypass-sj1j7g` (knk-plugin `239ea49`, brought up to `main` in `7e9e8cf`), **live smoke test passed and merged to knk-plugin `main` 2026-10-10** (merge `2649911`). Linear [KNG-58](https://linear.app/kngpandi/issue/KNG-58)
**Last updated:** 2026-10-12 (KNG-123: ignore lists added, knk-plugin branch `claude/kng-123-outage-main-thread-ignore`, unmerged)
**Related:** [`domain-access-enforcement.md`](domain-access-enforcement.md) (KNG-56: domain rules already survive outages as WorldGuard flags); [`reports/2026-10-06-offline-critical-data-inventory.md`](../reports/2026-10-06-offline-critical-data-inventory.md) (why these items are P0); KNG-57 (SignalR push, incl. erasure); KNG-34 D14-D16 (data deletion); KNG-81 (duplicate `CacheManager`)

## 1. Problem

After a restart with knk-web-api unreachable, the game server knew no account for any player:
- every permission check failed for non-ops, so staff lost /freeze, /tp, `knk.region.bypass` and modes, and non-op owners were forced to SURVIVAL and teleported to spawn on join;
- a frozen player who relogged was free;
- vanished staff were revealed.

Even with the API up, the first permission check after each 30 s memory expiry failed closed.

## 2. What is kept

`OfflineSecurityStore` (`knk-core/.../core/offline/`) keeps the last state **the API confirmed**, in memory and in `plugins/KnightsAndKings/offline-security.json`:

| Entry | Fields | Max age |
|---|---|---|
| Account | Minecraft UUID, knk user id, username, active mode (NONE/STAFF/OWNER), frozen + reason, last confirmed | `identity-max-age-days` (30, capped at 30: the GDPR erasure deadline) |
| Permission answer | user id, node, allowed, last answered | `permission-max-age-hours` (72) |
| Ignore list (KNG-123) | owner UUID and user id; per entry the ignored player's user id, UUID, name and since when; last returned | `identity-max-age-days` (30) |

No email, balances, titles or other profile data.

Entries come only from API answers:
- `UsersDataAccess` reports every user the API returns, and every UUID it knows no user for.
- `PermissionsDataAccess` reports every check answer.
- `IgnoreService` reports every ignore list the API returns (KNG-123).

Local edits update their own fields without counting as a confirmation: a freeze or mode change made on this server is kept for the next join, but doesn't extend the max age. The same holds for an /ignore or /unignore the API accepted. The file is written every `flush-seconds` (10) off the main thread, and on disable (temp file plus atomic move; a corrupt file is moved aside as `.corrupt`).

## 3. When it is used — fallback only

A live API answer always wins, and every API answer overwrites the store.

| Case | Behaviour |
|---|---|
| Permission check, sync (`KnkPermissible.hasPermission`) | A fresh in-memory answer is used first. Otherwise the store's last answer is used (and a refresh starts in the background). Otherwise no. |
| Permission check, async (`checkAsync`) | If the API can't answer, the store's last answer is used; otherwise UNAVAILABLE. A last-known **deny stays a deny**. An answer older than the max age counts as unknown, so no. |
| Account for a UUID | Taken from the user cache, else from the store. This is what makes permissions work after a restart. |
| Freeze at join (`AdminFreezeManager.restoreOnJoin`) | If the API lookup fails, the last known freeze is applied (it used to fail open). |
| Ignore list (`IgnoreService.load`, KNG-123) | If the API fails, or the player's user id isn't known (restart during an outage), the list the API last returned is used, so chat, /msg and /tpa stay filtered. The next load (join, the second join refresh, /ignore while unloaded) asks the API again, and its list replaces the stored one. No stored list: the player ignores nobody until the API answers (fail open, as before). An /ignore during the outage is rolled back as before. |
| Active mode at join (`ModeService`, `ModeListener`) | The persisted mode comes from the store when the account isn't loaded. If the mode permission can't be checked (API down and no last answer), the player stays hidden and the mode is kept; before, the mode was revealed and cleared. A real "no" still clears it. |

## 4. Erasure and correctness (KNG-34 D14-D16)

- **Not found.** A UUID the API reports no user for (404, e.g. erased: its UUID is cleared) deletes that player's account, permission answers and ignore list, and takes them off every other player's stored ignore list. So does a permission check for a user id the API no longer knows.
- **No resurrection.** A different account for the same UUID (a returning player after erasure) replaces the old one and deletes its permission answers.
- **Hourly re-check** (`OfflineIdentityVerifier`, off the main thread). It re-asks the API about every account not confirmed for `verify-after-hours` (6). Not found is deleted, a different account is replaced, the same account is refreshed. If the API is unreachable it stops and changes nothing. It also prunes everything past its max age.
- **Push.** When the two-way channel lands (KNG-57), an `account-erased` event deletes the player's local data immediately. The hourly re-check and the 30-day max age remain the backstop.

## 5. Privacy inventory (game server)

| File | Personal data | Retention | Deleted on erasure |
|---|---|---|---|
| `offline-security.json` | UUID, user id, username, active mode, freeze reason, permission answers; ignore lists (KNG-123): owner UUID/user id and the ignored players' user id, UUID, name, since when | ≤ 30 days since the API last confirmed the account; permission answers ≤ 72 h; an ignore list ≤ 30 days since the API last returned it | Yes: on the next API answer for that UUID or user id, the hourly re-check, or (KNG-57) the push. An erased player's own list is deleted and they are taken off the other stored lists. An ignored player who never joined this server has no account entry to re-check: they leave the stored list when the owner's list is next loaded from the API, or after 30 days at most. |

Other per-player files on the game server are listed in KNG-57's erasure section: discovery spool, statistics spool (KNG-34), siege vault, PM-log spool.

## 6. Config (`config.yml`, `offline-cache`)

```yaml
offline-cache:
  enabled: true
  file: offline-security.json
  identity-max-age-days: 30
  permission-max-age-hours: 72
  verify-after-hours: 6
  flush-seconds: 10
```

## 7. Not in this change

- **Duplicate `CacheManager`** (KNG-81). Fixed 2026-10-11 (knk-plugin `main` `0ee516aa`), after the first-join kit grant was made idempotent in the API. The store listens to API answers, so it never depended on which cache instance was used.
- **P1 items of KNG-58 (now KNG-123):** gates snapshot, siege runtime config, combat safezones and a generic stale-on-error layer in `DataAccessExecutor` remain open. Ignore lists were added 2026-10-12 (above). The respawn town no longer blocks the main thread since KNG-52 rounds 3-4 (towns load async; the respawn reads them).
- **First join during an outage:** a player whose account the server has never seen (or not within 30 days) has no last-known state. They get no non-op permissions until the API is back, as before.

## 8. Tests and live checklist

Unit tests:
- `OfflineSecurityStoreTest` (11): restart round trip, minimal file contents, max ages and pruning, forget, replacement, local freeze/mode, corrupt file, verifier cases.
- `KnkPermissibleOfflineTest` (7): restart with the API down, unknown node, too old, denial stays, first check after the TTL, 404 forgets, unknown player.
- `OfflineFreezeAndModeTest` (5): frozen relog, local freeze kept, unfrozen stays free, vanish kept, mode change kept.
- `OfflineIgnoreListsTest` (12, KNG-123): restart round trip, older file without lists, max age and pruning, local change keeps the age, erasure of the owner and of an ignored player, replacement.
- `IgnoreServiceOfflineTest` (14, KNG-123): API down after a restart, no user id, API back replaces the list, fail open without a list, max age, erased owner, accepted/refused changes (only the confirmed change is stored, also when two overlap), rollback during the outage, quit, a load for a replaced account discarded.

Live (developer, on the dev server) — **passed 2026-10-10**: phases 1-3 all pass; the never-joined player having no staff rights during an outage and the optional checks (cleanup pass, max age, corrupt file) were accepted by the developer. Steps:
1. As a non-op staff member with the API up: join, use `/staffmode` and a staff command, and walk through a closed domain with `knk.region.bypass`. Freeze a test player.
2. Stop knk-web-api and restart the server.
3. Join as the staff member: still staff (no SURVIVAL/spawn teleport for an owner), staff commands work, bypass works, still vanished if they were.
4. The frozen test player joins: still frozen.
5. A player who never joined before: joins normally, no staff rights.
6. Start the API again and check that changes made in the web app apply.
7. `plugins/KnightsAndKings/offline-security.json` contains only the fields in §2.
