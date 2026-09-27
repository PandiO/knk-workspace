Read docs/ai-agents/handoffs/ROAD_NAVIGATION_CHAIN.md first and follow it; it overrides anything below.

Implement road navigation **Phase 1 — knk-web-api: data model, services, API** from
docs/specs/navigation/IMPLEMENTATION_PLAN.md, end to end (code, tests, commits, push to `claude/road-navigation`, plan
status block, progress report, handoff), as **link 1** of the chain.

State you start from: nothing implemented yet. `claude/road-navigation` doesn't exist — create it in knk-web-api from
`origin/master` (chain charter §1.2). You also create the progress report `docs/reports/2026-09-27-road-navigation-chain.md`
(charter §7) and claim the feature in `docs/ACTIVE_SESSIONS.md`. Record the web-api test baseline first (5 known
failures, by name, plan §0.4).

What earlier phases say Phase 1 must wire: nothing — you are first. Later phases depend on your DTO/route shapes:
Phase 2e mirrors your DTOs in Java (`@JsonProperty` names = your camelCase `[JsonPropertyName]`s), Phase 3 calls
`PUT api/road-tiles/{world}/{x}/{z}/graph`, `GET …/graph` with ETag/304, `GET api/road-network/meta`,
`GET api/road-network/seed-locations`; Phase 5 calls the profile/tile/edge endpoints. Keep the routes and field names
exactly as the plan's Phase 1 tables say; if you must change one, write it prominently in your status block under
"What later phases must wire".

Phase-specific reading: plan §0, §1 (D1, D3-D8, D11, D12), §2 rows R29-R33, Phase 1 (all of it); DESIGN §3, §5.6-5.11
(what the upsert, stitching, components and street labelling must do), §7.1 E (street renames stay on the Street
entity).

Open flags that affect this phase: none from earlier links. Watch: EF InMemory cascades only tracked entities —
delete edges explicitly (plan 1.4); every indexed string needs `HasMaxLength` (plan 1.2); the `Tests/` folder is
capital T; `dotnet` may need installing (charter §1.4).

Known risks: the migration must pass all four steps of the fresh-DB CI workflow (update, no pending model changes,
roll back to 0, re-apply) — run them locally against a throwaway MySQL if you can, otherwise rely on the workflow
after push and flag if you can't read its result.

Next after you: **Phase 2a** (knk-plugin core extractions). Write
`docs/ai-agents/handoffs/<date>-road-navigation-phase-2a.md` and start it per charter §6.
