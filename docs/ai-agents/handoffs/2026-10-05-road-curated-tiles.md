# Handoff: road navigation rev. 6 Part B — curated tiles

**Status:** Implemented 2026-10-05 (cloud session), **not live-tested**. Next: a Claude Code session on the developer's
machine (knk-workspace with the component repos under `Repository/`), with the dev DB and world available.
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27).
**Last updated:** 2026-10-05

---

Read `AGENTS.md`, `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md` and `docs/ACTIVE_SESSIONS.md` first. The rev. 6
Part B row is yours, so update it when you start and stop. Then read:
1. `docs/specs/navigation/IMPLEMENTATION_PLAN.md` **§5.7**: decisions D1-D7, the steps, and "§5.7 status": what was
   built, how it was verified, the implementation choices, and the developer to-do.
2. `docs/guides/road-navigation-smoke-test.md`: "Build v202 analysed" (finding L re-test), then "Curated tiles
   (rev. 6 Part B) — live re-test".

## State (2026-10-05, everything pushed)

| Repo | Branch | Head | Base |
|---|---|---|---|
| knk-web-api | `claude/road-curated-tiles-nsrorb` | `176b9d3` | `claude/road-navigation` `7f99cbd` |
| knk-plugin | `claude/road-curated-tiles-nsrorb` | `e5d7562` | `claude/navigation-walkable-path` `75f6a0e` |
| knk-workspace | `claude/road-curated-tiles-nsrorb` | this handoff's commit | `main` + `claude/road-navigation-smoke-test-bugs-fagl4i` (`ad7615d`) |
| knk-web-app | — | no change | B5 (later) |

- The decisions are recorded in plan §5.7 and were not asked again. D1: a tile is curated by its first build;
  `uncurate` is one-shot. D5: proposals live in the API. D6 waits for the developer's other world. D7: the replay
  harness is in knk-plugin.
- The developer had **not yet run the finding L re-test** (builder 5) when this was written. That re-test uses the
  `claude/navigation-walkable-path` jar, before anything from this branch.

## Steps for the local session (in order; ask before each DB write)

1. Ask how the finding L re-test went (it runs first, with the `claude/navigation-walkable-path` jar). If it is not
   done yet, help with it first.
2. **Back up `road_tiles`, `road_nodes` and `road_edges`** with mysqldump from MySQL Workbench. Use a defaults file
   without a `database=` line, and delete it afterwards. Then, **only with the developer's explicit go-ahead**, apply
   the migration `20261005084003_AddRoadCuratedTiles` with `dotnet ef database update`. The API never migrates on
   start-up. Report which tiles D2 curated:
   `SELECT TileX, TileZ, State, BuilderVersion FROM road_tiles WHERE World = 'world_KNK-DEV';`
3. Build and deploy this branch's API and plugin. **Only after step 2:** this API build reads the new columns, so it
   fails against a database without the migration.
   - API: `dotnet build --artifacts-path <scratch>`, since the Visual Studio debugger may hold `bin/Debug`.
   - Plugin: `./gradlew build --offline -x deployToDevServer`, then copy the jar, or `./gradlew :knk-paper:dev`.
4. Walk the developer through the guide's "Curated tiles (rev. 6 Part B) — live re-test". Record findings under it.
   Fix bugs on `claude/road-curated-tiles-nsrorb` with a test each, then update "§5.7 status" and the tracker row.
5. Optional: check a proposal offline with the replay harness (`tools/road-replay/README.md` in knk-plugin). Its
   output lists the proposal the live build would make against the stored graph.

## Rules

- knk-web-api tests are tracked under `Tests/`. On a case-insensitive Windows checkout where the folder shows as
  `tests/`, stage new test files with `git update-index --add --cacheinfo` under the `Tests/` path.
- The dev DB is read-only unless the developer approves a write. Migrations need a go-ahead each time.
- Never run the road reset script, and never import the old phpMyAdmin dump (it drops tables).
- Before changing shared builder code, confirm the cause from data and code and report it.
- Keep messages to the developer short; they check in between other work.
