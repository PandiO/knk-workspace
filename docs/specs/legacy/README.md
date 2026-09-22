# spec/legacy/

Source-driven inventory and analysis of the legacy `knk` codebase.

## Purpose
Document actual code patterns, entities, and migrations from legacy to avoid speculation and hallucination.

## Contents
- `SOURCES_*.md`: Verified field/entity inventories (e.g., SOURCES_TOWNS.md)
- Subsystem-specific source analyses (e.g., Economy, Guilds, Creation)
- Migration patterns and anti-patterns identified
- Per-system feature specs mined from `knk-v1-archive` and `knk-v2-archive` (data model,
  business rules, known bugs, finished-vs-WIP, v1/v2 diffs, open questions):
  - [items.md](items.md) — the item/product entity and its features
- Five sibling docs of the same shape (`user-system.md`, `inventory-menus.md`,
  `towns-districts-gates.md`, `kits.md`, `siege-minigame.md`) exist on the unmerged
  `legacy-spec-mining` branch but haven't been pulled into `main` yet — only `items.md`
  was brought in here, for the Items plan re-analysis that needed it.

## Principles
- **Verbatim only:** All fields/relations extracted directly from source code.
- **Annotated:** Include ORM/framework dependencies (Hibernate, Bukkit, etc.).
- **Marked gaps:** Flag missing concepts as "NOT FOUND" with search terms.
- **No invention:** Never add fields or flows not present in code.

## Audience
Migration engineers, architects, and decision-makers validating v2 design against reality.
