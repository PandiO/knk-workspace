# Road navigation chain — closeout (2026-09-29)

**Status:** chain complete — every phase implemented and pushed; nothing merged to trunk (the developer tests and
merges). Written by link 9 per `ROAD_NAVIGATION_CHAIN.md` § top / plan §8. Not a prompt for a next link: there is none.
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27) · **Plan:** `docs/specs/navigation/IMPLEMENTATION_PLAN.md`
(a "Phase N status" block under every phase) · **Report:** `docs/reports/2026-09-27-road-navigation-chain.md`.

## Branch heads (what to merge, in this order)

| Order | Repo | Branch → trunk | Head | Contains |
|---|---|---|---|---|
| 1 | knk-web-api | `claude/road-navigation` → `master` | `77e0a29` (cut from `master` `ccc8c02`) | Phase 1: road tables + migration, services, controllers, Street counts. Apply the migration to the dev DB yourself (never done by the chain). |
| 2 | knk-plugin | `claude/road-navigation` → `main` | `4e3f8af` (contains `main` `27b4236`, i.e. KNG-17) | Phases 2a-2e (core + api-client), 3 (admin side), 4 (`/navigate`). One merge; Gradle on the head: knk-core 1545, knk-api-client 184 (2 skipped), knk-paper 1074 (14 skipped), 0 failures. |
| 3 | knk-web-app | `claude/road-navigation` → `main` | `9dbb481` (cut from `main` `f56d421`) | Phase 5: `/admin/roads`, Street road panel. The API contract is Phase 1's. |

The plugin branch needs the web-api branch running (Phase 1 endpoints) and the web app needs both; each branch
builds and tests on its own.

## Before merging: the live checklists

Each phase's plan status block ends with a "Developer to-do" — run them in this order on the dev server once the
three branches are checked out and the migration applied:

1. **Phase 3** (admin side): survey three road types, `/knk road build radius 1500`, `/knk road show`, a street label,
   dirty tracking, rebuild — this produces the network everything else needs.
2. **Phase 5** (web app): profiles, tiles, edges, Street panel (grant `knk.admin.road`; add the `streetRoad` display
   panel to the Street form).
3. **Phase 4** (`/navigate`): the eleven checks in the plan's "Phase 4 status → Developer to-do" (Location / Town
   spawn / Town `region` / Structure / street / node; tunnel phrases; gate closed → detour or "Guiding you to the
   gate", opened → "shorter route"; pass-through hint; denied domain → "Guiding you to its edge"; the 48-block refusals
   and direct mode; walk off → re-route; stop / teleport / death / siege join; `/knk road why`; `/tps`).
4. Phases 1, 2a-2e have nothing observable of their own (pure code + API); their checks are folded into 3-5.

Decisions worth a look before merging are ranked in the report's "Review first" lists (Phase 4 first, then the
earlier phases); every decision is numbered in its status block and reversible.

## After merging: branches to delete

- `knk-web-api` `claude/road-navigation`
- `knk-plugin` `claude/road-navigation`
- `knk-web-app` `claude/road-navigation`

Nothing else was created: no worktrees on the developer's machine, no other branches, no tags. The chain's handoff
prompts (`2026-09-27-road-navigation-phase-1.md` … `2026-09-28-road-navigation-phase-5.md`) and this file stay as
history; `ROAD_NAVIGATION_CHAIN.md` can be archived once KNG-27 closes.

## Follow-ups the chain left open (not started — Phase 6 in DESIGN §8, or small)

- Real off-road pathfinding for the legs `/navigate` draws as straight lines (DESIGN §6.2 step 3).
- Consumers of `NavigationStartEvent` / `NavigationRerouteEvent` / `NavigationArriveEvent` / `NavigationEndEvent`
  (transport quests, tutorials, ambushes).
- `GateAvailability.SIEGE_HINT` wording assumes the default `PreLockdownView` ("walk up to it"); with
  `PassThroughOnly` the player right-clicks.
- knk-web-app trunk: `npm ci` fails (lockfile out of sync) and 16 pre-existing test failures in 10 suites (Phase 5
  status).
- knk-plugin: `CacheManager` is constructed twice in `onEnable` (flagged in Phase 3, not fixed); WorldEdit resolves
  as 7.3.0 through WorldGuard 7.0.10 although the build declares 7.2.13 (deprecation warnings only).
- Linear: KNG-27's acceptance boxes, and the follow-ups above as issues if wanted.

## Facts for whoever picks this up later

- Every link's session id and the option used to start the next link are in the report's "Next link" lines.
- Cloud sessions can build the plugin since 2026-09-29 (`repo.papermc.io`, `maven.enginehub.org` allowed);
  `~/.gradle/gradle.properties` with `org.gradle.workers.max=2`, `systemProp.org.gradle.internal.repository.max.tentatives=6`,
  `systemProp.org.gradle.internal.repository.initial.backoff=1500` avoids Maven Central's 429s without minute-long
  backoffs; run `--offline` after the first build.
- The plan's §0.4 scratch-build recipe (links 1-8) is no longer needed for knk-core; it remains documented in the
  Phase 2a status block.
