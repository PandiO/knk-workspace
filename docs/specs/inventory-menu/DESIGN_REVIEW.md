# Inventory Menu — Design Review & Recommendations

A critical pre-implementation review of the flexbox/webapp-style architecture
(`docs/specs/inventory-menu/`), plus formal specs for the four capabilities
requested (search, conditional menu-button actions, filters, permissions) and
cross-cutting recommendations across UI, customizability, portability,
scalability, and functionality.

## 1. Architecture assessment: the flexbox/webapp-imitation approach

**The core call is right.** Composite pattern for the menu tree, and splitting
template/definition from rendered-per-player-instance, are both proven,
well-trodden choices for exactly this kind of problem — not over-engineering.
Worth noting explicitly: this is the *same* split already decided for Items
(`ItemTemplate`/`ItemInstance`). That's real consistency across the codebase,
not a coincidence worth losing — keep using it as the default pattern whenever
"one definition, many live copies" shows up elsewhere.

**Where the web/flexbox framing is worth tempering, not abandoning:**

- **Real flexbox exists to solve variable-sized containers.** A Minecraft
  inventory is a fixed 9-wide grid, max 54 slots, always known up front. There's
  no actual "flex-grow into unknown space" scenario here. Importing the full
  align/justify/grow/wrap vocabulary as a *mental model* is fine and matches
  your instinct — but building a fully general flex-layout algorithm for a
  problem space this constrained risks spending real engineering time on
  generality nothing will ever exercise. A CSS-Grid-with-static-tracks mental
  model (explicit cell placement, not a flex-solving algorithm) gets the same
  composability with much less to get wrong and much easier debugging.
- **Watch the indirection cost of "webapp imitation" specifically.**
  `MenuSession`'s own doc comment describes itself as "a session of a user in
  an internet browser" — a useful analogy, but resist importing web concepts
  that don't have a real payoff here. Concretely: don't reach for
  virtual-DOM-style diffing/reconciliation for inventory updates unless
  profiling actually shows full-rewrite is a problem. 54 `ItemStack` writes is
  cheap. That's solving a problem you don't have.
- **Reflection-based variable resolution (`$self.getX.getY$`) is elegant but
  has two real costs — resolved below, not just flagged:**

  **1. Cache invalidation policy (decided).** Every VariableString binding
  carries a `RefreshPolicy`, one of three:
  - `STATIC` — resolves once and never again. For variables backed by
    immutable template/definition data (item name, category, description).
    No TTL, no dirty-tracking overhead.
  - `ON_DIRTY` (**the default** — applies unless a variable is explicitly
    marked otherwise) — re-resolves only when the owning `MenuSession`/section
    is explicitly marked dirty (an action fired, a click changed state, a
    filter/search updated). This is what already happens conceptually via
    `commitUpdates()`/`updateDisplay()` — formalizing it as the default makes
    cache *correctness* the default behavior, not something each screen has
    to get right individually.
  - `TTL(ticks)` — an explicit opt-in escape hatch for genuinely volatile
    data with no corresponding "dirty" event of its own: player balance
    changing from outside the menu flow, cooldown timers, countdown displays
    (this is the existing FR-2.6.2 "time-aware variables" case). A short
    default — 20 ticks (1 second) — is a reasonable starting point; tune per
    variable if profiling says otherwise.

  Concretely: `VariableResolver` checks the binding's policy on every render
  pass — `STATIC` short-circuits to the cached value unconditionally,
  `ON_DIRTY` checks a dirty flag, `TTL` checks elapsed ticks — before doing
  any reflection work at all. No variable resolves without an explicit,
  declared policy; there is no "undecided" default state left in the system.

  **2. Load-time validation (decided).** At plugin enable — not first
  render — every registered menu definition's VariableString bindings get
  walked once: for each getter-chain hop, resolve it via
  `Class.getMethod(getterName)` against the **declared type** of the context
  binding at that point in the chain (e.g. `$player.getName$` → look up
  `getName` on `Player.class`, not on a live instance), following return
  types hop to hop. Any hop that doesn't resolve to a real method is
  collected as a validation error — chain, expected type, and menu/section
  id — rather than surfacing later as a blank tooltip in production.

  Failure handling: fail at the level of the *individual menu*, not the whole
  server. A menu with one or more unresolved bindings refuses to register and
  logs every broken chain clearly at startup (plus, ideally, an admin command
  to list currently-broken menus at any time) — visible and loud, but a
  single bad variable in one admin screen doesn't take the whole game down
  for players. This directly prevents a repeat of bug #7's actual failure
  mode: not that the bug existed, but that it went unnoticed for years.

  Known limitation worth accepting rather than solving: generic/erased types
  in a getter chain (e.g. a method returning `List<T>`) validate against the
  raw return type only, not full generic type-safety — a reasonable
  simplification for a startup sanity check, not a full type checker.
