# Overview map chain — charter

**Status:** Ready to start (2026-11-18)
**Last updated:** 2026-11-18 (drafted by the design session)
**Issues:** parent [PandiO/knk-workspace#732](https://github.com/PandiO/knk-workspace/issues/732); sub-issues per
link below. Reference issues as `PandiO/knk-workspace#n` in component repos.
**Progress report:** to be created by the coordinator at its first run (`reports/<date>-overview-map-chain.md`).
**Skills:** coordinator `.claude/skills/knk-coordinator/`, links `.claude/skills/knk-link/` (knk-workspace).

## 0. Binding documents

1. [specs/in-game-maps/OVERVIEW_MAP_DESIGN.md](../../specs/in-game-maps/OVERVIEW_MAP_DESIGN.md), status Decided
   2026-11-18 (decisions O01–O33; O08 superseded by O31).
2. [specs/in-game-maps/DECISION-map-data-source.md](../../specs/in-game-maps/DECISION-map-data-source.md) (O15:
   our own API, no BlueMap plugin on the game server).
3. [guides/overview-map-smoke-test.md](../../guides/overview-map-smoke-test.md), one section per link (§ 1 to § 9).
4. The sub-issue text **and its comments** (decisions added later live there).

## 1. Links

| Link | Sub-issue | Tier | What | Repos | Branch | Base | Flag | Gate |
|---|---|---|---|---|---|---|---|---|
| L1 | #735 | tier:3 | Region outlines: plugin reports, API table `map_region_outlines` | knk-plugin, knk-web-api | `claude/overview-map-outlines` | `next` | `map.reporting.enabled`, default off | now |
| L2 | #736 | tier:3 | Public map API: config, markers, panel DTOs, `map` rate limit, access tests | knk-web-api | `claude/overview-map-public-api` | `next` | `Map:Enabled`, default off | L1 merged into `next` |
| L3 | #737 | tier:2 | `/map` page, BlueMap iframe, bridge script, pins, flash and toggle, public panels, action registry, deploy notes | knk-web-app, knk-workspace | `claude/overview-map-page` | `next` | `Map:Enabled` | L2 merged into `next` |
| L4 | #738 | tier:3 | Live players backend: plugin reports, per-audience snapshots, arena pins | knk-plugin, knk-web-api | `claude/overview-map-players-api` | `next` | `Map:LivePlayers:Enabled`, default off | L2 merged into `next` |
| L5 | #739 | tier:2 | Live players layer on the page | knk-web-app | `claude/overview-map-players-page` | `next` | `Map:LivePlayers:Enabled` | L3 and L4 merged into `next` |
| L6 | #740 | tier:2 | Staff details: compact display-configuration renderer | knk-web-app | `claude/overview-map-staff-details` | `next` | none (node-gated) | L3 merged into `next` |
| L7 | #741 | tier:3 | Gate commands backend: endpoint, hub command, plugin handler | knk-web-api, knk-plugin | `claude/overview-map-gate-commands` | `next` | `Map:GateCommands:Enabled`, default off | L2 merged into `next` |
| L8 | #742 | tier:2 | Gate command buttons in the panel | knk-web-app | `claude/overview-map-gate-buttons` | `next` | `Map:GateCommands:Enabled` | L3 and L7 merged into `next` |
| L9 | #743 | tier:2 | Player context panel with moderation actions | knk-web-app | `claude/overview-map-moderation` | `next` | none (node-gated) | L5 merged into `next` |

## 2. Gates

1. "L<n> merged into `next`": `git rev-list --count origin/next..origin/<branch>` is 0 in every repo L<n> changed.
2. "L<n> done": L<n>'s block is in the progress report, its heads match `git ls-remote`, its checks passed.
3. L3 starts with the spike in OVERVIEW_MAP_DESIGN § 9.6: BlueMap's web app accepts runtime marker sets and click
   listeners from a script. If it doesn't, L3 stops as a blocker and the developer decides on the fallback.
4. The developer's live check of the L4 visibility steps (smoke § 4.1 steps 2, 3 and 5) before L5 is merged into
   `next`. It is recorded on #738.

Order and parallelism: at most one link per component repo at a time. L4 and L7 both touch knk-web-api and knk-plugin,
so they run one after the other. L3 (knk-web-app) may run alongside L4 or L7. L5, L6, L8 and L9 share knk-web-app, so
they run one at a time.

## 3. Chain notes

1. Overlaps with other "In progress" rows: the siege weapons design (#354, #613 tactical map) will reuse the bridge
   script and the tiles from L3. Keep the bridge protocol versioned (O14) so #613 builds on it without changing L3's
   messages.
2. Existing modes must stay unchanged: every part is off by default (O27). With all flags off, the API's existing
   endpoints, the game hub and the plugin's behaviour are unchanged.
3. Migrations: only L1 adds one (`map_region_outlines`, additive).
4. Model for link sessions: left to the coordinator.
