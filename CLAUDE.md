# CLAUDE.md — knk-workspace

Start at `AGENTS.md`, then read `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`
and the current `docs/ACTIVE_SESSIONS.md`. The shared instructions live in
this repo, so no cross-repo Claude import is needed here.

## Shipping a change

Essential docs (docs impact list, deploy notes including plugin `config.yml` keys, changelog entry, status)
ship with the feature before merge. At merge, put the remaining docs (guides, register, site/wiki pages) in a
`documentation` sub-issue, start a new docs session for it right away with
[the docs-session prompt](docs/ai-agents/docs-session-prompt.md), and close the feature issue. Once the `next` branch
model applies, the sub-issue and docs session start at the merge into `next` and the feature issue is closed when the
developer promotes `next` to trunk. See
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
