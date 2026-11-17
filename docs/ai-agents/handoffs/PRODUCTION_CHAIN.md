# Production, storage and transport chain — charter

**Status:** Ready to start (2026-11-16)
**Last updated:** 2026-11-16 (drafted by the design session; the coordinator completes it at its first run)
**Issues:** parent [PandiO/knk-workspace#22](https://github.com/PandiO/knk-workspace/issues/22); territory parent
[PandiO/knk-workspace#326](https://github.com/PandiO/knk-workspace/issues/326); sub-issues per link below. Reference
issues as `PandiO/knk-workspace#n` in component repos.
**Progress report:** to be created by the coordinator (`docs/reports/<date>-production-chain.md`).
**Skills:** coordinator `.claude/skills/knk-coordinator/`, links `.claude/skills/knk-link/` (knk-workspace).

## 0. Binding documents

1. [specs/production-storage-transport/DESIGN.md](../../specs/production-storage-transport/DESIGN.md), status
   **Decided 2026-11-16** (decisions D1-D11 §14; decision record
   [DECISIONS_2026-11-05.md](../../specs/production-storage-transport/DECISIONS_2026-11-05.md) §1-§15 incl. F1-F12,
   R1-R5, G1-G17 and the in-game menus M1-M5 §15.1). §17 acceptance A01-A27, §18 links and tiers.
2. Companions, binding per link: [PRODUCTION_KINDS.md](../../specs/production-storage-transport/PRODUCTION_KINDS.md)
   (P3, P4, P8), [TOWN_LOGISTICS.md](../../specs/production-storage-transport/TOWN_LOGISTICS.md) (P5, P9),
   [IMPLEMENTATION_PLAN.md](../../specs/production-storage-transport/IMPLEMENTATION_PLAN.md) (every link: "Rules for
   every phase", including G17 form/display seeds), [shops DESIGN](../../specs/shops/DESIGN.md) (P10-P12),
   [territory DESIGN](../../specs/territory/DESIGN.md) (T-a to T-c, P2), [NPC platform DESIGN §6a](../../specs/npc-platform/DESIGN.md)
   (P11, G12-G13).
3. Smoke-test guide [production-storage-transport-smoke-test.md](../../guides/production-storage-transport-smoke-test.md)
   (draft; each link updates its section).
4. The sub-issue text **and its comments** (scope notes of 2026-11-16 live there).

## 1. Links

Flags (G16): plugin `production.enabled`, API `Production:Enabled`; both default off. Branch per link:
`claude/production-<link id>` in each repo the link touches. Base: `next` everywhere.

| Link | Sub-issue | Tier | What | Repos | Branch | Base | Flag | Gate |
|---|---|---|---|---|---|---|---|---|
| L0 | #141 | tier:3 | Item identity: every obtainable item is a blueprint; generated "Uncurated" shadow blueprints (G4) | knk-web-api, knk-plugin | `claude/item-identity-141` | `next` | none (conversion log) | now (prerequisite, may be its own chain) |
| L1 | #326 | tier:3 | Territory API: holders, crown land entity (G10), power, range (G11), conflicts, loyalty | knk-web-api | `claude/production-t-a` | `next` | `Production:Enabled` | now |
| L2 | #689 | tier:3 | Territory plugin: chunk cache, lookup, BlueMap outlines | knk-plugin | `claude/production-t-b` | `next` | `production.enabled` | L1 merged |
| L3 | #690 | tier:2 | Territory web app | knk-web-app | `claude/production-t-c` | `next` | none | L1 merged |
| L4 | #97 | tier:3 | P1 stock core API: storages, ledger, reconciler, capacity, roll-up | knk-web-api | `claude/production-p1` | `next` | `Production:Enabled` | L0 merged |
| L5 | #675 | tier:2 | P1b stock web app | knk-web-app | `claude/production-p1b` | `next` | none | L4 merged |
| L6 | #91 | tier:3 | P2 world API: structure subtypes, TownId, placement rules | knk-web-api | `claude/production-p2` | `next` | `Production:Enabled` | L1, L4 merged |
| L7 | #676 | tier:2 | P2b world web app | knk-web-app | `claude/production-p2b` | `next` | none | L6 merged |
| L8 | #677 | tier:2 | P2c world plugin: managed-region kinds | knk-plugin | `claude/production-p2c` | `next` | `production.enabled` | L6 merged |
| L9 | #86 | tier:3 | P3 production engine API | knk-web-api | `claude/production-p3` | `next` | `Production:Enabled` | L6 merged |
| L10 | #678 | tier:2 | P3b production web app | knk-web-app | `claude/production-p3b` | `next` | none | L9 merged |
| L11 | #138 | tier:3 | P4 yield areas API | knk-web-api | `claude/production-p4` | `next` | `Production:Enabled` | L9 merged |
| L12 | #679 | tier:3 | P4b surveys plugin | knk-plugin | `claude/production-p4b` | `next` | `production.enabled` | L11 merged |
| L13 | #680 | tier:2 | P4c yield areas web app | knk-web-app | `claude/production-p4c` | `next` | none | L11 merged |
| L14 | #79 | tier:3 | P5 transport API (simulated carrying, G14) | knk-web-api | `claude/production-p5` | `next` | `Production:Enabled` | L9 merged |
| L15 | #681 | tier:2 | P5b lanes plugin | knk-plugin | `claude/production-p5b` | `next` | `production.enabled` | L14 merged |
| L16 | #682 | tier:2 | P5c transport web app | knk-web-app | `claude/production-p5c` | `next` | none | L14 merged |
| L17 | #683 | tier:2 | P6a API: StorageContainer, caller-filtered reads, menu seeds | knk-web-api | `claude/production-p6a` | `next` | `Production:Enabled` | L14 merged |
| L18 | #74 | tier:2 | P6 plugin: terminals, displays, Structures menu, structure menu, orders list | knk-plugin | `claude/production-p6` | `next` | `production.enabled` | L2, L17 merged |
| L19 | #60 | tier:3 | P7 delivery and inbox API | knk-web-api | `claude/production-p7` | `next` | `Production:Enabled` | L4 merged |
| L20 | #684 | tier:3 | P7b inbox plugin, kit/lootbox migration | knk-plugin | `claude/production-p7b` | `next` | `production.enabled` | L19 merged |
| L21 | #685 | tier:3 | P8a harvest API | knk-web-api | `claude/production-p8a` | `next` | `Production:Enabled` | L11 merged |
| L22 | #134 | tier:3 | P8 harvest plugin | knk-plugin | `claude/production-p8` | `next` | `production.enabled` | L12, L21 merged |
| L23 | #127 | tier:3 | P9 town logistics API | knk-web-api | `claude/production-p9` | `next` | `Production:Enabled` | L14 merged |
| L24 | #686 | tier:2 | P9b logistics web app | knk-web-app | `claude/production-p9b` | `next` | none | L23 merged |
| L25 | #248 | tier:3 | P10 shops API, town account | knk-web-api | `claude/production-p10` | `next` | `Production:Enabled` | L9 merged (restocking: L23) |
| L26 | #687 | tier:2 | P10b shop menus plugin | knk-plugin | `claude/production-p10b` | `next` | `production.enabled` | L25 merged; developer's shop menu templates |
| L27 | #688 | tier:2 | P10c shops web app | knk-web-app | `claude/production-p10c` | `next` | none | L25 merged |
| L28 | #249 | tier:2 | P11 shopkeepers | knk-plugin | `claude/production-p11` | `next` | `production.enabled` | L26 merged; NPC lifecycle §6a available (#358) |
| L29 | #250 | tier:2 | P12 display stalls | knk-plugin | `claude/production-p12` | `next` | `production.enabled` | L26 merged |

Web-app insight (#65, tier:2) is not a link of its own: each web app link adds its part.

## 2. Gates

1. "L<n> merged": `git rev-list --count origin/next..origin/<branch>` is 0 in the repo L<n> changed.
2. "L<n> done": L<n>'s block is in the progress report, its heads match `git ls-remote`, its checks passed.
3. Developer gates: the shop menu templates (L26, ask on #687); tier:3 links wait for the developer's smoke test of
   their guide section before the next tier:3 link in the same repo builds on them, unless the developer says
   otherwise.

Order and parallelism: at most one link per component repo at a time. API links run in the order above; a web app
or plugin link may run alongside the next API link (different repos).

## 3. Chain notes

1. Overlaps: NPC navigation work (#358, M-links on knk-plugin `claude/npc-*`) touches `paper/npc/`; L28 waits for the
   §6a lifecycle and must not touch navigation code. Kit delivery (#261) is the path L20 migrates; keep it working
   with `production.enabled: false`. Currency `AccountKind` (L25) — coordinate with the currency owner.
2. With both flags off, nothing of this feature runs (A21); existing kit, lootbox and region behaviour is unchanged.
3. Migrations: at most one additive migration per API link.
4. Every new entity: FormConfiguration and DisplayConfiguration seeds in the same link (G17, A23).
5. Model for link sessions: set by the coordinator.
