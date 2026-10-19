# New-session prompt: implement the drawbridge keyframed plank

**Date:** 2026-10-16
**Status:** Ready to copy into a fresh session
**Canonical design:** [DRAWBRIDGE_KEYFRAME_ANIMATION.md](../../specs/gate-structure-animation/DRAWBRIDGE_KEYFRAME_ANIMATION.md)
(on knk-workspace `main` since 2026-10-18, when the docs branch was merged and deleted; decided 2026-10-16)
**Last updated:** 2026-10-19. Rechecked: KNG-132 and KNG-139 are merged, so the web/API part is in scope.
**State (2026-10-19):** knk-plugin `main` `147806d8`, knk-web-app `main` `e30c815`, knk-web-api `master` `73c70d5`,
knk-workspace `main` `a624b7d`.
- KNG-132 is merged in knk-plugin (`82455cf5`, `GateReferencePoints`) and knk-web-app (`7c00508`). Its API description
  migration was not merged; the GateDoor field descriptions come from KNG-139's seed instead (`b04b429`).
- KNG-139 is merged in knk-web-api (`2929972`, `Data/FormConfigurationSeeds/GateDoor.json`).
- KNG-182 (Paper 26.3, Java 25) is open on knk-plugin `claude/mc-26.2-upgrade`; it changes only build files, no gate
  code.

