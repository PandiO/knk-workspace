# API Contract: Landmarks as domains (`api/landmarks`, landmark parts of `api/Domains`)

**Status:** Current · **Last updated:** 2026-11-22 (first version, landmarks as a Domain subtype #976, docs PandiO/knk-workspace#1008)
**Checked against:** knk-web-api `next` `3bc3cfd5` (PRs PandiO/knk-web-api#82, #84, #85; `Controllers/LandmarksController.cs`,
`Controllers/DomainsController.cs`, `Dtos/LandmarkDtos.cs`, `Services/LandmarkService.cs`,
`Repositories/DomainRepository.cs`), knk-plugin `next` `14645895` (the region task's `bounds`). Not released.
**Related:** [design](../landmark-domain/DESIGN.md) § 6, [landmarks admin guide](../../guides/admin/landmarks-admin-guide.md),
[managed WorldGuard regions § 7](../../architecture/managed-worldguard-regions.md),
[smoke test](../../guides/landmark-domain-smoke-test.md) §§ 1–2 (every endpoint with an example)

## 1. Model

`Landmark : Domain` (TPT; table `landmarks` keyed by the domain id). On `domains`: Name, Description, `LocationId`
(the pin; a landmark always has its own Location), `WgRegionId` (**nullable**; every other domain type still requires
it, a plain domain write without it answers 400 "WgRegionId is required."), AllowEntry/AllowExit, the five teleport
fields, sub-regions. On `landmarks`: `AreaKind`, `ParentDomainId` (SetNull), `ShowEnterLeaveMessages`, `Preference`
(0.25–4.0, default 1.0), `NavigationEnabled`, `Kind` (`General`). Migrations: `20261122164836_LandmarkAsDomain` (not
additive, drops every landmark row) and `20261122184739_AddLandmarkDiscoveryRule` (data only).

| `AreaKind` | Rule |
|---|---|
| `None` | A point: no region, no sub-regions. |
| `OwnRegion` | Needs `wgRegionId` (a drawn temp region, renamed `domain_<id>` on save, or an existing region no other domain holds; at most 128 characters): "Area Own region needs a region: draw one or name an existing region." |
| `LinkedDomain` | Needs a parent with a region; owns none: "Area Linked domain's area needs a parent with a region." |

Other rules (all 400): name at most 100 characters and unique per world of the pin among landmarks ("A landmark named
"…" already exists in world …"); the parent may be any domain, another landmark too, but not the landmark itself ("A
landmark can't be its own parent.") or a descendant ("Domain <name> (#<id>) is inside this landmark: a landmark can't
be its own ancestor."); a radius is refused ("The radius area is gone: draw a round region with //sel cyl instead.").
A pin given as another domain's `locationId` is copied to a new Location.

## 2. `api/landmarks`

| Method and route | Access | Body / answer |
|---|---|---|
| `GET api/landmarks?world=<world>` | Anonymous, per-IP `map` rate limit | `LandmarkReadDto[]`, every landmark or those whose pin is in the world, by name |
| `GET api/landmarks/{id}` | Anonymous, `map` rate limit | `LandmarkReadDto`; 404 when missing |
| `POST api/landmarks/search` | Dashboard read: the World area node, `knk.admin.world.landmark` or the plugin key | The paged search body; rows are `LandmarkListDto` |
| `POST api/landmarks` | `knk.admin.world.landmark` + `knk.admin.content`, or the plugin key | `LandmarkCreateDto` → `LandmarkReadDto` |
| `PUT api/landmarks/{id}` | as `POST` | `LandmarkUpdateDto` → `LandmarkReadDto` |
| `DELETE api/landmarks/{id}` | `knk.admin.world.landmark` + `knk.admin.delete`, or the plugin key | 204 |

`knk.admin.world.landmark` is matched by `knk.admin.world.*`, `knk.admin.*` and `*`, not by `knk.admin.world`.

### 2.1 `LandmarkReadDto`

1. Identity and place: `id`, `domainType` (always `Landmark`), `name`, `description`, `locationId`, `location`
   (`LocationDto`), `world`, `worldName`, `createdAt`.
2. Area: `areaKind` (`None`, `OwnRegion`, `LinkedDomain`), `wgRegionId` (own main region, null unless `OwnRegion`),
   `subRegionIds` (in order), `subRegions` (`DomainSubRegionDto[]`).
3. Parent: `parentDomainId`, `parentDomain` (`LandmarkDomainNavDto`: `id`, `name`, `domainType`, `worldName`,
   `wgRegionId`), `parentDomainName`.
4. Domain behaviour: `allowEntry`, `allowExit` (default true), `showEnterLeaveMessages`, `teleportEnabled`,
   `teleportPriceGems`, `teleportMinTitleBracketId`, `teleportMinPremiumGroupId`, `teleportRequiresDiscovery` (off by
   default).
5. Navigation: `preference`, `navigationEnabled`, `kind`.
6. **Off-road projection (#708 names), kept for older clients until a later change:** `domainId`, `domain`,
   `domainName` (= the parent), `extentKind` (`Region` when the area has a main region, own or the parent's, else
   `None`; never `Radius`), `regionId` (that main region), `radius` (always null). knk-plugin from `14645895` and
   knk-web-app from `8c9c3553` no longer read them.

### 2.2 Writes (`LandmarkCreateDto`, `LandmarkUpdateDto`)

Every field is optional on the wire (`null` keeps the stored value or the default): `name`, `description`,
`locationId` or an embedded `location`, `areaKind`, `wgRegionId`, `parentDomainId`, `allowEntry`, `allowExit`,
`showEnterLeaveMessages`, the teleport fields, `preference`, `navigationEnabled`, `kind`. `LandmarkUpdateDto` adds
`id`. Compatibility: `domainId` is read when `parentDomainId` is not sent; `extentKind` `None`/`Region` with
`regionId` when `areaKind`/`wgRegionId` are not sent; `extentKind` `Radius` or a `radius` value is refused.

### 2.3 `LandmarkListDto` (search rows)

`id`, `name`, `world`, `x`, `y`, `z`, `areaKind`, `wgRegionId`, `parentDomainId`, `parentDomainName`,
`parentDomainType`, `preference`, `navigationEnabled`, `kind`; projection `domainId`, `domainName`, `domainType`,
`extentKind`.

## 3. Landmarks in `api/Domains`

1. **Lists, lookups and search** include landmarks with `domainType` `Landmark`.
2. **`POST api/Domains/search` filters** (in `filters`):
    1. `domainType`: one or more exact types, comma separated, any case (`Landmark`, `Town,GateStructure`).
       `Structure` means plain structures (a gate is `GateStructure`); an unknown type matches nothing; `totalCount`
       counts only the matches.
    2. `excludeSubtreeOf`: a domain id; leaves out that domain and every landmark below it (the parent picker of a
       saved landmark).
3. **`PUT api/Domains/{id}` and `DELETE api/Domains/{id}` on a landmark (LD19):** 403 "This domain is a landmark:
   changing it requires the knk.admin.world.landmark permission." unless the caller holds that node (the plugin key
   passes); with it, the write runs through `LandmarkService` (its name and area rules) and answers the landmark DTO.
4. **`POST api/Domains/search-region-decisions` and `GET api/Domains/by-region/{region}?world=`** resolve a landmark's
   region and its sub-regions with the parent chain (one parent walk for every type, with a cycle guard, #981); in a
   top-down search the landmark is the innermost entry.

## 4. Discovery, warps and realtime

1. **Discovery:** `GET api/discovery-rewards` lists a `Landmark` type rule last, **disabled** (XP 0.05–0.25, coin
   hours 0.05–0.25, no gems, no ancestors); `PUT api/discovery-rewards/landmark` edits it. A landmark is discoverable
   through its per-domain override (`PUT api/discovery-rewards/overrides/{domainId}` with `{"isEnabled": true}`).
   Only an `OwnRegion` landmark is a discovery node; `POST api/users/{id}/discoveries` skips others as `NotADomain`
   and an `OwnRegion` landmark without its override as `Disabled`. The discovery summary's `byType` has a `Landmark`
   row.
2. **Warps:** `GET api/teleport-destinations?userId=` lists a landmark with its warp on as `domainType` `Landmark`
   (after towns, districts and structures), with its price, title and premium locks. "Requires discovery" answers
   `available` false with `lockCode` `NotDiscovered` until the player discovered the landmark.
3. **Realtime:** a landmark save or delete sends `EntityChanged` with type `Landmark`, keyed by its own region id
   (none for a point or a linked-area landmark), next to the domain access, teleport and navigation events.

## 5. The region task's `bounds` (#951)

The plugin's region task result (`ReagionCreate`, `RegionCreate`, `RegionClaim`; the world task's output) carries
`bounds` with `minX`, `minY`, `minZ`, `maxX`, `maxY`, `maxZ` of the drawn or selected region (knk-plugin
`WgRegionIdTaskHandler`, from `14645895`). knk-web-app fills a form's empty `MinX`…`MaxZ` fields from it; typed
values are kept.
