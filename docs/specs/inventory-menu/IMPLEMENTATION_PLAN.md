# InventoryMenu — Implementation Plan

Ref: vision.md §10 (decided architecture). Sources: `docs/specs/inventory-menu/
{REQUIREMENTS_INVENTORY_MENU,ARCHITECTURE_DESIGN,QUICK_REFERENCE,RECONCILIATION,
DESIGN_REVIEW,FORMCONFIG_INTEGRATION}.md`. This plan describes *how to build
it*; decisions themselves live in those docs and aren't restated here.

## Explicitly out of scope for this plan
- `FormWizard`/`FormConfigBuilder` authoring UI — deferred to a future update
  (`FORMCONFIG_INTEGRATION.md`). Templates are DB-persisted from day one, but
  created directly (seed data / API), not through a generated admin form.
- Porting v1's ~60 screens and the two live v2 screens (Kits, Sieges) — this
  is the engine the content gets built on, not the content itself. Separate
  effort, sequenced after this plan.
- Admin audit log, preview-as-player mode, spectate-another-player's-menu —
  real but non-blocking, noted in `DESIGN_REVIEW.md`, not part of the core
  engine build.
- The nested-related-entity-creation gap in the M2M form editor — only
  matters once the authoring UI is built; not a blocker here.

## Entities

### `MenuTemplate`
Top-level definition: id, key/name, description. Root of the composite tree.

### `MenuSectionTemplate`
FK to parent `MenuTemplate`. Layout properties (position, size, alignment,
growth, overflow mode, priority — implemented as static-grid cell placement
per `DESIGN_REVIEW.md` §1, not a general flex-solving algorithm). A `kind`
field selects a preset section type (content-grid, search-bar, filter-bar,
static-buttons, confirm-dialog — see Phase 7). **Explicit integer `sortOrder`
field** — not inferred from list position — per the ordering concern raised
in `FORMCONFIG_INTEGRATION.md`.

### `MenuItemTemplate`
FK to parent `MenuSectionTemplate`. Slot/position, display properties (icon/
material, name and lore as variable-bound strings), display-mode rules
(NORMAL/DISABLED/HIGHLIGHT/HIDDEN). Explicit integer `sortOrder` as above.
Carries `visibilityPermission` and `actionPermission` (separate — see Phase 4).

### `VariableBinding`
Child of `MenuItemTemplate`/`MenuSectionTemplate`. A getter-chain expression
(`$player.getName$`-style) plus a `RefreshPolicy`: `STATIC`, `ON_DIRTY`
(default), or `TTL(ticks)` — the decided policy from `DESIGN_REVIEW.md` §1.

### `ActionBinding` / `ConditionBinding`
`actionTypeId`/`conditionTypeId` plus a params map (key-value), not inline
code. Resolved against code-side registries at runtime (below) — keeps the
persisted schema stable regardless of what a future FormConfig UI adds.

### `MenuSession` (runtime only — not persisted)
Per-player, in-memory: current menu/navigation stack, active search/filter
predicate state, dirty flags for `ON_DIRTY` variable refresh. Created on
menu open, **explicitly cleared on `PlayerQuitEvent`** — closes reconciliation
gap #4 (v1's unbounded static-map growth bug).

## Code-side registries (not persisted)
- `ActionRegistry` — `actionTypeId` → executable handler.
- `ConditionRegistry` — `conditionTypeId` → `Predicate<MenuSession>` factory.
  Ship a small reusable library: permission-node, affordability, ownership,
  item-age — not one-off lambdas per screen.
- `SectionTypeRegistry` — preset `kind` → renderer + expected field schema.

## Load-time validation
`MenuDefinitionValidator` runs at plugin enable (not first render): resolves
every `VariableBinding`'s getter chain against declared context types, and
confirms every `ActionBinding`/`ConditionBinding` references a registered ID.
Failure is per-menu, not per-server — a broken menu refuses to register and
logs clearly; the rest of the game keeps running. Implements the decided
policy from `DESIGN_REVIEW.md` §1.

## Phased build order

**Phase 1 — Core data model & persistence**
DB schema + entities for everything above, with explicit `sortOrder` fields
on section/item tables. Direct CRUD API (no FormConfig UI). A
`MenuTemplatesDataAccess` gateway following the existing pattern
(`ItemBlueprintsDataAccess` precedent) through the confirmed-existing cache/
data-access layer. A seed-data mechanism, since templates are authored
directly for now.

**Phase 2 — Rendering engine core**
Runtime `Menu`/`MenuSection`/`MenuItem` classes (the rendered-instance side),
composite tree assembly from persisted templates, static-grid layout.
`MenuSession` with real lifecycle (open → quit-cleanup). Overflow/pagination
implemented on the **base** class, not subclass-only — closes gap #9 (v2's
no-op `Menu.nextPage` stub). Async rendering: expensive work off-thread,
`Inventory` mutation back on the main thread via the Bukkit scheduler — fixes
bug #6's actual root cause.

**Phase 3 — Variable resolution**
`VariableResolver` implementing the three-tier `RefreshPolicy`.
`MenuDefinitionValidator` wired into plugin enable. A regression test that
asserts real substitution happens end-to-end — this specific thing silently
didn't work for the entirety of v2, so this phase doesn't ship without that
test passing.

**Phase 4 — Permissions**
`visibilityPermission` (render-time hide) and `actionPermission` (click-time
reject) as genuinely separate checks, both enforced — not just the button
hidden. Closes gap #10 (v2's unguarded debug item).

**Phase 5 — Search & filters**
Searchable flag on content-listing sections; pick one input mechanism as the
standard (anvil-GUI-style text capture) rather than leaving it per-screen.
`FilterBar` section type. Both feed one shared active-predicate concept in
`MenuSession` so search and filters compose rather than conflict. Explicit
empty-results state (new UX — neither legacy system had one).

**Phase 6 — Conditional actions**
Wire `ActionRegistry`/`ConditionRegistry`. Conditions checked at click time,
not just render time — closes the staleness window described in
`DESIGN_REVIEW.md` §2.2 (state going stale between menu-open and click).

**Phase 7 — Preset section/item library**
Search bar, filter bar, paginated content grid, confirm dialog as first-class
reusable components. This is what the (separate, later) content-porting work
for v1's screens and Kit/Siege will actually build on — worth having solid
before that starts, not required to finish this plan's own phases first.

**Phase 8 — Scalable content access**
Content-listing sections pull through a paged/cursor query against
`DataAccessExecutor` rather than loading a full list into memory first.
Menu-definition caching (long-lived, rarely changes) kept distinct from
underlying content-data caching (changes per interaction) — different
lifetimes, different invalidation triggers.

## Delegation notes
Phases 1–4 are mechanical and well-specified — good short-burst Claude Code
candidates, in order, each buildable and testable independently. Phase 5 has
one real judgment call (confirming the anvil-GUI input approach) before it
becomes equally mechanical. Phase 6 benefits from settling the initial
condition-library list (which conditions are actually needed first) before
delegating. Phases 7 and 8 can run in parallel with each other once 1–4 are
solid, and Phase 8 specifically shouldn't be pushed past "whenever real
content volume shows up" — it's cheap now, a real retrofit later.
