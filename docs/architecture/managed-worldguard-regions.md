# Managed WorldGuard regions — hierarchy, priority, flags and startup repair

**Status:** Implemented, merged to trunk (2026-09-29, [knk-plugin#6](https://github.com/PandiO/knk-plugin/pull/6), [knk-web-api#3](https://github.com/PandiO/knk-web-api/pull/3); KNG-43 follow-up 2026-10-04) and **smoke-tested in game and accepted 2026-10-05** — Linear KNG-46, §9. Region-step re-run replacement (KNG-103) merged 2026-10-18 after its in-game check ([knk-plugin#12](https://github.com/PandiO/knk-plugin/pull/12), [knk-web-api#10](https://github.com/PandiO/knk-web-api/pull/10))
**Last updated:** 2026-10-21 (arena duels P1, KNG-210, on `claude/arena-duels`, not merged: arenas, battlegrounds and spectator areas are domains and managed by type, §3-§6; `BATTLEGROUND` no longer carries `entry deny`, §5; §8 items 3/7); 2026-10-18 (KNG-103 in-game check passed and merged; §7 recovering a domain the old bug left on a temp name, purge keeps what the last repair saw; §9 result); 2026-10-12 (§7 "Re-running a domain's region step" and `/knk regions temp`, KNG-103; §9 checklist, not yet run); 2026-10-06 (§5 "Rank-dependent access" links the domain entry/exit enforcement, KNG-55/KNG-56); 2026-10-05 (KNG-46 in-game smoke test passed; parent-inheritance decision accepted; vanilla spawn-protection note, §8 item 10)
**Supersedes:** Linear KNG-12 ("no WG flags on town/district regions"), the assumption noted in `CombatSafezone`'s Javadoc
**Evidence:** [`reports/2026-09-28-v1-permissions-worldguard-inventory.md`](../reports/2026-09-28-v1-permissions-worldguard-inventory.md) (categorized v1 inventory), the v3 domain model (`Town → District → Structure`, `GateStructure : Structure`), `vision.md` §2

## 1. What this is

One rule set decides what every Knights & Kings WorldGuard region looks like — its **parent**, **priority** and **category flags** — and is used by both:

- **creation:** when a world task's temporary region gets its final name (`domain_<id>`), and
- **repair:** every server start (and `/knk regions repair`), over all regions that back a v3 domain.

Both call the same `ManagedRegionReconciler` (`knk-core/.../core/regions/managed/`), so a new region and a repaired one cannot drift apart. The rules themselves are in `ManagedRegionPolicy`; nothing else in the code base carries a priority or category flag.

## 2. Important limit of the evidence

The v1 `regions.yml` was **not available** to this work — only the categorized inventory report (flags and counts per category, no per-region priority or parent). So:

- **Parent relationships** are derived from the v3 domain model (a District's parent is its Town's region, a Structure's is its District's) and from the inventory's statement that v1 child regions carry no flags and inherit from their base region.
- **Priorities** are *not* v1's numbers. They are computed from each region's actual place in the hierarchy (§4), which reproduces every ordering the inventory makes observable (e.g. a battleground's `pvp allow` beats a town's `pvp deny`). Any exact v1 number that turns out to matter is recorded per region in `regions.managed.overrides` (§7) — that is the intended escape hatch, not a code change.
- Do **not** read "10/20/30/…" as v1 values. They are a v3 scale with gaps.

## 3. v1 category → v3 entity mapping

| v1 category (inventory) | v3 entity | Managed kind | Decision |
|---|---|---|---|
| Town base (5) | `Town` | `TOWN` | Direct mapping. |
| Town children (68, no explicit flags) | `District` | `DISTRICT` | **Inferred:** unflagged children that inherit from a town = v3 districts. The domain model (`District.TownId`) is the authority for the parent. No flags of its own (inherits the Town's). |
| House base (29) / children (61) | `Structure` (House subtype, not yet in the API) | `HOUSE` | Children are v1 sub-regions of one house, not v3 domains — not modelled. **Opt-in per region** via `overrides.<region>.kind: house`, because the API has no structure subtype yet and `entry deny` on a region with no owners would lock everyone out. |
| Property base (36) / children (17) | `Structure` (Resource-Property subtype, `vision.md` §2.5) | `PROPERTY` | As House: opt-in via override. |
| `property_47` (wood-farm resource production) | a Resource-Property `Structure` | `RESOURCE_PRODUCTION` | Documented exception, §5. |
| Room base (22) / children (8) | none (v3 has no Room; v1 rooms were rentable units inside houses) | `ROOM` | Opt-in via override only. Sits above the structure tier. |
| Arena base `arena_2` (1) | `Arena : Structure` (KNG-210) | `ARENA` | A domain since arena duels P1 (DESIGN D12): the repair classifies it by type. `extra-regions` is only needed for an arena with no domain row. |
| Arena children `…-battleground` (8 flagged, 42 unflagged) | `ArenaBattleground : Domain` (the 8, KNG-210) | `BATTLEGROUND` (the 8) | Only the 8 flagged ones are battlegrounds; the other 42 are plain children (no flags) and need no management. Seeded with `POST api/Arenas/legacy-seed`; parent = the Arena's region. |
| — (no v1 region category) | `ArenaSpectatorArea : Domain` (KNG-210) | `SPECTATOR_AREA` | v3-only: where players watch duels; a plain child of its Arena, no flags. 0..n per arena. |
| — (no v1 region category) | `GateStructure` | `GATE` | **v3-only.** v1 handled gates by entity scan, not regions; v3 gate *doors* keep captured vertex JSON, not WG regions (item 6.2). The gate structure's own region is a normal Structure region: parent District, no flags. |
| Global `__global__` | — | `GLOBAL` | **Off by default** (`manage-global-region`): `build deny` changes what is buildable across the whole world. |
| Street | `Street` | — | No region (`vision.md` §2.4). |

Any other v3 `Structure` subtype (Shop, Warehouse, Keep, …) is `STRUCTURE`: hierarchy only, no flags.

## 4. Parent and priority

```
priority = max(kind floor, parent priority + 10)      (just the floor when there is no resolvable parent)
```

| Kind | Parent | Floor | Typical result |
|---|---|---|---|
| `TOWN` | none | 10 | 10 |
| `DISTRICT` | its Town's region | 20 | 20 |
| `STRUCTURE`, `HOUSE`, `PROPERTY`, `RESOURCE_PRODUCTION`, `GATE` | its District's region | 30 | 30 |
| `ROOM` | its House/Structure region | 40 | 40 |
| `ARENA` | its District's region (an `Arena` domain), or config-declared | 40 | 40 |
| `SPECTATOR_AREA` | its Arena | 40 | 50 |
| `BATTLEGROUND` | its Arena | 50 | 50 |

Priority therefore **depends on the region's chain, not only its category**: a Room under a House ranks above it; a House whose District is missing degrades to its floor; a deeper chain ranks above a shallower one. An override can pin any region's priority (and children then build on it).

### How overlapping regions resolve

WorldGuard picks a flag's value from the highest-priority region covering the spot that sets it; for a region that leaves the flag unset it walks the region's parent chain. So:

| Spot | Regions covering it | `pvp` | `entry` |
|---|---|---|---|
| Street in a district | Town, District | `deny` (District inherits the Town's) | unset |
| Inside a house (if opted in) | Town, District, House | `deny` (inherited) | `deny` (House) |
| Inside a gate structure | Town, District, Gate | `deny` (inherited) | unset |
| Inside an arena | Town, District, Arena | `deny` (Arena sets none) | `allow` |
| Inside a battleground | …, Arena, Battleground | **`allow`** (Battleground, priority 50) | `allow` (WG); entry is refused by `knk-allow-entry` (the battleground's `AllowEntry = false`) except for the duelists the duel runtime exempts (KNG-210, D16) |
| A Town with `pvp allow` set by an admin | Town | `allow` — the KNG-11 override is kept (§5) | unset |

This is exercised by `ManagedRegionReconcilerTest.overlappingRegionsResolveMostSpecificFirstAndInheritFromTheTown` with a WorldGuard-style resolver.

Setting a **parent** also makes the child inherit the parent's *owners and members* for build permission (WorldGuard semantics; v1 did the same). v3 does not own WG owners/members today, so nothing is set, but a v1-imported Town with owners will now extend build rights into its Districts. Check this on the dev server.

## 5. Flags per category, and exceptions

`SEED` = set only while the region doesn't carry the flag (an admin's deliberate value survives every restart). `ENFORCE` = the category is defined by it; a different value is corrected.

| Kind | Flags (mode) | Source / reason |
|---|---|---|
| `TOWN` | `damage-animals allow`, `entity-item-frame-destroy deny`, `mob-spawning deny`, `pvp deny`, `deny-message ""` (all SEED) | Shared base flags of all 5 v1 towns. `pvp` is SEED so `/rg flag <town> pvp allow` stays the working override that `CombatSafezone` (KNG-11) documents. |
| `DISTRICT`, `STRUCTURE`, `GATE` | none | Inherit through the parent link (v1 children had no flags). |
| `HOUSE`, `ROOM` | `entry deny`, `entry-deny-message ""`, `feed-amount 20`, `feed-delay 1` (SEED) | Shared base flags of v1 houses and rooms. |
| `PROPERTY` | `entry allow`, `entry-deny-message ""` (SEED) | Shared base flags of v1 properties. |
| `RESOURCE_PRODUCTION` | as `PROPERTY`; `block-break allow` **only** with `resource-production-block-break: true` | Exception, below. |
| `ARENA` | `entry allow`, `entry-deny-message ""` (SEED) | `arena_2` and every `Arena` domain. |
| `BATTLEGROUND` | `pvp allow`, `entry allow` (**ENFORCE**) | The `ArenaBattleground` domains (the 8 flagged v1 children). `pvp allow` makes them battlegrounds. Since KNG-210 there is no `entry deny`: see below. |
| `SPECTATOR_AREA` | none | Inherits through the Arena; normal town rules apply between spectators (arena duels DESIGN §9.3). |
| `GLOBAL` | `build deny`, `damage-animals allow`, `pvp allow`, `deny-message ""` — only if enabled | v1 `__global__`. |

**Exceptions and the decisions behind them**

- **Battleground PvP.** `pvp allow` is enforced and the priority floor (50) sits above every other category, so it beats the Town's `pvp deny`. The duel runtime still decides who may hit whom (arena duels DESIGN §8.1); `pvp allow` only takes WorldGuard's own PvP check out of the fighting pair's way.
- **Battleground entry (arena duels D16, KNG-210).** Battlegrounds are domains with `AllowEntry = false`, which the access sync writes as `knk-allow-entry deny` and the domain-access handler enforces on foot, by vehicle and by teleport ([`domain-access-enforcement.md`](domain-access-enforcement.md)). The duel runtime (P4) exempts the two duelists of a match through `DomainAccessExemptions`. WorldGuard's own `entry deny` would keep the duelists out too (only owners/members pass it), so the policy now **enforces `entry allow`**, which also corrects the v1 `entry deny` on the 8 battlegrounds at the next repair. Staff with `knk.region.bypass` can still walk in to watch. Seed the battleground domains before the repair runs with this policy (an `extra-regions` battleground with no domain row would be left open: it gets `entry allow` but no `knk-allow-entry deny`).
- **Wood farm (`property_47`).** v1 set `block-break allow` *and* the custom `allow-blocks: LOG;` (only logs breakable). WorldGuard has no `allow-blocks`, so `block-break allow` alone would let anyone break every block in the plot. Decision: `RESOURCE_PRODUCTION` does **not** get `block-break` unless the config opts in, and `allow-blocks` is never set (an override that names it is skipped with a warning, because WorldGuard doesn't know the flag). Enforcing "logs only" needs a v3 block-break listener — **unresolved**, §8. `property_45`/`_46` also had `block-break allow` with no `allow-blocks`; if they matter, add the flag through `overrides` after deciding it's intended.
- **Greeting/farewell text.** Not managed. v3 sends its own transition messages from domain data (`SimpleRegionTransitionService`); a WG greeting flag would duplicate it, and the per-town v1 texts aren't category data.
- **Rank-dependent access.** Not managed. The v1 `entry-deny-message` wording mentions ranks, but the flag alone doesn't prove WG enforced a rank check (the inventory says so). v3 gates entry through `Domain.AllowEntry`/`AllowExit` and title/premium checks in the plugin (since KNG-56 as the custom WorldGuard flags `knk-allow-entry`/`knk-allow-exit`, synced from the API and enforced by a WorldGuard session handler: [`domain-access-enforcement.md`](domain-access-enforcement.md)). `entry` on Towns is left unset (four v1 towns set `allow`, one none — equivalent to unset for non-members).
- **`deny-message ""`.** Applied to Towns only (shared there). For Properties (22 of 36), Rooms (17 of 22) and `house_9` it's per-instance, not category data, so it's not applied; use an override if wanted.
- **`__global__`** stays untouched unless explicitly enabled.

## 6. Startup repair

`ManagedRegionRepairService` (core) driven by `ManagedRegionsBootstrap` (paper), scheduled `delay-ticks` (default 100) after enable so WorldGuard has loaded its regions:

1. Read every Town, District and Structure from the API (paged, 1-based) plus the `domainType` per domain id (`/Domains/search`) to tell Gates and Arenas from plain Structures, and every Arena with its battlegrounds and spectator areas (`GET /api/Arenas`, KNG-210). If the Towns/Districts/Structures can't be read, **nothing is repaired** (a half-read hierarchy must not be applied); it retries `attempts` times, `retry-delay-seconds` apart. If the domain-type lookup alone fails, Structures are treated as plain `STRUCTURE`s and a warning is logged; if the arenas alone can't be read, battlegrounds and spectator areas are left as they are and a warning is logged.
2. On the main thread: only regions named by a domain's `wgRegionId` (plus `extra-regions`) are looked at. Each is compared with its desired state; only priority, parent and the policy's flags are ever written. Owners, members, other flags and unrelated regions are never touched; no region is created or deleted.
3. Changes are applied per region atomically (a failure restores what that region had) and saved once at the end (`RegionManager.saveChanges`).
4. One log line: `[KnK Regions] Managed-region repair: checked=N changed=N skipped=N failed=N unchanged=N [save=FAILED]`, then a `WARNING` per failed region and up to 10 warnings. Per-region detail is at `FINE`.

Outcome rules: **checked** = distinct regions considered; **skipped** = domain without a region id, region not in WorldGuard (stale domain record — never recreated), or one region claimed by two domains with different kind/parent (ambiguous — left alone); **failed** = read/apply error for that region; **unchanged** = already correct. A missing parent keeps the current parent (never cleared) and the region falls back to its floor priority; a parent cycle is cut with a warning. Running again on the result changes nothing (`aSecondRunChangesNothingAndDoesNotSave`).

`/knk regions repair` (permission `knk.admin.regions`, child of `knk.admin`) runs the same pass on demand — needed after creating a Town or Structure in the web app (§8).

## 7. Creation path and config

`POST /Regions/rename` (API → plugin) now accepts optional `domainType` and `parentRegionId`. Every domain service — `TownService`, `DistrictService`, `StructureService`, `GateStructureService`, `DomainService` — calls the shared `IDomainRegionNameFinalizer` after create/update (KNG-43): a region still named `tempregion_worldtask_<n>` becomes `domain_<id>`, with the concrete type and the parent's region (District → its Town, Structure/Gate → its District). A failed rename never fails the save; the region keeps its temp name. Since KNG-210 the types also include `Arena` (parent: its District), `ArenaBattleground` and `ArenaSpectatorArea` (parent: their Arena), mapped to `ARENA`, `BATTLEGROUND` and `SPECTATOR_AREA`. The plugin renames the temp region — **copying owners and members**, and (KNG-43) keeping the region's own parent and re-linking regions whose parent it was — then runs `reconcileOne` for the new name. Without a type the rename behaves as before and the next repair sets the region up.

### Re-running a domain's region step (KNG-103)

Before KNG-103 the rename refused whenever `domain_<id>` existed, so re-running the **Region and Location** step of an existing domain left the domain on `tempregion_worldtask_<n>` and its old `domain_<id>` behind as an orphan (seen on District 17, world task 227, 2026-10-09). Now:

- **The API decides which region is replaced.** Each domain service's `UpdateAsync` passes the domain's `WgRegionId` from before the save to `IDomainRegionNameFinalizer.FinalizeAsync(domain, previousRegionId)`. The finalizer names it as `replaceRegionId` on `POST /Regions/rename` only when it is the domain's own: its final name `domain_<id>` or a temp-named region, and no other domain in the same world (KNG-111) uses it. Any other previous region (a v1 region picked with "select") is kept.
- **The plugin checks and applies it in one world** (`RegionRenamePlan` in `knk-core` decides, `WorldGuardRegionRenamer` in `knk-paper` applies):
  - `replaceRegionId` = the final name → **redefined in place**: the new shape, with the old `domain_<id>`'s priority, parent, owners, members and flags (an admin's `pvp allow`, the synced `knk-allow-entry`/`knk-allow-exit`); the drawn region's own flags and owners only fill gaps. Child regions (a District's Structures) are re-linked to it.
  - a temp-named region → renamed, then that region is removed.
  - anything else → never removed. An existing target the API did not name is still refused (the v2 name collision in §8 item 9 keeps behaving as before).
  - A failure part-way puts every region back.
  Then `reconcileOne` and the access-flag sync run as for any finalized region. The name stays `domain_<id>`, so nothing that cached it goes stale.
- **Order and partial failure:** the plugin renames/replaces first (one main-thread step, rolled back on error), then the API stores `domain_<id>`. Until then the database names the temp region, which still exists if the plugin refused. If storing fails after the plugin renamed, the API renames the region back to the temp name the database still holds; only if that also fails does it log that `WgRegionId` must be fixed by hand. Residual case: if the API's call to the plugin times out after the plugin did the rename, the API keeps the temp name while WorldGuard has `domain_<id>`; `finalize-temp-names` then lists the domain as failed and `/rg info domain_<id>` shows the region is there: set `WgRegionId` to `domain_<id>`.
- A plugin from before KNG-103 ignores `replaceRegionId` and refuses as before.

**Leftover temp regions.** `/knk regions temp` (permission `knk.admin.regions`) reports every `tempregion_worldtask_*` region with the daily cleanup's policy (§8 item 5): unused and old enough, used by a domain (rename those with `finalize-temp-names`), too recent, without a creation time (never deleted), or not checked because the API could not be asked. It also lists `domain_<id>` regions that no domain uses (report only, never deleted: see §8 item 9). `/knk regions temp purge [hours]` deletes the unused temp regions older than `hours` (default 24, at least 1, so a region step that is still in progress is safe); regions without a creation time are kept. Chosen over a one-off report because the dev server already has dozens and every re-run before this fix left one more. Limit: the domain lookup by region (`GET /Domains/by-region/{id}`) is not world-qualified yet, so a region id that a domain uses in another world counts as in use.

**What the purge keeps.** Besides regions without a creation time, the purge skips every region the last managed-region repair (startup or `/knk regions repair`) saw a domain use, without asking the API. After a domain moves to a new region that record is stale until the next repair: run `/knk regions repair` first, then `/knk regions temp purge`.

**A domain the old bug left on a temp name** (before KNG-103: its `WgRegionId` is `tempregion_worldtask_<n>` and the old `domain_<id>` is still in the world, listed under "domain_<id> regions no domain uses"). The fix doesn't heal this on its own: the API names the temp region as the one being replaced, so the plugin still refuses to overwrite a `domain_<id>` it wasn't told about (§8 item 9). Check `/rg info domain_<id>` is the domain's old shape, `/rg remove domain_<id>`, then save the domain again or run `POST /api/Regions/finalize-temp-names`. If the temp region the domain names no longer exists, re-run its region step instead. Seen on District 15 (2026-10-11 alpha smoke test, step 10; cleaned up 2026-10-18).

**The repair never renames.** `/knk regions repair` only fixes parent, priority and flags. Domains that still have a temp name (created before KNG-43, or renamed while the server was down) are renamed by `POST /api/Regions/finalize-temp-names` (plugin key or `knk.admin.regions`; needs the server running; parents first; returns found/renamed/failed; safe to repeat).

`config.yml`, `regions.managed`: `startup-repair.{enabled,delay-ticks,attempts,retry-delay-seconds,page-size}`, `resource-production-block-break`, `manage-global-region`, `overrides.<regionId>.{kind,priority,parent,flags}`, `extra-regions[].{region,kind,parent}`. Bad entries are logged and ignored, never fatal. The override mechanism is how a House/Property/Room/`property_47` counterpart is identified until `Structure` gets subtypes, and where any exact v1 priority is recorded.

## 8. Unresolved v1 → v3 differences and observed hazards

1. **No House/Property/Room subtype in the API**, so those kinds are opt-in per region (overrides). A `StructureType` on `Structure` would let the repair apply them automatically — needs a migration and design decision (`vision.md` §2.5 already decides on subclasses). Linear KNG-47.
2. **`allow-blocks` / wood farm**: needs a v3 listener to restrict block breaking in `RESOURCE_PRODUCTION` regions to logs; until then `block-break` is not opened up. Linear KNG-48.
3. **Exact v1 priorities** unknown (§2). Supply `regions.yml` to compare, or set overrides. Linear KNG-49. Its Arena/Battleground entity question is settled by arena duels DESIGN D12 (KNG-210).
4. ~~Town/Structure creation don't finalize temp region names~~ — fixed by KNG-43 (§7); existing temp-named domains need one `finalize-temp-names` call.
5. **`TempRegionRetentionTask`** (14 days after creation, `knk-creation-timestamp` flag) deletes a temp-named region only when (a) the last repair didn't see a domain use it (and the repair has run at all), (b) it has a valid timestamp older than the cutoff, and (c) a fresh `GET /Domains/by-region/{id}` right before the delete returns 404. An API error keeps the region. Policy: `knk-core` `TempRegionCleanupPolicy` (KNG-43; before, only (a) existed, so a domain created after the last repair was not protected).
6. **Entry gating by rank** and **greetings** remain v3-plugin behaviour, not WG flags (§5).
7. ~~Arena/battleground regions have no domain entity~~ — since KNG-210 (arena duels P1, on `claude/arena-duels`, not merged) `Arena`, `ArenaBattleground` and `ArenaSpectatorArea` are domains, managed by type; the `extra-regions` entries for `arena_2` are no longer needed once it is seeded (`POST api/Arenas/legacy-seed` with the 8 battleground region ids from `/rg list`). The inventory report counts the 8 flagged battlegrounds but doesn't list their ids; v1 named them `arena_2,<part>-battleground` (legacy `commands-v1.md`).
8. `WorldGuardManagementCommand` (`/knk wgm rename`) is not registered anywhere (dead code) — left as is.
9. **Legacy regions can already hold a `domain_<id>` name.** v2 used the same `domain_<n>` scheme, and imported v2 regions keep their names, so a new domain's final name can collide with an orphaned v2 region. The plugin then refuses the rename (`target region name already exists: domain_<id>` in the server log), the domain keeps its temp-named region, and `finalize-temp-names` lists it under `failed`. Seen live on 2026-10-04 for GateStructure 11 (an orphaned v2 `domain_11`): removing the orphan and calling the endpoint again fixed it. Check `/rg info domain_<id>` before deleting: if it is the domain's own region, only the `WgRegionId` in the database is stale.
10. **Vanilla spawn protection overrides WorldGuard.** `server.properties` → `spawn-protection` (default 16 blocks around the world spawn) stops every non-operator from placing, breaking and interacting with blocks there, whatever the WG flags say; operators bypass it, so testing as an op hides it. FAWE warns about this on `/rg info` (seen 2026-10-05 for `domain_11`, the Keep Gate in `town_1`). Plugin-driven block changes (gate animation, repair) are not affected — only players. Risk: non-op players can't use doors, buttons, chests or the gate area in that radius, which would break siege play and town builds near spawn. Fix is server config, not code: set `spawn-protection=0` and let WorldGuard protect spawn (the town region already denies building to non-members). Not changed in any repo — the server's `server.properties` is outside version control.

## 9. Verification status and in-game smoke test

Automated: `knk-core` tests for the policy, planner/reconciler (hierarchy, overlap resolution, flags and exceptions, creation-vs-repair equality, idempotence, preservation of unrelated regions/owners/members/greetings, stale/missing/ambiguous/cyclic data, apply and save failures), spec building, paging and the repair service, and config parsing. The WorldGuard adapter, the Paper wiring and the C# API changes have since been compiled and tested (2026-10-04: `./gradlew build -x deployToDevServer` green; `dotnet test` 1622 pass, 4 unrelated pre-existing failures) and exercised on the dev server (below).

KNG-43 live run (2026-10-04, dev server): `POST /api/Regions/finalize-temp-names` found 2 temp-named domains; one renamed, GateStructure 11 failed on the v2 name collision in §8 item 9, then renamed after the orphan was removed. Accepted by the developer.

**KNG-46 in-game smoke test (2026-10-05, dev server) — passed, accepted by the developer.** Startup logged `Managed-region repair: checked=8 changed=0 skipped=0 failed=0 unchanged=8`; districts parented to their town with priorities 10/20/30, `domain_11` (Keep Gate) under `district_1000006` under `town_1` with priority 30; town flags correct and an admin `pvp allow` survived restarts; later restarts `changed=0`; owners/members, greetings and manual regions untouched; vanilla PvP blocked in town/district and allowed with `pvp allow`; KNG-11 safezone enchant gate unchanged; creating a District and another domain type in the web app renamed the region at once; API-down boot retried then skipped, and `/knk regions repair` worked once the API was back; temp-region cleanup accepted; orphaned v2 `domain_<n>` regions checked. Not separately checked, accepted: owners/members carried over by a creation rename, a failed creation rename being recoverable via `finalize-temp-names`, and the optional `extra-regions` arena/battleground. **Decision (2026-10-05):** a Town's WG owners/members inheriting build rights in its Districts through the parent link is accepted for imported v1 towns. Found: the vanilla spawn-protection overlap, §8 item 10.

**KNG-103 in-game check (passed 2026-10-18, developer, dev server; merged).** Back up `plugins/WorldGuard/worlds/*/regions.yml`, deploy both branches, then:

1. Create a District in the web app through the FormWizard. `/rg list` shows `domain_<id>`; the domain's `WgRegionId` (web app or `GET /api/Districts/<id>`) is `domain_<id>`; `/rg info domain_<id>`: parent = the Town's region, priority 20.
2. Set something by hand on it: `/rg flag domain_<id> greeting Hello` and `/rg addmember domain_<id> <player>`. If the district has a Structure, note that its region's parent is `domain_<id>`.
3. Re-run its **Region and Location** step and draw a visibly different shape. The server log shows `Successfully renamed region from tempregion_worldtask_<n> to domain_<id> …: replaced the previous domain_<id> in place`.
4. `/rg list`: one `domain_<id>`, no `tempregion_worldtask_<n>`. `/rg info domain_<id>`: the new shape (`//sel` + `/rg select domain_<id>`), still parent = Town and priority 20, the greeting and member from step 2 still there, a Structure's region still has it as parent. `WgRegionId` is still `domain_<id>`. Walking in/out of the new area shows the district's enter/leave messages.
5. Re-run the step a second time: same results as step 4.
6. `/knk regions temp`: the regions just drawn are not listed; nothing new under "domain_<id> regions no domain uses". Then `/knk regions temp purge` and `/rg list | tempregion` (or the report again): the old leftovers that no domain uses are gone; any listed under "used by a domain" are fixed with `POST /api/Regions/finalize-temp-names`.
7. Optional: a domain whose region was chosen with `select` (a hand-made region, not `domain_…`/`tempregion_…`) keeps that region when its step is re-run with a new drawing: the new region becomes `domain_<id>` and the log says the previous region "is kept".

Result 2026-10-18: run on District 15 (no Structure) instead of a new district, through the District's edit form ("Replace via Minecraft" on the region field, complete the task, then save the form; the rename runs on save). District 15 first had to be cleaned up as described in §7 ("A domain the old bug left on a temp name"): it was on `tempregion_worldtask_228` with an orphaned `domain_15`, the first save was refused as designed, and its new temp region `tempregion_worldtask_296` was gone from WorldGuard (cause not found). After `/rg remove domain_15` and a new drawing the plugin logged `Successfully renamed region from tempregion_worldtask_298 to domain_15 in world_KNK-DEV: previous region domain_15 no longer exists`. Steps 2-6 then passed (replace in place keeps shape change, parent, priority, greeting and member; second re-run the same; `/knk regions temp` clean). Step 7 not run. Leftover found: `knk_hub/domain_28` (no domain uses it; not touched).

In-game checklist used (dev server, back up `plugins/WorldGuard/worlds/*/regions.yml` first):

1. Start the server: one `[KnK Regions] Managed-region repair: …` line; districts show the town as parent (`/rg info <district>`), priorities 10/20/30.
2. `/rg info <town>`: `pvp deny`, `mob-spawning deny`, … set; an existing `pvp allow` on a town is still there after a restart.
3. Restart twice: second/third summary reads `changed=0`.
4. A town owner/member, a house owner and a manually made region keep their owners/members and flags.
5. Walk from a district into a battleground/arena (via `extra-regions`) and check PvP flips on/off; check combat-enchant safezone (KNG-11) still behaves.
6. Create a District in the web app: the region ends up `domain_<id>` with parent, priority and inherited flags without a restart; owners/members on the temp region survive the rename.
7. Stop the API and start the server: repair retries, then logs "skipped … No region was changed"; `/knk regions repair` works once the API is back.
8. Confirm that giving a Town's owners build rights inside its Districts (parent inheritance) is acceptable for imported v1 towns.
