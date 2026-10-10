# Handoff: road navigation P4 — a region over part of a road's width

**Status:** Ready, 2026-10-10. Prompt for a Claude Code session **on the developer's machine** (knk-workspace with the
component repos under `Repository/`, dev DB read-only, dev server), **with Linear access**.
**Linear:** none yet. Create one first (below). Related: [KNG-92](https://linear.app/kngpandi/issue/KNG-92) (rev. 7:
routing view, entry rule on roads), [KNG-76](https://linear.app/kngpandi/issue/KNG-76) (centred trails),
[KNG-104](https://linear.app/kngpandi/issue/KNG-104) (domain cache).
**Last updated:** 2026-10-10

---

Read `AGENTS.md`, `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md` and `docs/ACTIVE_SESSIONS.md` first, then:
1. `docs/specs/navigation/REV7_PROPOSAL.md`: §2 (routing view), §4 (Part C), §7.2 (implementation notes).
2. `docs/specs/navigation/DESIGN.md`: §6.4 (centred trail, KNG-76) and §6.7 (availability, routing view, fresh domain rules).
3. `docs/guides/road-navigation-smoke-test.md`, section "Rev. 7 Part A — routing view": run 2, finding **P4**.

## Rules for this session (developer)

- **Develop only in worktrees**, never in the main checkouts (`Repository/knk-*`). The developer switches those between
  branches and runs the API, web app and dev server from them. Plugin:
  `git -C Repository/knk-plugin worktree add <abs>/Repository/_worktrees/knk-plugin-p4 -b claude/navigation-p4-partial-width-regions origin/main`.
- **Docs and the tracker** also go through a workspace worktree based on `origin/main`
  (`Repository/_worktrees/knk-workspace-docs` exists; `git reset --keep origin/main` before each edit), pushed to
  `main`. Other sessions commit in the shared workspace checkout.
- Claim the work in `docs/ACTIVE_SESSIONS.md` **before** editing code. Check the in-progress rows: a KNG-75 session
  works in `paper/navigation/NavigationService`, `paper/navigation/walk/` and the navigation config; KNG-52 has just
  merged. Coordinate before touching their files.
- Plugin build: `./gradlew build --offline -x deployToDevServer` (a plain `build` deploys to the dev server). The
  developer deploys with `./gradlew :knk-paper:dev` from the worktree. Count test results from
  `*/build/test-results/test/*.xml`.
- One commit per fix, each with tests, and **check that every new test fails without its fix** (break the code, run,
  restore).
- When the branch is merged, remove your worktree yourself after checking that no process runs from it.

## The problem (P4)

The navigator judges a road by its **centre line** only: the floor blocks of the edge geometry. `LiveEdgeTags` samples
each edge every `EdgeTagging.REGION_STEP` (2 blocks) at feet level (`Probe.regionsAt`), and `RoutingView.spans` cuts
the edge where the region tags change. A no-entry region that covers the centre row blocks that stretch, even when part
of the road's width is still free.

**Seen (live test 2026-10-09, run 2):** Kardenna end, edge **#5228**, a road three blocks wide. Its centre line runs
along **z = -477** for x ≈ 1391-1397.
- A region covering **z -479..-478** (one outer row) did not touch the centre: the road stayed open and the player
  walked past it.
- A region covering **z -479..-477** (two rows, including the centre) blocked the stretch: the route went the other
  way round the island into "Navigation Test". A free row (z -476) was still there.

The dev world may have changed since then (the test regions `domain_17` and `tempregion_worldtask_227` came from a
district that was edited badly, see KNG-103). Make fresh test regions for the live test.

**Already handled elsewhere:** houses and shops along a street are set to "Ignored" for roads (rev. 7 Part C): the
router ignores their rule and their regions do not cut roads. P4 is about the remaining cases, where a district or a
structure that does apply to roads overlaps part of a road.

## Proposed fix (confirm the open points with the developer first)

1. **A region blocks a stretch only where it covers the whole width.** In the `LiveEdgeTags` pass, when a sample's
   centre cell has a region, look across the road (perpendicular to the edge, up to `TrailCentring.MAX_HALF_WIDTH` = 3
   blocks each side) at the road cells there. Keep the region's tag on that sample only if it covers every road cell
   of the cross-section, so no free gap of at least the minimum width (1 block) is left. Otherwise drop the tag for
   that sample.
   - Road cells: the same rule as the trail, `TrailCentring.Ground.roadFloor` (profile floor material with room above,
     at the height or one off), implemented by `RoadSurfaceGround` with `RoadNetworkCache.roadMaterialNames()`.
     `LiveEdgeTags.Probe` needs a way to ask that, plus regions at a cell (it has `regionsAt`).
   - Only scan across when the centre has a region: the extra lookups stay near regions. Watch the per-tick budget
     (`LOOKUPS_PER_TICK`).
   - `RoutingView` itself does not change: it still cuts where the (now width-aware) tags change.
2. **The trail goes through the gap.** Otherwise it runs straight into the region and the WorldGuard border pushes the
   player back. `TrailRenderer` centres the trail through `TrailCentring` with a per-**world** `Ground`
   (`TrailRenderer.roadSurface`, `Function<World, TrailCentring.Ground>`). Make it per **player**: cells inside a
   region the player may not enter (and whose domain applies to roads) count as no road, so the centring moves the
   trail to the free part.
   - The access rule is the router's: `DomainAvailability` / `DomainAccessEvaluator`, with the region → domain lookup
     and the bypass in `NavigationAccess`. Reuse that, don't write a second rule.
   - Keep the centred trail stable between redraws (`TrailRenderer.centredWindow`: fixed spots, centred with a margin).
3. **Tests:**
   - core: spans/tags with a region covering part of the width (stays open), the whole width (blocks), and the centre
     only with a one-block gap on one side;
   - `LiveEdgeTagsTest` with a probe giving road cells and a partial region;
   - `TrailCentring` / trail tests with blocked cells;
   - an offline check on a copy of the dev world, like KNG-76 (`tools/road-replay/README.md`: copy the region files
     into scratch, `export_replay.py` reads the dev DB read-only, `RoadReplayTest`'s `Chunk` reader gives the blocks).

### Open points to ask the developer at the start

- **Minimum gap width:** 1 block (a player fits through one block)? Recommended: 1.
- **Exit rule:** a road partly inside a region the player may not *leave* (`AllowExit` false). Today an edge that
  carries the region counts as staying inside. With width-aware tags the free part no longer carries it, so the
  router would treat it as leaving. Recommended: apply the width rule to entry only, and keep exit tags as today (the
  whole cross-section).
- **Doors:** gate doors usually span the whole road. Keep door tagging as it is (not width-aware)? Recommended: yes.

## First steps

1. **Linear:** create an issue, team KngPandi, label Improvement: "Road navigation: a region over part of a road's
   width blocks it only where it covers the whole width (P4)". Link this handoff and the guide's finding P4, and mark it
   related to KNG-92 and KNG-76. Put the issue number into this handoff's header and the tracker row.
2. Tracker row (workspace worktree, pushed to `main`), plugin worktree and branch as above.
3. Ask the three open points (briefly, with the recommendations), then implement, test, document. Add smoke-test steps
   to the guide; suggested:
   - a region over one outer row of a road: open, the trail passes it;
   - over two of three rows including the centre: open, the trail moves to the free row;
   - over the whole width: blocked as before, guidance to its edge;
   - a player with `knk.region.bypass`: the trail stays in the middle;
   - `/knk road status` counts and no lag.
4. After the developer's live test: document the results, update Linear, merge into knk-plugin `main` (merge `main`
   into the branch first and re-run the tests), push, remove the worktree.

## State of trunk (2026-10-10)

- knk-plugin `main` `973aa68b` or later. It has rev. 7 Parts A and C, the "Ignored" no-cut filter (`eea80099`),
  KNG-104 (`1159ae5d`), KNG-76 (`d0167a6d`), KNG-75 steps 1-2 and KNG-52.
- The API and the web app need no change for P4.
- Relevant classes:
  - core: `roads/route/{RoutingView,TrailCentring,DomainAvailability}`, `roads/build/EdgeTagging`;
  - paper: `roads/LiveEdgeTags`, `navigation/{TrailRenderer,RoadSurfaceGround,NavigationAccess}`, and the
    `LiveEdgeTags` / `TrailRenderer` wiring in `KnKPlugin`.
