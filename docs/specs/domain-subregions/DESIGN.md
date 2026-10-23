# Domain sub-regions (expansion regions) — design

**Status:** Design accepted by the developer (2026-10-23, rev. 2). **Implemented on unmerged feature branches, not live-tested** (§13): every phase KNG-254–KNG-259 is In Review. Follow-ups: [KNG-260](https://linear.app/kngpandi/issue/KNG-260) (navigation), [KNG-261](https://linear.app/kngpandi/issue/KNG-261) (placement checks).
**Last updated:** 2026-10-23 (§13 implementation status and the changes against this design; phase issues KNG-254–KNG-259 filed. Rev. 2: the 7 decisions in §12 taken, all as recommended; §6 select renames. Rev. 1: investigation of v1/v2 and the current API, plugin and web app; first design)
**Linear:** [KNG-253](https://linear.app/kngpandi/issue/KNG-253). Related: [KNG-103](https://linear.app/kngpandi/issue/KNG-103) (region step re-run, replace in place), [KNG-56](https://linear.app/kngpandi/issue/KNG-56) (access flags), [KNG-46](https://linear.app/kngpandi/issue/KNG-46) / [KNG-43](https://linear.app/kngpandi/issue/KNG-43) (managed regions, rename on save), [KNG-111](https://linear.app/kngpandi/issue/KNG-111) (domain world)
**Sources:** developer request 2026-10-23; `knk-v1-archive` (`src/DataManager/{Towns,Districts,Worldguard,Creations}.java`, `src/Models/creations/{Town,District,Structure}Creation.java`, `src/Towns/{Town,TownCommands,TownEvents}.java`); `knk-v2-archive` (`model/dominion/Dominion.java`, `util/WorldguardUtil.java`); knk-web-api `master` `4f34f58`; knk-plugin `main` `69c9388`; knk-web-app default branch; [managed WorldGuard regions](../../architecture/managed-worldguard-regions.md); [domain access enforcement](../../architecture/domain-access-enforcement.md); [legacy towns/districts/gates](../legacy/towns-districts-gates.md)

---

## 1. Requested behaviour

A garrison is a cylindrical tower with a cuboid-like house attached at its base, and it has a gate. It should be **one** GateStructure. Today a domain has exactly one WorldGuard region (`Domain.WgRegionId`), and one region has one shape, so this can't be modelled.

Requirements as stated by the developer (2026-10-23):

- **R1.** A domain can have any number of **sub-regions** besides its main region. A sub-region belongs to exactly one domain. Sub-regions are added, edited and removed through a new property of the domain.
- **R2.** A sub-region without a domain is an **orphan**. Orphans are deleted under the grace period and retention rules that already apply to temp regions.
- **R3.** Sub-regions are created and edited through **world tasks**.
- **R4.** Flags, enter/exit messaging and everything else that should be synced are **the same** on the main region and every sub-region of a domain.
- **R5.** **Renaming** follows the main region's system.

Requirements found during the investigation that the request doesn't name (§2.4). Each is designed below:

- **R6.** The domain is the **union** of its regions. Moving between two regions of the same domain is not an entry or an exit. That matters for messages, events, analytics and access enforcement.
- **R7.** A **cylinder** selection has to become a cylinder-shaped region. Today it becomes the cuboid around it, so the tower can't be drawn.
- **R8.** Containment checks treat the domain's regions as one area. That covers a gate door's location inside the gate, a Structure inside a District that has an expansion, and a sub-region inside the parent domain.
- **R9.** Every region-to-domain lookup also resolves sub-region ids. That covers the plugin cache, `GET /Domains/by-region`, temp cleanup, discovery and navigation.
- **R10.** Child domains keep their WorldGuard **parent** pointing at the domain's main region. The startup repair and `/knk regions repair` also cover sub-regions.
- **R11.** **Deleting a domain** orphans its sub-regions (R2). Re-running the main region step doesn't touch the sub-regions.

## 2. Investigation

### 2.1 v1 (what the developer remembers)

v1 had "parts":
- **Naming.** A part's WorldGuard region was `<type>_<id>,<n>`, e.g. `town_5,2`. While a wizard ran it was `tempregion_<creation>_sub_<millis>` (`TownCreation.java:226-237`, `DistrictCreation.java:247-251`, `StructureCreation.java:497-503`).
- **Storage.** Only towns recorded parts in the database, in `TownRegion(TownID, SubID)` (`Town.java:292-360`).
- **Creating parts:**
  - The creation wizards had a "save another sub-region" stage.
  - `/town part add|remove` managed parts afterwards (`TownCommands.java:195-298`).
  - The district wizard checked that both corners of each part lie in the town.

**What v1 did *not* do** (this differs from the recollection in the request):
- **No sync.** The only link was `part.setParent(main)` (`Towns.java:163-190`), so a part inherited the main region's flags and members through WorldGuard's parent chain. Priority, flags and members were never copied. Member and owner helpers wrote only to the first matching region (`House.java:664-685`, `Property.java:835-866`).
- **No orphan cleanup for finished parts.** Only `tempregion*` was wiped, on reload (`Creations.java:90-100`). Wizard-made town parts were never written to `TownRegion`, so `removeTown` couldn't find them and left them behind.
- **Lookup by parsing the id.** `getStructureIDbyRegion` split the id on `_` and `,` (`Worldguard.java:229-250`). It used substring matching, so `town_1` also matched `town_12,3`.
- **Enter dedupe** came from an `inTown` map keyed by town id (`TownEvents.java:50,86`). The leave message fired only when no `town` region was left at the position (`:182-191`).
- **Known bugs:**
  - The district sub-region save loop reused the main region's bounds and id for every part (`Districts.java:140-166`).
  - `/town part add` never added its region (`TownCommands.java:631`).
  - The structure wizard never registered its part.

v2 dropped parts: one `regionName` per Dominion (`Dominion.java:110-140`).

**Conclusion:** we take from v1 the idea, the WorldGuard parent link (as a safety net, §5.2) and the per-domain enter/leave dedupe. Sync, orphan handling and lookup are new.

### 2.2 knk-web-api today

- **Region field.** `Domain.WgRegionId` is a required string (`Models/Domain.cs:21`). It is unique per world only in code (`DomainWorldResolver.RegionTakenAsync`); there is no database index.
- **No region policy in the API.** Priority, parent region and flags aren't modelled; the plugin derives them from `domainType` and the parent domain.
- **Mapping.** Domain uses TPT mapping: `domains`, `towns`, `districts`, `structures`, `gate_structures`.
- **Rename on save.** Every domain service calls `IDomainRegionNameFinalizer.FinalizeAsync(domain, previousRegionId)` after a save (`DomainRegionNameFinalizer.cs`). It renames `tempregion_worldtask_<n>` → `domain_<id>` through `POST {plugin}/Regions/rename` with `domainType`, `parentRegionId`, `world` and `replaceRegionId` (KNG-103).
- **World task results.** A region world task's output (`regionId`, `worldName`) is written into the form field by the web app, and the entity is then saved through its CRUD endpoint. The API never writes a task's region into an entity.
- **Lookups:**
  - `GET api/Domains/by-region/{id}?world=` and `POST api/Domains/search-region-decisions` match on `WgRegionId` only.
  - `GET api/Domains/access-rules` lists one row per domain, with one `wgRegionId`.
- **Seeds.**
  - The `WgRegionId` form fields use `settingsJson.worldTask.taskType` `"ReagionCreate"`, or `"RegionClaim"` for Structure.
  - Containment rules: `RegionContainment` against `District.WgRegionId` for GateStructure (`GateStructure.json:265-266`), and `LocationInsideRegion` against `GateStructure.WgRegionId` for door locations (`GateDoor.json:765-802`).
- **Retention.** There is no region retention in the API. The temp-region cleanup is entirely in the plugin.

### 2.3 knk-plugin today

- **Managed regions.** `DomainRegionSpecs.build` makes one spec per domain from its single `wgRegionId`. `ManagedRegionReconciler` sets only parent, priority and category flags. It never creates or deletes regions, and it skips regions that aren't in a spec.
- **Rename.**
  - `RegionRenamePlan` decides: rename, replace in place, or rename and remove the previous region. `FINAL_NAME = domain_\d+` (`RegionRenamePlan.java:24`).
  - `WorldGuardRegionRenamer` rebuilds the region under its new id and copies priority, parent, flags, owners and members. It re-links children. Only polygonal and cuboid regions are supported.
- **Temp cleanup.**
  - `TempRegionRetentionTask` runs every 24 h. The 14-day cutoff is hard-coded in `KnKPlugin.java:591`.
  - `TempRegionCleanupPolicy` applies the rules: the region has the temp prefix, the last repair didn't see a domain use it, its `knk-creation-timestamp` is older than the cutoff, and a fresh `GET /Domains/by-region` returns 404.
  - `/knk regions temp [purge [hours]]` reports, and purges on request. Orphaned `domain_<id>` regions are reported only, never deleted.
- **Shapes.** `WorldGuardIntegration.createRegionFromSelection` makes a polygon for a `//sel poly` selection. **Every other selection, including a cylinder, becomes the cuboid around it.**
- **Access (KNG-56).**
  - `AccessFlagSync` writes `knk-allow-entry`/`knk-allow-exit`/`knk-domain-name` per `rule.wgRegionId()`, and clears the flags on regions no rule owns.
  - `RegionAccessRules` refuses a move when any entered region denies entry or any left region denies exit. It reads each region's own flags with `region.getFlag`, so there is no inheritance.
- **Tracker.** `WorldGuardRegionTracker` fires `OnRegionEnterEvent`/`OnRegionLeaveEvent` per region id. `SimpleRegionTransitionService` takes set differences of `DomainSnapshot`. That record includes `wgRegionId` (`RegionDomainResolver.java:837-849`), so two regions of one domain would be two "different" domains.
- **Gates.** A GateStructure's region is an ordinary `domain_<id>` with kind `GATE`. Door shapes (`ClosedRegionData`/`OpenedRegionData`) are vertex JSON, not WorldGuard regions, and are not affected by this design.

### 2.4 knk-web-app today

- **No region editor of its own.** There is no domain-specific region editor. A field becomes world-task-backed through `settingsJson.worldTask` (`FormWizard.tsx:1017-1024`, `WorldBoundFieldRenderer.tsx`).
- **Owned child collections.** These exist already: `settingsJson.ownedChildCollection: true`, used for GateStructure → GateDoors (`FieldRenderers.tsx:328-343`).
  - Each child is created or edited in a `ChildFormModal`, which can run its own world task (`worldTaskHint`, `FormWizard.tsx:1818-1856`).
  - "Create New" is disabled until the parent is saved.
  - **Sub-regions can use the same mechanism with no new web-app component.**
- **Display.** Display pages are generic DisplayConfigurations, and a collection section exists (`CollectionSection.tsx`).

## 3. Overview

```
Domain (Town / District / Structure / GateStructure / Arena …)
 ├─ WgRegionId            domain_42                 ← main region: the source of truth for flags, members, priority, parent
 └─ SubRegions[]          (new, owned, 0..n)
     ├─ #7  domain_42_sub_7   "Tower"   (cylinder → polygon)
     └─ #8  domain_42_sub_8   "House"   (cuboid)
```

- **API.** It holds which regions belong to a domain: a new owned entity `DomainSubRegion`. Its names follow the main region's lifecycle: drawn as `tempregion_worldtask_<n>`, renamed on save, replaced in place on a re-run.
- **Plugin.** It keeps every sub-region a **mirror** of the main region: priority, parent, all flags, owners and members. That happens at the same moments the managed repair and the access sync already run, plus right after a rename.
- **Domain-level logic.** The plugin resolves every region of the domain to the same domain. Tracker, messages, events, access rules and containment then work per domain, not per region.

## 4. Data model (knk-web-api)

### 4.1 `DomainSubRegion`

```csharp
[FormConfigurableEntity("DomainSubRegion")]
public class DomainSubRegion
{
    public int Id { get; set; }
    public int DomainId { get; set; }           // required, cascade delete
    public Domain Domain { get; set; } = null!;
    public string WgRegionId { get; set; } = null!;   // tempregion_worldtask_<n> until saved, then domain_<domainId>_sub_<id>
    public string? Name { get; set; }            // optional label: "Tower", "House" (web app, /rg info, logs)
    public DateTime CreatedAt { get; set; } = DateTime.Now;
}

// Domain
public ICollection<DomainSubRegion> SubRegions { get; set; } = new List<DomainSubRegion>();
```

- **Table and index.** The table is `domain_sub_regions`, with an index on `(DomainId)`.
- **World.** No `WorldName` column: a sub-region is always in its domain's world. The world task's `worldName` must equal `Domain.WorldName`, otherwise the task fails with "wrong world" (cf. KNG-187).
- **Uniqueness.** `WgRegionId` is unique per world across `domains.WgRegionId` ∪ `domain_sub_regions.WgRegionId`. `DomainWorldResolver.RegionTakenAsync` gets a second query, and `RegionTaken` covers both tables. A region can't be a domain's main region and also another domain's sub-region.
- **Cascade delete.** Deleting the domain deletes its rows. The WorldGuard regions then become orphans (§8).
- **Applies to every domain type.** It is on the `Domain` base class (Town, District, Structure, GateStructure, Arena and later types). See §12 Q-scope.

### 4.2 Endpoints

- **CRUD.** `api/DomainSubRegions` (`GET` by domain, `POST`, `PUT`, `DELETE`). Every write takes `[RequirePermission(StaffPermissions.AdminWorld)]` (`knk.admin.world`, like the domains themselves). `EndpointAccessRulesTests` must pass.
- **Saving.** `DomainSubRegionService.Create/UpdateAsync` validates the world and uniqueness, then calls the finalizer (§6).
- **The domain read DTOs** get `subRegions: [{id, wgRegionId, name}]`. These are the Town/District/Structure DTOs that `DomainRegionSpecs` reads, plus `DomainListDto`.
- **`DomainAccessRuleDto`** gets `subRegionIds: string[]`. The plugin then gets every region of every domain from the call it already makes every 5 min. This list is also the plugin's **authority for orphans** (§8).
- **Region lookups.** `GET api/Domains/by-region/{id}` and `POST api/Domains/search-region-decisions` also match `domain_sub_regions.WgRegionId`, and return the owning domain. The response gets `matchedSubRegionId` (null for the main region).
- **Finalize sweep.** `POST api/Regions/finalize-temp-names` also renames sub-regions that are still on a temp name. It runs after their domain's main region.

### 4.3 Form configuration (seeds)

- **New form `DomainSubRegion`.** It has one step:
  - `Name` (optional).
  - `WgRegionId` with `settingsJson.worldTask = { enabled: true, taskType: "ReagionCreate" }` (the typo is intentional, see the seeds README). Its containment rule is §9's "inside the parent domain" (the District for a Gate), the same as the main region's rule.
- **Each domain form** (Town, District, Structure, GateStructure, Domain) gets a `SubRegions` field.
  - It is `List` of `DomainSubRegion` with `settingsJson.ownedChildCollection: true`.
  - It goes in the "Region and access" step, after `WgRegionId`.
  - Like GateDoors, the list is usable once the domain is saved: "Create New" is disabled before then. For a new garrison: create it with the main region (the house), save, then add the tower as a sub-region.
- **Display configuration.** A sub-region collection section on each domain's DisplayConfiguration.

## 5. Sync: the main region is the source of truth

### 5.1 What is synced

| Item | Main region | Sub-region | Mechanism |
|---|---|---|---|
| Priority | `ManagedRegionPolicy` (parent + 10, floor per kind) | **same value as the main region** (not main + 10) | managed reconcile |
| WG parent | the parent domain's main region | **the main region** (§5.2) | managed reconcile |
| Category flags (TOWN `pvp deny`, …) | SEED/ENFORCE per policy | copied from the main region | mirror |
| Admin flags (`/rg flag domain_42 pvp allow`, greeting, …) | as set | copied | mirror |
| `knk-allow-entry`/`knk-allow-exit`/`knk-domain-name` (KNG-56) | from the API | from the API, on every region of the domain | access sync |
| `knk-domain-id` (new, §7.2) | domain id | domain id | access sync |
| Owners / members | as set (`/rg addmember`) | copied | mirror |
| Enter/exit messages, AllowEntry/AllowExit, discovery, navigation default | domain data in the API | same domain → automatically the same | per-domain resolution (§7) |
| Not synced: geometry, `knk-creation-timestamp`, `knk-orphaned-since` | — | own | — |

- **Mirror semantics.** The sub-region's flag set **becomes** the main region's: flags the main region lacks are removed from the sub-region. A flag set by hand on a sub-region is overwritten at the next sync. Admins set flags on the main region.
- **The sync is one-way.** That keeps it idempotent: a second run changes nothing and doesn't save.

### 5.2 Why copy *and* set the parent to the main region

v1 relied only on `setParent(main)` and WorldGuard inheritance. That isn't enough in v3:
- KNG-56 reads the access flags per region with `region.getFlag`, which ignores inheritance.
- The managed policy seeds flags per region.
- WorldGuard's `entry`/`exit` and membership checks look at the region itself before its parents.

Copying makes every region self-contained. The parent link to the main region is kept as a **safety net**: a flag an admin sets on the main region between two syncs takes effect at once through inheritance, wherever the sub-region doesn't carry a copy yet. It also makes `/rg info` show which domain the region belongs to.

Child domains (a Structure inside a District's expansion) keep the **main** region as their WorldGuard parent. They never point at a sub-region.

§12 Q-sync offers the alternative (inheritance only, no copies).

### 5.3 When the sync runs

1. **Startup repair and `/knk regions repair`.** `DomainRegionSpecs` emits a spec for each sub-region (kind and priority of its domain, parent = the main region). `ManagedRegionReconciler` applies it. A new `SubRegionMirror` then copies flags, owners and members from each main region to its sub-regions.
2. **Access-flag sync**, every 5 min and on repair. It writes the access flags to every region of a domain, then runs `SubRegionMirror` for every domain. That is a local, cheap operation: an admin's `/rg flag` on the main region reaches the sub-regions within 5 min.
3. **After a rename/finalize.** For a main region: `reconcileOne` plus the mirror for its sub-regions. For a new sub-region: reconcile, mirror and access flags for that sub-region.
4. **On demand.** `/knk regions sync [domainId]` (permission `knk.admin.regions`) mirrors at once. The repair does too.

**Failure handling.**
- **Ambiguous main region.** A domain whose main region is missing in WorldGuard is "stale" and skipped, as today. Its sub-regions are left untouched (never synced from nothing).
- **Missing sub-region.** If a sub-region named by the API is missing in WorldGuard, it is reported as stale. It is never recreated.

## 6. Naming and rename (R5)

- **Final name.** The final name is `domain_<domainId>_sub_<subRegionId>`. Both ids come from the database, so they are stable, unique and parseable. They contain only characters WorldGuard allows. v1's `,` and an index `<n>` aren't used: an index would change when a part is removed.
- **API.** `IDomainRegionNameFinalizer` gets `FinalizeSubRegionAsync(subRegion, previousRegionId)`, which mirrors `FinalizeAsync`:
  - It runs only when `WgRegionId` starts with `tempregion_worldtask_`.
  - It calls `POST /Regions/rename` with `oldRegionId`, `newRegionId = domain_<d>_sub_<s>`, `domainType`, `parentRegionId = <the domain's main region>`, `world` and `replaceRegionId`.
  - `replaceRegionId` is the previous region, when it is the sub-region's own (its final name or a temp name that no other domain or sub-region uses). That is exactly KNG-103's `ReplaceableRegionAsync`.
  - On success it stores the final name. If the store fails it renames back. A failure never fails the save.
- **Plugin.**
  - `RegionRenamePlan.FINAL_NAME` becomes `domain_\d+(_sub_\d+)?`. The plan is otherwise unchanged: rename, replace in place, or rename and remove the previous temp region.
  - The rename request gets an optional `subRegionOf=<main region id>` so that `finalizeNewRegion` runs the sub-region path (§5.3 step 3).
  - How a plugin from before this change handles a `_sub_` target name is not verified; it doesn't know the mirror path in any case. So don't add sub-regions until the plugin is updated (§10). A rename that fails leaves the temp name, and `finalize-temp-names` retries it after the plugin update.
- **Re-running a sub-region's world task** ("Replace via Minecraft" in the child modal) works exactly like KNG-103: the new shape replaces `domain_<d>_sub_<s>` in place.
- **Re-running the main region** doesn't touch sub-regions. The renamer's existing re-link sets their parent to the new main region, because the name `domain_<id>` stays the same.
- **Select.** The world task's `select {region}` adopts an existing region as a sub-region. An example is a v1 `town_5,2` part (§10). On save it is **renamed** to `domain_<d>_sub_<s>`, so it falls under the orphan rules (decision Q-select). This differs from a selected main region, which KNG-103 keeps under its own name.
  - The finalizer runs for any sub-region whose `WgRegionId` isn't its final name yet, not only for temp names.
  - The previous name is not removed: the region is rebuilt under the new name, as a plain rename.
  - A region used as another domain's main region or sub-region can't be selected (uniqueness, §4.1).

## 7. Domain-level behaviour (R6, R9)

### 7.1 Region → domain resolution

- **Resolver.** `RegionDomainResolver` maps the main region and each sub-region id to the **same** `DomainSnapshot`. The lookup comes from `search-region-decisions`, which now also matches sub-regions (§4.2).
- **Snapshot.** The snapshot gets `regionIds` (all of the domain's regions). Its identity for set operations becomes the domain id: `DomainSnapshot` equality must not include `wgRegionId`. Either compare by id, or drop `wgRegionId` from the record and use a `Set<String> regionIds`.
- **Effect on transitions.** `SimpleRegionTransitionService.computeTransition` already works on sets of domains. With id-based identity, moving from the house into the tower changes nothing: there are no messages, no gate control and no discovery event.
- **Region-level events.** The per-region `OnRegionEnterEvent`/`OnRegionLeaveEvent` stay, because some listeners care about regions. New `OnDomainEnterEvent`/`OnDomainLeaveEvent` fire only when the domain set changes.
  - `DomainInteractionRecorder` (analytics) moves to the domain events.
  - `RegionTaskEventListener` stays on regions.
  - Audit every listener of the region events during implementation.
- **Other API consumers.** Discovery (KNG-20) grants per domain, so it works once the plugin reports the domain. Navigation's access borders and default destination region (KNG-73/92) use the domain's union of regions; review that during implementation.

### 7.2 Access enforcement (KNG-56)

**Problem.** Take a domain with `AllowExit=false`. Moving from its main region into its sub-region leaves the main region (deny exit) and enters the sub-region. `RegionAccessRules` would refuse it as an exit.

**Fix: a new custom flag `knk-domain-id`** (string), synced with the other access flags onto every region of a domain. `RegionAccessRules` then groups the entered and left regions by domain id:
- a domain is **left** only when none of its regions is in the destination set;
- a domain is **entered** only when none of its regions is in the origin set.

The flag lives on the region, so the rule keeps working at startup, at join and while the API is down. That was KNG-56's reason for flags.

- **Fallback.** A region without `knk-domain-id` (synced before the update) counts as its own domain, which is today's behaviour.
- **Clearing.** `AccessFlagSync` clears `knk-domain-id` together with the other access flags on regions no rule owns. Those are orphans: §8 makes them stop enforcing at once.

### 7.3 Messages

Enter/leave messages come from domain data through the transition service, so with §7.1 they are the same for every region of the domain. They are shown once per domain transition, not once per region. No WorldGuard greeting flags are introduced (managed-regions §5 decision). An admin's greeting on the main region is mirrored like any other flag.

## 8. Orphans and retention (R2, R11)

**Definition.** An orphan sub-region is a WorldGuard region named `domain_<d>_sub_<s>` that no domain lists in `subRegionIds` (§4.2). A sub-region becomes an orphan when:
- it is removed in the web app, or
- its domain is deleted, or
- a re-run replaced the region under a different name (not possible with §6, listed for completeness).

**What happens:**
1. **Detection: the access sync**, every 5 min, holding the complete list of domains and sub-regions. On first sight the sync:
   - clears the access flags and `knk-domain-id`, so the region no longer refuses anyone and no longer counts as the domain;
   - removes the region's parent link;
   - sets `knk-orphaned-since = <now millis>`.
   The region stays in WorldGuard.
2. **Deletion: the daily `TempRegionRetentionTask`.** It deletes the orphan when all of the following hold. These are the temp-region rules applied to sub-regions:
   - the name matches `domain_\d+_sub_\d+`;
   - the last access sync or repair didn't list it (and one has run);
   - `knk-orphaned-since` is older than the grace period (14 days, the temp-region cutoff);
   - a fresh `GET /Domains/by-region/{id}` returns 404.
   Without `knk-orphaned-since` the region is never deleted; the next sync stamps it. An API error keeps the region.
3. **Reporting.** `/knk regions temp` lists orphaned sub-regions with their age. `/knk regions temp purge [hours]` deletes those orphaned longer than `hours` (default 24, minimum 1), as for temp regions.
4. **Undo.** Within the grace period an orphan can be adopted again with `select domain_<d>_sub_<s>` in a new sub-region world task. The sync then clears `knk-orphaned-since`.

**Why the grace period counts from orphaning.** The temp-region rule counts from `knk-creation-timestamp`. The renamer copies that flag, so a finalized sub-region carries its creation time. Counting from creation would delete a sub-region removed today at once if it was drawn more than 14 days ago. §12 Q-orphan.

**What doesn't change.** Orphaned **main** regions (`domain_<id>` with no domain) stay report-only (managed-regions §8 item 9): they can collide with imported v2 names. Only the `_sub_` pattern, which v1 and v2 never used, is deleted automatically.

**Optional cleanup.** The 14-day cutoff hard-coded in `KnKPlugin.java:591` moves to config while touching this code (`regions.temp-retention.days`). Both rules use it.

## 9. Region shapes and containment (R7, R8)

### 9.1 Cylinders and other selections

WorldGuard has no cylinder region. `createRegionFromSelection` (used for main regions and sub-regions alike) changes as follows:
- **`CylinderRegion`** becomes a `ProtectedPolygonalRegion` over its circle, from min Y to max Y. The vertex count follows the radius: the block outline of the circle (Bresenham midpoint), so it matches the blocks WorldEdit's `//cyl` places. WorldGuard polygons have no vertex limit. The output mentions "cylinder → polygon with N points".
- **`EllipsoidRegion`** gets the same treatment over its horizontal ellipse. That over-covers the top and bottom, so the task shows a warning.
- **`ConvexPolyhedralRegion`** becomes a polygon over the 2D convex hull of its vertices.
- **Cuboid and poly2d** are unchanged.

`WorldGuardRegionRenamer` already supports polygonal regions, so rename and replace keep working. This also fixes the main region of any round domain.

### 9.2 Containment against a domain

Validation rules today name one region (`District.WgRegionId`, `GateStructure.WgRegionId`). They become **domain-aware**: when the dependency path ends in `WgRegionId` and the resolved entity is a domain, the rule's region set is the main region plus its sub-regions. The API sends `regionIds[]` in the world task's `validationContext` next to the existing single id, so older plugins keep working.

- **`LocationInsideRegion`**: the location is inside any of the regions. Example: a door location in the tower part of the garrison.
- **`RegionContainment`**: every block column of the drawn region must lie inside the union at the region's min and max Y. The check samples at 1-block steps. A region larger than 256×256 columns is sampled at a coarser step, and its edge is always sampled at 1 block. `requireFullContainment=false` keeps today's "overlap is enough" meaning.
- **A sub-region's own placement rule:**
  - It must be inside the **parent** domain (the District for a Gate), like the main region.
  - It must touch or overlap one of its own domain's regions: a warning, not a block. §12 Q-placement.
  - Overlap with its own domain's regions is allowed and expected.
- **Web app.** It shows the same rules in the form (KNG-187 wording).

## 10. Migration and existing data

- Existing domains get an empty `SubRegions`. Nothing changes for them; the first sync stamps `knk-domain-id`.
- v1 `<type>_<id>,<n>` parts that were imported with a domain can be adopted with `select` (§6). Without that they stay unmanaged, as today. A bulk import is not planned (§12 open note N3).
- After deploying the plugin before the API (or the other way round), all old behaviour still works:
  - an old API sends no `subRegionIds`, so the plugin manages no sub-regions and deletes nothing;
  - an old plugin ignores the new fields.
  Deploy both before adding the first sub-region.

## 11. Phases (Linear KNG-254 – KNG-259)

| Phase | Repo | Content |
|---|---|---|
| P1 [KNG-254](https://linear.app/kngpandi/issue/KNG-254) | knk-web-api | `DomainSubRegion` entity and migration, CRUD with access rules, uniqueness across both tables, finalizer for sub-regions and `finalize-temp-names`, DTO fields (`subRegions`, `subRegionIds`, `matchedSubRegionId`), lookups, form and display seeds, domain-aware `validationContext.regionIds`. Tests. |
| P2 [KNG-255](https://linear.app/kngpandi/issue/KNG-255) | knk-plugin | `RegionRenamePlan` name pattern and `subRegionOf`, sub-region specs in `DomainRegionSpecs`, `SubRegionMirror`, access sync over all regions plus `knk-domain-id`, `RegionAccessRules` per domain, `/knk regions sync`. Tests (core). |
| P3 [KNG-256](https://linear.app/kngpandi/issue/KNG-256) | knk-plugin | Resolver and snapshot identity by domain, `OnDomainEnter/LeaveEvent`, transition dedupe, listener audit (analytics, gate control, discovery, navigation). |
| P4 [KNG-257](https://linear.app/kngpandi/issue/KNG-257) | knk-plugin | Cylinder, ellipsoid and convex → polygon in `createRegionFromSelection`, domain-aware containment checks. |
| P5 [KNG-258](https://linear.app/kngpandi/issue/KNG-258) | knk-plugin | Orphan detection (`knk-orphaned-since`), retention task and `/knk regions temp` for sub-regions, configurable cutoff. |
| P6 [KNG-259](https://linear.app/kngpandi/issue/KNG-259) | knk-web-app + docs | Verify the owned-collection flow for `SubRegions` (likely seed-only), display; update `managed-worldguard-regions.md`, `domain-access-enforcement.md`, the admin guide; in-game checklist (garrison: house main region, cylindrical tower sub-region, gate door inside the tower, AllowExit=false domain walk-through). |

## 12. Decisions

All seven were asked through AskUserQuestion and decided by the developer on 2026-10-23. Each was decided as recommended.

| # | Question | Decision | Alternatives not taken |
|---|---|---|---|
| Q-sync | How a sub-region stays in sync | **Copy from the main region** (priority, all flags, owners/members) **plus parent = the main region** as a safety net (§5) | v1-style inheritance only |
| Q-orphan | Start of the 14-day grace period | **From orphaning**: `knk-orphaned-since`, access flags cleared at once, adoptable again until it is deleted (§8) | from `knk-creation-timestamp`; delete immediately |
| Q-placement | Must a sub-region touch the domain? | **Warning only.** It must still be inside the parent domain (§9.2) | refuse disconnected parts; no check |
| Q-shapes | Cylinder selections | **Auto-convert** cylinder/ellipsoid/convex to a polygon, for main regions too (§9.1) | manual `//sel poly` |
| Q-scope | Domain types | **All domain types** (base `Domain`, §4.1) | Structures and Gates only |
| Q-naming | Final name | **`domain_<domainId>_sub_<subRegionId>`** (§6) | `domain_<id>_<n>` |
| Q-select | Adopting an existing region with `select` | **Renamed to the final name** (§6) | kept under its own name |

Open notes, not blocking:
- **N1.** A maximum number of sub-regions per domain: none proposed.
- **N2.** Lootbox spawn areas and arena battlegrounds have their own region models and are out of scope.
- **N3.** A bulk import of v1 `town_<id>,<n>` parts: not planned, adopt by hand with `select`.

## 13. Implementation status (2026-10-23)

Branch `claude/domain-expansion-regions-s46gvf` in each repo; nothing merged. **Smoke test passed 2026-10-23** (developer, sections 0-7). One bug was found and fixed: a gate's edit form showed no sub-regions (`503c541`); re-check that one before merging. Check with the [smoke test](../../guides/domain-subregions-smoke-test.md); [admin guide](../../guides/admin/domain-subregions-admin-guide.md).

| Phase | Commit(s) | Tests |
|---|---|---|
| P1 API ([KNG-254](https://linear.app/kngpandi/issue/KNG-254)) | knk-web-api `7632c2f` | `dotnet test` 2905 passed, 4 failed: the known reds (`ClientActivityStore`, `PathResolution` ×2, `FieldValidation`) |
| P2 mirror, access ([KNG-255](https://linear.app/kngpandi/issue/KNG-255)) | knk-plugin `0ec8b8e` | Gradle core / api-client / paper all green (final: 2230 / 268 / 1983) |
| P3 resolution, events ([KNG-256](https://linear.app/kngpandi/issue/KNG-256)) | knk-plugin `f93758d`, knk-web-api `43e95dc` (discovery, analytics) | as above |
| P4 shapes, containment ([KNG-257](https://linear.app/kngpandi/issue/KNG-257)) | knk-plugin `5e4aa67` | as above |
| P5 orphans ([KNG-258](https://linear.app/kngpandi/issue/KNG-258)) | knk-plugin `808acc4`, `46f805e` (bookkeeping flags by name) | as above |
| P6 web app, docs ([KNG-259](https://linear.app/kngpandi/issue/KNG-259)) | knk-web-app `4b88565`, knk-web-api `6d438bf` (display seeds), `503c541` (gate edit form lists its sub-regions), this repo | web app: `tsc` clean outside 3 errors already in `sessionPinnedRows.test.ts`; util tests 316 passed |

**Changes against this design:**

- **§5.3 One mirror sets everything.** `SubRegionMirror` sets priority, parent, flags, owners and members; `DomainRegionSpecs` emits no sub-region specs. It runs after every access sync, so `/knk regions repair` covers sub-regions through the access sync it already runs. Right after a sub-region rename the plugin mirrors at once, and runs the access sync 5 s later: the API stores the final name only after the plugin answers.
- **§8 Orphans need two syncs.** A sub-region is marked only when two access syncs in a row don't list it, so a just-renamed one is never taken for an orphan.
- **§9.2 Containment without the API.** The domain's regions are found by the `knk-domain-id` flag (`DomainRegionUnion`), not by `validationContext.regionIds`. No web-app or API change was needed.
- **§9.2 Placement checks are not built.** "Inside the parent domain" and the touch warning moved to [KNG-261](https://linear.app/kngpandi/issue/KNG-261). One `DomainSubRegion` form serves every domain type, and there is no "touches" validation type yet.
- **§7.1 Snapshot identity.** `DomainSnapshot` is equal by domain id (no `regionIds` component was added). Analytics records domain enter/leave events by the main region id.
- **§7.1 Discovery and analytics.** The API resolves a sub-region id to its domain in discovery and in world-analytics ingestion.
- **Bookkeeping flags by name** (`46f805e`). WorldGuard keys flags by object, and `knk-creation-timestamp` and `knk-orphaned-since` were unregistered, so after a restart neither could be read back. Both are now read and written by name (`RegionBookkeepingFlags`) and registered in `onLoad`. This also likely fixes temp regions reported "without a creation time" after a restart. The mirror copies the main region's own flag objects, so a flag WorldGuard doesn't know no longer fails the copy.
- **Web app.** `findParentLinkField` links a child of any domain type through a field typed `Domain`. Before, it needed the exact parent type, so the sub-region form's `DomainId` would not have been filled in.
- **Display seeds.** Structure and GateStructure seed v2 list the sub-regions. Town and District have no display seed.
- **Navigation.** It still knows only the main region: [KNG-260](https://linear.app/kngpandi/issue/KNG-260).

**Before merging:**
- run the smoke test;
- apply the `DomainSubRegions` migration;
- import the seeds;
- deploy the API and the plugin together.

