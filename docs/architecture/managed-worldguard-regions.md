# Managed WorldGuard regions — hierarchy, priority, flags and startup repair

**Status:** Implemented and merged to trunk 2026-09-29 ([knk-plugin#6](https://github.com/PandiO/knk-plugin/pull/6), [knk-web-api#3](https://github.com/PandiO/knk-web-api/pull/3)); CI green, **not yet smoke-tested in game** — Linear KNG-46, §9
**Last updated:** 2026-10-04 (KNG-43 merged: rename on submit for every domain type, `finalize-temp-names`, fresh-lookup temp-region cleanup — knk-plugin `3ac34db`, knk-web-api `14b3b8b`; accepted after a live run)
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
| Arena base `arena_2` (1) | none | `ARENA` | No v3 entity. Managed only if listed in `regions.managed.extra-regions`. |
| Arena children `…-battleground` (8 flagged, 42 unflagged) | none | `BATTLEGROUND` (the 8) | Only the 8 flagged ones are battlegrounds; the other 42 are plain children (no flags) and need no management. Via `extra-regions`. |
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
| `ARENA` | config-declared (a District/Town) | 40 | 40 |
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
| Inside a battleground | …, Arena, Battleground | **`allow`** (Battleground, priority 50) | `deny` |
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
| `ARENA` | `entry allow`, `entry-deny-message ""` (SEED) | `arena_2`. |
| `BATTLEGROUND` | `entry deny`, `pvp allow` (**ENFORCE**) | The 8 flagged battleground children; this is what makes them battlegrounds. |
| `GLOBAL` | `build deny`, `damage-animals allow`, `pvp allow`, `deny-message ""` — only if enabled | v1 `__global__`. |

**Exceptions and the decisions behind them**

- **Battleground PvP.** `pvp allow` + `entry deny` are enforced and the priority floor (50) sits above every other category, so it beats the Town's `pvp deny`.
- **Wood farm (`property_47`).** v1 set `block-break allow` *and* the custom `allow-blocks: LOG;` (only logs breakable). WorldGuard has no `allow-blocks`, so `block-break allow` alone would let anyone break every block in the plot. Decision: `RESOURCE_PRODUCTION` does **not** get `block-break` unless the config opts in, and `allow-blocks` is never set (an override that names it is skipped with a warning, because WorldGuard doesn't know the flag). Enforcing "logs only" needs a v3 block-break listener — **unresolved**, §8. `property_45`/`_46` also had `block-break allow` with no `allow-blocks`; if they matter, add the flag through `overrides` after deciding it's intended.
- **Greeting/farewell text.** Not managed. v3 sends its own transition messages from domain data (`SimpleRegionTransitionService`); a WG greeting flag would duplicate it, and the per-town v1 texts aren't category data.
- **Rank-dependent access.** Not managed. The v1 `entry-deny-message` wording mentions ranks, but the flag alone doesn't prove WG enforced a rank check (the inventory says so). v3 gates entry through `Domain.AllowEntry`/`AllowExit` and title/premium checks in the plugin. `entry` on Towns is left unset (four v1 towns set `allow`, one none — equivalent to unset for non-members).
- **`deny-message ""`.** Applied to Towns only (shared there). For Properties (22 of 36), Rooms (17 of 22) and `house_9` it's per-instance, not category data, so it's not applied; use an override if wanted.
- **`__global__`** stays untouched unless explicitly enabled.

## 6. Startup repair

`ManagedRegionRepairService` (core) driven by `ManagedRegionsBootstrap` (paper), scheduled `delay-ticks` (default 100) after enable so WorldGuard has loaded its regions:

1. Read every Town, District and Structure from the API (paged, 1-based) plus the `domainType` per domain id (`/Domains/search`) to tell Gates from plain Structures. If the Towns/Districts/Structures can't be read, **nothing is repaired** (a half-read hierarchy must not be applied); it retries `attempts` times, `retry-delay-seconds` apart. If the domain-type lookup alone fails, Structures are treated as plain `STRUCTURE`s and a warning is logged.
2. On the main thread: only regions named by a domain's `wgRegionId` (plus `extra-regions`) are looked at. Each is compared with its desired state; only priority, parent and the policy's flags are ever written. Owners, members, other flags and unrelated regions are never touched; no region is created or deleted.
3. Changes are applied per region atomically (a failure restores what that region had) and saved once at the end (`RegionManager.saveChanges`).
4. One log line: `[KnK Regions] Managed-region repair: checked=N changed=N skipped=N failed=N unchanged=N [save=FAILED]`, then a `WARNING` per failed region and up to 10 warnings. Per-region detail is at `FINE`.

Outcome rules: **checked** = distinct regions considered; **skipped** = domain without a region id, region not in WorldGuard (stale domain record — never recreated), or one region claimed by two domains with different kind/parent (ambiguous — left alone); **failed** = read/apply error for that region; **unchanged** = already correct. A missing parent keeps the current parent (never cleared) and the region falls back to its floor priority; a parent cycle is cut with a warning. Running again on the result changes nothing (`aSecondRunChangesNothingAndDoesNotSave`).

`/knk regions repair` (permission `knk.admin.regions`, child of `knk.admin`) runs the same pass on demand — needed after creating a Town or Structure in the web app (§8).

## 7. Creation path and config

`POST /Regions/rename` (API → plugin) now accepts optional `domainType` and `parentRegionId`. Every domain service — `TownService`, `DistrictService`, `StructureService`, `GateStructureService`, `DomainService` — calls the shared `IDomainRegionNameFinalizer` after create/update (KNG-43): a region still named `tempregion_worldtask_<n>` becomes `domain_<id>`, with the concrete type and the parent's region (District → its Town, Structure/Gate → its District). A failed rename never fails the save; the region keeps its temp name. The plugin renames the temp region — **copying owners and members**, and (KNG-43) keeping the region's own parent and re-linking regions whose parent it was — then runs `reconcileOne` for the new name. Without a type the rename behaves as before and the next repair sets the region up.

**The repair never renames.** `/knk regions repair` only fixes parent, priority and flags. Domains that still have a temp name (created before KNG-43, or renamed while the server was down) are renamed by `POST /api/Regions/finalize-temp-names` (plugin key or `knk.admin.regions`; needs the server running; parents first; returns found/renamed/failed; safe to repeat).

`config.yml`, `regions.managed`: `startup-repair.{enabled,delay-ticks,attempts,retry-delay-seconds,page-size}`, `resource-production-block-break`, `manage-global-region`, `overrides.<regionId>.{kind,priority,parent,flags}`, `extra-regions[].{region,kind,parent}`. Bad entries are logged and ignored, never fatal. The override mechanism is how a House/Property/Room/`property_47` counterpart is identified until `Structure` gets subtypes, and where any exact v1 priority is recorded.

## 8. Unresolved v1 → v3 differences and observed hazards

1. **No House/Property/Room subtype in the API**, so those kinds are opt-in per region (overrides). A `StructureType` on `Structure` would let the repair apply them automatically — needs a migration and design decision (`vision.md` §2.5 already decides on subclasses). Linear KNG-47.
2. **`allow-blocks` / wood farm**: needs a v3 listener to restrict block breaking in `RESOURCE_PRODUCTION` regions to logs; until then `block-break` is not opened up. Linear KNG-48.
3. **Exact v1 priorities** unknown (§2). Supply `regions.yml` to compare, or set overrides. Linear KNG-49 (also the Arena/Battleground entity decision).
4. ~~Town/Structure creation don't finalize temp region names~~ — fixed by KNG-43 (§7); existing temp-named domains need one `finalize-temp-names` call.
5. **`TempRegionRetentionTask`** (14 days after creation, `knk-creation-timestamp` flag) deletes a temp-named region only when (a) the last repair didn't see a domain use it (and the repair has run at all), (b) it has a valid timestamp older than the cutoff, and (c) a fresh `GET /Domains/by-region/{id}` right before the delete returns 404. An API error keeps the region. Policy: `knk-core` `TempRegionCleanupPolicy` (KNG-43; before, only (a) existed, so a domain created after the last repair was not protected).
6. **Entry gating by rank** and **greetings** remain v3-plugin behaviour, not WG flags (§5).
7. **Arena/battleground regions** have no domain entity; they are managed only through `extra-regions`.
8. `WorldGuardManagementCommand` (`/knk wgm rename`) is not registered anywhere (dead code) — left as is.
9. **Legacy regions can already hold a `domain_<id>` name.** v2 used the same `domain_<n>` scheme, and imported v2 regions keep their names, so a new domain's final name can collide with an orphaned v2 region. The plugin then refuses the rename (`target region name already exists: domain_<id>` in the server log), the domain keeps its temp-named region, and `finalize-temp-names` lists it under `failed`. Seen live on 2026-10-04 for GateStructure 11 (an orphaned v2 `domain_11`): removing the orphan and calling the endpoint again fixed it. Check `/rg info domain_<id>` before deleting: if it is the domain's own region, only the `WgRegionId` in the database is stale.

## 9. Verification status and in-game smoke test

Automated: `knk-core` tests for the policy, planner/reconciler (hierarchy, overlap resolution, flags and exceptions, creation-vs-repair equality, idempotence, preservation of unrelated regions/owners/members/greetings, stale/missing/ambiguous/cyclic data, apply and save failures), spec building, paging and the repair service, and config parsing. **The WorldGuard adapter and the Paper wiring (`WorldGuardManagedRegionStore`, `ManagedRegionsBootstrap`, `RegionsAdminCommand`, the rename hook) and the C# API changes could not be compiled or run in the cloud session** (Paper/EngineHub Maven repos and `dotnet` unavailable) — they need a local `./gradlew build` / `dotnet test`.

KNG-43 live run (2026-10-04, dev server): `POST /api/Regions/finalize-temp-names` found 2 temp-named domains; one renamed, GateStructure 11 failed on the v2 name collision in §8 item 9, then renamed after the orphan was removed. Accepted by the developer.

In-game checklist (dev server, back up `plugins/WorldGuard/worlds/*/regions.yml` first):

1. Start the server: one `[KnK Regions] Managed-region repair: …` line; districts show the town as parent (`/rg info <district>`), priorities 10/20/30.
2. `/rg info <town>`: `pvp deny`, `mob-spawning deny`, … set; an existing `pvp allow` on a town is still there after a restart.
3. Restart twice: second/third summary reads `changed=0`.
4. A town owner/member, a house owner and a manually made region keep their owners/members and flags.
5. Walk from a district into a battleground/arena (via `extra-regions`) and check PvP flips on/off; check combat-enchant safezone (KNG-11) still behaves.
6. Create a District in the web app: the region ends up `domain_<id>` with parent, priority and inherited flags without a restart; owners/members on the temp region survive the rename.
7. Stop the API and start the server: repair retries, then logs "skipped … No region was changed"; `/knk regions repair` works once the API is back.
8. Confirm that giving a Town's owners build rights inside its Districts (parent inheritance) is acceptable for imported v1 towns.
