# CLAUDE.md — knk-workspace

This repo IS the documentation — there's no separate global-instructions
import needed here since `GLOBAL_AGENT_INSTRUCTIONS.md` lives in this repo,
at `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`. Read it directly.

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
- The three active component repos (`knk-web-app`, `knk-web-api`,
  `knk-plugin`) are checked out as subfolders under `Repository/` in this
  repo — e.g. `Repository/knk-web-app` — not as siblings of this repo.
  Each of their `CLAUDE.md` files imports this repo's global instructions
  via `@../../docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`, which assumes
  that layout; if you ever reorganize where those repos are cloned, update
  the import path in all three.
- `ACTIVE_SESSIONS.md` does not exist yet anywhere in this repo (checked
  the repo root and `docs/` up to a few levels deep) — it's referenced by
  the global instructions as the live cross-repo work tracker but hasn't
  been created. Create it at `docs/ACTIVE_SESSIONS.md` the first time it's
  needed, rather than assuming it already exists.
- When editing docs, keep a consistent header (title, status, last-updated)
  across files of the same type — see the doc-audit instructions in
  `docs/guides/` for the format being standardized on.
