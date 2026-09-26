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
  - [inventory-menu-screens.md](inventory-menu-screens.md) — every v1/v2 menu screen and item (what it
    showed, what a click did), allocated to a v3 feature, with the engine gaps a port would hit
  - [towns-districts-gates.md](towns-districts-gates.md) — world hierarchy and gate structures
  - [kits.md](kits.md) — starter/premium kit system
  - [siege-minigame.md](siege-minigame.md) — Scenario/Siege minigame
  - [commands-v1.md](commands-v1.md) — every player/admin-facing Minecraft command in v1: syntax,
    args, permission gate, actual behavior, feature-domain allocation, known bugs
  - [commands-v2.md](commands-v2.md) — same, for v2's ACF `BaseCommand` classes, plus a v1→v2
    command-level diff
  - [events-v1.md](events-v1.md) — every Bukkit/Spigot event listener in v1 (the passive/reactive
    half of the behavior surface commands don't cover): event type, trigger condition, actual
    behavior, feature-domain allocation, known bugs — and which handlers are confirmed dead code
  - [events-v2.md](events-v2.md) — same, for v2's listener classes

All five sibling docs (`user-system.md`, `inventory-menus.md`, `towns-districts-gates.md`,
`kits.md`, `siege-minigame.md`) originated on the `legacy-spec-mining` branch and have now
been pulled into `main` in full — none were rewritten or trimmed in the move.

`commands-v1.md`/`commands-v2.md` were added 2026-09-25 as a follow-up scan: the original
mining pass documented data models and business rules per subsystem but never systematically
inventoried the *commands* themselves (what existed, what args/permissions each took, what it
actually did). The v3-side counterpart lives at
[docs/specs/user-features/COMMAND_CATALOG_V3.md](../user-features/COMMAND_CATALOG_V3.md).
Read all three before drafting a v3 feature design/implementation plan for any area that had a
legacy command surface, so prior behavior and known bugs aren't silently reinvented.

`events-v1.md`/`events-v2.md` were added the same day as a second follow-up: commands only cover
behavior a player *typed*; a large share of v1/v2 gameplay logic (combat skills, economy payouts,
region-touch effects, menu clicks, minigame state machines) is instead driven by Bukkit event
listeners with no command counterpart at all. The v3-side counterpart lives at
[docs/specs/user-features/EVENT_CATALOG_V3.md](../user-features/EVENT_CATALOG_V3.md). Read these
alongside the command catalogs for the same reason — a striking fraction of what these two docs
found is *dead* event-handler code (whole classes registered as listeners with every
`@EventHandler` method commented out), which is exactly the kind of "was this abandoned on
purpose or still wanted" signal a v3 feature design needs before treating v1/v2 behavior as a
spec to follow.

## v3 port designs built on these reports

Feature designs (legacy design, gap analysis, v3 design, implementation plan) mined from these reports and
the source on 2026-09-26: [teleport](../teleport/DESIGN.md) (KNG-17), [private-messages](../private-messages/DESIGN.md)
(KNG-18), [lootboxes](../lootboxes/DESIGN.md) (KNG-19), [domain-discovery](../domain-discovery/DESIGN.md) (KNG-20),
[currency-payments](../currency-payments/DESIGN.md) (KNG-21/KNG-22). Corrections to `commands-v1.md` /
`events-v1.md` found along the way are listed in each design's discrepancy notes.

## Principles
- **Verbatim only:** All fields/relations extracted directly from source code.
- **Annotated:** Include ORM/framework dependencies (Hibernate, Bukkit, etc.).
- **Marked gaps:** Flag missing concepts as "NOT FOUND" with search terms.
- **No invention:** Never add fields or flows not present in code.

## Audience
Migration engineers, architects, and decision-makers validating v2 design against reality.
