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

**Phase 9 — Domain integration (E1–E9)** — added 2026-09-25, full section
below ("Phase 9 — Domain integration (E1–E9)"). The nine generic engine
extensions `docs/specs/siege-minigame/MENU_TEMPLATES.md` Part B needs before
the Siege menus (and later Kits) can be expressed as templates.

## Delegation notes
Phases 1–4 are mechanical and well-specified — good short-burst Claude Code
candidates, in order, each buildable and testable independently. Phase 5 has
one real judgment call (confirming the anvil-GUI input approach) before it
becomes equally mechanical. Phase 6 benefits from settling the initial
condition-library list (which conditions are actually needed first) before
delegating. Phases 7 and 8 can run in parallel with each other once 1–4 are
solid, and Phase 8 specifically shouldn't be pushed past "whenever real
content volume shows up" — it's cheap now, a real retrofit later.

---

## Phase 9 — Domain integration (E1–E9)

**Status:** Implemented, builds + unit tests green, **not verified live**
(2026-09-25). Siege implementation plan Phase 8a, delegated to its own
session. **Last updated:** 2026-09-25

**Branches:** `claude/inventorymenus` in `knk-web-api` (forked from
`origin/master` `87c7649`) and `knk-plugin` (forked from `origin/main`
`9cf81a7`), built in worktrees under `Repository/_worktrees/` so the
`Repository/*` checkouts (on `claude/user-management`, with other sessions'
uncommitted work) stay untouched. Both pushed, not merged to trunk.

**Commits:**
- knk-web-api: `07b6174` schema/API (`AutoRefreshTicks`, `IsRowTemplate`,
  `ConditionBinding.Phase`, migration `20260925123418_AddInventoryMenuPhase9DomainIntegration`,
  service rules, empty lore expressions) · `86a72d9` `example.domain` seeds +
  `MenuTemplateServicePhase9Tests`.
- knk-plugin: `38abc14` knk-core engine extensions + api-client DTOs + tests ·
  `2c3b0ad` throwing providers resolve as null · `216bb3b` knk-paper
  (main-thread render pipeline, `MenuFeature`, auto-refresh task, E6 mapping,
  `menu.back`, `value-equals`, demo feature, paper tests).

**Why:** `docs/specs/siege-minigame/MENU_TEMPLATES.md` Part B lists nine
generic extensions the Siege menus (Part C) need; Kits' future menu needs the
same set. This phase builds the engine side only — no siege roots, actions,
conditions, content sources or templates (that is Siege Phase 8b).

### 9.0 Cross-cutting decision — threading (J1)

Phases 2–8 ran the whole render (`MenuRenderer.computeState`, including every
`$…$` getter call) on an async thread. That is unsafe for feature-registered
roots/sources/conditions: Siege's runtime is main-thread-owned (Siege
`DESIGN.md` §5.3). Phase 9 splits a render into:

1. **async** — template fetch + assembly + material-ref lookups for template
   items (unchanged work, still HTTP/cache-backed);