```text
Implement the drawbridge "keyframed plank" animation for Knights and Kings
(ROTATION gate doors with a horizontal hinge). The design is decided; your job
is the knk-plugin implementation, the GateDoor form-seed change, tests and
doc updates. Do not redesign it,
and do not re-tune the old blend (residual taper, snap radius, rigid fit).

READ FIRST
- knk-workspace main: AGENTS.md, docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md,
  docs/ACTIVE_SESSIONS.md (the "Drawbridge animation redesign" row is this
  feature).
- knk-workspace main (merged 2026-10-18 from the deleted branch
  claude/drawbridge-keyframe-animation):
  - docs/specs/gate-structure-animation/DRAWBRIDGE_KEYFRAME_ANIMATION.md:
    §5 method, §5.11 door shape mask, §8 decisions, §9 plan.
  - scripts/gate-animation/drawbridge_keyframes_sim.py: the Python reference
    implementation. Your Java must reproduce its numbers. It rounds half-up,
    like Math.round.
- knk-plugin CLAUDE.md, in particular the test rule: keep a mocked World in a
  field; never wrap mock(World.class) inline in a Location.

BRANCHES AND TRACKING
- knk-plugin: create claude/drawbridge-keyframe-animation from a freshly
  fetched main (main was 147806d8 on 2026-10-19).
  - KNG-182 (Paper 26.3, Java 25, branch claude/mc-26.2-upgrade) may merge
    while you work. It touches only build files. If it lands, merge main into
    your branch and rebuild on Java 25; don't wait for it.
- knk-web-api (and knk-web-app only if needed): a branch of the same name from
  a freshly fetched master/main, for the form part below.
- knk-workspace: the old docs branch claude/drawbridge-keyframe-animation was
  merged and deleted on 2026-10-18; cut a new branch of that name from a freshly
  fetched main for doc changes.
- Tracker rows go to knk-workspace main as single commits (the repo's
  convention). Before editing, update the existing row to claim the knk-plugin
  files below.
- No Linear issue exists yet. Search for a duplicate, then create one (link the
  design doc) and reference its id in commits and the tracker row.

DECIDED (2026-10-16, do not reopen)
D1 Deck length is counted in blocks (an 8-tall door makes an 8-block deck).
D2 MotionDistanceBlocks sets the deck length L for ROTATION doors without an
   open scan (0 = GeometryHeight). An open scan always sets the length,
   because its far edge is the last keyframe; a non-zero value that
   disagrees with it logs a warning at load.
D3 Thin plank: an 8-connected "naive" digital line.
D4 Keyframe timing is linear in angle.
D5 No display entities; real blocks only.
D6 The old path stays behind a config switch until the developer's live check
   passes. It is deleted after that, not in this session.
D7 Nearest-row mask sampling.
D8 The PLANE_GRID scan stays unchanged. Non-rectangular doors use REGION
   (//sel convex) plus ScanMaterialWhitelist.

WHAT TO BUILD (knk-plugin)
1. knk-core: a new Bukkit-free gates/DrawbridgeKeyframes (pure functions,
   Vector only). Precompute the keyframes once per door at load and cache them
   on CachedGateDoor.
   - Basis: cell = anchor + i*uStep + k*e + y*(0,1,0).
     - e is a unit world axis with det(uStep, e) = ±1 in x/z. It points to the
       side the door opens toward: dot > 0 with vStep rotated about the hinge by
       +RotationMaxAngleDegrees.
     - f = (e·uStep)/|uStep|² (0 for cardinal, ½ for 45°).
     - σ = a² + b² for uStep = (a, 0, b).
   - Shape mask: the closed scan's blocks as (a = along-hinge index, v = row).
     H = max v + 1. Columns come from the mask (§5.11), not from GeometryWidth.
   - K = the largest strip index k among the open-scan blocks if there are any;
     otherwise σ*(L-1).
   - Tip: tip(θ) = (K sin θ, (H-1) cos θ) for θ in [0, RotationMaxAngleDegrees].
     One keyframe per change of the rounded tip cell; record the angle at which
     each keyframe starts.
   - Profile: the naive line hinge -> tip, one cell per major-axis step, ordered
     from the hinge. Profile cell p samples mask row round(p*(H-1)/(P-1)).
   - Width: a strip cell at a = i + f*k exists iff the mask has (a, row). When a
     is a half step, both floor(a) and ceil(a) must have that row.
   - Blockdata:
     - material from the sampled mask cell;
     - orientation via GateBlockOrientation at the keyframe angle;
     - cells that never move (the hinge row) keep their scanned blockdata;
     - keyframe 0 = the closed scan verbatim;
     - last keyframe = the open scan verbatim when one exists.
   - Fall back to today's exact path, logging one warning at load, for:
     - slopes without a unit-axis e (e.g. 3:2);
     - closed blocks off the hinge plane (k != 0, e.g. GeometryDepth > 1);
     - DOUBLE_DOORS;
     - an angle outside (0, 90];
     - a missing basis.
2. knk-paper:
   - GateLoaderAdapter builds the keyframes. Build on KNG-132's basis check,
     which is on main (GateReferencePoints): a door it refuses never reaches the
     keyframes.
   - GateAnimationTask, for ROTATION with keyframes:
     - map frame -> current angle -> the last keyframe whose start angle is at
       most that angle;
     - when the index changes, apply only the difference, atomically in that
       tick: remove the leaving cells, place the entering or changed cells;
     - update GateSpatialIndex;
     - keep the jam handling;
     - when lagging, skip to the last keyframe.
   - GateRestingFramePlacer.restingFrameCells returns keyframe 0 or the last
     keyframe for these doors. Startup sync, the world-sync check and the siege
     fake-block view (GateViewCells) then follow automatically.
   - These must read keyframe cells instead of per-block positions for these
     doors:
     - GateSweep.cells (knk-core);
     - CollisionPredictor;
     - GateManager.doorBlockPositions;
     - HealthSystem's block removal.
   - New config gates.rotation.keyframes-enabled in config.yml (default true).
     false = today's exact behaviour, including Mechanism 1 and the open-scan
     blend.
   - Set GateAnimationTask.TRACE_LOGGING_ENABLED to false.

TESTS (unit; reuse GateFrameCalculatorTest.buildRealGate14)
- Entity 14: anchor (1378,44,-588), Ref1 (1375,44,-585), Ref2 (1378,51,-588),
  4 wide × 8 tall, 45°, uStep (-1,0,1), e (-1,0,0), open scan as built
  (K = 13).
  - Expect 21 keyframes.
  - Keyframe 0 = the 32 closed cells.
  - The last keyframe = 49 cells: strips k = 0..13, alternating a = 0,1,2,3
    and a = 0.5,1.5,2.5. This is cell for cell the stored open scan.
- Without an open scan, from the script:
  - 45° 4×8: 22 keyframes, 32 -> 53 blocks;
  - cardinal 4×8: 15 keyframes, 32 -> 32;
  - cardinal 4×8 with L = H: end frames equal today's end frames.
- Arched masks: cardinal 7×9 (column heights 7,8,9,9,9,8,7) gives 17
  keyframes, 57 -> 57; 45° 5×7 (6,7,7,7,6) gives 19, 33 -> 55. For both:
  - keyframe 0 equals the mask;
  - the apex row is present in every keyframe;
  - no cell lies outside the mask outline at its row;
  - a one-row hole survives both resting frames.
- Every keyframe:
  - the tip moves exactly one cell between keyframes;
  - the hinge cell never moves;
  - a cell has one blockdata.
- The fall-back cases above use the old path. With the switch off, the
  existing tests stay green unchanged.

BUILD
- Use ./gradlew build -x deployToDevServer. A plain ./gradlew build deploys to
  the developer's dev server.
- Report pass/fail counts per module (core, api-client, paper). If Maven
  Central rate-limits (429), say which modules were not rerun.

WEB APP / API PART (§9 step 4; KNG-132 and KNG-139 are merged)
- The GateDoor default form is the seed file knk-web-api
  Data/FormConfigurationSeeds/GateDoor.json (KNG-139). It also holds the
  geometry field descriptions (b04b429); KNG-132's own API description
  migration was never merged, so don't recreate it.
- Change the seed:
  - the MotionDistanceBlocks description for ROTATION (deck-length rule, D2);
  - a ScanMaterialWhitelist field for REGION doors (D8);
  - the GeometryDefinitionMode description "PLANE_GRID = rectangular doors
    only" (D8).
- Follow the seed authoring guide, knk-workspace
  docs/specs/form-configurations/DEFAULT_FORM_SEEDS.md. In particular, imports
  never overwrite: follow its rule for a changed seed (new name/guid) instead of
  editing an imported configuration in place. No data migration. The developer
  imports the new seed.
- FormConfigurationSeedFilesTests must stay green; it dry-runs and imports
  every seed.
- knk-web-app: touch the static GateDoorConfig (src/config/objectConfigs.tsx)
  only if the seeded form doesn't cover REGION doors' whitelist. Check before
  editing.

DONE MEANS
- knk-plugin branch pushed, with a green build.
- The web/API branches pushed, and their tests run (API:
  dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj; web app:
  npm run test:ci), with counts reported against the known-red baseline.
- Workspace docs updated on the workspace branch (§9 step 6):
  - mark the ROTATION mid-swing part of ROTATION_GAP_FILL Mechanisms 1–2 as
    superseded when the switch is on;
  - update SPEC.md's gap-fill section;
  - add a "Drawbridges" section to docs/guides/gate-smoke-test.md with §9 step
    5's live checklist.
- Tracker row updated with commits, test counts and the live checks the
  developer must do (§9 step 5): entity 14, a new cardinal 4×6 drawbridge, an
  arched door captured with REGION, and toggling the switch.
- No PR and no merge unless the developer asks. The developer live-tests
  before anything merges.

DATA, IF YOU NEED TO RECHECK STORED GEOMETRY
- The dev DB seed is PandiO/knk-dev-db-seed (public). It holds
  knk_uiux_seed.sql.gz (dump of 2026-10-07).
- Its seed.sh names a file that does not exist. Instead:
  service mysql start
  mysql -uroot -e "CREATE DATABASE knightsandkings_dev_v2"
  zcat knk_uiux_seed.sql.gz | mysql -uroot knightsandkings_dev_v2
- Door 14 is gate_doors.Id 14, "Outer Gate". Run the reference script with
  `mysql -B` exports of its gate_opened_block_snapshots and gate_block_snapshots
  rows; it prints the cell-for-cell check.
```