- **Testing strategy should go one step further than what's written.** The
  design already calls for unit tests on slot calculation and variable
  resolution, and mock-inventory rendering tests — good. Given that v1 and v2
  *both* shipped pagination/overflow bugs that hand-written example tests
  would plausibly have missed (off-by-one indices, an inverted overflow-guard
  condition), recommend property-based/fuzz testing specifically for slot
  calculation and overflow guards: generate random width/height/alignment
  combinations, assert invariants ("no computed slot ever exceeds inventory
  size," "occupied slots == width × height," "expansion guard rejects
  anything that would exceed 54 slots"). This is exactly the bug class that's
  recurred across three implementation generations now — worth the extra
  test-design effort specifically here.

## 2. New capabilities — formal specs

### 2.1 Search
Model as a section-level capability, not a bolted-on feature: a "searchable"
flag on content-listing sections, which filters the underlying content list
*before* pagination runs (search and paging must compose, not conflict).
Minecraft has no native inventory text-input widget — pick one input pattern
as the standard rather than leaving it per-screen (an anvil-GUI-style
text-input is the common idiomatic approach in Bukkit/Paper plugins). Define
an explicit empty-results state — neither legacy system had one, so this is
genuinely new UX, not reuse.

**Text-input mechanism, decided (2026-09-22):** AnvilGUI (the md5lukas fork,
Paper-only), not chat capture. Phase 5's implementation reused this
codebase's existing `ChatCaptureManager` instead — a reasonable-looking
shortcut at the time (it was already built and idiomatic for other
account-flow input), but a follow-up research pass confirmed it's the wrong
call for this specifically: chat capture requires closing the menu Inventory
entirely to type (vanilla Minecraft closes any open custom Inventory the
instant chat opens), then reopening it after — a jarring close/reopen cycle
for something that should feel like a normal menu interaction. AnvilGUI
avoids that: it opens in place, captures the query via the anvil's rename
field, and closes back into the originating menu with the result already
applied. This is now the standard text-input mechanism for InventoryMenu,
superseding Phase 5's chat-capture approach — see §2.5 below for the full
interaction-model decision this is part of, and `docs/backlog/
QOL_BUGFIX_BACKLOG.md` item 8 for the implementation follow-up this implies.

### 2.2 Conditional menu-button actions
Add a `condition` check per action (or per `MenuItem`), evaluated **at click
time**, distinct from visibility (Display modes control whether something
*renders*; this controls whether a click actually *does* something). This
closes a real staleness window: render-time state can go stale between when a
menu opens and when the player clicks (e.g. an affordability check done at
render time, then the price or the player's balance changes before the
click). Recommend a small reusable condition library (permission node,
affordability, ownership, item-age) rather than one-off lambdas scattered
through screen code — keeps business rules declarative and testable in
isolation, instead of hardcoded into UI classes the way gem-shop affordability
got baked directly into lore-color strings in both legacy systems.

### 2.3 Filters
Distinct from search: search is free-text query, filters are structured/
faceted narrowing (category, grade, owned/not-owned, price range) — this maps
directly onto fields that already exist as real structured data in the Items
model (`Category`, `Grade`, `Tag` per §9.1). Model as a "FilterBar" section
type that emits filter-predicate state into the `MenuSession`. Both search and
filters should compose through one shared "active content predicate" concept
in the session, not two independent bolt-on mechanisms that each content
section has to know how to combine separately.

### 2.4 Permissions
Formalizes reconciliation gap #10. Every `MenuItem` — and every `MenuSection`,
for whole-section hiding (e.g. an entire "Admin Tools" section for non-staff,
rather than gating each item individually) — gets an optional permission
property. Recommend two independent checks rather than one: `visibilityPermission`
(should this render at all) and `actionPermission` (can this action execute) —
usually the same node, but not always (e.g. a preview visible to everyone,
actionable only by the owner). Check both at render time (hide/disable) *and*
at click time (defense in depth — never trust that hiding a button was
sufficient, in case of any client/timing edge case).

### 2.5 Interaction model: UI-first, command fallback (decided 2026-09-22)
Added after Phase 5 shipped a command-triggered search/filter mechanism and
the developer flagged that commands should never be the main or only way to
drive these interactions — a dedicated research pass then produced this
decision. It's broader than §2.1's text-input question alone: it's the
general interaction principle for every InventoryMenu flow, current and
future.

**Principle:** InventoryMenu flows are click/GUI-driven by default. A command
equivalent may exist for power users or scripting, but it is never required
to complete a flow, and no menu action should force a close-command-reopen
cycle.

- **Browsing / pagination / filtering by category**: in-place re-render, no
  external input — a click on a pagination arrow or filter-cycle item
  re-renders the same Inventory in place.
- **Free-text input** (search, naming, custom values): AnvilGUI. Opens in
  place, captures text via the rename field, closes back into the
  originating menu with the result applied. See §2.1's update above — this
  supersedes Phase 5's chat-capture-based search input specifically.
- **Numeric input** (quantities, amounts): click actions first — left-click
  = +1/select, right-click = -1/deselect, shift-click = +stack or max,
  matching the v1/v2 pattern. Anvil-based custom-amount entry is the
  fallback only, for values outside the click-driven range.
- **Confirmations**: an in-menu confirm/cancel item pair, not a chat y/n or
  a command. (Also closes the loop on `MenuSectionKind.CONFIRM_DIALOG`,
  which has existed as an enum value since Phase 2 with no defined
  interaction behavior yet.)
- **Commands**: kept only as an optional fallback path (e.g. `/inv search
  <term>` still works for scripting/macros), but never the only path.

**Library choices:** InvUI for chest-menu construction/pagination; AnvilGUI
(md5lukas fork, Paper-only) for the free-text capture surface. Neither is a
dependency of `knk-plugin` today.

**Implementation impact — flagged, not yet actioned:** adopting InvUI for
menu *construction*/pagination is a materially bigger change than it first
sounds, because Phase 2 already built and shipped a hand-rolled equivalent
(`MenuSlotCalculator`, `RuntimeMenuSection.resolveSlots`'s pagination,
`MenuRenderer`, `MenuItemBukkitMapper`) that Phases 3-5 are all built on top
of. This decision does **not** by itself specify how the two reconcile —
whether InvUI replaces the Bukkit-facing rendering/pagination layer while
the Bukkit-free template/domain model (`MenuTemplate`/`MenuSection`/
`MenuItem`, `VariableBinding`, `MenuSession`) stays as the source of truth
feeding it, or something else. That's real design work for whichever phase
picks this up, not a decision to make silently while just updating docs.
Similarly, click-driven pagination/search/filter/confirmation triggers all
depend on `ActionRegistry` (Phase 6, not yet built) to do anything on click.
See `docs/backlog/QOL_BUGFIX_BACKLOG.md` item 8 for the tracking entry and
`ACTIVE_SESSIONS.md`'s Phase 5 entry for how the superseded chat-capture
approach got built in the first place.

## 3. Cross-cutting recommendations

### UI
- **End-user**: make navigation chrome placement (Back/Close/Search) a
  structural convention — same physical slot on every screen — rather than a
  per-screen choice. v1's Houselist back-button bug (opened the wrong menu)
  traces directly to ad hoc, inconsistent back-navigation; a structural
  convention removes the whole bug class rather than requiring careful porting
  of each screen.
- **End-user**: make the async pipeline's loading-state screen the default for
  any content-heavy section, not opt-in — avoids a jarring pop when a slower
  content fetch (especially once web-API-backed data is in the mix) resolves.
- **Admin**: a "preview as player X" / permission-simulation mode is a natural
  and valuable extension now that permissions are first-class — lets an admin
  verify a screen renders correctly for a given rank without a second test
  account. Direct evolution of the existing "spectate another player's menu"
  concept, but proactive instead of reactive.

### Customizability
- **Decided: DB-persisted from day one; FormConfig-authored UI deferred.**
  `Menu`/`MenuSection`/`MenuItem` exist as real backend entities and no
  templates are hardcoded in Java — but authoring them via `FormWizard`/
  `FormConfigBuilder` (the pattern `GateStructure` uses) is a future update,
  not a day-one requirement. Day one, templates get created directly
  (seed data / direct API), which sidesteps the nested-entity-creation gap
  in the form system for now — see `FORMCONFIG_INTEGRATION.md`, which stays
  relevant as the design for when that update happens.
- Design the `MenuItem`/`MenuSection` property schema as plain, serializable
  data — actions/conditions referenced by a registered ID/key rather than
  inline code — so the plugin consumes persisted template data rather than
  authoring it. This also keeps the later FormConfig work a pure additive
  authoring layer instead of a schema change.
- Build a small library of reusable preset section/item types (search bar,
  filter bar, paginated content grid, confirm dialog) as first-class,
  exportable components — both to speed up porting v1's ~60 screens, and
  because a preset library is explicitly named as one of v1's own real
  strengths worth keeping. Recommend any future builder UI expose *these
  presets*, not raw layout primitives, per `FORMCONFIG_INTEGRATION.md` §4.

### Portability
- Treat "no NMS dependencies" (already in the design doc) as a hard
  constraint, not a suggestion — this is precisely what made v1 fragile to
  Spigot/Paper version churn.
- Keep Bukkit-specific types out of the Model and Display-Engine layers
  entirely, isolated behind the Integration layer. Low cost now, large
  optionality payoff later — directly consistent with the same
  future-engine-portability principle already applied to the permissions
  system (§5.1's PermissionsEx-independence rationale).

### Scalability
- Content-listing sections should assume "the list could be large," not just
  "the list could paginate." The current pagination model (slice an in-memory
  list) is fine for small lists (Kits, Sieges) but won't hold up for a shop
  backed by the full `ItemTemplate` catalog, or a personal item stash
  accumulated over years. Recommend content sections pull through a paged/
  cursor-based query interface rather than loading a full list into memory
  first — a real contract decision to make now, since it shapes the
  content-section API either way.
- Separate menu-definition caching (rarely changes, weak-reference/pooling as
  already planned) from underlying content-data caching (changes on every
  purchase/acquisition) — different lifetimes, different invalidation
  triggers, shouldn't share one cache policy.

### Functionality
- **Admin**: with search/filters/permissions now first-class, add a
  lightweight audit log for admin-tool-gated actions (who triggered what,
  when) — consistent with the auditability already expected elsewhere in
  admin-configurable systems (salary multipliers, premium tiers).
- **End-user**: define explicit timeout/failure UX for content sections now
  that the async pipeline can involve web-API calls — v1/v2 never needed this
  (fully local), so it's new design surface, not something to reuse from
  legacy patterns.

## Summary
Architecture is sound and already fixes the two serious legacy bugs by
design. Recommend: temper (don't abandon) the flexbox/web vocabulary toward a
static-grid mental model to avoid unneeded layout-algorithm complexity; add an
explicit cache-invalidation policy and load-time validation for variable
resolution; add property-based tests for slot/overflow logic specifically;
build search, conditional actions, filters, and permissions in as specified
above; and treat scalable content access as a decision to make now, not a
retrofit later.
