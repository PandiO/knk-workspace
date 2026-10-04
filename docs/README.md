# Knights & Kings documentation

This is the documentation for the Knights & Kings project, covering game design/vision, technical architecture, specs, guides, and historical/analysis material. See [ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md](ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md) for how AI agents should work in this repo, and [ACTIVE_SESSIONS.md](ACTIVE_SESSIONS.md) for the live cross-repo work tracker.

## Start here

| Looking for | Read |
|---|---|
| What is intended, built, on a branch, or tested? | [Living V1 → V2 → V3 feature register](FEATURE_REGISTER.md) |
| What shipped and when? | [Project changelog](CHANGELOG.md) |
| How to keep specs, technical docs, player/admin guides and the changelog current? | [Documentation maintenance guide](guides/developer/DOCUMENTATION_MAINTENANCE.md) |
| How does the system fit together? | [System overview](architecture/system-overview.md), [API architecture](architecture/web-api-architecture.md), [web-app architecture](architecture/web-app-architecture.md) |
| How to implement and document a feature? | [Feature specs](specs/README.md), [developer code map](guides/developer/CODEMAP.md), [active sessions](ACTIVE_SESSIONS.md) |
| How to play or administer a feature? | [Guides and coverage map](guides/README.md), [commands](guides/users/commands.md), [Siege authoring](guides/authoring-a-siege-scenario.md) |

The feature register distinguishes intent, implementation and live verification. Historical reports in `reports/` may predate current trunk and should not be used as current status without checking code.

## Folder guide

- **`vision/`** — the game's design vision: what the game is and where it's going. `vision/vision.md` is the authoritative top-level document. The root `vision.md` copy currently lacks newer Siege status and needs reconciliation. `reference/` holds inspiration/mood material (third-party reference images, PDFs) that informed design decisions but isn't itself a design decision. `brand/` holds marketing/brand-identity material (style guides, logos).
- **`architecture/`** — technical architecture: system overview, ADRs, database schema, and diagrams. Living documents, updated in place.
- **`guides/`** — user-facing and developer-facing how-to guides.
- **`specs/`** — per-feature design/implementation specs, one subfolder per feature area.
- **`backlog/`** — outstanding work: bugs, epics, stories.
- **`reports/`** — dated, point-in-time audit/scan/inventory output. Never overwritten — a new scan is a new dated file, not an edit to an old one.
- **`archive/`** — superseded or historical material kept for reference/provenance, not actively maintained. `vision-history/` specifically holds the evolution of the game's concept documents (2017–2020), kept distinct from the current `vision/vision.md`.
- **`ai-agents/`** — instructions for AI coding agents working in this repo and its component repos.

## Authority order

When documents disagree, resolve the conflict in this order:

**`vision/` > `architecture/` / `specs/` > `backlog/` / `reports/` > `archive/`**

`vision/vision.md` states the current intended design. `architecture/` and `specs/` translate that into concrete technical decisions and should follow it; if a spec contradicts the vision doc, the vision doc wins (or the spec needs updating — flag it). `backlog/` and `reports/` describe outstanding work and point-in-time findings, not decisions in themselves. `archive/` is never authoritative — it exists purely for historical/provenance value.