2. **main thread** — build the variable scope, interpolate
   `ContentSourceParamsJson`, **call** every content source's `fetch`
   (a source that does I/O returns an incomplete future; in-memory sources
   such as Siege's return a completed one);
3. **async wait** — only if some fetch is still incomplete (plus material-ref
   lookups for Java-mapped fetched items, e.g. `catalog.itemblueprints`);
4. **main thread** — resolve every binding, evaluate render conditions, build
   the `ItemStack`s and apply them to the `Inventory`.

Contract for feature code: **variable providers, content-source `fetch`
calls, and condition handlers (both phases) are always invoked on the main
thread.** Auto-refresh (E4) skips step 1 entirely (it reuses the open menu's
assembled template and material keys), so a refresh of a menu whose sources
are in-memory runs synchronously inside the refresh tick.

### E1 — Menu context parameters

- **Schema/API:** none (ctx travels in `ActionBinding.ParamsJson`).
- **Template syntax:** `menu.open` params `{"key": "x", "ctx.lobbyId": "3"}` —
  every `ctx.`-prefixed key becomes one ctx entry (prefix stripped). Values
  are interpolated at click time (E3), so `"ctx.lobbyId": "$row.getLobbyId$"`
  works. `$ctx.lobbyId$` resolves to the string value; a missing key resolves
  to `""`.
- **Runtime:** new knk-core `MenuContextParams` (immutable `String → String`
  map, `get`/`getOrDefault`/`has`/`asMap`). `MenuSession`'s nav stack now holds
  `NavigationEntry(key, ctx, title)`; `navigateTo(key)` is kept (empty ctx),
  `navigateTo(key, ctx, title)`, `currentEntry()`, `currentContext()`,
  `hasPrevious()`, `previousEntry()`, `goBackEntry()` added; `goBack()` keeps
  returning the key for compatibility. `MenuService.openMenu(player, key, ctx)`
  is the public API commands call (Siege's `/siege info <lobby>` etc.).
- **Push vs. root rule (J2):** `openMenu` **pushes** onto the nav stack only
  when the player currently has a KnK menu open (i.e. navigation from inside a
  menu, which is what `menu.open` always is); opened from outside a menu
  (command, respawn hook) it **resets** the stack, so Back reads "Exit" — v2's
  `/siege join` behaviour (MENU_TEMPLATES A.1). Re-opening the entry that is
  already current (same key + ctx) replaces instead of pushing.
- **Validator:** `ctx` is an engine root declared as `MenuContextParams`; any
  hop after `ctx` is a key lookup whose type is `String`.

### E2 — Feature-registered variable roots

- **Runtime:** knk-core `MenuVariableProviderRegistry<P>` (generic over the
  player type, Bukkit-free): `register(root, declaredType, (player, ctx) → value)`,
  `declaredTypes()`, `scope(player, ctx, engineValues)` → a lazy, per-render/
  per-click memoised `Map` (a provider is only called if a binding in that
  pass references its root, and at most once per pass). knk-paper's
  `MenuVariableContext.registerDefaults` registers `player → Player.class` as
  the default provider (its old static `DECLARED_TYPES`/`liveValues` are
  replaced by the registry — one source of truth).
- **Reserved engine roots:** `ctx`, `menu`, `section`, `row` — registering one
  of these throws `IllegalArgumentException`.
- **Registration order guarantee (J11):** knk-paper gains a `MenuFeature`
  interface + `MenuFeatureRegistries` record (actions, conditions, content
  sources, variable providers). `KnKPlugin` registers every feature (engine
  defaults, the `example.domain` demo feature, later Siege/Kits) from one
  list, then runs `MenuDefinitionValidationRunner`, which **locks all four
  registries first**. Any registration after the lock throws
  `IllegalStateException` — a late registration fails loudly at enable
  instead of silently producing menus that were validated without it.
- **Validator:** `MenuDefinitionValidationRunner` passes
  `providerRegistry.declaredTypes()` (+ row types, E3) to
  `MenuDefinitionValidator.validate`.

### E3 — Row templates for content sources

- **Schema:** `menu_item_templates.IsRowTemplate` (`bool`, default `false`).
- **API/DTO:** `isRowTemplate` on `MenuItemTemplateDto` (web-api and
  knk-api-client). `MenuTemplateService` rejects: a row template with a
  `SlotOverride`; a row template in a section without `ContentSourceId`; more
  than one row template per section.
- **Runtime:** `MenuContentSourceRegistry` keeps `register(id, source)` for
  Java-mapped item sources (`catalog.itemblueprints` unchanged) and adds
  `registerRows(id, rowType, rowSource)` for sources that return plain row
  objects and declare their row type. The renderer renders each row through
  the section's row template with `$row$` bound to that row object; the row is
  also kept per slot so click-time actions/conditions see the same `$row$` the
  player saw.
- **Param interpolation:** `$…$` placeholders in the **values** (not keys) of
  `ActionBinding.ParamsJson` / `ConditionBinding.ParamsJson` /
  `ContentSourceParamsJson` are resolved (text form, never cached) — per click
  for actions and Click-phase conditions, per render (per row on row
  templates) for Render-phase conditions, per render for content-source
  params.
- **Variable cache for rows (J4):** the per-session cache key becomes
  `(bindingId, scope)`; for a row the scope is `(sectionId, index on page)`
  and each cached entry remembers the row's identity (the row's
  `MenuRowKey.menuRowKey()` if it implements that optional knk-core interface,
  else the row object itself via `equals`). A different row at that position
  (paging, re-ordering, a changed record value) is a cache miss. Memory stays
  bounded by slots × bindings, never by the number of distinct rows seen.
- **Validator:** a row-template item validates `$row.*$` chains against its
  source's declared row type; `$row$` anywhere else is an error; a row source
  without a row template in its section is an error; a row template on an
  item-source section is an error; placeholder chains inside params values are
  validated like binding expressions.

### E4 — Live repaint

- **Schema:** `menu_templates.AutoRefreshTicks` (`int?`); the service stores
  `≤ 0` as `null` (off) (J17). DTO `autoRefreshTicks`.
- **Runtime:** `RuntimeMenu.autoRefreshTicks`; knk-core `MenuRefreshSchedule`
  (Bukkit-free due/in-flight bookkeeping, unit-tested); knk-paper
  `MenuAutoRefreshTask` — **one** sync repeating task (period 1 tick) that
  re-renders every open menu whose period has elapsed, in the same tick
  (batched), skipping any menu whose previous render is still in flight.
  A refresh does **not** mark the session dirty, so `Static` bindings stay
  cached, `OnDirty` ones stay cached until something marks dirty, and `Ttl`
  ones re-resolve once expired — the first time TTL does anything visible.
- `MenuService.refreshOpenMenus(Predicate<OpenMenuContext>)` — for
  event-driven refresh (join/leave/vote/phase change): marks each matching
  session dirty, then re-renders it the same way. `OpenMenuContext` exposes
  `menuKey()` and `menuContext()` for predicates.
- **Apply (J13):** `applyToInventory` now writes only slots whose `ItemStack`
  changed (and clears slots that became empty) instead of `clear()` + rewrite,
  so a once-a-second repaint doesn't flicker tooltips.

### E5 — Render-time conditions

- **Schema:** `menu_condition_bindings.Phase` (`varchar(20)`, `Click` |
  `Render`, default `Click`). DTO `phase`; knk-core `MenuConditionPhase`.
- **Semantics (J8):**
  - item-level Render condition denies → the item is not rendered (for a row
    template: that row's slot stays empty — rows are not compacted, J7);
  - action-level Render condition denies → that action is dropped from the
    rendered item (not run on click, no control hint);
  - at click time Render conditions are **re-checked silently** (no denial
    message): an item-level deny ignores the click and refreshes that
    player's menu, an action-level deny skips that action;
  - Click conditions behave exactly as in Phase 6.
- **Runtime:** one shared evaluator in knk-core (`MenuConditionEvaluator`)
  used by the renderer and `MenuClickListener`; handlers get the same
  `MenuActionContext` at render time as at click time (now carrying
  `menuContext()` and `row()`).
- **No section-level conditions (J14):** `ConditionBinding` still belongs to
  an item. To hide a whole section, put the Render condition on its row
  template and on each pinned item; a content source that knows it is not
  applicable should return an empty page (cheaper than rendering hidden rows).

### E6 — Item-meta bindings

New `VariableBinding.TargetProperty` values (free-text column, so no schema
change; matched case-insensitively; first binding per property wins). A
whole-expression placeholder that resolves to `null`/blank means "not set" —
the template's static value is used.

| TargetProperty | Value | Effect |
|---|---|---|
| `Material` | namespace key (`minecraft:green_banner`) or enum name (`GREEN_BANNER`) | Overrides `MaterialRefId`. Unresolvable → falls back to `MaterialRefId`'s material, then `PAPER`; warned once per (item, value). |
| `Amount` | integer | Clamped 1–64; when above the material's default max stack (e.g. banners: 16) the stack's max-stack-size component is raised so the count shows (J9). Unparsable → the `Amount` column, warned once. |
| `BannerPatterns` | `[BASE_COLOR]\|pattern:COLOR,pattern:COLOR…` or just `pattern:COLOR,…` | Maps to `BannerMeta` layers in order. `pattern` = a banner-pattern registry key (`stripe_bottom`, `minecraft:border`), `COLOR` = a `DyeColor` name (case-insensitive). `BASE_COLOR` swaps the material to `<BASE_COLOR>_BANNER` when the item is a banner (J10). Bad layers are skipped and warned once; on a non-banner material the binding is ignored (warned once). Pattern tooltip lines are hidden. Example: `WHITE\|stripe_bottom:RED,border:BLACK`. |
| `SkullOwner` | UUID or player name | `SkullMeta` owner. Online player → their profile; UUID → `createProfile(uuid)`; name → cached offline player, else a name-only profile (no blocking Mojang lookup on the main thread). Ignored on non-skull materials. |
| `DisplayMode` | `NORMAL` / `DISABLED` / `HIGHLIGHT` / `HIDDEN` | Overrides the item's `DisplayMode` for this render (and for the click check — `DISABLED`/`HIDDEN` rows can't be clicked). Invalid → the column value, warned once. |

The Bukkit-free part (resolving every property into one
`MenuItemPresentation`, parsing `BannerPatterns`) lives in knk-core and is
unit-tested; knk-paper only maps the result onto an `ItemStack`.

### E7 — Inline colour

`&`-codes (`&0–9`, `&a–f`, `&k–o`, `&r`, case-insensitive) in resolved
`Name`/`Lore` text — including text returned by getters — are translated.
Precedence: the whole-line `ChatColorName`/`ChatColorDescription` colour is
applied **first** (as a line prefix); inline codes **after** it override it
from that point on; `&r` resets to Minecraft's default styling, not to the
prefix colour. (Phases 2–8 already routed text through
`DisplayTextFormatter.translateToLegacy`, which translated `&` — Phase 9
makes the rule explicit, Bukkit-free and tested in knk-core
`MenuTextColors`.)

### E8 — Lore omission / expansion

Per `Lore` binding (J5):
- the expression is **exactly one placeholder** (`$row.getJoinHintLines$`):
  `null` → the line is dropped; an `Iterable`/array → one line per element in
  order (null elements dropped); anything else → one line via `String.valueOf`;
- anything else (text around/between placeholders): one line, a `null` piece
  renders as `""`, an `Iterable` piece is joined with `", "`;
- an empty string stays a blank line.

The same rule makes a `Name` binding resolving to `null` leave the name unset.
Cache entries now store the resolved shape (text, lines, or absent), so the
refresh policies apply to lists as well.

### E9 — `menu.back` + engine roots

- **Action `menu.back`:** pops the nav stack and re-opens the previous entry
  (key **and** ctx, no push); with no previous entry it closes the menu and
  resets navigation. `MenuService.goBack(player)` is the shared entry point.
- **`$menu$`** → knk-core `MenuView`: `getTitle`, `getKey`, `hasPrevious`,
  `getPreviousTitle`, `getBackLabel` ("Back" / "Exit"), `getBackHint`
  ("Click here to go back to <previous title, colour codes stripped>" /
  "Click here to close this menu").
- **`$section$`** → knk-core `SectionView` for the section being rendered (or
  clicked): `getName`, `getPage` (**1-based**, J15), `getPageCount` (≥ 1),
  `hasNextPage`, `hasPreviousPage`. The legacy automatic "Page X/Y" lore on
  `menu.page.next/prev` buttons is suppressed when the item already references
  `$section.` (no duplicate line).

### Validator changes (summary)

`MenuDefinitionValidator.validate(menu, declaredTypes, rowTypesBySourceId)`
(the 2-argument overload stays): declared types come from the provider
registry + engine roots; `$row$` rules (E3); `MenuContextParams` key hops
(E1); placeholders inside action/condition/content-source params values.
`validateActionsAndConditions`/`validateContentSources` unchanged apart from
covering both condition phases.

### Seed / demo

Create-only seed templates `example.domain` and `example.domain.detail`
(`MenuTemplateSeed` convention) plus a demo `MenuFeature` in knk-paper
(`ExampleDomainMenuFeature`): row source `example.rows` (static in-memory
`ExampleMenuRow`s), variable roots `exampleClock` (ticking seconds, for the
TTL/auto-refresh demo) and `exampleSelected` (resolves the row named by
`$ctx.rowId$`). Engine library addition (J12): generic condition
`value-equals` (`{"value": "$…$", "expected": "true", "negate": "false",
"denyMessage": "…"}`) so Render conditions are usable without feature code.

### Judgment calls

| # | Call | Why |
|---|---|---|
| J1 | Feature callbacks always on the main thread; render split async/main | Siege state is main-thread-owned; the alternative ("providers must be thread-safe") pushes a subtle contract onto every feature |
| J2 | Push only when navigating from an open menu; commands reset | Gives v2's "Exit when opened by command" without a flag on every call |
| J3 | ctx values are strings (`MenuContextParams`) | They travel through `ParamsJson` (a string map) anyway; typed lookups belong in the feature's provider |
| J4 | Row cache scoped by (binding, section, index) + identity check | Bounded memory; correct across paging |
| J5 | Whole-expression rule for null/list | Matches every Part C usage; mixed text keeps Phase 3 behaviour |
| J6 | Row sources use a separate `registerRows` API | Keeps `catalog.itemblueprints` and its tests untouched |
| J7 | Hidden rows leave gaps | Compacting would desync page size/count from the source |
| J8 | Render conditions re-checked silently at click | Defense in depth like `visibilityPermission`; silent because the player never saw a reason |
| J9 | `Amount` binding raises max stack size | Siege uses banner stack size as a player counter; banners cap at 16 otherwise |
| J10 | Banner base colour = material swap, banners only | Modern banners have no separate base-colour field |
| J11 | Registries lock when validation runs | Enforces "register before validation" instead of only documenting it |
| J12 | Generic `value-equals` condition | Lets templates express render conditions over any getter without new code |
| J13 | Diff-based `applyToInventory` | Avoids tooltip flicker at a 1 Hz repaint; cheap `ItemStack.equals` |
| J14 | No section-level conditions | Not in E1–E9; row-template + pinned-item conditions cover C.3 |
| J15 | `$section.getPage$` is 1-based | It is display text ("Page 1/3") |
| J16 | `SlotOverride` stays **absolute** | Existing engine + seeds; Part C's "section-local" notation must be converted by Siege 8b |
| J17 | `AutoRefreshTicks ≤ 0` stored as null | One representation of "off" |

### Notes for Siege Phase 8b

- Implement a `MenuFeature` and add it to the feature list in `KnKPlugin`
  (next to `ExampleDomainMenuFeature`); registering anywhere after
  `MenuDefinitionValidationRunner` throws.
- View/row classes used in `$…$` chains should be **public** with public
  zero-arg getters (reflection); a getter returning `List<String>` is what E8
  expands.
- `SlotOverride` is absolute (J16): Part C's section-local slots need
  converting (e.g. C.2 `Sieges` local 27 at `DisplaySlot` 9 → slot 36).
- Hide a whole section via Render conditions on its row template + pinned
  items; prefer returning an empty page from the source when not applicable.
- Use `MenuService.refreshOpenMenus(ctx -> ctx.menuKey().startsWith("siege."))`
  (optionally matching `ctx.menuContext().get("lobbyId")`) on join/leave/vote/
  phase change; `AutoRefreshTicks = 20` covers countdowns.
- `menu.confirm.doubleclick` keys its arm on the item template id, so on a row
  template all rows would share one arm — use it on pinned items (C.3's leave
  button is pinned, so this is fine).

### Deviations from MENU_TEMPLATES.md Part B (E1–E9)

- **E2 registration guarantee** is enforced, not just documented: all four
  menu registries lock when validation starts (J11) — a stricter contract than
  "providers must register before".
- **E3** row sources register through a separate `registerRows(id, rowType, source)`
  (J6) and receive the interpolated params as an argument; a row source that
  returns more rows than the page size is sliced by the engine. Java-mapped
  `register(id, source)` sources are unchanged.
- **E3/E8** `VariableBinding.Expression` may now be empty (`""` = blank lore
  line); the API used to reject it, which made Part C's blank lines
  unexpressible.
- **E4** event-driven refresh (`refreshOpenMenus`) re-renders on the **next
  tick** (batched with auto-refresh), not synchronously inside the call.
- **E5** additionally defines action-level Render conditions (drop the
  action) and a silent click-time re-check (J8); Part B only sketched
  item hiding.
- **E6** `Amount` raises the stack's max-stack-size component when needed (J9);
  `BannerPatterns` base colour is a material swap (J10).
- **Extra (not in E1–E9):** generic `value-equals` condition (J12);
  diff-based `applyToInventory` (J13); fix — `menu.open` to a *different* menu
  used to render into the previous menu's `Inventory` (in-place refresh is now
  limited to the same menu key and size).

