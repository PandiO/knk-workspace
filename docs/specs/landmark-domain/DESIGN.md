# Landmarks as a Domain subtype — sub-regions, entry and exit, warps and domain lists for landmarks

**Status:** **Decided 2026-11-22** (developer). Phases as sub-issues in § 11. Phase 1 (#983) built on knk-web-api `claude/landmark-domain`, in review.
**Last updated:** 2026-11-22 (phase 1 built by link L1, #983, in review); 2026-11-22 (approved by the developer; LD25 and the final phases added on approval); 2026-11-22 (design session: decisions LD01–LD10 from the developer, LD07 and LD11–LD24 agent).
**Issue:** [PandiO/knk-workspace#976](https://github.com/PandiO/knk-workspace/issues/976); phases as sub-issues in § 11.
**Dependencies:** the landmark entity (#708, on `next`, not promoted), landmark weights (#709), landmark and production
area drawn regions (#944, #945, #946, on `next`), domain sub-regions
([domain-subregions/DESIGN.md](../domain-subregions/DESIGN.md), on trunk).
**Authority:** the developer's messages and answers of 2026-11-22 in the design session (§ 2). This design supersedes
[navigation-offroad/DESIGN.md](../navigation-offroad/DESIGN.md) § 6.1 items 1 and 2 ("a separate entity", "It is not
a domain"), § 6.3 (the `landmarks` table and the Radius extent) and the radius form of `/knk landmark create` in
§ 4 item 5; the rest of § 6 stands. It also changes the landmark part of #945 (drawn landmark regions are named like any
domain's). This document is the canonical specification, not a claim that the proposed entities, endpoints or
behaviour exist.

Related: [navigation-offroad/DESIGN.md](../navigation-offroad/DESIGN.md) § 6 and § 10.1,
[domain-subregions/DESIGN.md](../domain-subregions/DESIGN.md),
[domain-discovery/DESIGN.md](../domain-discovery/DESIGN.md), [teleport/DESIGN.md](../teleport/DESIGN.md),
[architecture/domain-access-enforcement.md](../../architecture/domain-access-enforcement.md),
[architecture/managed-worldguard-regions.md](../../architecture/managed-worldguard-regions.md).

## 1. Goal and scope

1. **Goal:** a landmark is a domain. Staff get sub-regions, entry and exit rules, warps and the domain lists and
   pickers for landmarks through the same code as towns, districts and structures. A landmark still works as a point
   without any region, never becomes an effect-damage safe zone, and can borrow the area of the domain it is linked
   to.
2. **In scope (v1):**
    1. `Landmark` as a TPT subtype of `Domain`; `Domain.WgRegionId` nullable for landmarks only (LD01, LD02, LD11).
    2. Three area kinds: none (a point), its own region with sub-regions, or the linked domain's area (LD06–LD08,
       LD16).
    3. The linked domain as the parent in the domain hierarchy, no containment check (LD09); a generic parent walk
       that also ends the CrownLand loop (LD23).
    4. Entry and exit flags, optional enter and leave messages, optional discovery, warps (LD01, LD05, LD15, LD21).
    5. No effect-damage safe zone from landmarks (LD03, LD12).
    6. Domain region handling: `domain_<id>` names, sub-regions, the LANDMARK managed-region kind, cleanup (LD13,
       LD14).
    7. Domain lists and pickers with landmarks; the landmark API kept; generic domain writes guarded (LD19, LD20).
    8. Navigation on the new model: arrival and weights over the union of the area's regions (LD22).
    9. A migration that drops the existing landmark rows (LD10).
3. **Out of scope:**
    1. Mirroring the linked domain's region into a region of the landmark's own (LD07 alternative (a)); a later
       second mode if needed.
    2. A per-landmark switch to make a landmark a safe zone (LD12 alternative (a)).
    3. Landmarks on the overview map (the map shows towns, districts and structures; a landmark layer is a later
       issue).
    4. The plaza landmark kind (#714), which keeps its `Kind` column.
    5. Filling Area from Region id automatically (#975).

## 2. Decision log

| ID | Date | Who | Decision |
|---|---|---|---|
| LD01 | 2026-11-22 | developer | `Landmark` becomes a subtype of `Domain` (knk-web-api TPT hierarchy), reversing off-road § 6.1. Wanted from the domain side: entry and exit flags, the domain lists and pickers, the teleport engine, the domain region handling and sub-regions, "without having to add dupe code". |
| LD02 | 2026-11-22 | developer | A landmark's region stays optional: a point-only landmark is valid. |
| LD03 | 2026-11-22 | developer | A landmark must not automatically become an effect-damage safe zone ("the no effect damage is not great to automatically have"). |
| LD04 | 2026-11-22 | developer | ~~A landmark must be able to use a region another domain owns ("one owner per region is also not desired").~~ Superseded by LD06. |
| LD05 | 2026-11-22 | developer | Question 1, entering a landmark's area: "Optional messaging, optional discovery". Enter and leave messages and discovery are both opt-in per landmark; a landmark that has neither is silent (entry and exit rules still apply). |
| LD06 | 2026-11-22 | developer | Question 2, using another domain's region: "A landmark has its own region, and can be linked to a domain type. We can add an option in the FormConfig that would allow the landmark to mirror the linked domain's region (or just point to that domain's region)." A landmark owns its own region (with sub-regions) or none; an option on the landmark form makes the linked domain's area its area instead. |
| LD07 | 2026-11-22 | agent | LD06's option **points to** the linked domain's area (its main region and sub-regions, read live); it does not mirror (copy) the geometry into a region of the landmark's own (alternatives in 2.1). |
| LD08 | 2026-11-22 | developer | Question 3, the radius area: "I'd say we drop radius and have the worldguard region cover this, so cylinder regions are allowed." `ExtentKind` Radius and the `Radius` field go; a round area is a cylinder-shaped WorldGuard region drawn with a cylinder selection (domain sub-regions § 9.1 already turns `//sel cyl` into a cylinder-shaped polygon region). |
| LD09 | 2026-11-22 | developer | Question 4, the linked domain: "Parent, no containment check". The linked domain is the landmark's parent in the domain hierarchy (region decisions, the WorldGuard parent and priority of the landmark's region). The landmark's own region may reach outside its parent; nothing checks containment. A landmark without a link is top level. |
| LD10 | 2026-11-22 | developer | Question 5, existing landmark rows: "Drop and recreate". The migration drops the rows of the `landmarks` table (only the dev DB has any; #708 is not promoted); the developer recreates the test landmarks by hand. |
| LD11 | 2026-11-22 | agent | `Domain.WgRegionId` becomes nullable. Every other subtype's service keeps requiring a region; only `LandmarkService` allows none (alternatives in 2.1). |
| LD12 | 2026-11-22 | agent | Landmarks never count for the effect-damage rule: `DomainEffectDamage` looks only at the other domains at the spot, so a landmark in a town keeps the town's rule and one in the wilderness keeps normal damage (alternatives in 2.1). |
| LD13 | 2026-11-22 | agent | A LANDMARK managed-region kind: WorldGuard parent = the parent domain's main region (top level without one), priority parent + 10 (floor as STRUCTURE), no category flags. Landmarks take part in the startup repair, `/knk regions repair`, the sub-region mirror and the access-flag sync like every domain. |
| LD14 | 2026-11-22 | agent | A drawn landmark region is named like any domain's: `domain_<id>`, sub-regions `domain_<id>_sub_<n>`. The landmark path of #945 (`landmark_<id>`, the landmark owner in the region finalizer and the plugin's landmark usage lookup) is removed; production areas (#946) keep the generic owner lookup. |
| LD15 | 2026-11-22 | agent | LD05's options: a landmark column `ShowEnterLeaveMessages` (default off) for the messages; discovery through a `Landmark` type rule that is off and the existing per-domain discovery override, no landmark column. |
| LD16 | 2026-11-22 | agent | The area kind is a landmark column `AreaKind` with `None`, `OwnRegion` and `LinkedDomain` (replacing `ExtentKind`); the own region is `Domain.WgRegionId` (the old `RegionId` column goes). `LinkedDomain` needs a parent with a region. |
| LD17 | 2026-11-22 | agent | The pin: a landmark always has `Domain.LocationId`, its own Location. A pin taken from a domain's spawn is copied, because a Location belongs to one domain (unique index). |
| LD18 | 2026-11-22 | agent | Name: at most 100 characters and unique per world among landmarks, checked by `LandmarkService` as today; the domain name rules apply on top. |
| LD19 | 2026-11-22 | agent | `api/landmarks` stays the landmark API (anonymous reads, landmark DTO, `knk.admin.world.landmark` writes), now on the Domain hierarchy. `PUT` and `DELETE api/Domains/{id}` on a landmark answer 403 unless the caller holds the landmark write rights, and run the landmark rules through `LandmarkService`. |
| LD20 | 2026-11-22 | agent | Domain lists and pickers include landmarks with a type column and a type filter; a landmark's parent picker leaves out the landmark itself and its descendants. |
| LD21 | 2026-11-22 | agent | Warps use the domain teleport fields (TeleportEnabled off by default); `/warp` lists them with the type word `landmark`. "Requires discovery" only unlocks once the landmark's discovery is on. |
| LD22 | 2026-11-22 | agent | Navigation: `LandmarkProvider` stays the one landmark destination source (the catalogue keeps skipping landmarks); arrival and route weights use the union of the area's regions (own main region and sub-regions, or the parent's in `LinkedDomain`); a point-only landmark arrives within `arrive-distance`. Landmark changes reach the plugin through realtime like other domain changes. |
| LD23 | 2026-11-22 | agent | One parent walk for every domain type (a `ParentDomain` resolution per subtype, landmark included, with a cycle guard), used by the region decisions, the region finalizer's hierarchy and the repository's parent loading. It also ends the CrownLand loop in `GetParentDomainDecisions`. A landmark's parent may be any domain, also another landmark. |
| LD24 | 2026-11-22 | agent | No new feature flag: every domain behaviour of a landmark is off or neutral by default (entry and exit allowed, messages off, discovery off, warp off), and navigation keeps `navigation.landmarks`. The schema change makes the API phase `tier:3`. |
| LD25 | 2026-11-22 | agent | The new Landmark form ships as seed v2 (a new `configurationGuid`, default for Landmark) in phase 1, so the form on `next` matches the model as soon as the model changes. Existing Landmark configurations are not deleted; the developer's edited dev form (with the Region id projection of 2026-11-22) is superseded and its projection is not carried over (#975). |

### 2.1 Agent decisions: alternatives

1. **LD07 point to, not mirror.** Chosen: the landmark's area is the linked domain's main region plus its sub-regions,
   read from that domain each time (navigation arrival and weights). The landmark owns no region in this mode, so
   no ownership conflict arises and nothing has to be kept in sync. Entering that area is entering the linked
   domain: its messages, discovery and entry and exit rules apply, not the landmark's (LD05's options do nothing in
   this mode, and the form hides them).
    1. (a) Mirror: copy the linked domain's region geometry into a region the landmark owns (`domain_<landmarkId>`),
       with its own flags, messages and discovery. Why not now: the copy has to follow every edit of the original
       (main region and each sub-region, re-runs, renames, deletes), which is the same work the sub-region mirror
       does for flags, plus geometry. Two regions with the same shape also stack their entry and exit rules. It can be
       added later as a second mode if a landmark needs its own messages over an existing area.
    2. (b) A free region reference (today's `RegionId`, any region): drops the domain link and can point at a single
       sub-region, but needs its own lookup path in navigation and the cleanup, which the developer's answer did not
       ask for.
2. **LD11 nullable `WgRegionId`.** Chosen: a nullable column; the other subtypes' services keep requiring a region,
   and the plugin's region code already skips domains with a blank region (access rules, sync, map, cleanup).
    1. (a) An empty string for "no region": no schema change, but empty strings would compete in the one-owner check
       and every reader has to treat `""` and null alike.
    2. (b) A separate "has region" flag: duplicates what null already says.
3. **LD12 effect damage.** Chosen: the rule leaves landmarks out, so they never change damage at a spot.
    1. (a) A per-landmark "safe zone" switch: possible later (out of scope 3.2); nobody asked for it.
    2. (b) Seed `knk-effect-damage allow` on landmark regions: a landmark inside a town would then turn damage back on
       inside the town, because its region has the higher priority.
4. **LD13 managed-region kind.** Chosen: a LANDMARK kind with the child priority rule and no flags, so a landmark's
   region inherits its parent's flags through the WorldGuard parent and doesn't set its own.
    1. (a) Leave it to `fromDomainType`'s default (STRUCTURE): wrong kind in the logs, and a STRUCTURE floor priority
       and flag set nobody chose for landmarks.
    2. (b) Keep landmark regions out of the managed regions: no repair, no parent, and the cleanup would not know them.
5. **LD14 region names.** Chosen: the domain names, so one rename path, one usage lookup (`by-region`) and the
   existing sub-region names.
    1. (a) Keep `landmark_<id>`: a second name pattern in `RegionRenamePlan`, the orphan check and the scenarios,
       for no gain once a landmark is a domain.
6. **LD15 storage of the options.** Chosen: one column for messages, discovery through its existing type rule and
   per-domain override.
    1. (a) A messages switch on every domain: changes towns and districts, which show messages today.
    2. (b) A landmark discovery column: duplicates the override, which already turns discovery on or off per domain.
7. **LD16 area kind.** Chosen: `None`, `OwnRegion`, `LinkedDomain`; the region itself in `Domain.WgRegionId`.
    1. (a) Keep `ExtentKind` with a new value: its `Radius` value goes (LD08), so a rename costs nothing and says what
       it means.
    2. (b) Derive the kind (no region and a parent = linked): can't tell a point-only landmark with a parent from a
       landmark that borrows its parent's area.
8. **LD17 the pin.** Chosen: always its own Location.
    1. (a) Make `Domain.LocationId` non-unique: changes every domain's spawn rule for one landmark case.
9. **LD18 name rule.** Chosen: keep the landmark rule (100, unique per world) in the service.
    1. (a) Only the domain rules: drops a rule the off-road design decided (§ 6.3).
10. **LD19 generic domain writes.** Chosen: 403 without the landmark rights, and the landmark rules when allowed.
    1. (a) Refuse every generic write on a landmark: the domain dashboard's edit would break for landmarks.
    2. (b) Allow with the domain rights: skips `knk.admin.world.landmark` and the landmark checks (O26).
11. **LD20 lists and pickers.** Chosen: a type column and filter.
    1. (a) Hide landmarks from domain lists: the developer asked for them there (LD01).
12. **LD21 warps.** Chosen: the domain teleport fields, off by default.
    1. (a) A separate landmark warp: the duplicate code LD01 wants to avoid.
13. **LD22 navigation.** Chosen: `LandmarkProvider` as the only source.
    1. (a) Let the catalogue list landmarks as domains too: every landmark would show twice in `/navigate`.
14. **LD23 parent walk.** Chosen: one walk with a per-subtype parent.
    1. (a) Add a landmark case to each of the five walks: keeps five copies of the same loop, one of which already
       loops forever for CrownLand.
    2. (b) Forbid landmark parents that are landmarks: nothing breaks with a cycle guard, and a "Throne room" inside a
       "Palace" landmark is a natural case.
15. **LD24 flag.** Chosen: no new flag, because every landmark behaviour is off or neutral until staff set it.
    1. (a) A `landmarks.domain` flag: the schema change can't be switched off, and a flag would only hide settings.
16. **LD25 form seed v2.** Chosen: a v2 seed in the model phase, because the v1 form names fields the model drops (`ExtentKind`, `RegionId`, `Radius`) and an import never overwrites an existing configuration.
    1. (a) Change v1 in place: databases that imported it keep the broken form.
    2. (b) Seed in a later phase: the Landmark form on `next` is broken between the two merges.

## 3. Current state and legacy behaviour

1. **Built today (V3, `next`):**
    1. knk-web-api: `Models/Landmark.cs` (own table `landmarks`, migration `20261118152046_AddLandmarks`, only on
       `next`): Name (100, unique per world of the pin), a required `LocationId` (the pin, may be shared with a domain's
       spawn), optional `DomainId` link (SetNull), `ExtentKind` None/Region/Radius, `RegionId` (any region, also one a
       domain owns), `Radius` (cylinder), `Preference`, `NavigationEnabled`, `Kind` (General; Plaza later, #714).
       `LandmarkService`, `api/landmarks` (anonymous reads with the `map` rate limit, writes with
       `knk.admin.world.landmark`), the region finalizer's landmark path (`landmark_<id>`, #945).
    2. `Domain` (`Models/Domain.cs`, TPT, no discriminator, the type is the CLR type): Name, Description (required),
       AllowEntry/AllowExit, `WgRegionId` (NOT NULL), WorldName, IsHub, `LocationId` (nullable, unique one-to-one),
       five teleport fields, NavigationDefaultOverride, RoadAccessOverride, `SubRegions`. Parent links live on the
       subtypes (District.TownId, Structure.DistrictId/TownId). One region belongs to at most one domain per world
       (`DomainRegionOwnership`). `Mapping/DomainMappingProfile.GetParentDomainDecisions` never ends for a type other
       than Town, District or Structure (CrownLand today).
    3. knk-plugin: `LandmarkExtent` (region or cylinder), `LandmarkProvider` (`landmark:<id>`), `ModelLandmarks`,
       `/knk landmark` (`LandmarkAdminCommand`); domain side: `RegionDomainResolver`, `AccessFlagSync`
       (`knk-allow-entry`/`-exit`, `knk-domain-id` per region), `SubRegionMirror`, `DomainEffectDamage` (no effect
       damage inside any domain, #162), `SimpleRegionTransitionService` (messages for town, district, structure),
       `ManagedRegionKind.fromDomainType` (unknown types become STRUCTURE), discovery, warps (`WarpTargets`),
       the realtime router (catalogue and region cache only for Town, District, Structure).
    4. knk-web-app: landmark list and form (seed `Landmark.json`), `DomainLandmarksPanel` on domain pages, domain
       lists and pickers (no type column), `DOMAIN_ENTITY_TYPES` in `utils/forms/domainWorld.ts`.
2. **V1/V2:** v1 had general warp points (`/point`, alias `/warp`, `SpawnPoints/SpawnPointCommands.java`, legacy
   commands-v1 § 8): named points with a gem price and title gate, listed by `/point list`. The v3 teleport port kept
   only domain warps and dropped the general points (teleport DESIGN). Landmark warps bring them back as domains
   (kept, as a domain feature). No v1 or v2 landmark entity existed.
3. **Related open work:** #708 and #709 (landmark entity and weights, in review on `next`), #714 (plaza landmark kind,
   later), #945/#946 (drawn regions, in review), #974 (their docs), #975 (auto-projection), the CrownLand loop in
   `GetParentDomainDecisions` (#981; LD23 replaces the walk, #981 can land first).
4. **Vision.** § 2.5 prefers "inheritance for type identity, interfaces/composition for behavior". A landmark is a
   named place of the world like the other domains, so it takes the type identity; the behaviours it gets are the
   domain's own, switched per landmark (LD24).

## 4. Player and admin experience

1. **Creating a landmark (web app).** The landmark form keeps its steps (name, pin, parent, preference, navigation)
   and gains the domain steps:
    1. **Area:** `None` (a point), `Own region` (draw or select a region with the region task; a `//sel cyl` selection
       makes a round region), or `Linked domain's area` (only offered when the parent has a region).
    2. **Sub-regions:** with `Own region`, the domain sub-region step (draw more regions; they count as one area).
    3. **Access:** Allow entry, Allow exit (both on by default), with an own region.
    4. **Messages and discovery:** "Show enter and leave messages" (off) and the discovery override (off), with an
       own region.
    5. **Warp:** the domain teleport fields (off by default).
2. **In game.** `/knk landmark create <name> [region <id>]` at the admin's position (the `radius` form is gone,
   LD08); `link <landmark> <domain>` sets the parent, `unlink` removes it; `list`, `show`, `move`, `delete` as today.
3. **Domain dashboard.** Landmarks appear in the domain list with the type "Landmark" and can be filtered; opening one
   opens the landmark form. Domain pickers list landmarks too, with their type.
4. **Players.**
    1. Walking into a landmark's own region: the entry and exit rules apply; a message shows only when the landmark's
       messages are on; discovery happens only when its override turns it on.
    2. `/warp landmark:<name>` (and the warp menu) for a landmark with its warp on, with its price and title lock.
    3. `/navigate <landmark>` as today; arrival counts anywhere inside the landmark's area (own region and sub-regions,
       or the parent's area), otherwise within `arrive-distance` of the pin.
5. **Permissions.** Landmark writes keep `knk.admin.world.landmark` (O26) with `knk.admin.content` and
   `knk.admin.delete`, also through `api/Domains` (LD19). Warps follow the teleport permissions.

## 5. Rules

1. **Subtype (LD01).** A landmark is a `Domain`; every domain list, lookup and event includes it unless a rule below
   says otherwise.
2. **Region optional (LD02, LD11).** A landmark may have no region; every other domain type keeps requiring one.
3. **Area kinds (LD06–LD08, LD16).**
    1. `None`: the area is the pin; no region, no sub-regions, no access flags.
    2. `OwnRegion`: the landmark owns `WgRegionId` and its sub-regions, under the one-owner rule like any domain.
    3. `LinkedDomain`: the area is the parent's main region and sub-regions; the landmark owns no region. Saving fails
       without a parent, or with a parent that has no region.
    4. A change of kind away from `OwnRegion` orphans the landmark's regions under the existing orphan and retention
       rules (domain sub-regions § 8).
4. **Parent (LD09, LD23).** The linked domain is the parent. No containment check. The parent walk guards against
   cycles; a landmark can't be its own ancestor.
5. **Effect damage (LD03, LD12).** A landmark never makes a spot free of effect damage, and never turns it back on.
6. **Messages and discovery (LD05, LD15).** Off unless switched on per landmark. In `LinkedDomain`, the parent's own
   messages and discovery apply.
7. **Entry and exit (LD01).** A landmark with an own region gets the domain access flags like any domain; the
   defaults allow both.
8. **Region names and cleanup (LD13, LD14).** Drawn regions become `domain_<id>` and `domain_<id>_sub_<n>`;
   regions already named `landmark_<n>` in a world stay as they are (they are no longer used after LD10).
9. **Warps (LD21).** As any domain's; "requires discovery" needs the landmark's discovery on.
10. **Navigation (LD22).** One destination per landmark (`landmark:<id>`); arrival and weights over the area's union.
11. **Writes (LD19).** Generic domain writes on a landmark need the landmark rights and run the landmark rules.
12. **Migration (LD10).** Existing landmark rows are dropped.

## 6. Data and API

1. **Entities and fields (knk-web-api), not additive:**
    1. `Landmark : Domain` (TPT, table `landmarks` keyed by the domain id). Moves to `domains`: Name, LocationId (the
       pin), CreatedAt, the region (`WgRegionId`). Stays on `landmarks`: `AreaKind` (None, OwnRegion, LinkedDomain),
       `ParentDomainId` (the former `DomainId`, SetNull), `Preference`, `NavigationEnabled`, `Kind`,
       `ShowEnterLeaveMessages`. Removed: `ExtentKind`, `RegionId`, `Radius`. Kept: `CK_landmarks_Preference_Range`.
    2. `Domain.WgRegionId` nullable (LD11).
    3. Migration: drop the `landmarks` rows (LD10), rebuild the table as a TPT child, alter `domains.WgRegionId`; a
       working Down for the migrations workflow.
    4. Discovery: a `Landmark` type rule, disabled (LD15).
2. **Endpoints:**
    1. `api/landmarks` (GET list and by id anonymous with the `map` rate limit, `POST search`, `POST/PUT/DELETE` with
       the landmark rights) stays; DTOs gain the domain fields (access, warp, messages, area kind, sub-region ids).
    2. `api/Domains` lists, search and lookups include landmarks with `domainType = "Landmark"`; `PUT/DELETE` on a
       landmark follow LD19.
    3. `search-region-decisions` and `by-region` resolve landmark regions and sub-regions with their parent chain
       (LD23); the catalogue search marks the type so the plugin can skip it (LD22).
    4. Pinned access tests updated: `EndpointAccessRulesTests`, `ReadAccessRulesTests`, `DashboardAccessTests`,
       `DeleteAccessRulesTests`, `DashboardChangeAccessRulesTests`, `LookupFiltersTests`.
3. **Web app:**
    1. Landmark DTOs extend the domain base DTO; `DOMAIN_ENTITY_TYPES` gains `landmark` (world prompt, sub-region
       parent link).
    2. Domain list: a type column and filter; pickers show the type (LD20).
    3. `DomainLandmarksPanel` lists a domain's child landmarks and doesn't show on a landmark's own page as a list of
       itself.
    4. Seed `Landmark.json`: the steps of § 4.1, Area as an enum `AreaKind`, the region task on `WgRegionId`; a
       Landmark display seed.

## 7. Plugin

1. **`knk-core` (Bukkit-free):**
    1. `ManagedRegionKind.LANDMARK` and its spec in `DomainRegionSpecs` (LD13).
    2. `DomainEffectDamage`: leave out landmark domains (LD12).
    3. Transition messages: a landmark case driven by its `showEnterLeaveMessages` (LD15).
    4. `LandmarkExtent`: a point or a union of region shapes (own main region and sub-regions, or the parent's), the
       cylinder test removed (LD08, LD22); `LandmarkProvider` keys from the new ids.
    5. Discovery and warp wording for landmarks (`DiscoveryMessages`, `DiscoveryRow`, `DiscoveriesView`, warp rows).
    6. `RegionRenamePlan` and `TempRegionCleanupPolicy`: the `landmark_<id>` pattern and the landmark usage lookup
       removed (LD14).
2. **`knk-paper` adapters:**
    1. `/knk landmark`: no radius; `link` sets the parent and leaves the landmark itself out of the candidates.
    2. Realtime: `Landmark` changes clear the domain catalogue and region cache and refresh the navigation model
       (LD22).
    3. The startup repair and map reporting read landmarks with the other domains (LD13).
    4. `SimpleRegionTransitionService`: the null-unsafe `equals("gate")` fixed while the type cases change.
3. **Configuration:** no new keys (LD24); `navigation.landmarks` unchanged.

## 8. Platform-specific parts

| Part | Why platform-specific | Lives in | Port in `knk-core` |
|---|---|---|---|
| Landmark region shapes (own, sub-regions, parent's) | WorldGuard regions | `knk-paper` `WorldGuardRegionShapes` | `RegionShapes` (exists) |
| Access flags, sub-region mirror, managed regions for landmarks | WorldGuard flags and parents | `knk-paper` `AccessFlagSync`, `SubRegionMirror`, managed-region adapter | `ManagedRegionPolicy` (exists) |
| Effect damage | Paper damage events | `knk-paper` listener | `DomainEffectDamage` (rule) |
| Enter and leave messages | Paper chat and titles | `knk-paper` message sink | transition service (exists) |
| Warps | Paper teleport | `knk-paper` teleport adapter | teleport engine (exists) |
| Cylinder region from a selection | WorldEdit selections | `knk-paper` `WorldGuardIntegration` | none: no game logic |

## 9. Risks and integration checks

1. **Every place that lists all domains** now sees landmarks: dashboards, pickers, warps, navigation catalogue, region
   decisions, analytics, road seeds, world backfill, hub settings, storage holders. Check each against § 5 (the
   feasibility sweep of 2026-11-22 lists them; § 3.1).
2. **A region outside its parent (LD09)** still has the parent as WorldGuard parent and inherits its flags (for
   example a town's `pvp deny`) where it reaches outside the town. This is the developer's choice; the form says so.
3. **Ids change (LD10)**: the dev DB loses its landmarks; `landmark:<id>` keys in saved navigation state stop
   resolving. Only `next` and the dev DB are affected.
4. **Nullable `WgRegionId`**: readers that assume a region (the hub, the subtype services) keep their own check; the
   C# DTOs change to `string?`. Check every `WgRegionId` read in the API and the plugin's DTO mapping.
5. **The parent walk (LD23)** replaces code on the hot path of `search-region-decisions`; cover every subtype with
   tests, CrownLand included.
6. **The off-road chain (#698)**: its smoke § 6 (landmarks) runs on the new model after this; #709's weights read
   `LandmarkExtent`.

## 10. Acceptance checklist

| ID | Check | Phase |
|---|---|---|
| A01 | A landmark is created through `api/landmarks` (and the v2 form) with no region and saved as a `Domain` of type Landmark; a Town without a region is still refused. | 1 |
| A02 | The migration applies on a database with landmark rows (they are dropped) and on a fresh database, and its Down works. | 1 |
| A03 | `AreaKind = LinkedDomain` saves only with a parent that has a region; the landmark then owns no region. | 1 |
| A04 | A drawn landmark region is renamed `domain_<id>`; a landmark sub-region becomes `domain_<id>_sub_<n>`. | 1 |
| A05 | `search-region-decisions` and `by-region` for a landmark region, a landmark sub-region and a crown land region return with their parent chain and end. | 1 |
| A06 | `PUT`/`DELETE api/Domains/{id}` on a landmark answer 403 without `knk.admin.world.landmark` and apply the landmark rules with it. | 1 |
| A07 | Domain list and search show landmarks with the type Landmark; the type filter works. | 1, 3 |
| A08 | Discovery has a disabled Landmark rule; a landmark with its override on is discoverable, one without is not. | 1, 2 |
| A09 | A landmark with its warp on is a `/warp landmark:<name>` target with its price; with "requires discovery" it unlocks after discovery. | 1, 2 |
| A10 | A landmark's own region gets the access flags and `knk-domain-id`; with Allow entry off a player is kept out. | 2 |
| A11 | Fire, lava and poison damage inside a wilderness landmark region hurt as outside; inside a landmark in a town they don't, as in the town. | 2 |
| A12 | With messages off, entering a landmark region shows nothing; with messages on, the enter and leave messages show once per crossing, not when moving between its sub-regions. | 2 |
| A13 | A landmark region's managed kind is LANDMARK: WorldGuard parent = the parent's main region, priority parent + 10, no category flags; the repair restores it. | 2 |
| A14 | `/navigate` lists each landmark once; arrival counts inside a landmark sub-region, and inside the parent's area for `LinkedDomain`. | 2 |
| A15 | `/knk landmark create <name> radius <n>` is refused with the usage line; `link` sets the parent and doesn't offer the landmark itself. | 2 |
| A16 | A `Landmark` change in the API reaches the plugin's catalogue, region cache and navigation model within the realtime path. | 2 |
| A17 | The landmark form offers None, Own region and Linked domain's area; sub-regions, access, messages, discovery and warp show with Own region only. | 3 |
| A18 | Domain pickers show landmarks with their type; a landmark's parent picker leaves out the landmark and its descendants. | 3 |

## 11. Phases

Decided 2026-11-22. Each phase merges into `next` on its own; no flag (LD24).

| Phase | Scope | Acceptance | Repos | Tier | Flag | Sub-issue | Depends on |
|---|---|---|---|---|---|---|---|
| 1 | API model: `Landmark : Domain` (TPT), nullable `WgRegionId`, the migration (rows dropped), `AreaKind`, the parent (`ParentDomainId`) and one parent walk, `LandmarkService` and `api/landmarks` on the hierarchy, drawn regions as `domain_<id>`, guarded `api/Domains` writes, the pinned access tests, the Landmark form and display seeds v2 | A01–A06 | knk-web-api | tier:3 | none | #983 | #981 can land first |
| 2 | API integration: domain lists and search with the type and a type filter, the disabled `Landmark` discovery rule with the per-landmark override, warps with the type word `landmark`, landmark entries in the realtime change map | A07, A08 and A09 (API side) | knk-web-api | tier:2 | none | #984 | 1 |
| 3 | Plugin: LANDMARK managed kind, effect damage without landmarks, opt-in messages, discovery and warp wording, the landmark area as a union of regions, `/knk landmark` without radius and with `link` as parent, realtime for landmarks, the `landmark_<id>` path removed | A08–A16 (plugin side) | knk-plugin | tier:2 | none | #985 | 1, 2 |
| 4 | Web app: landmark DTOs on the domain base, `DOMAIN_ENTITY_TYPES`, the type column and filter in domain lists, pickers with the type and the parent picker without the landmark itself, `DomainLandmarksPanel`, the landmark list columns, e2e | A07, A17, A18 | knk-web-app | tier:2 | none | #986 | 1, 2 |

Smoke test: [guides/landmark-domain-smoke-test.md](../../guides/landmark-domain-smoke-test.md).

## 12. Open questions

None. The developer approved the design with the agent decisions LD07 and LD11–LD25 on 2026-11-22.

### After v1

1. A mirror mode for the linked domain's region (LD07 (a)), if a landmark needs its own messages over an existing
   area.
2. A per-landmark safe-zone switch (LD12 (a)).
3. Landmarks on the overview map.
4. The plaza landmark kind (#714).
