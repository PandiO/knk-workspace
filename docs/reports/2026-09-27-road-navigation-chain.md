# Road navigation chain — progress report

**Status:** running
**Last updated:** 2026-09-27 (link 1: Phase 1, in progress)
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27) · **Charter:** `docs/ai-agents/handoffs/ROAD_NAVIGATION_CHAIN.md` · **Plan:** `docs/specs/navigation/IMPLEMENTATION_PLAN.md`

## Summary for the developer

| Phase | State | Branch heads | Details |
|---|---|---|---|
| 1 — knk-web-api: data model, services, API | in progress (link 1) | knk-web-api `claude/road-navigation` (from `master` `ccc8c02`) | [Phase 1](#phase-1--knk-web-api-data-model-services-api-link-1) |
| 2a — plugin core extractions | not started | — | |
| 2b — survey maths | not started | — | |
| 2c — builder | not started | — | |
| 2d — router | not started | — | |
| 2e — api-client | not started | — | |
| 3 — plugin paper admin side | not started | — | |
| 5 — web-app admin pages | not started | — | |
| 4 — `/navigate` | waiting for KNG-17 on trunk | — | |

- **Review first:** (filled in per phase)
- **Test when you have time:** pull `claude/road-navigation` in each repo; build the plugin (`./gradlew build -x deployToDevServer`, fix compile errors first if any link marked knk-paper "not compiled"); apply the new web-api migration to the dev DB (developer only); run the web-api; `./gradlew :knk-paper:dev`; then each phase's live checklist from the plan in phase order.

## Phase 1 — knk-web-api: data model, services, API (link 1)

_In progress — started 2026-09-27. Baseline and results are filled in when the phase ends._
