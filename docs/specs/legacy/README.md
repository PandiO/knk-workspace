# spec/legacy/

Source-driven inventory and analysis of the legacy `knk` codebase.

## Purpose
Document actual code patterns, entities, and migrations from legacy to avoid speculation and hallucination.

## Contents
- `SOURCES_*.md`: Verified field/entity inventories (e.g., SOURCES_TOWNS.md)
- Subsystem-specific source analyses (e.g., Economy, Guilds, Creation)
- Migration patterns and anti-patterns identified
- Per-system feature specs mined from `knk-v1-archive` and `knk-v2-archive` (data model, business rules, known bugs, finished-vs-WIP, v1/v2 diffs, open questions):
  - [user-system.md](user-system.md) — users, roles, ranks, levels, permissions
  - [inventory-menus.md](inventory-menus.md) — the in-game inventory menu (GUI) framework
  - [towns-districts-gates.md](towns-districts-gates.md) — Town / District / Street / Gate / Structure / Warehouse
  - [items.md](items.md) — the item/product entity and its features
  - [kits.md](kits.md) — the kit system, including permissions
  - [siege-minigame.md](siege-minigame.md) — the Siege minigame

## Principles
- **Verbatim only:** All fields/relations extracted directly from source code.
- **Annotated:** Include ORM/framework dependencies (Hibernate, Bukkit, etc.).
- **Marked gaps:** Flag missing concepts as "NOT FOUND" with search terms.
- **No invention:** Never add fields or flows not present in code.

## Audience
Migration engineers, architects, and decision-makers validating v2 design against reality.
