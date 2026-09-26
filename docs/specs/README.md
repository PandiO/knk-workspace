# KNK Requirements & Specs Hub

Central home for requirements, specifications, and implementation roadmaps across KNK services (web API, web app, and Minecraft plugin). Keep new cross-cutting docs here so they are discoverable by all teams and AI assistants.

## Structure
- project-overview/: portfolio-level summaries and source pointers (CHANGES, implementation roadmap, source map)
- users/: user/account management specs and requirements (including linking, merge, password rules)
- towns/: towns/world feature specs and hybrid create/edit flow notes
- api/: API contract snapshots and backlog for REST endpoints
- items/: item catalog (`ItemBlueprint`) design/implementation
- kits/: Kit (equipment loadout) design, implementation plan, and legacy-DB seed data
- user-features/: rank/permission/title/salary architecture
- user-management/: tailored admin module built on top of user-features
- legacy/: legacy reference notes kept for historical context
- reconcile/: reconciliation guides for aligning legacy data with v2

## Key documents
- User domain: [docs/specs/users/SPEC_USER.md](docs/specs/users/SPEC_USER.md), [docs/specs/users/SPEC_USER_ACCOUNT_MANAGEMENT.md](docs/specs/users/SPEC_USER_ACCOUNT_MANAGEMENT.md), [docs/specs/users/REQUIREMENTS_USER.md](docs/specs/users/REQUIREMENTS_USER.md), [docs/specs/users/USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md](docs/specs/users/USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md), [docs/specs/users/USER_ACCOUNT_MANAGEMENT_QUICK_REFERENCE.md](docs/specs/users/USER_ACCOUNT_MANAGEMENT_QUICK_REFERENCE.md)
- Towns domain: [docs/specs/towns/SPEC_TOWNS.md](docs/specs/towns/SPEC_TOWNS.md), [docs/specs/towns/CREATE_FLOW_SPLIT_TOWNS.md](docs/specs/towns/CREATE_FLOW_SPLIT_TOWNS.md), [docs/specs/towns/LOGIC_CANDIDATES_TOWNS.md](docs/specs/towns/LOGIC_CANDIDATES_TOWNS.md), [docs/specs/towns/REQUIREMENTS_HYBRID_CREATE_EDIT_FLOW.md](docs/specs/towns/REQUIREMENTS_HYBRID_CREATE_EDIT_FLOW.md)
- Portfolio overview: [docs/specs/project-overview/IMPLEMENTATION_ROADMAP.md](docs/specs/project-overview/IMPLEMENTATION_ROADMAP.md), [docs/specs/project-overview/CHANGES_SUMMARY.md](docs/specs/project-overview/CHANGES_SUMMARY.md), [docs/specs/project-overview/SOURCES_LOCATION.md](docs/specs/project-overview/SOURCES_LOCATION.md)
- API contract snapshots: [docs/specs/api/README.md](docs/specs/api/README.md) (includes swagger export and contract notes)
- Items domain: [docs/specs/items/IMPLEMENTATION_PLAN.md](docs/specs/items/IMPLEMENTATION_PLAN.md)
- Kits domain: [docs/specs/kits/DESIGN.md](docs/specs/kits/DESIGN.md), [docs/specs/kits/IMPLEMENTATION_PLAN.md](docs/specs/kits/IMPLEMENTATION_PLAN.md), [docs/specs/kits/SEED_DATA.md](docs/specs/kits/SEED_DATA.md)
- User features (rank/permissions/title/salary): [docs/specs/user-features/DESIGN.md](docs/specs/user-features/DESIGN.md), [docs/specs/user-features/IMPLEMENTATION_PLAN.md](docs/specs/user-features/IMPLEMENTATION_PLAN.md)
- User management (admin module): [docs/specs/user-management/DESIGN.md](docs/specs/user-management/DESIGN.md), [docs/specs/user-management/IMPLEMENTATION_PLAN.md](docs/specs/user-management/IMPLEMENTATION_PLAN.md)
- Reconciliation: [docs/specs/reconcile/README.md](docs/specs/reconcile/README.md)
- Legacy reference: [docs/specs/legacy/README.md](docs/specs/legacy/README.md)
- Siege minigame (MVP driver, vision §7): [siege-minigame/DESIGN.md](siege-minigame/DESIGN.md),
  [siege-minigame/IMPLEMENTATION_PLAN.md](siege-minigame/IMPLEMENTATION_PLAN.md),
  [siege-minigame/MENU_TEMPLATES.md](siege-minigame/MENU_TEMPLATES.md) (legacy siege menus inventoried
  item-by-item + proposed v3 templates, built in Phase 8b); evidence in
  [../reports/2026-09-25-siege-minigame-gap-analysis.md](../reports/2026-09-25-siege-minigame-gap-analysis.md).
  **Status (2026-09-26):** MVP phases 1–9 code complete on `claude/siege-minigame` (Phase 9: non-live parts only;
  plugin code from Phase 6b on not compiled yet), not merged; playtesting open. Admin how-to:
  [../guides/authoring-a-siege-scenario.md](../guides/authoring-a-siege-scenario.md)
- Command catalogs (every Minecraft command across all three codebases — syntax, permissions,
  behavior, feature allocation): [docs/specs/legacy/commands-v1.md](docs/specs/legacy/commands-v1.md),
  [docs/specs/legacy/commands-v2.md](docs/specs/legacy/commands-v2.md),
  [docs/specs/user-features/COMMAND_CATALOG_V3.md](docs/specs/user-features/COMMAND_CATALOG_V3.md)
- Event-listener catalogs (every Bukkit/Spigot event handler across all three codebases — the
  passive/reactive behavior commands don't cover): [docs/specs/legacy/events-v1.md](docs/specs/legacy/events-v1.md),
  [docs/specs/legacy/events-v2.md](docs/specs/legacy/events-v2.md),
  [docs/specs/user-features/EVENT_CATALOG_V3.md](docs/specs/user-features/EVENT_CATALOG_V3.md)

## Conventions
- Keep feature requirements and roadmaps grouped by domain folder above.
- When adding a new feature, create a subfolder under docs/specs that matches the domain and add a short entry in this README.
- Cross-link related docs (API contracts, UI flows, in-game flows) so teams can navigate quickly.
- Leave module-local implementation notes near the code, but keep cross-cutting requirements here.
