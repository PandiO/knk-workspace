# Handoff: road navigation rev. 6 Part B — curated tiles

**Status:** Ready to start on 2026-10-05 (written 2026-10-04 evening by the Claude Code session that did finding L).
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27). **Prompt for:** a Claude Code session on the developer's
machine (knk-workspace with the component repos under `Repository/`).

---

> **Update 2026-10-05 (cloud session):** D1-D7 are answered and recorded in plan §5.7 ("Decisions"), which also
> rewrites the step table. Implementation runs on `claude/road-curated-tiles-nsrorb` in knk-web-api (from `7f99cbd`)
> and knk-plugin (from `75f6a0e`); see "§5.7 status" for what is done. The developer runs the builder-5 re-test with
> the `claude/navigation-walkable-path` jar before deploying this branch or applying the B1 migration. A local session
> picking this up: skip "First step", read §5.7 status, back up `road_tiles` and apply the migration only with a
> go-ahead.

Read `AGENTS.md`, `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md` and `docs/ACTIVE_SESSIONS.md` first; the KNG-27 row is
yours, so update it when you start and stop. Then read, in this order:
1. `docs/specs/navigation/IMPLEMENTATION_PLAN.md` **§5.7**: the work (steps B1-B4), the dependency rules and the
   **open decisions D1-D7**.
2. `docs/specs/navigation/REV6_PROPOSAL.md` §3: the idea behind it (and §2, Part A, which comes after).
3. `docs/guides/road-navigation-smoke-test.md`, "Build v202 analysed" (finding L): the current builder state and the
   re-test list.

## State at handoff (2026-10-04, nothing pushed by this session)

| Repo | Branch | Head |
|---|---|---|
| knk-plugin | `claude/navigation-walkable-path` | `75f6a0e` (merge of origin/main on top of builder 5 `5d9a5e9`). Gradle: core 1659, api-client 185, paper 1177, all green. |
| knk-web-api | `claude/road-navigation` | `7f99cbd` (merge of origin/master on top of `070b747`). Tests: master's 8 existing failures plus the known locale failure `Validation_GeometryFarFromItsNode`. Migration `AddRoadNodePlazaRadius` is applied on the dev DB. |
| knk-workspace | `claude/road-navigation-smoke-test-bugs-fagl4i` | this handoff's commit (on top of merge `b55fad4`). |

- Builder 5 is **not deployed** yet. The developer may deploy it and run the finding L re-test first; ask how it went,
  because the result can change decision D2.
- The developer's Visual Studio debugger may be running the API from `knk-web-api/bin/Debug`. Build and test with
  `--artifacts-path <scratch>` instead of touching it.
- `./gradlew build` deploys the jar to the dev server; use `./gradlew build --offline -x deployToDevServer`.

## First step

Ask the developer decisions **D1-D7** (plan §5.7, with recommendations) in one short message, and whether builder 5 is
deployed and re-tested. Do not start B1 before the answers. B1 includes a migration: back up `road_tiles` first
(mysqldump from MySQL Workbench, with a defaults file without a `database=` line; delete it afterwards), and apply it
only with the developer's explicit go-ahead.

## Then

Implement B1 → B4 in order, one commit per step, each with its tests. Record progress in a "§5.7 status" block in the
plan and in the tracker row.
- Keep `navigation.builder.curated-tiles: false` working as today's behaviour.
- Code pointers:
  - knk-web-api: `Models/Roads/RoadTile.cs`, `Services/RoadNetworkService.cs` (the edit endpoints listed in B1),
    `Controllers/RoadTilesController.cs`.
  - knk-plugin core: `core/roads/build/{TileBuilder,TileBuildResult,NodeMatcher}`; ids are already matched there,
    which is what `TileDiff` needs.
  - knk-plugin paper: `paper/roads/{RoadBuildJob,RoadBuildQueue,RoadAdminCommand,RoadOverlayRenderer,RoadTileCache}`.

## Rules

- knk-web-api tests are tracked under `Tests/` (capital T) while the folder on disk is `tests/`. Stage new test files
  with `git update-index --add --cacheinfo` under the `Tests/` path.
- The dev DB is read-only unless the developer approves a write; migrations need a go-ahead each time.
- Never run the road reset script, and never import the old phpMyAdmin dump (it drops tables).
- Before changing shared builder code, confirm the cause from data and code and report it.
- The offline replay harness is in `docs/ai-agents/handoffs/road-replay/` (README there). Use it to check that B2's diff
  shows exactly the changes a config or builder change makes on tile 2,-2.
- Keep messages to the developer short; they check in between other work.
