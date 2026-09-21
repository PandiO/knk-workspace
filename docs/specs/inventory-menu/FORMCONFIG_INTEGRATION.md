# Inventory Menu — FormConfig / FormWizard Integration

> **Status update:** after review, DB persistence for menu templates stays a
> day-one requirement (no hardcoded Java templates), but building the
> `FormWizard`/`FormConfigBuilder` authoring UI described here is **deferred
> to a future update**, not day one. Day one, templates are created directly
> (seed data / direct API) rather than through a generated admin form. This
> document stays as the design for that future update — the analysis below,
> including the nested-entity-creation gap in §3, is unchanged and still
> worth reading before that work starts; it's just no longer blocking the
> initial implementation.

Analyzes what "no hardcoded menu templates, fully admin-configurable via the web
app, persisted in the database" actually requires, based on how `FormWizard`/
`FormConfigBuilder` genuinely work today (per `docs/architecture/web-app-architecture.md`
and the `GateStructure` precedent, `docs/specs/gate-structure-animation/GATE_FORMCONFIG.md`).
Read this alongside `RECONCILIATION.md` and `DESIGN_REVIEW.md`.

## 1. How the pattern actually works (confirmed, not assumed)

The web app has a genuinely metadata-driven CRUD engine, not a form-per-entity:
a `FormConfigurationDto` (steps, fields, field types, per-field and per-step
display conditions, validation rules) is authored via `FormConfigBuilder` and
rendered generically by `FormWizard` for any backend entity exposed through the
metadata endpoint. `GateStructure` is the clearest real precedent — its field
matrix is type-dependent (four `GateType`s, each showing different fields/steps),
some fields are server-derived rather than form-entered, and some fields are
"world-bound" (captured in-game via a `WorldTask` — a point-picking flow — and
held ephemeral in `WorldTask.OutputJson` until the entity is actually created).

**This directly changes the InventoryMenu architecture decision, not just its
implementation plan.** The January design doc's "web API menu definitions" was
scoped as a medium-term (3–6 month) enhancement, built after a code-first engine
existed. Given what you've asked for, that ordering inverts: the persisted,
FormConfig-authored template *is* the v1 requirement, not a later layer on top
of a code-first system.

## 2. What this means concretely

- **`Menu`, `MenuSection`, `MenuItem` (and their as-designed properties — layout,
  variable bindings, actions, conditions, permissions) need to exist as real
  backend entities** (knk-web-api models + DTOs), not just Java POJOs built via
  the builder pattern in plugin code. The plugin becomes a *consumer* of
  persisted template data, not the author of it.
- **The plugin should load these through the data-access/cache layer already
  confirmed to exist** (`knk-core/.../dataaccess/`) — a `MenuTemplatesDataAccess`-
  style gateway follows the exact same pattern as `ItemBlueprintsDataAccess`,
  `TownsDataAccess`, etc. No new caching mechanism needed; this is exactly the
  scalability recommendation from `DESIGN_REVIEW.md` §Scalability, now with a
  concrete implementation path.
- **Type-dependent field matrices, `GateStructure`-style, make sense for
  `MenuItem` "kind"** — a search-bar item, a filter-bar item, a content-grid
  item, and a simple action button each need different fields visible in the
  builder, the same way `GateType` drives which fields `GateStructure`'s form
  shows. This is a strong argument for the preset-type library already
  recommended in `DESIGN_REVIEW.md` §Customizability: each preset type maps to
  one field schema in the form config, rather than exposing raw layout
  primitives (x/y/width/height/align/priority) directly to admins.

## 3. A real gap you should know about before committing to this

Menu → MenuSection → MenuItem is a **deeply nested, mostly one-off-per-menu**
hierarchy — building a "Personal Menu" template means creating dozens of bespoke
MenuItems, not linking a handful of shared reference records (the way linking
existing `EnchantmentDefinition`s to an `ItemBlueprint` works today).

Checked the actual current many-to-many editor spec directly: **creating a
brand-new related entity inline from a parent form is explicitly a non-goal of
the current implementation** — you can only select *existing* related entities
from a picker table and edit join-entity fields on the relationship itself.
"Create new related entity" inline is named as a real, wanted improvement in
`m2m-join-creation-improvement-spec.md`, but it's still an **open question
there** ("should this be allowed for all types or only specific ones?"), not
built. There's a partial workaround already in place — a many-to-many step can
link a full child `FormConfiguration` for its join-entity fields — but that's
for editing fields *on the relationship*, not for authoring a whole new
`MenuItem` from inside a `Menu`'s edit form.

There's also a second, smaller but sharp-edged issue: the current form-submission
normalization **collapses list relationships into plain ID arrays, which can
drop join-entity fields** on many-to-many payloads. For most existing uses that's
a minor issue. For menus, it's not — a section's *item order* and an item's *slot
position* are exactly the kind of "join-entity field" (order/position on the
Menu↔Section or Section↔Item relationship) this would silently drop. This needs
either a fix or explicit verification before menu ordering can be trusted through
this pipeline.

**Practical read**: this doesn't block starting the work, but it does shape
sequencing. Building MenuSection/MenuItem creation as a good experience inside
a Menu's edit form is currently blocked on functionality that's designed but not
built. Two honest paths, not a recommendation either way since this is your call:
(a) treat inline related-entity creation as a genuine co-requirement and either
prioritize or contribute to that M2M work alongside InventoryMenu's own, or
(b) scope v1 as "create MenuSections/MenuItems as standalone entities first,
then assemble a Menu by selecting them" — more clicks for you as admin, but
buildable entirely with what exists today.

## 4. Questions for you

1. Given the gap above: prioritize/build the inline-related-entity-creation
   improvement alongside this work, or accept the more-clicks "create then
   link" flow for v1?
2. Confirm the ordering fields (section order within a menu, item order/slot
   within a section) should be explicit integer fields on the join entities —
   and that the normalization-drops-join-fields issue gets a fix or at least a
   verified test before menu templates depend on it.
3. Scope check: should the builder expose the *full* raw layout system
   (explicit x/y/width/height/alignment per item, as the engine itself
   supports), or should it expose only the preset-type library recommended in
   `DESIGN_REVIEW.md` (search bar, filter bar, content grid, confirm dialog,
   etc.), with raw layout primitives staying code-only? My recommendation is
   the latter — much lower risk of an admin building a broken/overlapping
   layout through the form, and still fully data-driven/no-hardcoded-templates
   either way — but it's a real scope decision, not something to assume.
4. For MenuItem click actions/conditions (from `DESIGN_REVIEW.md` §2.2): the
   plan there was already "referenced by registered ID, not inline code" —
   confirming that stands, meaning the form config exposes a dropdown of known
   action-type IDs plus that type's parameters, while the action
   implementations themselves stay code-side. Worth confirming since it's now
   load-bearing for the FormConfig integration, not just a nice-to-have.

## Summary
This is a real, precedented pattern (not a new invention for this feature), and
the plugin-side dependency (data-access/cache layer) already exists and fits
cleanly. The one genuine risk is the inline-child-entity-creation gap in the
form system itself — worth resolving sequencing on that explicitly before
implementation planning, rather than discovering it mid-build.
