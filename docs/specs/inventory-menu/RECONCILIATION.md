# Inventory Menu — Design Doc Reconciliation

Reconciles `docs/specs/inventory-menu/{REQUIREMENTS,ARCHITECTURE_DESIGN,QUICK_REFERENCE}.md`
(Jan 17, 2026 — analysis of v2's orphaned `menu/`+`command/menu/` flexbox tree)
against `docs/specs/legacy/inventory-menus.md` (full v1/v2 bug-and-behavior mining).

**Decision this reconciles against:** the flexbox-style engine (Menu → MenuSection →
MenuItem composite, MenuSession, VariableResolver, align/position/growth/overflow/
priority model) becomes the v3 InventoryMenu engine. v1's actual screens — and the
two currently-live v2 screens (Kits, Sieges) — get rebuilt as *content* on top of it.
Neither v1's god-class nor v2's `model/menu`/`Menu2`/`ContentGroup` tree carries
forward as architecture; both get ported for content only, then retired.

## 1. Does the new engine actually fix the known bugs?

| # | Legacy bug | Verdict | Notes |
|---|---|---|---|
| 1 | v1 pagination `IndexOutOfBoundsException` on partial last page | **Fixed by design** | Slot-capacity-vs-item-count pagination (mirrors what `ContentGroup` already got right) replaces hardcoded index math entirely. No hardcoded page-size arithmetic anywhere in the new model. |
| 2 | v1 pagination hard-caps at page 10 | **Fixed by design** | Same root cause as #1 — generic overflow handling has no case-by-case ceiling. |
| 3 | v1 Houselist Back button opens wrong menu | **Not an architecture bug — a content bug.** | Generic `BackMenuItem`-equivalent exists in the design (reads a previous-menu reference), but the actual mistake was a hand-wired override in one screen's click handler. Carries a real risk when porting v1 content: verify each ported screen's back-target against v1 behavior *and* against what the label says, not just one or the other. |
| 4 | v1 static per-player maps never cleared (unbounded growth) | **Partially addressed — real gap.** | `MenuSession` replaces the scattered static maps conceptually, but the design doc never specifies session lifecycle — nothing about clearing/evicting a session on player quit. Needs an explicit requirement: `MenuSession` must be removed from any session registry on `PlayerQuitEvent`, not just left to a weak reference and GC. |
| 5 | v1 `openHouselist` NPE on null pagenumber | **Moot** | Hardcoded page-number parameters disappear entirely with generic pagination. |
| 6 | v1 `MenuItemBlink` mutates `Inventory` off the main thread | **Fixed by design** | §6.3 Async Rendering is explicit: expensive work off-thread, `Bukkit.getScheduler().runTask` back on main thread before touching the `Inventory`. This is the correct fix for the actual defect (not "don't blink," but "don't touch Inventory off-thread"). Blink/highlight itself is a named requirement (FR-2.6.1), so the feature survives with the bug fixed. |
| 7 | v2 `%...%` variables never substitute (broken `$(.*?)$` regex) | **Fixed by design, needs a regression test** | New resolver uses a properly escaped, bounded pattern (`\$([\w.]+)\$`) against a *different* delimiter convention (`$x.y$` chained-getter, matching the orphaned tree's own original syntax, not the live `%x%` one). Structurally sound, but given how badly the equivalent bug bit v2 last time with no one noticing, this specifically needs a unit test asserting real substitution happens — not just an architecture read-through. |
| 8 | v2 `Menu2.expandInventory` checks the wrong variable, overflow guard never fires | **Moot for the new engine, but same failure class recurs** | `Menu2` itself is retired. But §5.1's validation checklist ("sections fit within menu bounds") is the same kind of guard that failed in bug #8 — needs a unit test asserting the check actually rejects an over-54-slot menu, since "we wrote a check" was exactly what failed here last time. |
| 9 | v2 base `Menu.prevPage/nextPage` are no-op stubs (only subclasses page) | **Design gap — needs an explicit requirement** | The design doesn't say whether pagination/overflow lives on the base `MenuSection`/`Menu` or is opt-in per subclass. Given bug #9 happened because paging was subclass-only, the requirement should be explicit: overflow/pagination behavior lives on the base class, not something a screen can silently lack. |
| 10 | v2 debug-only Caches button not permission-gated | **Design gap** | No `permission`/visibility-gate property appears anywhere in `MenuItem`'s FR-2.1.3 property list. Needs adding — every clickable/visible item should carry an optional permission check, not rely on screen authors remembering to hide debug items manually. |
| 11 | v2 has two incompatible variable-templating conventions coexisting | **Resolved by consolidation** | Adopting one engine with one resolver syntax retires both `%x%` and the ad hoc mismatches — assuming nothing new introduces a second convention later. |

**Net read:** the architecture is sound and fixes the two structurally serious bugs
(#6 thread safety, #7 the regex) by design, not by luck. Three real gaps to close
before implementation (#4 session cleanup, #9 base-class pagination, #10 permission
gating) — all cheap to add now, expensive to retrofit later.

## 2. What the design doc doesn't cover at all (by design — it's engine-only)

The Jan doc is purely a framework spec. It has **zero mention of actual menu content.**
Everything below is real scope the legacy doc surfaces that still needs a home:

- **v1's screen catalogue** — ~60 `open*` methods. Explicitly enumerated in the legacy
  doc: Houselist, Propertylist, Roomlist, Skill, Gate Manager, HS (Hide & Seek)
  Manager, Siege Information, plus the ~20-item Personal Menu (financial, skills,
  teleport, titles, social, gem-shop, assignments, quests, events, support, admin
  tools). The legacy doc itself flags (open question #4) that only a subset was
  examined in depth — a full catalogue pass is still open if full parity matters.
- **The two currently-live v2 screens** (Kit and Siege overviews, built on
  `ContentGroup`) — these are the only working parts of the *current* game. They
  need porting to the new engine too, not just v1's content — migration Phase 1
  should explicitly target both sources, not just "legacy" ambiguously.
- **"Spectate another player's menu"** admin feature — present, largely unchanged,
  in both v1 and v2. Not mentioned anywhere in the new requirements doc. Real gap
  if it's still wanted (legacy open question #5 already flags this as worth a
  deliberate keep/drop call rather than silent omission).
- **Gem-shop affordability styling** ("Available!"/"Unavailable!" baked into lore
  color in both v1 and v2) — this is the one place the menu and Items work
  actually touch. Per the Items plan (vision.md §9.1), lore becomes pure display
  output driven by instance state; the menu engine's Display-mode system
  (DISABLED/HIGHLIGHT) is the natural mechanism to replace baked-in colored lore
  text here, rather than reinventing it. Worth stating explicitly as a design
  constraint when this screen gets ported, so it doesn't get rebuilt the old way
  by default.

## 3. Migration-path note

The design doc's own three-phase migration plan (parallel implementation → gradual
per-screen cutover → cleanup) is reasonable but written generically against
"legacy." Given there are now three systems in play — v1's god-class, v2's live
`model/menu` (Kits/Sieges), and the orphaned flexbox tree being adopted as the new
engine — Phase 1's adapter work should explicitly cover porting *from* both v1 and
the live `model/menu` screens, not just v1. Otherwise Kits/Sieges is the one thing
that's currently working and it's easy to assume "legacy" means only the old stuff.

## Summary for vision.md Section 10

Current Section 10 text ("not rebuilt for v3, only a single-commit planning doc
exists") is now inaccurate — there's a real, mostly-sound engine design, just no
code yet and three concrete gaps to close before implementation starts. Recommend
updating Section 10 to state: engine architecture decided (flexbox tree, adopted
from the Jan design doc), three open design gaps to close before implementation
(session cleanup, base-class pagination, permission gating), and content-porting
scope (v1's ~60 screens + the two live v2 screens) explicitly called out as
separate, not-yet-planned work.
