# KNK Requirements & Specs Hub

Central home for requirements, specifications, and implementation roadmaps across KNK services (web API, web app, and Minecraft plugin). Keep new cross-cutting docs here so they are discoverable by all teams and AI assistants.

## Structure
- project-overview/: portfolio-level summaries and source pointers (CHANGES, implementation roadmap, source map)
- users/: user/account management specs and requirements (including linking, merge, password rules)
- towns/: towns/world feature specs and hybrid create/edit flow notes
- api/: API contract snapshots and backlog for REST endpoints
- legacy/: legacy reference notes kept for historical context
- reconcile/: reconciliation guides for aligning legacy data with v2

## Key documents
- User domain: [docs/specs/users/SPEC_USER.md](docs/specs/users/SPEC_USER.md), [docs/specs/users/SPEC_USER_ACCOUNT_MANAGEMENT.md](docs/specs/users/SPEC_USER_ACCOUNT_MANAGEMENT.md), [docs/specs/users/REQUIREMENTS_USER.md](docs/specs/users/REQUIREMENTS_USER.md), [docs/specs/users/USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md](docs/specs/users/USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md), [docs/specs/users/USER_ACCOUNT_MANAGEMENT_QUICK_REFERENCE.md](docs/specs/users/USER_ACCOUNT_MANAGEMENT_QUICK_REFERENCE.md)
- Towns domain: [docs/specs/towns/SPEC_TOWNS.md](docs/specs/towns/SPEC_TOWNS.md), [docs/specs/towns/CREATE_FLOW_SPLIT_TOWNS.md](docs/specs/towns/CREATE_FLOW_SPLIT_TOWNS.md), [docs/specs/towns/LOGIC_CANDIDATES_TOWNS.md](docs/specs/towns/LOGIC_CANDIDATES_TOWNS.md), [docs/specs/towns/REQUIREMENTS_HYBRID_CREATE_EDIT_FLOW.md](docs/specs/towns/REQUIREMENTS_HYBRID_CREATE_EDIT_FLOW.md)
- Portfolio overview: [docs/specs/project-overview/IMPLEMENTATION_ROADMAP.md](docs/specs/project-overview/IMPLEMENTATION_ROADMAP.md), [docs/specs/project-overview/CHANGES_SUMMARY.md](docs/specs/project-overview/CHANGES_SUMMARY.md), [docs/specs/project-overview/SOURCES_LOCATION.md](docs/specs/project-overview/SOURCES_LOCATION.md)
- API contract snapshots: [docs/specs/api/README.md](docs/specs/api/README.md) (includes swagger export and contract notes)
- Reconciliation: [docs/specs/reconcile/README.md](docs/specs/reconcile/README.md)
- Legacy reference: [docs/specs/legacy/README.md](docs/specs/legacy/README.md)

## Conventions
- Keep feature requirements and roadmaps grouped by domain folder above.
- When adding a new feature, create a subfolder under docs/specs that matches the domain and add a short entry in this README.
- Cross-link related docs (API contracts, UI flows, in-game flows) so teams can navigate quickly.
- Leave module-local implementation notes near the code, but keep cross-cutting requirements here.
