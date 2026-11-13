# Architecture decision records

**Status:** Active · **Last updated:** 2026-11-13 (created from knk-plugin `docs/adr/README.md` at `b8aa582f7a`, PandiO/knk-workspace#304)

Architecture decision records (ADRs) for all Knights and Kings components. Most decisions are recorded in the feature
specs (`docs/specs/<feature>/DESIGN.md`) and in the issues; an ADR is for a decision that cuts across features.

## Format

Each ADR follows [MADR](https://adr.github.io/madr/): a short decision title, **Status** (Proposed, Accepted,
Deprecated or Superseded), context, the decision and why, consequences, the alternatives considered, and related
decisions. Name new files `ADR-NNN-short-title.md`.

## Records

| ADR | Status | Note |
|---|---|---|
| [Towns implementation plan (vertical slice)](ADR_TOWNS_IMPLEMENTATION.md) | Superseded | knk-plugin, 2025-12-14. Moved from `knk-plugin/docs/adr/`; keeps its old file name. |

The old knk-plugin index listed `ADR-001-async-ports-for-io.md`, `ADR-002-paper-adapter-thin-layer.md` and
`ADR-003-source-grounded-migration.md`. Those files were never written; the async-ports and thin-Paper-layer rules live
in [plugin architecture](../plugin-architecture.md) and the [plugin API client pattern](../plugin-api-client-pattern.md).