### Findings for Siege Phase 8b (Part C vs the engine)

1. **Absolute `SlotOverride` (J16).** Part C's notation says "`slot` is
   section-local `SlotOverride`", but the engine (Phases 2–8) treats
   `SlotOverride` as an absolute inventory slot. Convert when seeding, e.g.
   C.2 `Sieges` local 27/35 at `DisplaySlot` 9 → 36/44.
2. **C.3 `Body` — "one section per phase" at the same slots is not
   expressible:** sections can't carry conditions (J14) and
   `MenuLayoutValidator` rejects two sections sharing slots (reconciliation
   bug #8's guard). Recommended: **one** `Body` section with one phase-aware
   source (e.g. `siege.body {lobbyId}` → member rows in MATCHMAKING/HUB,
   objective rows in IN_PROGRESS/ENDING) whose declared row type is a single
   view (`SiegeBodyRowView`) exposing the union of getters the row template
   needs (`getMaterial`, `getSkullOwner`, `getBannerPatterns`, `getDisplayMode`,
   `getName`, `getLoreLines`). If per-phase templates are really wanted, the
   engine follow-up would be "several row templates per section, first one
   whose Render conditions allow wins" plus a shared row supertype — not built.
3. `C.3 Votes` "section rendered only while `siege.vote-open`": Render
   condition on the row template (and pinned items); have
   `siege.vote-candidates` return an empty page when voting is closed.
4. Getters returning a Bukkit `Material` are fine for `Material` bindings
   (`String.valueOf` gives the enum name); `BannerPatterns` getters must
   return the E6 string format.

### Verification

**Done (2026-09-25, on the developer's machine — `repo.papermc.io` and the
`dotnet` SDK were both reachable):**
- knk-plugin `./gradlew test shadowJar`: **knk-core 512 tests** (369 menu,
  58 new), **knk-api-client 28**, **knk-paper 240** (7 new in
  `MenuPhase9PaperTest`, 14 skipped = the pre-existing `integration`/
  `requires-bukkit` tags) — 0 failures. All pre-existing menu tests (311)
  stayed green unchanged. The plugin jar builds (`shadowJar`).
- knk-web-api `dotnet build` clean; `dotnet test`: 318 tests, **5 failures,
  all pre-existing** — the identical 5 fail on `origin/master` (checked in a
  throwaway worktree): `ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`,
  `FormSubmissionProgressRepositoryTests.DeleteCompletedOlderThanAsync_…`,
  `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_…`,
  `PathResolutionServiceTests.ValidatePathAsync_AllowsValidV1Paths` ×2. The 12
  new `MenuTemplateServicePhase9Tests` pass, including one that runs the seed
  into an EF InMemory database twice (create-only) and round-trips every
  `example.domain*` template through the real mapping profile and
  `MenuTemplateService.CreateAsync`.
- Migration generated with `dotnet ef migrations add` (snapshot diff contains
  only the three new columns; `Phase` default hand-set to `'Click'`).
- `MenuPhase9PaperTest.seedExpressionsValidateAgainstTheRegisteredTypes`
  validates every getter chain the seeds use against the demo feature's
  declared types (guards the seed ↔ plugin contract).

**Not verified — no live server/DB was used:**
- the migration was **not applied** to any database (the only configured DB is
  the shared dev MySQL, which this session deliberately left alone);
- nothing was run in-game: rendering, clicks, auto-refresh, banner/skull
  meta, the main-thread pipeline and the `menu.open` Inventory fix are covered
  by unit tests of their Bukkit-free parts only;
- `refreshOpenMenus` has no in-game caller yet (Siege 8b will be the first).

**Manual checklist (`example.domain`)** — deploy the plugin branch, run the
web-api branch with `dotnet ef database update`, restart:
1. Startup log: `InventoryMenu startup validation: checked N menu(s), 0 blocked.`
   (`example.domain` and `example.domain.detail` must not be blocked).
2. `/knk menu open example.domain`:
   - slot 0 clock: "Seconds since enable" counts up every second while the
     menu stays open; the "Static line" never changes; hovering doesn't
     flicker;
   - slot 4: your own head; name "(your name)'s head" (green then grey); lore
     line 1 grey then aqua; line 2 red then reset + italic;
   - slot 8: BARRIER **Exit** / "Click here to close this menu"; click closes;
   - row 2: Emerald ×3 glowing with note + blank line + 2 detail lines; Red
     Banner showing **20** (red base, white bottom stripe, black border, no
     pattern tooltip lines); Gradient Banner (white, 3 layers); Notch's head;
     Broken Material as PAPER ×64 with **one** server-log warning (not one per
     second); an **empty slot** where the hidden "Secret Row" would be;
     Disabled Row with "(Unavailable)" that ignores clicks;
   - pager slots 9/17: exactly one "Page 1/2" line; Next shows Diamond,
     Gold Ingot ×5, Iron Ingot ×12; Prev/Next cycle;
   - row 3: an op sees "You are op" (slot 20), a non-op "You are not op"
     (slot 21); the lever (23) opens the detail menu for row 1 as op and closes
     the menu as non-op; the book (25) shows no line for the null note and one
     blank line.
3. Click Emerald → `example.domain.detail`: slot 0 "ctx.rowId = 1" and
   "Previous menu: Example Domain Menu"; slot 4 = emerald ×3 with its note and
   detail lines; slot 8 **Back** / "Click here to go back to Example Domain
   Menu"; "Others" lists the 9 other rows.
4. Click Red Banner in "Others" → detail for row 2 (banner ×20); **Back** →
   detail for row 1 (ctx restored); **Back** → `example.domain` (label Exit
   again); Exit closes. Re-open by command → Exit (fresh stack).
5. `deop` yourself from the console while `example.domain` is open: within a second the
   op/non-op items swap (auto-refresh re-evaluates Render conditions).
