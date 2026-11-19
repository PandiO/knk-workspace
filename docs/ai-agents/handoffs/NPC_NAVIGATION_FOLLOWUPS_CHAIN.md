# NPC navigation follow-ups chain — charter

**Status:** Running (2026-11-19): links J1, H1, G1 (developer go); retest of B5, C1, E1, R1 open
**Last updated:** 2026-11-19
**Issues:** parent [PandiO/knk-workspace#358](https://github.com/PandiO/knk-workspace/issues/358); link sub-issues
[#519](https://github.com/PandiO/knk-workspace/issues/519) (L1),
[#520](https://github.com/PandiO/knk-workspace/issues/520) (L2),
[#521](https://github.com/PandiO/knk-workspace/issues/521) (L3),
[#522](https://github.com/PandiO/knk-workspace/issues/522) (L4); fix links
[#592](https://github.com/PandiO/knk-workspace/issues/592) (L5),
[#593](https://github.com/PandiO/knk-workspace/issues/593) (L6),
[#594](https://github.com/PandiO/knk-workspace/issues/594) (L7, dropped); design link
[#603](https://github.com/PandiO/knk-workspace/issues/603) (L8); movement links #621 (M1), #622 (M2), #623 (M6), #624 (M3), #625 (M5), #626 (M4), #627 (M7); fix links after the smoke test of 2026-11-16: #668 (L9), #670 (B1), #671 (B2), #672 (B3), #673 (B4). Reference issues as `PandiO/knk-workspace#n` in
component repos.
**Progress report:** [reports/2026-11-14-npc-navigation-followups-chain.md](../../reports/2026-11-14-npc-navigation-followups-chain.md)
**History:** the first NPC navigation chain (Phases 1–4 and #490, all merged into `next`):
[charter](NPC_NAVIGATION_CHAIN.md), [progress report](../../reports/2026-11-13-npc-navigation-chain.md).
**Skills:** coordinator `.claude/skills/knk-coordinator/`, links `.claude/skills/knk-link/`, tests
`.claude/skills/knk-test-writer/` (knk-workspace).

## 0. Binding documents

1. [specs/npc-platform/DESIGN.md](../../specs/npc-platform/DESIGN.md) (working design; § 6 movement, § 7 gates,
   § 9 navigation), [BEHAVIOR_MODEL.md](../../specs/npc-platform/BEHAVIOR_MODEL.md) § 2 (NAV requirements) and § 13,
   [IMPLEMENTATION_PLAN.md](../../specs/npc-platform/IMPLEMENTATION_PLAN.md) Phases 1–4 including their known limits
   and developer test steps, on knk-workspace `next`.
2. The developer's test results of 2026-11-14 on [#359](https://github.com/PandiO/knk-workspace/issues/359),
   [#360](https://github.com/PandiO/knk-workspace/issues/360), [#361](https://github.com/PandiO/knk-workspace/issues/361)
   and [#377](https://github.com/PandiO/knk-workspace/issues/377): Phase 3 passed; Phase 2 fails at the stair corner
   (#491); Phase 4 steps 3, 4, 6, 8, 12, 14 work, steps 5 and 7 stuck (#492), 9 (#507), 10 (#506) fail, 11
   inconclusive.
3. The scope issues **and their comments**: [#508](https://github.com/PandiO/knk-workspace/issues/508) (wall
   corners), [#491](https://github.com/PandiO/knk-workspace/issues/491), [#492](https://github.com/PandiO/knk-workspace/issues/492)
   (three comments: the stuck spot, the screenshot, the retest after the road line moved),
   [#493](https://github.com/PandiO/knk-workspace/issues/493) (two developer comments: shoulder to shoulder, smaller gap
   between ranks), [#506](https://github.com/PandiO/knk-workspace/issues/506),
   [#507](https://github.com/PandiO/knk-workspace/issues/507) (developer decision 2026-11-14: keep follow-the-leader,
   add a toggle so followers finish the trip).
4. The L1 design once the developer approves it (binds L3 and L4), and the developer's answers to the L1 questions
   (recorded on #519 and in the report § 3).
5. The global instructions, "Testing: automated first" (on `main` since `8576b1be`, 2026-11-14), and the
   knk-test-writer skill.

## 1. Links

| Link | Sub-issue | Tier | What | Repos | Branch | Base | Flag | Gate |
|---|---|---|---|---|---|---|---|---|
| L1 | #519 | tier:3 | Design: BEHAVIOR_MODEL / IMPLEMENTATION_PLAN for #508 (corner clearance, turns through the corner point, recovery target on the NPC's own floor, recovery order back-off → side-step → local leg ahead → replan, retry spacing and cap, stats), #493 (lateral spacing key, narrowed shapes incl. `escort-ring`, hysteresis, metrics) and the #507 toggle (name, per group, config default) | knk-workspace | `claude/npc-followups-l1` | `next` | none (docs) | now |
| L2 | #520 | tier:3 | #506 follower recheck and trespass guard; #507 no gate push on NPCs; tests | knk-plugin, knk-workspace | `claude/npc-followups-l2` | `next` | `npc.navigation.enabled` (off) | now (no other knk-plugin link or session on the same files) |
| L3 | #521 | tier:3 | #508 with #491 and #492 per the L1 design; corner test scene | knk-plugin, knk-workspace | `claude/npc-followups-l3` | `next` | `npc.navigation.enabled` (off) | L1 approved and merged into `next`; L2 merged into `next` |
| L4 | #522 | tier:3 | #493 narrowed formations and tighter spacing; #507 toggle; #490 audit re-run in its test steps | knk-plugin, knk-workspace | `claude/npc-followups-l4` | `next` | `npc.navigation.enabled` (off) | L3 merged into `next` |
| L5 | #592 | tier:3 | Fix L3's retest failures: the #491 stair corner is still cut (route points 216–221), the `ranks` right row stuck at 1433 44 -518 (#492); scenarios from the real geometry | knk-plugin, knk-workspace | `claude/npc-followups-l5` | `next` | `npc.navigation.enabled` (off) | developer retest 2026-11-15 (now) |
| L6 | #593 | tier:3 | Fix L2's retest failure (#506 step 10): followers enter a district whose entry was removed where a gate region overlaps the district entry | knk-plugin, knk-workspace | `claude/npc-followups-l6` | `next` | `npc.navigation.enabled` (off) | L5 merged into `next` |
| L7 (dropped: #490 clean on the right build) | #594 | tier:2 | #490: test walkers still drown (DROWNING 809 with the dry walkers) | knk-plugin, knk-workspace | `claude/npc-followups-l7` | `next` | none (test walkers only) | L6 merged into `next` |
| L8 | #603 | tier:3 | Design: movement quality (local steering and lookahead, formation keeping with narrowing before folding, crowding and yielding, plaza road lines), real spots as scenarios, implementation links in plan Phase 7 | knk-workspace | `claude/npc-followups-l8` | `next` | none (docs) | developer decision 2026-11-15 (now); implementation after the developer's approval |
| M1 | #621 | tier:2 | Evidence and diagnostics: schematic scenes, five report-mode scenarios (collision on/off), fold reasons, corridor trace (plan 4c.4 item 1) | knk-plugin, knk-workspace | `claude/npc-movement-m1` | `next` | none (no behaviour change) | L8 merged (now) |
| M2 | #622 | tier:3 | Corridor steering, option A (4c.4 item 2) | knk-plugin, knk-workspace | `claude/npc-movement-m2` | `next` | `corridor-steering` (off) | M1 merged |
| M6 | #623 | tier:2 | Clearance-aware local legs and recovery, add-on D (4c.4 item 6) | knk-plugin, knk-workspace | `claude/npc-movement-m6` | `next` | `local-legs-clearance` (off) | M2 merged |
| M3 | #624 | tier:3 | Formation keeping (4c.4 item 3) | knk-plugin, knk-workspace | `claude/npc-movement-m3` | `next` | `group-formation-keeping` (levels = today) | M6 merged |
| M5 | #625 | tier:2 | Plaza lines (4c.4 item 5) | knk-plugin, knk-workspace | `claude/npc-movement-m5` | `next` | `plaza-lines` (off) | M3 merged |
| M4 | #626 | tier:3 | Crowd awareness (4c.4 item 4); then the option-B checkpoint (item 8) | knk-plugin, knk-workspace | `claude/npc-movement-m4` | `next` | `crowd-awareness` (off) | M5 merged |
| M7 | #627 | tier:3 | Collision on with push resistance and recovery (4c.4 item 7) | knk-plugin, knk-workspace | `claude/npc-movement-m7` | `next` | `npc.navigation.collidable` (default on only at its end) | B checkpoint done |
| L9 | #668 | tier:3 | Realtime deny for running groups: NPC rule checks saw no WorldGuard region (module started before the region tracker) | knk-plugin, knk-workspace | `claude/npc-followups-l9` | `next` | `npc.navigation.enabled` (off) | smoke test 2026-11-16 (merged `a78fcce8`) |
| B1 | #670 | tier:2 | Evidence: `/knk npc nav snapshot <route>` (region files, route line, roads, domains along the route, settings) with replay support; the stair-house scene over the whole schematic on the real route with short stretches, failing on `next` (report decisions 33–35) | knk-plugin, knk-workspace | `claude/npc-movement-b1` | `next` | none (admin command, scenarios) | L9 merged |
| B2 | #671 | tier:3 | Stretch handover: 3D progress, append instead of replace, bridge from the feet, unbridgeable step as a local leg, no falls copied into the group path | knk-plugin, knk-workspace | `claude/npc-movement-b2` | `next` | `npc.navigation.enabled` (off) | B1 merged |
| B3 | #672 | tier:2 | Crowd turns judged in 3D | knk-plugin, knk-workspace | `claude/npc-movement-b3` | `next` | `crowd-awareness` (off) | B4 merged; needed (report decision 39) |
| B4 | #673 | tier:2 | Waypoints and group slots at real stair heights; jump detection by upward speed | knk-plugin, knk-workspace | `claude/npc-movement-b4` | `next` | `npc.navigation.enabled` (off) | B2 merged (report decision 38) |
| B5 | #699 | tier:3 | Group followers under a leader one flight above: lanes, rejoin and slots in 3D (smoke test 2026-11-17) | knk-plugin, knk-workspace | `claude/npc-movement-b5` | `next` | `npc.navigation.enabled` (off) | B3 merged |
| C1 | #700 | tier:3 | Off-road starts and ends with today's walk search within its caps, walked like stretches; road join by reachability; hops as fallback; snapshot box over from/to (long walks come from #698) | knk-plugin, knk-workspace | `claude/npc-movement-c1` | `next` | `npc.navigation.enabled` (off) | B5 merged and #698 phase 1 (move to `core/navigation/shape/`) merged (report decision 44) |
| E1 | #701 | tier:2 | Exit rules checked while NPCs walk (recheck, trespass guard, follower lanes), not only when planned | knk-plugin, knk-workspace | `claude/npc-movement-e1` | `next` | `npc.navigation.enabled` (off) | C1 merged |
| R1 | #724 | tier:2 | A cache refresh's first event with an empty region map lets held NPCs cross; fix the refresh path, count such a crossing | knk-plugin, knk-workspace | `claude/npc-movement-r1` | `next` | `npc.navigation.enabled` (off) | E1 merged; off-road coordinator's OK (2026-11-18) |
| J1 | #695 | tier:2 | The stair-climb's intermittent jump toward a waypoint (CI flake) and the hall-entry jumps; the check stays as it is | knk-plugin, knk-workspace | `claude/npc-movement-j1` | `next` | `npc.navigation.enabled` (off) | developer go 2026-11-19 |
| H1 | #779 | tier:2 | NPC checks agree with the walk search on open roof hatches over ladders | knk-plugin, knk-workspace | `claude/npc-movement-h1` | `next` | `npc.navigation.enabled` (off) | J1 merged |
| G1 | #814 | tier:2 | Road goal by reachable walk length for NPC point destinations, shared with F2 (#780) | knk-plugin, knk-workspace | `claude/npc-movement-g1` | `next` | `npc.navigation.enabled` (off) | H1 merged; where the shared rule lives agreed with the off-road chain |

## 2. Gates

1. "L<n> merged into `next`": `git rev-list --count origin/next..origin/claude/npc-followups-l<n>` is 0 in every repo
   L<n> changed.
2. "L1 approved": the developer's approval of the design, in this session or as a comment on #519. Asked by the
   coordinator with the open points; recorded in the report § 3.
3. "No other knk-plugin link or session on the same files" (L2): the open knk-plugin PRs and the "In progress" rows on
   the sessions board, checked at start. See chain note 1.

Order and parallelism: L1 (knk-workspace only) and L2 run together. At most one running link in knk-plugin, so L3 and L4
run after L2, one at a time. The fix links L5, L6, L7 run in that order, one knk-plugin link at a time (priority: the stair-release gate first).

## 3. Chain notes

1. **Overlap with the #486 fix session** (knk-plugin `claude/erasure-first-join-486-retest`, unmerged at start, no PR
   yet). It changes `core/npc/nav/NpcMoverFactory`, `paper/npc/citizens/CitizensNpcMover`, `CitizensNpcRuntime`, new
   `DryBlockExaminer`, `paper/npc/nav/NpcTestWalkers`, `KnKPlugin` and the account listeners (the #490 drowning
   walkers and #486). Links don't touch the test walkers or the dry examiner, and keep edits in the other shared files
   additive, outside the lines that branch changes (`git diff origin/next...origin/claude/erasure-first-join-486-retest`
   shows them), so a later merge stays mechanical. L3 and L4 merge `origin/next` again before their PR.
2. **Overlap with the #421 scenario session** (knk-plugin `claude/plugin-scenarios-421`): new `scenario` packages,
   the `config.yml` test flag, the boot workflow. Links don't touch them. Once #421's framework is on `next`, the
   corner test scene (L3) and the gate/access group tests (L2, L4) become scenarios; until then they are "scenario
   later" in the PR's Testing section.
3. **One branch per link** (`claude/npc-followups-l<n>`, from `next`), not the first chain's standing branch, because L1
   and L2 run together. A later link starts from the current `next`, which carries the earlier links.
4. **Flag:** NPC navigation stays off by default (`npc.navigation.enabled: false`); nothing changes for servers with it
   off. New keys go into `NavigationSettings` with a `config.yml` comment, a layer test and the configuration reference
   § 4.27 (the YAML block, also in the PR's deploy notes).
5. **Engine neutrality** (first chain's note 4): no Citizens or Bukkit type outside `paper/npc/citizens/` and the Paper
   wiring; new engine needs are new port methods.
6. **Developer test steps** use routes that exist on the dev world: `quarry-to-keep` (through the south gate and the
   stair house) and a short route through the south gate (#360: there is no `south-gate` route). Every link reports its
   developer test steps on its sub-issue. L4's steps include the developer's #490 audit re-run once the #486 session's
   walker fix is in `next`.
7. **Tests, automated first:** every link loads the knk-test-writer skill and runs its suites in its baseline and
   before its PR (`./gradlew build -x deployToDevServer`; the `taggedTest` and `paper-boot` jobs where they apply).
8. **Migrations:** none (plugin and docs only).
9. **Model for link sessions:** the coordinator's model from `get_session`, passed explicitly to `create_session`.
