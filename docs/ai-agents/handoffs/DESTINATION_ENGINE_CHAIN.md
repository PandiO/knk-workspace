# Navigation destination engine chain — charter

**Status:** Ready to start (2026-11-18). The design is Decided 2026-11-18; the manager schedules the chain.
**Last updated:** 2026-11-18 (design approved: tiers confirmed, phase 4b is #747); 2026-11-18 (draft by the design
refresh session)
**Issues:** parent [PandiO/knk-workspace#25](https://github.com/PandiO/knk-workspace/issues/25); sub-issues per
link below. Reference issues as `PandiO/knk-workspace#n` in component repos.
**Progress report:** to be created by the coordinator at its first run (`docs/reports/<date>-destination-engine-chain.md`).
**Skills:** coordinator `.claude/skills/knk-coordinator/`, links `.claude/skills/knk-link/` (knk-workspace).

## 0. Binding documents

1. [specs/navigation-destination-engine/DESIGN.md](../../specs/navigation-destination-engine/DESIGN.md) on
   knk-workspace `next`, status **Decided 2026-11-18** (developer decisions E1–E13; agent decisions E14–E21, accepted by
   the developer on 2026-11-18). § 3.2 (landmark provider), § 10 (phases,
   tiers, flag), § 10.2 (the October P1 code and its deltas), § 10.3 (the API change), § 13 (acceptance items).
2. [guides/navigation-destination-engine-smoke-test.md](../../guides/navigation-destination-engine-smoke-test.md), one
   section per phase (draft; each link updates its section).
3. [specs/navigation-offroad/DESIGN.md](../../specs/navigation-offroad/DESIGN.md) § 6 and decision O27 (what the
   landmark provider needs from the engine).
4. The sub-issue text **and its comments** (decisions added later live there), and the developer's answers on #25.

## 1. Links

| Link | Sub-issue | Tier | What | Repos | Branch | Base | Flag | Gate |
|---|---|---|---|---|---|---|---|---|
| L1 | #96 | tier:2 | P1: pure engine in knk-core. Reuse: merge `next` into the October branch (conflict in `ArchitectureGuardTest`: keep both tests), apply the deltas of DESIGN § 10.2.4, finish and test | knk-plugin | `claude/navigation-destination-engine` (existing, `ea368a8b`) | `next` (merged in) | none | design Decided |
| L2 | #103 | tier:2 | P2: domain search returns each domain's Location (knk-web-api); `NavigationModel` with domain places, Locations, compass settings, road-access answers and an empty `landmarks` section; snapshot, refresh, paced fallback, `degraded` | knk-web-api, knk-plugin | `claude/navigation-destination-engine` (API: new) | `next` | none (nothing reads the model before L3) | L1 merged into `next` |
| L3 | #69 | tier:3 | P3: command, completion, compass and `NavigationService` on the engine handle; catalogue, siege match and compass target providers; road access from the model | knk-plugin | `claude/navigation-destination-engine` | `next` | `navigation.destination-engine` (off) | L2 merged into `next` |
| L4 | #62 | tier:3 | P4: hard blocks into scopes, live re-validation, `DESTINATION_NOT_ALLOWED` | knk-plugin | `claude/navigation-destination-engine` | `next` | `navigation.destination-engine` (off) | L3 merged into `next` |
| L5 | #747 (phase 4b) | tier:2 | Removal: old paths, `NavigationDestinations`, `NavigationEligibility`, `EndReason.SIEGE`, the flag; the handle is the only entry | knk-plugin | `claude/navigation-destination-engine` | `next` | removes the flag | L4 merged into `next` and the developer's live test of smoke § 3 and § 4 with the flag on |
| L6 | #55 | tier:2 | P5: arena duels provider and scope; optional hub list | knk-plugin | `claude/navigation-destination-engine` | `next` | none | L5 merged and the arena duels work merged into `next`; timing not confirmed by the developer |

## 2. Gates

1. "Design Decided": `git show origin/next:docs/specs/navigation-destination-engine/DESIGN.md` has the status line
   `**Decided 2026-11-18** (developer)` (met once PR #744 is merged into `next`).
2. "L<n> merged into `next`": `git rev-list --count origin/next..origin/<branch>` is 0 in every repo L<n> changed.
3. "L<n> done": L<n>'s block is in the progress report, its heads match `git ls-remote`, its checks passed.
4. "Developer's live test of P3 and P4" (gate of L5): the developer's word on #25 or on the sub-issue of L4 that smoke
   § 3 and § 4 passed with `navigation.destination-engine: true`.

Order and parallelism:

1. Strictly in order L1 → L2 → L3 → L4 → L5 → L6. The knk-web-api part of L2 may start with L1 (it shares no repo).
2. **At most one knk-plugin link touching navigation code at a time**, across chains: `paper/navigation/`,
   `core/navigation/` and `NavigationService` in particular. Before starting a link, check the sessions board and the
   off-road chain (#698, charter [NAVIGATION_OFFROAD_CHAIN.md](NAVIGATION_OFFROAD_CHAIN.md)) for a running link
   there; wait for it to merge or agree an order with its coordinator.
3. **The off-road chain's L8 (#708, landmarks) waits for L1, L2 and L3 merged into `next`** (off-road O27, DESIGN
   § 3.2). It must not run at the same time as L3, L4 or L5.

## 3. Chain notes

1. Overlaps: the off-road chain (#698) is running in knk-plugin navigation code (walk links, trail quality, plaza
   lines behind their own flags); `NavigationService` grew about 630 lines from it and from NPC work (DESIGN § 2.1
   item 8). Links merge `next` in at start and before the pull request.
2. Behaviour that must stay unchanged: with `navigation.destination-engine` off (default), `/navigate`, tab
   completion, the compass and session endings behave exactly as on `next` before L3 (smoke § 3.1).
3. Migrations: none. L2's API change is an additive DTO field and an `Include`, no schema change.
4. Config keys with deploy notes: `navigation.destinations.stale-after-days` (L2), `navigation.destination-engine`
   (L3, removed in L5).
5. Model for link sessions: set by the coordinator.
