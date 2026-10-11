# Handoff: KNG-111 / KNG-112 — domains know their world

**Date:** 2026-10-10 (updated 2026-10-11)
**Status:** Implemented on branches, not merged or deployed. First live round (items 1-6 below) passed or accepted by the developer on 2026-10-11; the roads, navigation and repair changes from 2026-10-11 are not live-tested.
**Issues:** [KNG-111](https://linear.app/kngpandi/issue/KNG-111) (API + web app), [KNG-112](https://linear.app/kngpandi/issue/KNG-112) (plugin). Parent: [KNG-109](https://linear.app/kngpandi/issue/KNG-109).
**Design / audit:** hub [DESIGN §16](../../specs/hub/DESIGN.md), [multiworld audit](../../reports/2026-10-10-multiworld-capability-audit.md). Decisions confirmed 2026-10-10: full fix first; the world comes from the region/Location world task, and the form asks only when neither gives one.

## Branches

All on `claude/blissful-fermat-b7ihrz`. The default branches were merged in on 2026-10-11:

| Repo | Default branch merged in | Commits | No PR opened |
|---|---|---|---|
| knk-web-api | `master` `f409271` | `ad65859`, `bccd5f9`, merge `a13d6a1`, `a72e496` | yes |
| knk-web-app | `main` `5f40f93` | `de1fa96`, merge `c2d8828` | yes |
| knk-plugin | `main` `0ee516aa` (with KNG-122 and P4) | `08326d6`, merge `d60f2578`, `dc61fd4d` | yes |

## What changed

### API (KNG-111)

- **`Domain.WorldName`** (varchar 64), added by migration `20261010121436_AddDomainWorldName`.
  - The migration adds the column only, with **no backfill**: older Locations often carry a defaulted `"world"`.
  - Existing rows stay NULL. Every world-qualified lookup still matches them as a fallback.
- **`DomainWorldResolver`** decides a domain's world on every Town/District/Structure/GateStructure/Domain create and update.
  - **Sources, in order:** the form; the region world task (`tempregion_worldtask_<taskId>` → that task's `worldName`); the domain's Location; the parent; on update, the saved world.
  - **Rules:**
    - every source must agree;
    - a parent can't move away from its children's world;
    - a region id is used once per world;
    - GateStructure guard spawns must be in the gate's world.
  - **Errors:** missing → `DomainWorldRequired`; conflict → `DomainWorldConflict` / `DomainRegionTaken`. Both are answered as 400 with the message.
- **DTOs:** `worldName` on every domain DTO, region decision and access rule.
- **Lookups:** `by-region?world=` and `search-region-decisions.worldName` are world-qualified. Without a world they stay world-blind, now deterministic (lowest id).
- **New endpoints:**
  - `POST api/Domains/world/resolve`: lets the form ask.
  - `GET api/Domains/world/missing`
  - `POST api/Domains/world/backfill`: the plugin's region report; needs the server key or `knk.admin.config`. The report decides; the Location and parent break ties; contradictions are left for an admin.
- **Region rename:** sends `&world=`.
- **Containment validators** (2026-10-11): `LocationInsideRegion` and `RegionContainment` send the parent domain's world to `contains-location` / `contains-region`.
  - A location in a different world from its parent domain is refused without calling the plugin.
  - A domain without a world uses the location's world.
  - `RegionContainmentValidator` now reads properties of typed objects too: `BindingFlags.Instance` was missing.

### Web app (KNG-111)

- Before saving a domain, `FormWizardPage` calls `world/resolve`:
  - on a conflict, it shows the API's reason;
  - when no source gives a world, `DomainWorldPromptModal` asks, offering the runtime worlds from Game Settings (or free text if none have been reported).
- A **World** column on the town, district, structure, gate structure and domain lists and pickers.

### Plugin (KNG-112)

- **Resolver cache:** `RegionDomainResolver` caches by (world, region) and has world-qualified overloads.
  - World-blind lookups still answer when the region id is in one world only, and answer nothing when it's in several.
  - A world-blind refresh re-asks about the entry it actually serves (KNG-104 kept).
- **Region tracker:** tracks each player's world. Moving to the same region id in another world leaves one domain and enters the other.
  - The transition service, access preview and combat safezones resolve per world.
- **KNG-56 access flags:** written to their own world's region only. Rules without a world still cover every world, and orphaned flags are cleared per world.
- **Region HTTP endpoints:** rename, contains-location and contains-region take `world`.
- **`DomainWorldBackfillReporter`:** at startup (`regions.access.sync.delay-ticks`), reports where the regions of world-less domains are, then logs what is still left.
- **Roads and navigation** (2026-10-11, after P4 merged): domains are looked up in their own world.
  - `NavigationAccess` uses the road network's world, or the player's world for the trail. Walk access uses the walk's world.
  - The live edge tags warm the domain cache and ask it per world.
  - `RoadNetworkCache` and `RoadBuildJob` use their tile's world.
- **Managed-region repair** (2026-10-11):
  - Specs carry their domain's world; a District or Structure without one takes its parent's.
  - The planner and reconciler key each region by world and id, so two worlds' `town_1` regions are not a conflict.
  - `WorldGuardManagedRegionStore` reads and changes only the named world's region.
  - A newly finalized region is set up in the world it was renamed in.
  - The Town, District and Structure summaries read `worldName` from the API.
  - `RegionsAdminCommand` is untouched (KNG-107 claim). Its `/knk regions repair` runs the same world-aware repair.

## Verified (no live server)

- **API**
  - Full suite: 1991 passed, 4 failed, 54 skipped. The same 4 fail on `master`: `PathResolutionServiceTests` ×2, `FieldValidationServiceTests`, `ClientActivityStoreTests`.
  - New tests: `DomainWorldResolverTests`, `DomainWorldBackfillTests` and a finalizer world test; 22 world tests pass after the follow-up.
  - Migration on a local MySQL 8.0.46 (the same steps as the CI workflow): apply all, no pending model changes, roll back to 0, re-apply.
- **Web app**
  - `npm run build` passes; the only warnings are the existing `FormWizardPage` hook warnings.
  - New `domainWorld.test.ts` passes.
  - Related suites: 146 passed, 1 failed (`RoadsAdminPage` profile delete, which also fails on `main`).
  - The lockfile is out of sync on `main` (`yaml@2.9.1`), so `npm ci` fails. Deps were installed without writing the lockfile.
- **Plugin:** `./gradlew test` is green. New tests: core 1849 (+10), api-client 224 (+5), paper 1418 (+4).
- **2026-10-11, after merging the default branches and the remainder:**
  - Plugin: core 2040, api-client 256 and paper 1620 tests, all green.
  - New tests: `ManagedRegionWorldsTest`, plus world tests in `LiveEdgeTagsTest` and `WalkAccessFactoryTest`.
  - API: 2432 passed. The 4 failures are the same ones that fail on `master`.
  - New API test: `RegionWorldValidatorTests`.
  - The migration CI sequence passed again on local MySQL after the merge.
- **Live (developer, 2026-10-11), first round:**
  1. Works.
  2. Works.
  3. Accepted.
  4. Works as designed: the Town form requires both region fields, so it cannot be completed without a region.
  5. Works.
  6. Accepted.
  - Maven Central answered 429 to this session. A local init script (`~/.gradle/init.d`, not in the repo) used Google's Central mirror.

## Not done yet

- **Discovery (KNG-20):** keys, spool and grant are still by region id ([KNG-118](https://linear.app/kngpandi/issue/KNG-118)).
- **Road "Ignored" rule:** the "Ignored for roads" check (`NavigationDestinations.roadsIgnoreRegion`) reads the `/navigate` catalogue by region id only. It is right while region ids are unique across worlds, and needs a world once the catalogue carries one.
- **Repair conflict check:** a config `extra-regions` entry has no world. If it names the same region as a domain that has a world, the conflict check no longer catches it.
- **Temp-region cleanup:** stays world-blind. It keeps any region id that a domain uses in any world.
- **DB not inspected;** the live data is unknown.

Other hub blockers are unchanged: KNG-113, KNG-114, KNG-115, KNG-116, KNG-117.

## Merge and live test

1. Merge the API first: it adds the column and the endpoints. The old plugin ignores `worldName` (`FAIL_ON_UNKNOWN_PROPERTIES` is off), and the new plugin works against an API that has no worlds yet. Rebase the migration snapshot if KNG-66, KNG-81 or KNG-34 merge first.
2. Deploy the plugin, start the server, and read `[KnK Worlds]` in the log:
   - "N given a world";
   - the domains still without one; choose those in the web form.
3. Run audit checklist items 2, 3 and 5 with two worlds that share a region name.
4. Create a domain without a region task: the form must ask for the world. Create a District whose region is in a different world from its Town: it must be refused.
5. For the 2026-10-11 remainder, use two worlds that share a region id:
   - `/knk regions repair` must change each world's own region;
   - `/navigate` in each world must obey that world's domain rules;
   - a Location in another world than its Town must be refused by the form validator.
