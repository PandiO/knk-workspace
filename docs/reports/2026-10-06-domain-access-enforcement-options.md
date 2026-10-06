# Domain AllowEntry/AllowExit enforcement — in-house vs WorldGuard, offline safety

**Status:** advice, awaiting the developer's decision (no code changed for this report)
**Last updated:** 2026-10-06
**Linear:** [KNG-56](https://linear.app/kngpandi/issue/KNG-56) (offline-safe enforcement), follow-up to [KNG-55](https://linear.app/kngpandi/issue/KNG-55)
**Code inspected:** knk-plugin `claude/worldguard-entry-deny-bypass-sj1j7g` @ `9ab1f5d` (= `main` `74607a9` + the KNG-55 fix); WorldGuard 7.0.10 bytecode (`worldguard-core`/`worldguard-bukkit`, the versions knk-paper compiles against); knk-web-api seed migrations

## Questions (developer, 2026-10-06)

1. Is the in-house enforcement on par with WorldGuard's region entry/exit enforcement and its exploit countering?
2. Does checking entry/exit need constant API requests? If so, would a local cache be better? Should players who keep pushing the rule (spamming W) be punished?
3. Entry/exit must still be enforced when the API connection is lost, including for players who join while there is no API connection. **Very high priority.** Does that tip the balance towards WorldGuard?

## Short answers

1. **Walking: on par since KNG-55. Overall: no.** Three gaps remain in how players are moved: respawning into a closed domain, mounting a vehicle that stands inside one, and spamming the deny message. Behind those sits one large gap: the rules are only known while the API has answered since the last restart.
2. **No constant requests.** There is one batched `POST /Domains/search-region-decisions` per region id per server lifetime, then nothing. The problem is the opposite: the cache is memory-only, empty at every start, and never refreshed. A changed AllowEntry/AllowExit only takes effect after a restart.
3. **Today, with the API down, nothing is enforced** for any region not looked up since the last start, joins included. This is decisive. The rules must live **locally and persistently on the game server**.

   **Recommendation: a hybrid.** Store each domain's AllowEntry/AllowExit on its WorldGuard region as two custom flags, which WorldGuard persists. Enforce them with a custom WorldGuard *session handler*, so WorldGuard's mature movement machinery does the policing while the rules stay ours.

   Plain WorldGuard `entry`/`exit` flags are **not** recommended: their semantics differ from the domain rules in ways that would trap or exempt the wrong players (§4).

## 1. Parity: in-house (after KNG-55) vs WorldGuard 7.0.10

WorldGuard's side was read from its bytecode:
- `PlayerMoveListener` chooses a `MoveType` per move.
- `Session.testMoveTo` asks every handler and, on a refusal, returns the last valid location.
- `EntryFlag` / `ExitFlag` are the session handlers for the standard flags.
- `WorldGuardVehicleListener` handles vehicle moves.

| Way in or out | WorldGuard | knk-plugin now | Gap |
|---|---|---|---|
| Walk, sprint, jump, knockback | `MOVE` on every block change. The player is put back at the **last valid location**, centred on its block. | `PlayerMoveEvent` cancelled. Every step is judged since KNG-55. | none |
| Elytra, swimming, riptide | `GLIDE` / `SWIM` (same check) | Same `PlayerMoveEvent` path | none |
| Riding (horse, boat, minecart, pig, strider) | `RIDE` from both `PlayerMoveEvent` and `VehicleMoveEvent`. The vehicle is stopped and sent back. | `VehicleMoveEvent` (KNG-55): the rider is taken off and put back, and so is the empty vehicle. | Riding an entity that isn't a Bukkit `Vehicle` is unchecked. This is rare. |
| Mounting a vehicle that stands inside a closed domain | `EMBARK`: `VehicleEnterEvent` is cancelled | **not checked** | **gap**: mounting a horse just over the border puts the rider inside |
| Teleport (commands, ender pearl, chorus fruit) | `TELEPORT`, with `exit-via-teleport` / `exit-override` options | `PlayerTeleportEvent` cancelled; the teleport engine refuses up front (`RegionTeleportRestriction`) | none (no "exit via teleport" option, not needed) |
| Respawn (bed or respawn anchor inside a closed domain) | `RESPAWN`: the respawn location is corrected | **not checked** | **gap** |
| Join inside a closed domain | not evicted (the session starts with the join spot as last valid) | sent to world spawn, **only if the domain is cached** | effectively none after a restart (§3) |
| Deny-message spam | at most one message every 2 s (`MESSAGE_THRESHOLD = 2000`) | an action bar on every refused step | cosmetic |
| Bypass | `worldguard.region.bypass.<world>` (Bukkit permission, cached) | `knk.region.bypass` through `KnkPermissible` (cache-only; fails closed while the permission cache is cold) | not interchangeable (§4) |
| **Rules available without the API** | yes: flags are stored with the regions on disk or in the database | **no**: memory-only cache, empty at start, fail-open | **critical** |
| A rule change takes effect | immediately (`/rg flag`) | after a server restart (nothing invalidates the cache) | **major** |

**Verdict:** on how players move, the in-house code is now close to WorldGuard. EMBARK and RESPAWN are the remaining holes, and both are small to close. On data availability it is far behind, and that is what matters for the high-priority requirement.

**Correction to the KNG-55 report:** WorldGuard handles `RIDE` from `PlayerMoveEvent` as well as `VehicleMoveEvent`, so riders may still get move events on some paths. The KNG-55 listener judges riders only on `VehicleMoveEvent`, which is safe either way for real vehicles. The claim "no `PlayerMoveEvent` for riders" in that report is softened accordingly.

## 2. API traffic and the cache

**Lookups:** one `POST /Domains/search-region-decisions` per tracker lookup, batched over that move's uncached region ids (`DomainsQueryApiImpl` → `RegionDomainResolver.resolveRegionsFromApi`).
- Ids already in flight are shared.
- Ids without a domain, and failed lookups, are retried at most every 30 s (`FAILED_LOOKUP_COOLDOWN_MS`, KNG-55).
- **A cached id is never fetched again.** `getDomainByRegionIdNoRefresh` returns it at any age, and nothing evicts it.

**Persistence:** none. `domainsByRegionId` is an in-memory `ConcurrentHashMap`.
- `warmCache` has no caller on `main`; it is only used by the unmerged road-navigation branch.
- No domain data is written to disk.
- `/knk cache refresh` and `CacheManager.clearAll()` don't touch the resolver.

**Invalidation:** none.
- The web app changing AllowEntry/AllowExit reaches the plugin only after a restart.
- The one exception: Town/District/Structure details that happen to sit in the shared caches (60 s TTL). In practice those rarely hold domain regions.

So this is not a "too many requests" problem. It is a "data only in RAM, never refreshed" problem. A good local cache is indeed the answer, and it must be **persistent** and **refreshable** to meet requirement 3.

## 3. Behaviour with the API down (today)

- **Startup:** the plugin enables, and the region listener is registered unconditionally (`KnKPlugin.java:790-799`). The cache is empty.
- **Any crossing:**
  1. The region is "missing", so the move is allowed and a lookup starts.
  2. The lookup fails, and the region goes on the 30 s cooldown.
  3. During the cooldown the region counts as having no domain, so moves are allowed.
  4. When the cooldown ends, the cycle repeats.
  
  Result: **no AllowEntry/AllowExit is enforced at all.**
- **Join:**
  - The join check resolves nothing, so nothing is enforced.
  - The forced re-validation at join deliberately never enforces.
  - `JoinLoadingGuard` releases the player after at most 15 s with minimal data, and movement isn't restricted during the hold.
- **Bypass:** `knk.region.bypass` is false for everyone but ops (no user id, permission cache cold). That is a safe default.
- **Mid-session outage:** domains cached before the outage stay enforced, because the cache never expires. Domains never looked up since the start are open.

This fails requirement 3 outright, independent of KNG-55.

## 4. Options

### A. Plain WorldGuard `entry` / `exit` flags, written by the managed-region reconciler

The reconciler (`ManagedRegionReconciler`) already runs at startup, on `/knk regions repair`, and when a region is created. It already sets `entry` for houses, rooms and battlegrounds. It would write `entry deny`/`exit deny` from each domain's flags.

Pros:
- WorldGuard's mature handlers cover every move type.
- The flags persist with the regions, so enforcement works offline and at joins.
- Rule changes are visible in `/rg info`.

Cons. These are **semantic mismatches**, not just effort:
1. **Members are exempt.** Both flags default to region group `NON_MEMBERS`, confirmed in the `Flags` static init. Members and owners walk through unless `entry-group`/`exit-group` is set to `all` explicitly.
2. **Priority, not "every entered domain".**
   - WorldGuard tests the destination's highest-priority value (`EntryFlag.onCrossBoundary` → `toSet.testState(ENTRY)`). The domain rule is that *every* domain being entered must allow it (`SimpleRegionTransitionService.checkEntryDenials`).
   - Managed regions have parents (district → town), so a closed town's `deny` is inherited by every district inside it. Anyone inside (a bypassing player who lost bypass, or someone who was there when it closed) is then stopped at every internal district border.
   - Writing an explicit `allow` on districts to stop that inheritance opens the closed town wherever a district touches its edge.
   - No single flag value per region reproduces the domain rule.
3. **Bypass** is `worldguard.region.bypass.<world>`, a Bukkit permission. `KnkPermissible` grants are not Bukkit permissions (no `PermissionAttachment` anywhere), so only ops would bypass unless a permission bridge is built.
4. **Future entry conditions** (title, rank, premium tier, clan, balance; vision §2.2) can't be expressed as a state flag. The navigation design already plans for them in the shared evaluator.

### B. In-house enforcement + a persistent local snapshot

Keep the KNG-55 tracker. Add:
- a snapshot file with every domain's `(wgRegionId → allowEntry, allowExit, type, parents)`, loaded in `onEnable` before the listener is registered;
- a full refresh at startup and periodically (for example every 5 min, with "last good" kept on failure);
- a change push from the web API;
- EMBARK and RESPAWN checks, plus message throttling.

Pros:
- Smallest change.
- Keeps the exact domain semantics.

Cons:
- We keep owning every movement edge case (new mounts, new teleport causes, Paper changes) forever.
- Push-back stays "cancel", not WorldGuard's last-valid-location.
- Two stores of region data (WorldGuard regions plus the snapshot) can drift.

### C. Hybrid (**recommended**): domain flags stored on the WorldGuard region, enforced by a custom WorldGuard session handler

1. **Data (local, persistent).**
   - Register two custom WorldGuard state flags in `onLoad`, for example `knk-allow-entry` and `knk-allow-exit` (`FlagRegistry.register`).
   - WorldGuard saves them with the regions (file or database), so they are there at startup, at joins and during outages.
   - The managed-region reconciler writes them as **ENFORCE** rules from the domain data:
     - at startup, on `/knk regions repair` and at region creation (all paths that exist today);
     - plus a refresh when a domain changes: a web-API → plugin push through the existing `RegionHttpServer`, and/or a periodic re-sync.
   - On API failure the last written values stay in force.
   - Needed: `ManagedRegionSpecSource` must learn AllowEntry/AllowExit. It doesn't today: `TownSummary`/`DistrictSummary`/`StructureSummary` lack them. Options: add them to the search DTOs in knk-web-api, or fetch them with `search-region-decisions` over the managed ids.
2. **Enforcement (WorldGuard machinery, our rules).**
   - Register a `Handler` with `SessionManager.registerHandler`.
   - Its `onCrossBoundary(player, from, to, toSet, entered, exited, moveType)` gets exactly the **entered** and **exited** regions. It refuses when an entered region has `knk-allow-entry deny` or an exited region has `knk-allow-exit deny`. That is the domain rule as it is today, with no priority or member semantics involved.
   - WorldGuard then applies the refusal for every move type (`MOVE`/`GLIDE`/`SWIM`/`RIDE`/`EMBARK`/`TELEPORT`/`RESPAWN`): push-back to the last valid location, vehicle handling, embark cancel.
   - Bypass stays ours (`knk.region.bypass` through `KnkPermissible`, plus ops). No permission bridge is needed.
3. **The KNG-55 tracker stops enforcing.** It keeps the enter/leave messages, gate control, district gate loading and `OnRegionEnterEvent`.
   - The join check, the teleport engine's up-front refusal and road navigation read the same flags through one evaluator (`DomainAccessEvaluator` on the road-navigation branch).
   - So every check agrees and none needs the API.
4. **Future entry conditions** fit into the same handler: it is our code, called by WorldGuard.

**Why C over A:** A gets offline safety but changes the rules (priority, member exemption, no bypass bridge, no future conditions). C gets offline safety and WorldGuard's movement coverage while the rules stay ours.

**Why C over B:** B needs a second persistent store and leaves us maintaining the movement edge cases. C stores the rule next to the region it belongs to and lets WorldGuard police movement.

**Risks of C to verify early:**
- **Unknown flags.** Custom flags must be registered before WorldGuard loads regions, so in `onLoad`. Check that WorldGuard keeps the unknown-flag values if knk-plugin is ever absent at load (WorldGuard 7 keeps unknown flags as raw values; confirm on the dev server).
- **Interaction with KNG-46** managed-region repair: the flag must be ENFORCE, and admin overrides need a decision.
- **Stale values during an outage:** a domain closed in the web app while the API is unreachable stays open until the next sync. That is acceptable, and the same holds for any cache.

### Interim mitigation (if C can't start soon)

The B-style snapshot alone (persist the resolver's cache, load it before the listener registers, refresh on start) closes the offline hole with a few files of change. It can be thrown away when C lands. It is only worth doing if C is more than a short wait away.

## 5. Players who keep pushing (W-spamming)

Since KNG-55, holding W gains nothing: every step is refused. Punishment is therefore about deterrence and visibility, not security. Recommended, inside the C handler (or the B listener):

1. **Throttle the deny message** to one every 2 s, as WorldGuard does.
2. **Push back, don't just cancel.** Put the player back at the last valid location (WorldGuard does this in C), optionally with a small velocity away from the border. That stops edge-hugging.
3. **Escalate by count**, all thresholds configurable:
   - more than about 10 refusals in 10 s → a short Slowness and a warning ("You may not enter X");
   - repeated windows → an alert to online staff plus an audit-log entry, spooled while the API is down, like the discovery and PM spools.
4. **No automatic kick or ban by default.** Lag, ice, water currents, mobs pushing, and navigation guidance near a border can all produce honest repeated refusals. Leave kicks to staff, or behind a config switch.

## 6. Decisions needed from the developer

1. **Which option:** C (recommended), B, or A. Also: the interim snapshot, yes or no.
2. **Member semantics:** should any domain role (owner, resident) be exempt from AllowEntry/AllowExit? Today nobody is, only `knk.region.bypass`.
3. **Change propagation:** a web-API push to the plugin (fast, needs knk-web-api work) or periodic plugin re-sync (simple, delayed), or both.
4. **Escalation thresholds** and whether a kick option should exist at all.

## 7. Suggested plan for C (once decided)

1. **Plugin:** register the custom flags in `onLoad`, and add a `KnkDomainAccessHandler` (WorldGuard session handler) with tests.
2. **Plugin:** reconciler rules writing the two flags (ENFORCE), and `ManagedRegionSpecSource` carrying AllowEntry/AllowExit.
3. **Web API:** expose AllowEntry/AllowExit in the region spec source (or reuse `search-region-decisions`), and add a domain-changed push.
4. **Plugin:** remove the tracker's enforcement paths. Point the join check, the teleport restriction and navigation at the flag-backed evaluator.
5. **Plugin:** add the escalation from §5.
6. **Live test on the dev server:**
   - API stopped before startup;
   - a player joining while it is down;
   - every move type from §1;
   - a bypass holder;
   - a rule change in the web app taking effect without a restart.
