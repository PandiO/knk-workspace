# Managed WorldGuard regions — hierarchy, priority, flags and startup repair

**Status:** Current · **Last updated:** 2026-11-22 (§3–§5 `LANDMARK` kind, §7 "Landmarks" rewritten: landmarks are domains, PandiO/knk-workspace#976, docs #1008); 2026-11-22 (§7: a row a failed re-run left on a temp name heals on a retry, except `domain_<id>`, PandiO/knk-workspace#952); 2026-11-22 (§7 "Siege weapon spots": a fourth drawn-region owner, `siege_spot_<id>`, the API's release check, the plugin's cleanup gap, PandiO/knk-workspace#988 in `next`, docs #999); 2026-11-21 (§7 "Landmarks" and "Production areas": drawn regions renamed to `landmark_<id>` / `production_area_<id>` through one owner path, region task found by task type, PandiO/knk-workspace#944/#945/#946; knk-web-api and knk-web-app in `next`, knk-plugin#115 open); 2026-11-20 (§7 overview map outlines on trunk, docs #767); 2026-11-19 (§3, §4, §5, §6, §7: production P2c region kinds `ProductionStructure` → `RESOURCE_PRODUCTION`, `Warehouse` → `STRUCTURE`, rural structures without a parent, with `production.enabled`; knk-plugin `next` `8ebb30be`, PandiO/knk-workspace#677, docs #830); 2026-11-19 (§7 "Domain sub-regions", "Overview map outlines": sub-region outlines reported after every access sync with `map.reporting.enabled`, PandiO/knk-workspace#750, branch `claude/overview-map-f1-subregions`); 2026-11-19 (§3, §4, §5: kind `CROWN_LAND` for crown land of territory V1, knk-plugin `next` `55804b11`, PandiO/knk-workspace#689, docs #806); 2026-11-18 (§7 "Overview map outlines": the repair and rename also report outlines with `map.reporting.enabled`, PandiO/knk-workspace#735, docs #766)
**Implementation:** Implemented, merged to trunk (2026-09-29, [knk-plugin#6](https://github.com/PandiO/knk-plugin/pull/6), [knk-web-api#3](https://github.com/PandiO/knk-web-api/pull/3); KNG-43 follow-up 2026-10-04) and **smoke-tested in game and accepted 2026-10-05** — Linear KNG-46, §9. Region-step re-run replacement (KNG-103) merged 2026-10-18 after its in-game check ([knk-plugin#12](https://github.com/PandiO/knk-plugin/pull/12), [knk-web-api#10](https://github.com/PandiO/knk-web-api/pull/10)). Lootbox spawn areas' drawn regions renamed to `lootbox_area_<id>` (PandiO/knk-workspace#34, §7): **in the PR into `next` from `claude/plugin-chains-into-next`, not merged, not live-tested**. Temp regions of abandoned drafts removed early (PandiO/knk-workspace#269, §7 "Abandoned drafts"): **in the PR into `next` from `claude/plugin-chains-into-next`, not merged, not live-tested**
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
| — | `ProductionStructure` (production P2, #91/#677) | `RESOURCE_PRODUCTION` | The v3 Resource-Property. Mapped only while `production.enabled` is on (`ManagedRegionKind.fromDomainType(type, production)`); with it off it stays `STRUCTURE`, because the kind seeds `entry` flags. In a district: parent its District; **rural** (a town, no district): no parent (§4). See [production world § 6](production-world.md#6-game-server-region-kinds-and-rural-regions). |
| — | `Warehouse` (production P2) | `STRUCTURE` | Hierarchy only, no flags; rural warehouses have no parent either (with `production.enabled`). |
| Room base (22) / children (8) | none (v3 has no Room; v1 rooms were rentable units inside houses) | `ROOM` | Opt-in via override only. Sits above the structure tier. |
| Arena base `arena_2` (1) | none | `ARENA` | No v3 entity. Managed only if listed in `regions.managed.extra-regions`. |
| Arena children `…-battleground` (8 flagged, 42 unflagged) | none | `BATTLEGROUND` (the 8) | Only the 8 flagged ones are battlegrounds; the other 42 are plain children (no flags) and need no management. Via `extra-regions`. |
| — (no v1 region category) | `GateStructure` | `GATE` | **v3-only.** v1 handled gates by entity scan, not regions; v3 gate *doors* keep captured vertex JSON, not WG regions (item 6.2). The gate structure's own region is a normal Structure region: parent District, no flags. |
| — (no v1 region category) | `CrownLand` (territory V1, #326/#689) | `CROWN_LAND` | **v3-only.** A kingdom-held domain region territory is measured from ([territory § 5.5](territory.md#55-players-and-other-features)). No parent, no flags of its own. The repair takes crown land regions from the domain catalogue only while `production.enabled` is on. |
| — (no v1 region category) | `Landmark` (#976) | `LANDMARK` | **v3-only.** A landmark's own region (Area `OwnRegion`): parent = its parent domain's main region, no flags of its own (§ 7 "Landmarks"). Point and linked-area landmarks own no region. |
| Global `__global__` | — | `GLOBAL` | **Off by default** (`manage-global-region`): `build deny` changes what is buildable across the whole world. |
| Street | `Street` | — | No region (`vision.md` §2.4). |

Any other v3 `Structure` subtype (Shop, Keep, …) is `STRUCTURE`: hierarchy only, no flags.

## 4. Parent and priority

```
priority = max(kind floor, parent priority + 10)      (just the floor when there is no resolvable parent)
```

| Kind | Parent | Floor | Typical result |
|---|---|---|---|
| `TOWN` | none | 10 | 10 |
| `CROWN_LAND` | none | 10 | 10 |
| `DISTRICT` | its Town's region | 20 | 20 |
| `STRUCTURE`, `HOUSE`, `PROPERTY`, `RESOURCE_PRODUCTION`, `GATE` | its District's region | 30 | 30 |
| `LANDMARK` | its parent domain's main region (any domain type; none for a top-level landmark) | 30 | parent + 10, at least 30 |
| `ROOM` | its House/Structure region | 40 | 40 |
| `ARENA` | config-declared (a District/Town) | 40 | 40 |
| `BATTLEGROUND` | its Arena | 50 | 50 |

**Rural structures** (production P2, a `TownId` and no district; with `production.enabled` on): no parent on purpose,
the kind's floor (30), in their town's world, and no "unknown district" warning. So PvP stays allowed around them (the
world default) and no town flags are inherited (production DESIGN § 3.4, confirmed 2026-11-11). A structure moved from
a district to rural keeps its old parent, because the repair never clears one (§6): clear it with `/rg setparent
<region>` ([#824](https://github.com/PandiO/knk-workspace/issues/824)). With `production.enabled` off a rural structure
gets the old warning "its District (id null) is unknown or has no region; no parent set" and its floor.

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
| `DISTRICT`, `STRUCTURE`, `GATE`, `CROWN_LAND`, `LANDMARK` | none | Inherit through the parent link (v1 children had no flags). |
| `HOUSE`, `ROOM` | `entry deny`, `entry-deny-message ""`, `feed-amount 20`, `feed-delay 1` (SEED) | Shared base flags of v1 houses and rooms. |
| `PROPERTY` | `entry allow`, `entry-deny-message ""` (SEED) | Shared base flags of v1 properties. |
| `RESOURCE_PRODUCTION` | as `PROPERTY`; `block-break allow` **only** with `resource-production-block-break: true` | Exception, below. Since P2c (#677) also every `ProductionStructure` region while `production.enabled` is on. |
| `ARENA` | `entry allow`, `entry-deny-message ""` (SEED) | `arena_2`. |
| `BATTLEGROUND` | `entry deny`, `pvp allow` (**ENFORCE**) | The 8 flagged battleground children; this is what makes them battlegrounds. |
| `GLOBAL` | `build deny`, `damage-animals allow`, `pvp allow`, `deny-message ""` — only if enabled | v1 `__global__`. |

**Exceptions and the decisions behind them**

- **Battleground PvP.** `pvp allow` + `entry deny` are enforced and the priority floor (50) sits above every other category, so it beats the Town's `pvp deny`.
- **Wood farm (`property_47`).** v1 set `block-break allow` *and* the custom `allow-blocks: LOG;` (only logs breakable). WorldGuard has no `allow-blocks`, so `block-break allow` alone would let anyone break every block in the plot. Decision: `RESOURCE_PRODUCTION` does **not** get `block-break` unless the config opts in, and `allow-blocks` is never set (an override that names it is skipped with a warning, because WorldGuard doesn't know the flag). Enforcing "logs only" needs a v3 block-break listener — **unresolved**, §8. `property_45`/`_46` also had `block-break allow` with no `allow-blocks`; if they matter, add the flag through `overrides` after deciding it's intended.
- **Greeting/farewell text.** Not managed. v3 sends its own transition messages from domain data (`SimpleRegionTransitionService`); a WG greeting flag would duplicate it, and the per-town v1 texts aren't category data.
- **Rank-dependent access.** Not managed. The v1 `entry-deny-message` wording mentions ranks, but the flag alone doesn't prove WG enforced a rank check (the inventory says so). v3 gates entry through `Domain.AllowEntry`/`AllowExit` and title/premium checks in the plugin (since KNG-56 as the custom WorldGuard flags `knk-allow-entry`/`knk-allow-exit`, synced from the API and enforced by a WorldGuard session handler: [`domain-access-enforcement.md`](domain-access-enforcement.md)). `entry` on Towns is left unset (four v1 towns set `allow`, one none — equivalent to unset for non-members).
- **`deny-message ""`.** Applied to Towns only (shared there). For Properties (22 of 36), Rooms (17 of 22) and `house_9` it's per-instance, not category data, so it's not applied; use an override if wanted.
- **`__global__`** stays untouched unless explicitly enabled.

## 6. Startup repair

`ManagedRegionRepairService` (core) driven by `ManagedRegionsBootstrap` (paper), scheduled `delay-ticks` (default 100) after enable so WorldGuard has loaded its regions:

1. Read every Town, District and Structure from the API (paged, 1-based) plus the `domainType` per domain id (`/Domains/search`) to tell Gates from plain Structures. If the Towns/Districts/Structures can't be read, **nothing is repaired** (a half-read hierarchy must not be applied); it retries `attempts` times, `retry-delay-seconds` apart. If the domain-type lookup alone fails, Structures are treated as plain `STRUCTURE`s and a warning is logged.
2. On the main thread: only regions named by a domain's `wgRegionId` (plus `extra-regions`) are looked at. Each is compared with its desired state; only priority, parent and the policy's flags are ever written. Owners, members, other flags and unrelated regions are never touched; no region is created or deleted.
3. Changes are applied per region atomically (a failure restores what that region had) and saved once at the end (`RegionManager.saveChanges`).
4. One log line: `[KnK Regions] Managed-region repair: checked=N changed=N skipped=N failed=N unchanged=N [save=FAILED]`, then a `WARNING` per failed region and up to 10 warnings. Per-region detail is at `FINE`.

Outcome rules: **checked** = distinct regions considered; **skipped** = domain without a region id, region not in WorldGuard (stale domain record — never recreated), or one region claimed by two domains with different kind/parent (ambiguous — left alone); **failed** = read/apply error for that region; **unchanged** = already correct. A missing parent keeps the current parent (never cleared) and the region falls back to its floor priority; a parent cycle is cut with a warning. Running again on the result changes nothing (`aSecondRunChangesNothingAndDoesNotSave`).

`/knk regions repair` (permission `knk.admin.regions`, child of `knk.admin`) runs the same pass on demand — needed after creating a Town or Structure in the web app (§8), and once after turning `production.enabled` on, so existing production structures get their kind (P2c, #677).

With `map.reporting.enabled: true` every run also reports the domain regions' outlines to the API for the overview map (§7 "Overview map outlines").

## 7. Creation path and config

`POST /Regions/rename` (API → plugin) now accepts optional `domainType` and `parentRegionId`. Every domain service — `TownService`, `DistrictService`, `StructureService`, `GateStructureService`, `DomainService` — calls the shared `IDomainRegionNameFinalizer` after create/update (KNG-43): a region still named `tempregion_worldtask_<n>` becomes `domain_<id>`, with the concrete type and the parent's region (District → its Town, Structure/Gate → its District). A failed rename never fails the save; the region keeps its temp name. The plugin renames the temp region — **copying owners and members**, and (KNG-43) keeping the region's own parent and re-linking regions whose parent it was — then runs `reconcileOne` for the new name. Without a type the rename behaves as before and the next repair sets the region up. A rural structure (production P2, a town and no district) is renamed with no parent region (territory is not a region), and with `production.enabled` on the plugin's creation hook (`ManagedRegionsBootstrap.finalizeNewRegion`) gives a `ProductionStructure` region the kind `RESOURCE_PRODUCTION` (log line `[KnK Regions] New region <id> as RESOURCE_PRODUCTION: ...`).

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

**A sub-region, lootbox area, production area or siege spot a failed re-run left on a temp name** (PandiO/knk-workspace#952, knk-web-api `next` once L1b is merged): heals on its own. On a retry for a row already stored on its temp region (an update that keeps it, or `finalize-temp-names`), the API names the row's own final name as `replaceRegionId`, so the plugin redefines the region left behind in place, or renames plainly when it is gone, unless another domain, sub-region, lootbox area, production area or siege spot names it. A first save names nothing. `domain_<id>` is left out (a v2 region can carry the name, §8 item 9; a redefine would keep its owners and flags), so a domain in that state still needs the way out above.

**The repair never renames.** `/knk regions repair` only fixes parent, priority and flags. Domains that still have a temp name (created before KNG-43, or renamed while the server was down) are renamed by `POST /api/Regions/finalize-temp-names` (plugin key or `knk.admin.regions`; needs the server running; parents first; returns found/renamed/failed; safe to repeat).

`config.yml`, `regions.managed`: `startup-repair.{enabled,delay-ticks,attempts,retry-delay-seconds,page-size}`, `resource-production-block-break`, `manage-global-region`, `overrides.<regionId>.{kind,priority,parent,flags}`, `extra-regions[].{region,kind,parent}`. Bad entries are logged and ignored, never fatal. The override mechanism is how a House/Property/Room/`property_47` counterpart is identified until `Structure` gets subtypes, and where any exact v1 priority is recorded.

### Domain sub-regions (KNG-254–KNG-258; merged 2026-10-23, knk-plugin `9dfd7aae`, live-tested)

A domain can have extra regions besides its main `WgRegionId` ([design](../specs/domain-subregions/DESIGN.md), [admin guide](../guides/admin/domain-subregions-admin-guide.md)), named `domain_<domainId>_sub_<id>`. They are **not** managed by the policy above.

- **Mirror.** `SubRegionMirror` (core) runs after every access sync: startup, every 5 min, `/knk regions repair`, `/knk regions sync`. It makes each sub-region a copy of its main region: priority, every flag, owners, members, and the main region as parent. Only the region's own `knk-creation-timestamp` / `knk-orphaned-since` are kept.
- **Rename.** `RegionRenamePlan` accepts the `_sub_` name (KNG-103 replace in place on a re-run). `POST /Regions/rename …&subRegionOf=<main>` mirrors at once.
- **Repair.** The reconciler never sees sub-regions; the main region's repair reaches them through the mirror.
- **Map outlines.** With `map.reporting.enabled: true`, every completed access sync hands its rules to the overview map after the mirror (`DomainAccessFlagSync.afterSync`), which reports the outlines of the sub-regions they list (§ "Overview map outlines", [#750](https://github.com/PandiO/knk-workspace/issues/750)). Off, no listener is set.
- **Orphans.** A `_sub_` region no domain lists on two syncs in a row is orphaned (`OrphanedSubRegions`): its access flags, `knk-domain-id` and parent are removed, and it gets `knk-orphaned-since`. The daily cleanup deletes it after `regions.temp-retention.days` (default 14) counted from that mark (`TempRegionCleanupPolicy.decideOrphanedSubRegion`). `/knk regions temp [purge [hours]]` lists and purges them; they are no longer reported among the orphaned `domain_<id>` regions.
- **Shapes.** Every region a world task draws (main or sub) turns a `//sel cyl`, ellipsoid or convex selection into a polygon (`SelectionShapes`). Before, it became the box around the selection.

### Lootbox spawn areas (PandiO/knk-workspace#34, drawn bounds kept since #487; in `next`)

A `LootboxSpawnArea` form's Region field uses the same region world task (`ReagionCreate`, `WgRegionIdTaskHandler`), so a drawn region is `tempregion_worldtask_<n>` too. Before #34 nothing renamed it and the daily cleanup deleted it after 14 days: the area silently stopped spawning. Spawn areas are **not managed regions** (no category, parent, priority or flags from §4–§5; the repair never sees them).

- **Name: `lootbox_area_<id>`** (the area's id). It sits in the in-game command's `lootbox_<name>` family on purpose: a `lootbox_` region belongs to one area (the API refuses a second area on it, `RegionInUse`) and `/knk lootbox area delete` removes it; a borrowed region (a town's) never is. Names that tell players little were weighed (the issue allowed a less obvious one); region names are only shown to players with WorldGuard's info permissions, and the in-game areas are already `lootbox_<name>`, so the plain name won. **Area names `area_<number>` are reserved** (API validation and the in-game command), since `lootbox_area_<n>` would otherwise be the in-game region of an area named `area_<n>`; an existing area keeps such a name.
- **On save** (`LootboxSpawnAreaService` create/update → `IDomainRegionNameFinalizer.FinalizeLootboxAreaAsync`): only a temp-named region is renamed; a selected region (a town, `lootbox_<name>`, anything else) is used as it is. `POST /Regions/rename?…&world=<area world>`, no `domainType`. The renamed region keeps **exactly the drawn shape: the polygon outline or cuboid footprint and the drawn Y range** (developer decision 2026-11-14, [PandiO/knk-workspace#487](https://github.com/PandiO/knk-workspace/issues/487); under #34 it was stretched to the world's full build height with `fullHeight=true`, which the API no longer sends and the plugin ignores). The log line ends with the kept range, `(Y <min> to <max>)`. `/knk lootbox area create` still builds its `lootbox_<name>` regions at full build height from a WorldEdit selection (not changed by #487).
- **Spawning in a region that stops below the surface** (#487, `LootboxSpawnPlanner.standY`): per random column the spawner takes the block above the highest motion-blocking block (leaves ignored). Inside the region's Y range it is the spot or there is none, as before, so a box never drops through water into a cave. Above the range (a roof, an overhang, a region drawn under the ground) the highest y from the region's top down to its bottom with good ground and two air blocks is the spot. Below the range (a region in the air) there is none. A box stands with its bottom inside the region, so a drawn region must include the layer of air just above the ground; form seed v3 says so.
- **Re-run of the region step:** as KNG-103 for domains. The area's WgRegionId before the save is the candidate: its own `lootbox_area_<id>` is redefined in place (the new drawn shape and Y range, its flags and owners kept; an area region from before #487 at full height becomes the new drawn shape), a previous temp-named region is removed after the rename; a borrowed or `lootbox_<name>` region is kept (a re-run of an in-game area leaves its old `lootbox_<name>` behind: `/rg remove` it). A previous region a domain, a domain sub-region or another area uses in the same world is kept. A temp region another area or a domain also stands on is not renamed away (the area keeps the temp name; the cleanup keeps it, below).
- **Failure:** never fails the save. The area keeps the temp name; storing after a successful rename failing renames it back. `POST /api/Regions/finalize-temp-names` also renames temp-named areas (listed as `LootboxSpawnArea <id> (<temp>)` under `failed` when the plugin refuses), as does the next save.
- **Cleanup:** `TempRegionRetentionTask`'s fresh lookup asks the lootbox areas too (`GET api/LootboxSpawns/runtime-config`, every area, disabled ones included; `TempRegionCleanupPolicy.inUseByAny`): a temp region an area stands on is kept, and one is deleted only when neither a domain nor an area uses it. An unreachable API keeps it, as before. Not world-qualified (like the domain lookup). A domain's or sub-region's re-run no longer removes a previous temp region an area stands on.
- **Not changed:** a web delete still can't reach WorldGuard and leaves `lootbox_area_<id>` behind (as it does `lootbox_<name>`, lootbox DESIGN §3.4). A region task that completed for a form that was then abandoned kept its temp region for the 14 days (#180 note on #34) until #269 (next section).

### Landmarks (PandiO/knk-workspace#976: knk-web-api `next` `8cc4511b`, knk-plugin `next` `14645895`; not live-tested)

Since [#976](https://github.com/PandiO/knk-workspace/issues/976) ([design](../specs/landmark-domain/DESIGN.md) LD13,
LD14) a `Landmark` is a **domain** (TPT child of `Domain`), so its regions follow the domain path of this section and
are **managed regions** of their own kind. This replaces the #945 design (a `landmark_<id>` region that was not
managed); see the 2026-11-21 entry under Changes for that history.

- **Only Area `OwnRegion` owns a region.** Its main region is `Domain.WgRegionId` (nullable for landmarks only), its
  sub-regions are ordinary domain sub-regions. A point landmark (`None`) and a `LinkedDomain` landmark own none; the
  latter's area is its parent's main region and sub-regions, read live (navigation finds the parent's sub-regions by
  their `knk-domain-id` flag).
- **Names:** a drawn region becomes `domain_<id>` and its sub-regions `domain_<id>_sub_<n>`, through the domain rename
  of `DomainRegionNameFinalizer` (`domainType` `Landmark`), re-runs as KNG-103 above. The finalize pass orders
  landmarks after the other domains, a landmark under another landmark after its parent. The world is the pin's
  world. Regions named `landmark_<n>` from #945 are left in the world and no longer used (the migration
  `LandmarkAsDomain` dropped every landmark row, LD10). A domain's own `domain_<id>` left on a temp name after a failed
  re-run is not healed by `finalize-temp-names` (#952, [#1006](https://github.com/PandiO/knk-workspace/issues/1006));
  use "A domain the old bug left on a temp name" above.
- **Managed kind `LANDMARK`** (knk-core `ManagedRegionKind.LANDMARK`, `DomainRegionSpecs.landmarks`): WorldGuard parent
  = the parent domain's main region (`parentDomain.wgRegionId`; top level without a parent or when the parent has no
  region), priority = parent + 10 with the structure-tier floor 30 (§ 4), **no category flags** (§ 5,
  `ManagedRegionPolicy`), so it inherits the parent's flags, also where it reaches outside the parent (no containment
  check, LD09). Set when the region is drawn and restored by the startup repair (§ 6) and `/knk regions repair`, which
  read `api/landmarks` for this (a failed read is a warning, "landmarks unavailable (…)", and leaves the landmark
  regions as they are). This is independent of `navigation.landmarks`.
- **Access flags and sub-region mirror:** as every domain's: `knk-allow-entry`, `knk-allow-exit` and `knk-domain-id`
  on the main region and its sub-regions (`AccessFlagSync`, `SubRegionMirror`).
- **Effect damage:** a landmark never counts for the no-effect-damage rule
  ([domain access enforcement](domain-access-enforcement.md)).
- **Cleanup and release:** a landmark's regions are found by the domain lookup (`by-region`); the plugin no longer
  asks `api/landmarks` for the cleanup, and the API's release list covers them through `domains.WgRegionId` and the
  sub-regions.
- **Realtime:** a landmark change sends `EntityChanged` of type `Landmark` (key: its own region id, none for a point
  or a linked-area landmark); the plugin clears that domain from the catalogue and the region cache and, once per
  burst, refreshes the navigation model and the landmark message settings. The navigation model also still refreshes
  every 60 s (`NavigationModelRuntime.REFRESH_SECONDS`).

### Production areas (PandiO/knk-workspace#946; API in `next` `4d9bea33`, plugin PR knk-plugin#115 open; not live-tested)

A Region-shaped `ProductionArea` (yield areas, #138/#680/#877) names its region in `WgRegionId`, and its form's region
field has the `RegionClaim` task, which can also draw a new region. Before #946 that region stayed
`tempregion_worldtask_<n>`, the 14-day cleanup deleted it, and the survey then failed with "WorldGuard region ... not
found" (`AreaSpec.resolve`), so the area stopped counting. Production areas are **not managed regions** either.

- **Name: `production_area_<id>`**, in the area's `WorldName`; no area name is reserved (an area's name never becomes a
  region id). Only a Region-shaped area with a temp-named region is renamed, after the save
  (`ProductionAreaService` create/update, then `IDomainRegionNameFinalizer.FinalizeProductionAreaAsync`); an existing
  region (`select <region>`, a typed id, the structure's `domain_<id>`) is kept as it is. Moving the area to another
  shape drops its region id and renames nothing.
- **Re-run, failure, `finalize-temp-names`, cleanup and release:** as for lootbox spawn areas above (one code path, below).
  The plugin's lookup is `productionAreaUsageVia` (`GET api/ProductionAreas`, every area; it answers while
  `Production:Enabled` is off too; a 404 counts as none); the API's release list skips a region an area names.
- **Survey:** the plugin reads the due areas, with their region id, from the API at every poll
  (`GET api/ProductionAreas/survey-due`) and the region's shape live from WorldGuard (`SurveyRegionShapes`), so the next
  survey uses `production_area_<id>`; a survey that ran between the save and the rename (milliseconds) fails once and is
  asked again. The harvest module's area index picks it up at its next catalogue refresh.
- **Bounds (#877):** an edit that names `production_area_<id>` and leaves the bounds empty takes them from the region's
  outline, which the rename reports under the new name (with `map.reporting.enabled`). The first save of a freshly drawn
  region has no stored outline yet, so its bounds must be typed ([#951](https://github.com/PandiO/knk-workspace/issues/951)).

**One path for the kinds of owner (#946, #988).** Lootbox spawn areas, production areas and (since #988)
siege weapon spots go through one
finalize path in `DomainRegionNameFinalizer` (`RegionOwnerKind`, `FinalizeOwnedRegionAsync`,
`ReplaceableOwnedRegionAsync`, `OtherUserOfRegionAsync`); each kind only says which entity, final name, world and plugin
call it uses. The plugin's cleanup has one lookup over a listed kind of owner (`TempRegionRetentionTask.ownerUsageVia`).
A new kind is a new `RegionOwnerKind` value, an owner builder, a usage query and one `ownerUsageVia` line (siege weapon
spots have no `ownerUsageVia` line yet, see above).
Known gap shared by every kind (domains too): a row left on a temp name after a failed re-run can't be healed by
`finalize-temp-names` while its old final region exists ([#952](https://github.com/PandiO/knk-workspace/issues/952)).

### Siege weapon spots (PandiO/knk-workspace#988; knk-web-api `next` `c647daf7`, knk-plugin `next` `822eb39b`; not live-tested)

Since #988 (developer decision 2026-11-22, [siege weapons spec W76](../specs/siege-minigame/SIEGE_WEAPONS.md)) a siege
weapon spot **is** its WorldGuard region: `SiegeWeaponSpot` keeps only `WgRegionId` (the six bounds columns are gone,
migration `DropSiegeWeaponSpotBounds`). The spot form's Region field has the normal `ReagionCreate` task, which can draw
a new region or `select` an existing one. Spots are **not managed regions**: no parent, priority or flags are set, and
the drawn box keeps its Y range. Admin steps: [siege weapons admin guide § 2](../guides/admin/siege-weapons-admin-guide.md#2-weapon-spots).

- **Owner kind:** `RegionOwnerKind.SiegeWeaponSpot`, the fourth kind on the shared owner path below
  (`SiegeWeaponSpotOwner`, `FinalizeSiegeWeaponSpotAsync`, `SiegeWeaponSpotUsingAsync`; plugin call
  `RegionService.RenameSiegeWeaponSpotRegionAsync`).
- **Name: `siege_spot_<id>`**, in the scenario's world (its town's `WorldName`, else its hub location's world;
  `SiegeScenarioWorld.OfAsync`). Only a temp-named region is renamed, after the save (`SiegeWeaponService` create and
  update, `FinalizeDrawnRegionAsync`); a picked region (`select <region>` or a typed id) keeps its name. A re-run of the
  task replaces the spot's old drawn region, as for production areas. A failed rename never fails the save: the spot keeps the
  temp name, and the next save or `POST api/Regions/finalize-temp-names` (which now also walks spots) tries again.
- **Size class:** the API asks the game server for the region's bounds over the game hub (`RegionGeometryQuery`,
  [realtime design § 6.12](../specs/realtime-signalr/DESIGN.md#612-region-queries-regiongeometryquery-and-spotsitecheckquery-pandioknk-workspace988-in-next))
  and works the class out from them and the facing; a polygon counts as its bounding box. No answer keeps the stored
  class; "not found" or "too small" refuses the save.
- **API release check (#269):** `TempRegionReleaseService.UsedByAsync` keeps a temp region a spot names ("a siege
  weapon spot uses it"), so a deleted draft never releases a region a saved spot still stands on.
- **Known gaps (both move to the generic region lifecycle, [#989](https://github.com/PandiO/knk-workspace/issues/989)):**
  1. The plugin's 14-day cleanup (`TempRegionRetentionTask.regionUsageVia`) does **not** ask spots: there is no
     `ownerUsageVia` line for them. A spot whose rename failed and stays on `tempregion_worldtask_<n>` loses its region
     after 14 days; run `POST api/Regions/finalize-temp-names` (or save the spot again) before then.
  2. Deleting a spot deletes the row only; its `siege_spot_<id>` region stays in the world (remove it with
     `/rg remove siege_spot_<id>`).

### Abandoned drafts: temp regions released early (PandiO/knk-workspace#269; in `next`)

Before #269 a `tempregion_worldtask_<n>` whose form was abandoned waited for the daily cleanup's 14 days. #180 already removed it at once when the region task itself was cancelled while the game server still ran it (the handler's 409 / heartbeat path). Now the API **releases** the region and the game server removes it within minutes, after the same checks as the cleanup minus the age.

- **When the API releases a region** (`Services/TempRegionReleaseService.cs`, table `temp_region_releases`, one row per task; no foreign key, a row outlives a task the sweep removes):
  - the **draft is deleted** (Delete in Saved Progress, the web app's "cancel or discard"; `FormSubmissionProgressService.DeleteAsync`, before the delete clears `world_tasks.FormSubmissionProgressId`): every region task of the draft — Completed ones unless the result picked an existing region with "select", open ones (offered once they close), other closed ones a game server held;
  - a region task **closes without a result**: Cancelled (web "Cancel task", "Capture again" replacing it, `POST …/status`), Failed (also a completion the API refused), Expired (the sweep, or a claim after the expiry) — only when a game server ever held it (`ClaimedAt` or `ReleaseCount` > 0: an unclaimed task drew nothing). This covers the case #180 could not: the server crashed or restarted after drawing, the lease lapsed and the task expired;
  - the **world-task sweep removes the task's workflow session** (no draft, 7 days quiet; never a session with a Completed task, unchanged), in the same save as the removal.
  A "region task" is one with task type `ReagionCreate`, `RegionCreate` or `RegionClaim` (#944: the plugin finds `WgRegionIdTaskHandler` by these on any field), with field `WgRegionId` (older configurations), or whose result names its own temp region. Leaving the form ("Cancel" in the wizard) keeps the draft, so it releases nothing.
- **What the game server is given** (`GET api/WorldTasks/temp-region-releases?serverId=`, plugin key only; a blank or missing `serverId` answers 400, as `GET open` does, [PandiO/knk-workspace#399](https://github.com/PandiO/knk-workspace/issues/399): the plugin always sends `realtime.server-id`): a release only when **all** hold, otherwise it waits (re-checked on every call). The API reads the due rows oldest first in pages of 200 until `max` (default 50) are listed or none is left, so waiting rows never hide later releases (#399; before, only the 200 oldest were looked at):
  - 5 minutes have passed since the release and since the task last changed (`WorldTasks:TempRegionReleaseGraceMinutes`);
  - the task is closed (or gone), and it is not a Completed task of a draft that still exists (a draft delete that failed);
  - **nothing names the region**, in any world, case-insensitive: a domain's or domain sub-region's `WgRegionId`, a lootbox area's region or exclusions (a landmark's region is a domain's since #976), a production area's `WgRegionId` (#946), a siege weapon spot's `WgRegionId` (#988), a road edge's regions, or any draft's step data (text match, so a longer id containing it also keeps it);
  - its server is this one or unknown (`ClaimedByServerId`; with several game servers, a release with no server goes to whichever asks first).
  Releases older than 30 days are dropped unsettled (`WorldTasks:TempRegionReleaseKeepDays`); by then the daily cleanup has decided.
- **What the game server does** (`TempRegionReleasePass`, every `regions.temp-retention.release-interval-minutes`, default 5, 0 = off; started with the retention task, first pass after 2 minutes). Per release, `TempRegionCleanupPolicy.decideRelease`:
  - only the release's own `tempregion_worldtask_<taskId>` name, in **exactly one** loaded world (the task's world when it is loaded, else all of them): none → settled `Missing` (renamed to `domain_<id>` / `lootbox_area_<id>` / `production_area_<id>` / `siege_spot_<id>` already, removed, or never drawn here); several → `Kept`;
  - waits while a player here still runs that task, or while the last managed-region repair hasn't run / saw a domain use it;
  - needs a creation timestamp (`knk-creation-timestamp`; without one it was not drawn by the region task → `Kept`);
  - the cleanup's fresh lookup (`regionUsageVia`: domain by region (landmarks included since #976) + lootbox runtime config + production areas since #946; not siege weapon spots, which the API's release list already skips): in use → `Kept`; API unreachable → waits; unused → removed (children keep their place without a parent, as the cleanup does) and settled `Removed`.
  `POST api/WorldTasks/temp-region-releases/{id}/settle` deletes the release; a failed settle lists it again (then `Missing`). The log says `Removed temp region <world>/<id> (its draft was deleted; …)`.
- **Not released:** a region task that completed for a draft that was then **completed** without using it (e.g. "Capture again" after a completed capture: the older region stays), a task deleted by hand (`DELETE api/WorldTasks/{id}`), drafts the 90-day retention deletes (long after 14 days). These still go after 14 days. A task still InProgress when its draft is deleted is not cancelled: if the player finishes, the region is removed afterwards.
- **Backstop unchanged:** the daily `TempRegionRetentionTask` pass (§8 item 5) still runs with its 14 days and catches everything not released (older API, plugin with the pass off, a release dropped after 30 days).

### Overview map outlines (PandiO/knk-workspace#735, on trunk since knk-plugin v0.3)

With `map.reporting.enabled: true` (and `realtime.enabled: true`) the repair and the rename path also report region
outlines for the web app's overview map ([design](../specs/in-game-maps/OVERVIEW_MAP_DESIGN.md) § 6.2.6, § 7;
[admin guide § 3](../guides/admin/overview-map-admin-guide.md#3-outlines-and-what-keeps-them-current)). Off by default:
then nothing is hooked in and the repair and rename behave exactly as above. Merged into `next` 2026-11-18 (knk-plugin#76,
knk-web-api#45), not on trunk, not live-tested ([smoke test § 1](../guides/overview-map-smoke-test.md#1-phase-1-region-outlines-735-tier3)).

- **Wiring** (`KnKPlugin`, `paper/map/MapReporting`, `core/map/MapReportingService`): `ManagedRegionRepairService.afterRepair`
  hands every run's domain region specs (Town, District, Structure, Gate) to `reportDomainRegions`;
  `WgRegionIdTaskHandler`'s rename listener calls `regionRenamed` after a world task's Region step renames a temp region
  to `domain_<id>` or redraws a domain's region in place (KNG-103 replace); the realtime resync hook calls `resendAll`
  on every game hub (re)connect, so a repair that finished before the hub was up, or an API restart, is covered.
  Since F1 ([#750](https://github.com/PandiO/knk-workspace/issues/750), branch `claude/overview-map-f1-subregions`,
  PR into `next`): `DomainAccessFlagSync.afterSync` hands every completed access sync's rules (startup, every
  `interval-minutes`, `/knk regions repair`, `/knk regions sync`, after a new region) to `reportSubRegions` with the
  sub-regions they list (`MapReporting.subRegions`, in the domain's world). That set is remembered next to the domain
  regions: the first sync sends every sub-region, later syncs only those not reported yet (a quiet sync reads
  nothing), one not found is tried again next sync, one no longer listed only leaves the set; `resendAll` sends both
  sets. A domain's outline is its main region plus its sub-regions.
- **What is sent:** the hub method `ReportRegionOutlines` with each region's 2D points in order (a cuboid's four
  corners, a polygon's points; at least three), min and max Y, keyed by world and region id; a rename names the old id
  under `removed` (never the final name of a re-run in place). `RegionOutlineAdapter` reads WorldGuard on the main
  thread; reports are split under the hub's message limit. Contract: [realtime design § 6.11](../specs/realtime-signalr/DESIGN.md#611-overview-map-region-outlines-live-players-and-gate-commands-pandioknk-workspace732-in-next).
- **API side:** `Services/Map/MapRegionOutlineService` upserts table `map_region_outlines` (migration
  `AddMapRegionOutlines`), one row per world and region id, linked to the domain whose `WgRegionId` or
  `domain_sub_regions` row names it; unchanged rows keep their `UpdatedAt`; rows for removed names are deleted. Only a
  plugin-key game hub connection can write.
- **Log lines:** `[KnK Map] Region outlines (domain regions): <n> outline(s), <m> removed, …` after a repair,
  `[KnK Map] Region outlines (sub-regions): …` after an access sync that found sub-regions not reported yet,
  `[KnK Map] Region outlines (region <id>): …` after a rename; the API logs `Game server <id> reported region outlines:
  <n> stored, <u> unchanged, <r> removed, <x> rejected`.
- **Limits:** a hand edit (`/rg redefine`) of a domain region is reported only by the next repair; of a sub-region
  only on the next hub reconnect or plugin restart (the access sync sends a known sub-region once). Lootbox areas and
  other unmanaged regions are never reported.

## 8. Unresolved v1 → v3 differences and observed hazards

1. **No House/Property/Room subtype in the API**, so those kinds are opt-in per region (overrides). A `StructureType` on `Structure` would let the repair apply them automatically — needs a migration and design decision (`vision.md` §2.5 already decides on subclasses). Linear KNG-47.
2. **`allow-blocks` / wood farm**: needs a v3 listener to restrict block breaking in `RESOURCE_PRODUCTION` regions to logs; until then `block-break` is not opened up. Linear KNG-48.
3. **Exact v1 priorities** unknown (§2). Supply `regions.yml` to compare, or set overrides. Linear KNG-49 (also the Arena/Battleground entity decision).
4. ~~Town/Structure creation don't finalize temp region names~~ — fixed by KNG-43 (§7); existing temp-named domains need one `finalize-temp-names` call.
5. **`TempRegionRetentionTask`** (14 days after creation; configurable as `regions.temp-retention.days` since KNG-258; `knk-creation-timestamp` flag) deletes a temp-named region only when (a) the last repair didn't see a domain use it (and the repair has run at all), (b) it has a valid timestamp older than the cutoff, and (c) a fresh `GET /Domains/by-region/{id}` right before the delete returns 404 and (#34, feature branch) no lootbox spawn area in the runtime config stands on it (§7 "Lootbox spawn areas"). An API error keeps the region. #269 (feature branch): regions the API released (abandoned drafts) are removed earlier with the same checks except the age (§7 "Abandoned drafts"). Policy: `knk-core` `TempRegionCleanupPolicy` (KNG-43; before, only (a) existed, so a domain created after the last repair was not protected).
6. **Entry gating by rank** and **greetings** remain v3-plugin behaviour, not WG flags (§5).
7. **Arena/battleground regions** have no domain entity; they are managed only through `extra-regions`.
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

## Changes

1. 2026-11-22: §3, §4, §5 the `LANDMARK` kind; §7 "Landmarks" rewritten: landmarks are domains (`domain_<id>`, managed under their parent, no category flags), the #945 `landmark_<id>` path is gone; PandiO/knk-workspace#976, docs #1008
2. 2026-11-22: §7 "Siege weapon spots" (a fourth owner kind, `siege_spot_<id>`, the release check, the plugin cleanup gap and delete gap), "Abandoned drafts" lists spots; PandiO/knk-workspace#988 in `next`, docs #999
3. 2026-11-21: §7 "Landmarks" and "Production areas" (drawn regions renamed to `landmark_<id>` / `production_area_<id>`, re-run replacement, cleanup lookups read once a minute, one owner path) and the region task found by task type; "Abandoned drafts" release rules; PandiO/knk-workspace#944/#945/#946, branch `claude/landmark-regions`, not merged
4. 2026-11-20: §7 "Overview map outlines" on trunk since knk-plugin v0.3 (docs #767)
5. 2026-11-19: §7 "Domain sub-regions", "Overview map outlines": sub-region outlines after every access sync, PandiO/knk-workspace#750
6. 2026-11-18: §7 "Overview map outlines": the repair and rename also report outlines with `map.reporting.enabled`, PandiO/knk-workspace#735, docs #766
7. 2026-11-15: #399 of §7 released in knk-web-api v0.3, `main` `2cc8254`, PandiO/knk-workspace#577
8. 2026-11-15: §7 "What the game server is given": `serverId` required, due rows read in pages, PandiO/knk-workspace#399, knk-web-api#33 into `next`
9. 2026-11-13: §7 #34 and #269 in the PR into `next` from `claude/plugin-chains-into-next`
10. 2026-11-09: §7 "Abandoned drafts: temp regions released early", PandiO/knk-workspace#269, on feature branch `claude/temp-region-drafts-269`, not merged; §8 item 5
11. 2026-11-05: §7 "Lootbox spawn areas", PandiO/knk-workspace#34, on feature branch `claude/lootbox-area-rename-34`, not merged; §8 item 5
12. 2026-10-23: §7 "Domain sub-regions", KNG-254–KNG-258, merged and live-tested
13. 2026-10-18: KNG-103 in-game check passed and merged; §7 recovering a domain the old bug left on a temp name, purge keeps what the last repair saw; §9 result
14. 2026-10-12: §7 "Re-running a domain's region step" and `/knk regions temp`, KNG-103; §9 checklist, not yet run
15. 2026-10-06: §5 "Rank-dependent access" links the domain entry/exit enforcement, KNG-55/KNG-56
16. 2026-10-05: KNG-46 in-game smoke test passed; parent-inheritance decision accepted; vanilla spawn-protection note, §8 item 10
