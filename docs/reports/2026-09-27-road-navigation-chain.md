# Road navigation chain — progress report

**Status:** running
**Last updated:** 2026-09-27 (link 1: Phase 1 done; link 2 started on Phase 2a)
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27) · **Charter:** `docs/ai-agents/handoffs/ROAD_NAVIGATION_CHAIN.md` · **Plan:** `docs/specs/navigation/IMPLEMENTATION_PLAN.md`

## Summary for the developer

| Phase | State | Branch heads | Details |
|---|---|---|---|
| 1 — knk-web-api: data model, services, API | **done** (link 1) | knk-web-api `claude/road-navigation` `77e0a29` (from `master` `ccc8c02`) | [Phase 1](#phase-1--knk-web-api-data-model-services-api-link-1) |
| 2a — plugin core extractions | in progress (link 2) | knk-plugin `claude/road-navigation` (to be cut from `main` `eb1d68c`) | |
| 2b — survey maths | not started | — | |
| 2c — builder | not started | — | |
| 2d — router | not started | — | |
| 2e — api-client | not started | — | |
| 3 — plugin paper admin side | not started | — | |
| 5 — web-app admin pages | not started | — | |
| 4 — `/navigate` | waiting for KNG-17 on trunk | — | |

- **Review first** (ranked): (1) Phase 1 decision 1 — stitch edges are owned by the last-built tile and reference the
  neighbour's node by id, so a tile download can point at a node of another tile; (2) decision 2 — Detected nodes
  touched by a Recorded edge survive rebuilds; (3) decision 6 — "continue along the road" writes Manual labels on
  every edge it reaches; (4) decision 4 — Inferred labels are recomputed from scratch per build (conflicts →
  unlabelled + warning). All in the plan's "Phase 1 status" block.
- **Test when you have time:** pull `claude/road-navigation` in each repo; build the plugin (`./gradlew build -x deployToDevServer`, fix compile errors first if any link marked knk-paper "not compiled"); apply the new web-api migration to the dev DB (developer only); run the web-api; `./gradlew :knk-paper:dev`; then each phase's live checklist from the plan in phase order.

## Phase 1 — knk-web-api: data model, services, API (link 1)

- **Commits** (knk-web-api `claude/road-navigation`, cut from `master` `ccc8c02`): `55d5aaa` enums/models/DbContext/
  JsonColumn/RoadManage · `8553dec` migration `AddRoadNetwork` + bootstrap profile · `c7df10e` DTOs, mapping,
  repository, `RoadNetworkService`, labeler, components, tests · `77e0a29` controllers (ETag/304), Street counts,
  `StreetServiceTests`. Workspace `main`: this report, plan header + "Phase 1 status" block, tracker rows, handoff
  `docs/ai-agents/handoffs/2026-09-27-road-navigation-phase-2a.md`.
- **Tests:** 1524 → 1627 passed, the same 5 known failures (named in the plan status), 42 skipped. Migration passed
  the four fresh-DB steps locally (MySQL 8.0.46 via apt) and in the `Migrations (fresh DB)` workflow on every
  commit that carries it (runs 108/110/111 green; 107 was the models-only commit, red as expected).
- **Acceptance:** Swagger shows the 17 road routes; a two-tile hand-made payload round-tripped on the running API
  (PUT 200 → GET with `ETag: "1"` → 304 on repeat; stitch across the tiles; dirty → Stale; 401/400 cases).
- **Flagged decisions:** 15, numbered in the plan status block; the four worth a look are in the summary above.
- **Discrepancies:** the cloud proxy blocks the dotnet install hosts but `apt-get install dotnet-sdk-8.0` /
  `mysql-server` work (plan §0.4 updated in the status block); web-api trunk had moved to `ccc8c02`; `dotnet run`
  listens on `localhost:5294` (launchSettings); `StreetsController` is in namespace `KnKWebAPI.Controllers`.
- **Live checklist:** plan "Phase 1 status → Developer to-do" (6 Swagger steps, ~5 min, payloads included).
- **Risks:** none open for this phase. Contract for later phases is written under "What later phases must wire".
- **Next link:** handoff `docs/ai-agents/handoffs/2026-09-27-road-navigation-phase-2a.md`; started per charter §6
  option 1 (Claude Code Remote `create_session` in the same environment) — the session id is appended below once created.
