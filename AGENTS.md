# Agent entrypoint — knk-workspace

This repository is the canonical Knights and Kings documentation source. Read
[global instructions](docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md) and
[active sessions](docs/ACTIVE_SESSIONS.md) before changing anything. Check
overlapping claims, publish a feature-scoped claim, and use the standing
feature branch (or create one from the current default branch).

For intended behavior consult the current feature plan and Linear issue; for
implemented behavior inspect the current default branches of affected code
repos. Date and verify old handoffs before using them. Documentation lives
under `docs/`; dated audits go to `docs/reports/`. Claude Code can also
load [CLAUDE.md](CLAUDE.md) for repo-specific conventions.

## Conventions for working in this repo

- Structure: `vision/`, `architecture/`, `guides/`, `ai-agents/`, `specs/`,
  `backlog/`, `reports/`, `archive/` under `docs/`. Don't create new
  top-level folders without a reason.
- `reports/` files are dated and never overwritten — new scan/audit run =
  new dated file. `architecture/` and `guides/` files are living documents —
  update them in place.
- Legacy repos are named `knk-v1-archive` / `knk-v2-archive`; this
  `knk-` prefix / `-archive` suffix convention applies to any future
  archived component too.
- The component repos may be checked out under `Repository/` or as siblings
  of this repo. Their `CLAUDE.md` files retain an optional
  `@../../docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md` import for the nested
  layout. If it does not resolve, open the shared file directly; their
  `AGENTS.md` entrypoints do not depend on that import.
- `ACTIVE_SESSIONS.md` lives at `docs/ACTIVE_SESSIONS.md` — the live
  cross-repo work tracker referenced by the global instructions. Check it
  before claiming work, update it when you start/pause/finish.
- When editing docs, keep a consistent header (title, status, last-updated)
  across files of the same type — see the doc-audit instructions in
  `docs/guides/` for the format being standardized on.
