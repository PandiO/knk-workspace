# Handoff: KNG-111 / KNG-112 — domains know their world

**Date:** 2026-10-10
**Status:** Implemented on branches. Not merged, not deployed, not live-tested.
**Issues:** [KNG-111](https://linear.app/kngpandi/issue/KNG-111) (API + web app), [KNG-112](https://linear.app/kngpandi/issue/KNG-112) (plugin). Parent: [KNG-109](https://linear.app/kngpandi/issue/KNG-109).
**Design / audit:** hub [DESIGN §16](../../specs/hub/DESIGN.md), [multiworld audit](../../reports/2026-10-10-multiworld-capability-audit.md). Decisions confirmed 2026-10-10: full fix first; the world comes from the region/Location world task, and the form asks only when neither gives one.

## Branches

All on `claude/blissful-fermat-b7ihrz`, based on the current default branch of each repo:

| Repo | Base | Commits | No PR opened |
|---|---|---|---|
| knk-web-api | `master` `8cce48d0` | `ad65859`, `bccd5f9` | yes |
| knk-web-app | `main` `12c1d600` | `de1fa96` | yes |
| knk-plugin | `main` `973aa68b` | `08326d6` | yes |

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
  - Maven Central answered 429 to this session. A local init script (`~/.gradle/init.d`, not in the repo) used Google's Central mirror.

## Not done yet

KNG-112 remainder:

- **Managed-region startup repair and `/knk regions repair`** still find a region by id in the first world that has it (`WorldGuardManagedRegionStore`). The specs from Town/District/Structure summaries carry no world yet.
- **Discovery (KNG-20)** keys, spool and grant are still by region id (KNG-118).
- **Roads and navigation** (`NavigationAccess`, `RoadNetworkCache`, `RoadBuildJob`) use the world-blind resolver methods. In a world-blind lookup, a region id present in two worlds now resolves to no domain. Those files are claimed by the road-navigation P4 session; switch them to the world overloads after P4 merges.
- **API validators** (`contains-location`/`contains-region`) don't send `world` yet.
- **DB not inspected;** the live data is unknown.

Other hub blockers are unchanged: KNG-113, KNG-114, KNG-115, KNG-116, KNG-117.

## Merge and live test

1. Merge the API first: it adds the column and the endpoints. The old plugin ignores `worldName` (`FAIL_ON_UNKNOWN_PROPERTIES` is off), and the new plugin works against an API that has no worlds yet. Rebase the migration snapshot if KNG-66, KNG-81 or KNG-34 merge first.
2. Deploy the plugin, start the server, and read `[KnK Worlds]` in the log:
   - "N given a world";
   - the domains still without one; choose those in the web form.
3. Run audit checklist items 2, 3 and 5 with two worlds that share a region name.
4. Create a domain without a region task: the form must ask for the world. Create a District whose region is in a different world from its Town: it must be refused.
