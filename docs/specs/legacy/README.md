# spec/legacy/

Source-driven inventory and analysis of the legacy `knk` codebase.

## Purpose
Document actual code patterns, entities, and migrations from legacy to avoid speculation and hallucination.

## Contents
- `SOURCES_*.md`: Verified field/entity inventories (e.g., SOURCES_TOWNS.md)
- Subsystem-specific source analyses (e.g., Economy, Guilds, Creation)
- Per-system feature specs mined from `knk-v1-archive` and `knk-v2-archive` (data model,
  business rules, known bugs, finished-vs-WIP, v1/v2 diffs, open questions):
  - [items.md](items.md) — the item/product entity and its features
  - [user-system.md](user-system.md) — users, roles, ranks, levels, permissions
  - [inventory-menus.md](inventory-menus.md) — the clickable inventory-menu UI framework
  - [towns-districts-gates.md](towns-districts-gates.md) — world hierarchy and gate structures
  - [kits.md](kits.md) — starter/premium kit system
  - [siege-minigame.md](siege-minigame.md) — Scenario/Siege minigame

All five sibling docs (`user-system.md`, `inventory-menus.md`, `towns-districts-gates.md`,
`kits.md`, `siege-minigame.md`) originated on the `legacy-spec-mining` branch and have now
been pulled into `main` in full — none were rewritten or trimmed in the move.

## Principles
- **Verbatim only:** All fields/relations extracted directly from source code.
- **Annotated:** Include ORM/framework dependencies (Hibernate, Bukkit, etc.).
- **Marked gaps:** Flag missing concepts as "NOT FOUND" with search terms.
- **No invention:** Never add fields or flows not present in code.

## Audience
Migration engineers, architects, and decision-makers validating v2 design against reality.
