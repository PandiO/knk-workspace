# Off-road navigation and landmarks chain — charter

**Status:** Running (2026-11-17)
**Last updated:** 2026-11-19 (O32: L6 on hold as the fallback; fix link F1 #771 added); 2026-11-17 (completed by the coordinator at its first run: progress report, model, gates checked against the branches, status Running); 2026-11-17 (drafted by the design session)
**Issues:** parent [PandiO/knk-workspace#698](https://github.com/PandiO/knk-workspace/issues/698); sub-issues per
link below. Reference issues as `PandiO/knk-workspace#n` in component repos.
**Progress report:** [reports/2026-11-17-navigation-offroad-chain.md](../../reports/2026-11-17-navigation-offroad-chain.md)
**Skills:** coordinator `.claude/skills/knk-coordinator/`, links `.claude/skills/knk-link/` (knk-workspace).

## 0. Binding documents

1. [specs/navigation-offroad/DESIGN.md](../../specs/navigation-offroad/DESIGN.md), status Decided 2026-11-17
   (decisions O01 to O32; the developer's answers O16, O23 to O32; agent decisions O11 to O15, O17 to O22, O25 in
   § 2.1). § 3.4 holds the code check of the shared shaping package that binds L2.
2. [guides/navigation-offroad-smoke-test.md](../../guides/navigation-offroad-smoke-test.md), one section per phase
   (draft from the design; each link updates its section and tags the automated steps).
3. Road navigation: [specs/navigation/DESIGN.md](../../specs/navigation/DESIGN.md) and
   [LAST_MILE_PATHFINDING.md](../../specs/navigation/LAST_MILE_PATHFINDING.md) (walk rules kept: rev. 9 "No
   conventional path", partial path, KNG-124, N17); [REV7_PROPOSAL.md](../../specs/navigation/REV7_PROPOSAL.md) § 7.2
   (id ranges, for L3). NPC: [architecture/npc-navigation.md](../../architecture/npc-navigation.md) § 12 (for L2, L6,
   L9). Destination engine: [specs/navigation-destination-engine/DESIGN.md](../../specs/navigation-destination-engine/DESIGN.md)
   (for L7).
4. The sub-issue text **and its comments** (decisions added later live there).

## 1. Links

| Link | Sub-issue | Tier | What | Repos | Branch | Base | Flag | Gate |
|---|---|---|---|---|---|---|---|---|
| L1 | #703 | tier:1 | Phase 0: walk search and capture counters, live measurements in the keep, stair house, courtyard, 200 and 400 block open-country legs; dated report sets the budgets | knk-plugin, knk-workspace | `claude/offroad-measurements` | `next` | none | now (the developer runs the live measurements) |
| L2 | #704 | tier:2 | Phase 1: shared shaping package `core/navigation/shape` (DESIGN § 3.4), no behaviour change | knk-plugin | `claude/offroad-shape-package` | `next` | none | now |
| L3 | #710 | tier:3 | Phase 6.1: clearance cost, shaping and curve of walk paths off the main thread (`WalkTerrainNavWorld`) | knk-plugin | `claude/offroad-trail-corners` | `next` | `navigation.guidance-v2` (off) | L2 merged into `next` |
| L4 | #711 | tier:3 | Phase 6.2: anchored walk-trail particles, progress and cursor, winding back | knk-plugin | `claude/offroad-trail-cursor` | `next` | `navigation.guidance-v2` (off) | L3 merged into `next` (same files: `TrailRenderer`, `NavigationService`) |
| L5 | #705 | tier:3 | Phase 2: route as a leg list, lazy walk links, own id space, block-change hook | knk-plugin | `claude/offroad-walk-links` | `next` | `navigation.walk-links` (off) | L1 done (budgets) and L4 merged into `next` (one plugin link at a time in `navigation/`) |
| L6 | #706 (on hold as the fallback, developer 2026-11-19, O32) | tier:3 | Phase 3: lazy hierarchical walk search, clusters in memory, wilderness W1 | knk-plugin | `claude/offroad-hierarchical` | `next` | `navigation.walk.hierarchical` (off) | L5 merged into `next` |
| L7 | #707 | tier:2 | Phase 4: route modes with permission nodes, default `preferred` = today | knk-plugin | `claude/offroad-route-modes` | `next` | none | L5 merged into `next` |
| L7b | #852 | tier:3 | Default route mode per permission group (API field + migration, web app form, plugin default when no mode word is typed) | knk-web-api, knk-web-app, knk-plugin | `claude/offroad-group-route-mode` | `next` | none (null default = today) | developer's go 2026-11-20; plugin part after F3 |
| L8 | #708 | tier:3 | Phase 5.1: landmark entity (API, web app, plugin, `LandmarkProvider`) | knk-web-api, knk-web-app, knk-plugin | `claude/offroad-landmarks` | `next` | `navigation.landmarks` (off) | destination engine #96, #103 and #69 merged into `next` |
| L9 | #709 | tier:2 | Phase 5.2: landmark preference weights, landmark nodes in the walk planner | knk-plugin | `claude/offroad-landmark-weights` | `next` | `navigation.landmarks` (off) | L7 and L8 merged into `next` (L6 for landmark nodes in clusters) |
| L10 | #712 | tier:2 | Phase 7: plaza lines for the players' trail; first a check on Cinix and Brink shown to the developer | knk-plugin | `claude/offroad-plaza-lines` | `next` | `navigation.plaza-lines` (off) | L3 and L4 merged into `next` |

| F1 | #771 | tier:2 | Fix link: walk-search fixes from the phase 0 runs (items 1 and 2: the keep storage hall route, a trapdoor over a ladder) | knk-plugin, knk-workspace | `claude/offroad-walk-fixes-771` | `next` | none (bug fixes) | developer's go 2026-11-19 |

Phase 8 (#713, persisted walk tiles) is not a link of this chain: its scope is designed after L1's report and L6.

## 2. Gates

1. "L<n> merged into `next`": `git rev-list --count origin/next..origin/<branch>` is 0 in every repo L<n> changed.
2. "L<n> done": L<n>'s block is in the progress report, its heads match `git ls-remote`, its checks passed.
3. "L1 done" needs the developer: the live measurements on the dev world and the dated report
   `docs/reports/<date>-offroad-navigation-measurements.md` (#703). If it shows that option A (raised caps) fits the
   keep, ask the developer before L6 (decision O32).
4. L10's first step needs the developer: the plaza lines on Cinix and Brink are shown before the trail uses them
   (O16, risk 12.5); recorded on #712.
5. L8 waits for another feature: destination engine P1 (#96), P2 (#103) and P3 (#69), decision O27.

Order and parallelism (O23): L1 and L2 first, in parallel (L1 is mostly live work by the developer). Then trail quality
(L3, L4) and walk links (L5); with one chain, trail quality first. All of L2 to L7, L9 and L10 change
`knk-plugin` navigation code, so at most one of them runs at a time. L8 (three repos) may run beside a plugin link only
when it touches no `navigation/` file in that link's change set.

## 3. Chain notes

1. Overlap: the NPC navigation follow-ups chain (#358, #603) works in `core/npc/nav`. L2 moves classes out of it; the
   coordinator checks that chain's open branches before L2 starts and ends L2 with a note to that chain.
2. Unchanged behaviour: with every flag above off, navigation, trails and NPC movement behave exactly as before
   (A16, A24, A26; transcript tests).
3. Migrations: only L8 (an additive `landmarks` table).
4. Model for link sessions: `claude-opus-5-5` for every link (coordinator decision 2, progress report § 3).
5. Rule set: the `next` branch model applies (CI on knk-web-api and knk-web-app `main`, checked 2026-11-17); links
   branch from `next`, the coordinator merges into `next`.
6. Gates checked against git, 2026-11-17 (knk-plugin `next` `e69dba6a`, knk-workspace `next` `b9c0a7fc`):
    1. L1: open.
    2. L2: open by the charter, held by the coordinator until NPC B5 `claude/npc-movement-b5` (#699, `d402d865`, not in
       `next`) is merged into `next` (same import lines in `core/npc/nav/group/`; the order the developer agreed with
       the NPC chain) and L1's plugin PR is merged (one plugin link at a time).
    3. L3 to L7, L9, L10: closed (their predecessor links are not in `next`).
    4. L8: closed; no destination-engine branch for #96, #103 or #69 is merged into `next`.
