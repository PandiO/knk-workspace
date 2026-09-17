# Knights and Kings — V3 Codebase Scan & Documentation Instructions

**Purpose:** produce a thorough, accurate, up-to-date picture of what actually
exists in the V3 codebase — knk-web-app, knk-web-api, knk-plugin — so that
future implementation work (by you or by AI agents) starts from ground truth
instead of memory or stale docs. This scan feeds three things:

1. A **feature/functionality inventory** — what is implemented today, and how.
2. A **legacy/obsolete/orphaned code report** — candidates for removal.
3. A **reading & implementation guide** per module — how a new session should
   navigate the code and what conventions to follow.

This document is meant to be handed, as-is or per-section, to one Claude Code
session per module (web app, web API, plugin). Each session should also read
`AGENTS.md` / the global agent instructions file (see companion doc) before
starting, for project-wide conventions and constraints.

---

## Ground rules for every scanning session

- **Read-only first.** This is an audit, not a refactor. Do not delete, rename,
  or "clean up" anything during the scan itself — only report and recommend.
- **Cite file paths and line ranges** for every claim. "The inventory system
  is implemented in `Services/InventoryService.cs` (lines 40–210)" is useful;
  "there's an inventory system" is not.
- **Distinguish fact from inference.** If something looks unused but you
  haven't verified it (e.g. via a repo-wide reference search), label it as
  "appears unused — verify" rather than "unused."
- **Don't trust file/folder names alone.** A file called `LegacyAuth.cs` might
  still be load-bearing; a file called `NewFeature.ts` might be dead. Check
  actual references and call sites.
- **Work module-by-module, not feature-by-feature**, in this pass — a
  cross-module feature-completeness report comes after all three module scans
  are done (see final section).
- **Output goes into `knk-workspace`**, under the paths specified per section
  below, as new/updated Markdown files — not inline chat output only.
- **Time-box it.** If the codebase is large, prioritize breadth (cover every
  top-level module/folder at a summary level) over exhaustive depth on any
  one file, then flag areas that need a deeper follow-up pass.

---

## Output locations (in knk-workspace)

- `docs/architecture/<module>-architecture.md` — structure, stack, data flow,
  key modules/classes, how it talks to the other two components.
- `docs/reports/<module>-scan-<yyyy-mm-dd>.md` — the raw scan findings:
  feature inventory + legacy code report for that module.
- `docs/guides/<module>-reading-guide.md` — practical onboarding guide for a
  new session or contributor working in this codebase.

Use the actual scan date in the filename so repeat scans don't overwrite each
other; the architecture and reading-guide docs, by contrast, should be
**updated in place** each time (they represent current state, not a log).

---

## Per-module scan instructions

### 1. knk-web-app (React + TypeScript)

**Inventory:**
- Enumerate top-level route/pages and what each does.
- Enumerate shared components, hooks, and state management (context/store),
  noting which are actively used vs. only referenced by other unused code.
- Document how it authenticates against knk-web-api and what API endpoints
  each page/feature actually calls (grep for fetch/axios/client calls).
- Note any feature-flagged, half-built, or commented-out UI.

**Legacy/orphaned code:**
- Unused components/hooks (no import references anywhere in the tree).
- Dead routes (defined but not linked from any nav/menu).
- Duplicate implementations of the same UI pattern (a sign of copy-paste
  drift across features built at different times).
- Outdated dependencies in `package.json` that nothing in the code uses.

**Deliverable additions:** a simple sitemap/route table, and a component
inventory table (component name, purpose, used by, status).

### 2. knk-web-api (ASP.NET Core)

**Inventory:**
- Enumerate controllers/endpoints, and for each: HTTP verb, route, purpose,
  auth requirements, request/response shape.
- Enumerate services and their responsibilities; map service → controller
  usage so orphaned services are visible.
- Document the EF Core / database layer: entities, migrations status
  (is the migration history clean or are there gaps/manual DB edits?),
  and any raw SQL bypassing the ORM.
- Note integration points with knk-plugin (what does the plugin call, and
  what does the API push to the plugin, if anything — webhooks, polling, etc.)

**Legacy/orphaned code:**
- Controllers/endpoints with no corresponding web-app or plugin caller.
- Old DTOs/models superseded by newer ones but still present.
- Config/appsettings entries for services no longer used (old MySQL/Hibernate-
  era leftovers, if any carried over conceptually from V2).
- Commented-out or `#if false`-style dead code blocks.

**Deliverable additions:** an endpoint table (route, verb, purpose, caller),
and an entity-relationship summary of the current DB schema as implemented
(not as originally designed — actual current state).

### 3. knk-plugin (Spigot/Paper)

**Inventory:**
- Enumerate commands, listeners/event handlers, and any custom GUIs/menus,
  with what each does and which in-game feature it belongs to.
- Document how it talks to knk-web-api (REST calls, auth, sync/polling model).
- Note any remaining local storage (files, embedded DB) vs. what's now
  delegated to the API — this is the key V2→V3 migration signal.
- Cross-reference against known V1/V2 features (gate structure, door
  animations, siege minigame, inventory menus, global game settings, user
  features) to note per-feature status: fully ported / partially ported /
  not yet started / reimplemented differently.

**Legacy/orphaned code:**
- Listeners registered but never doing meaningful work (stubs).
- Leftover local-storage code paths now superseded by API calls.
- Dependencies (WorldGuard/WorldEdit/Citizens-era, if any survived from V1/V2)
  that are declared but unused in V3.
- Config sections referencing removed features.

**Deliverable additions:** a command/listener table, and a V1/V2 → V3
feature-parity table (this is the one most directly useful for MVP planning).

---

## After all three module scans: consolidated report

Once web app, web API, and plugin scans are done, produce one more document —
`docs/reports/v3-feature-completeness-<yyyy-mm-dd>.md` — that:

- Merges the three "what's implemented" inventories into a single
  cross-cutting feature list (since most features span all three components).
- Flags features that are implemented in one layer but not the others
  (e.g. API endpoint exists, plugin never calls it — or vice versa).
- Compares against the V1 feature set to show what's still missing for
  reaching V1-level functionality in V3.
- Lists the highest-value legacy/dead code removal candidates across all
  three repos, ranked by how confidently "unused" was established.

This consolidated report is what should drive the next round of Linear
issues/sprint planning — not the raw per-module scans.

---

## Notes for the human (you)

- Run the three module scans as separate, simultaneous Claude Code sessions
  if you want speed — they're read-only and don't touch overlapping files,
  so they're safe to parallelize.
- Do the consolidated report as its own session afterward, once all three
  module reports exist in the repo for it to read.
- Treat the architecture and reading-guide docs as living documents; re-run
  the scan periodically (e.g. before a big push, or quarterly) rather than
  treating this as a one-time exercise.
