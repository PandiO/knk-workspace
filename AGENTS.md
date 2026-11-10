# Agent entrypoint — knk-workspace

This repository is the canonical Knights and Kings documentation source. Read
[global instructions](docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md) and
[active sessions](docs/ACTIVE_SESSIONS.md) before changing anything. Check
overlapping claims, publish a feature-scoped claim, and use the standing
feature branch (or create one from the current default branch).

For intended behavior consult the current feature plan and GitHub issue
(`PandiO/knk-workspace` issues; Linear is a read-only archive since
2026-10-25); for implemented behavior inspect the current default branches
of affected code repos. Date and verify old handoffs before using them.
Documentation lives under `docs/`; dated audits go to `docs/reports/`.
Claude Code can also load [CLAUDE.md](CLAUDE.md) for repo-specific
conventions.

## Shipping a change

Essential docs (docs impact list, deploy notes including plugin `config.yml` keys, changelog entry, status)
ship with the feature before merge. At merge, close the feature issue, put the remaining docs (guides,
register, site/wiki pages) in a `documentation` sub-issue and start a new docs session for it right away
with [the docs-session prompt](docs/ai-agents/docs-session-prompt.md). See
[global instructions § Shipping a change](docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md#shipping-a-change-documentation)
and [documentation maintenance](docs/guides/developer/DOCUMENTATION_MAINTENANCE.md).

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
