# Territory, grasp and public safety — Design

**Status:** Draft. Written from the developer's voice design session of 2026-11-11. Nothing is implemented. Items
are tagged **[V1]**, **[Later]** or **[Parked]** (as in the production [DESIGN](../production-storage-transport/DESIGN.md)
header).
**Last updated:** 2026-11-11
**Supersedes:** the region-based parts of production [DESIGN §3.4](../production-storage-transport/DESIGN.md#34-territory-and-region-rules-v1-2026-11-11)
(a required `WgRegionId`, region rules T1, T3, T4 and T7 as WorldGuard checks, the `TERRITORY` managed region kind).
See [decision record §13](../production-storage-transport/DECISIONS_2026-11-05.md#13-territory-is-computed-not-a-worldguard-region-2026-11-11).
**Related:** [production, storage and transport](../production-storage-transport/DESIGN.md) (structures in
territory), [navigation](../navigation/DESIGN.md) (the access-rule registry pattern reused in §7),
[NPC platform](../npc-platform/DESIGN.md) (garrisons, guards and patrols), [in-game maps](../in-game-maps/DESIGN.md)
(BlueMap).

## 1. Territory: computed, chunk-cached, no WorldGuard region

- **[V1]** Territory is not drawn by hand and is not a WorldGuard region. Ownership of any position is a
  **calculation**: distance from the holder's districts (or anchor, for crown land) against its range, and later its
  grasp (§5).
- **[V1]** Range = base range + power × factor. Base range and factor live in game settings. Capital districts get a
  range bonus (setting).
- **[V1]** Results are **cached per chunk**. Most chunks belong wholly to one holder or none. Chunks a border crosses
  are marked **split** and resolved per block column on demand, so borders can run diagonally instead of in 16-block
  steps.
- **[V1]** The cache is rebuilt when the inputs change: districts, power, range settings, and later points
  allocation.
- **[V1]** The player's current territory is looked up on each chunk crossing (per block inside split chunks). This
  covers entry and exit checks and region-based validation rules.
- **[V1]** BlueMap outlines are drawn straight from the chunk cache through its marker API.
- **[Parked]** WorldGuard stays undecided. If ready-made flags are needed later (mob spawning, deny-spawn,
  greetings), territory can be exported one-way into generated WorldGuard regions. The chunk cache stays the source
  of truth; WorldGuard is only a copy.
- **[V1]** Power is a single number per town, set by an admin. **[Later]** Power becomes a computed sum of factors
  (population, wealth, military and others, still to be decided). Consumers read only the power value.

## 2. Holders and hierarchy

- **[V1]** Territory belongs to a **holder**, not hard-wired to a town. V1 holder kinds: **town** and **kingdom**.
- **[V1]** **Crown land** (kingdom-held land, e.g. frontier forts, royal forests) outranks town territory: where they
  overlap, crown land wins without a conflict.
- **[V1]** A kingdom's total territory = its towns' territories + its crown land, worked out for the map and for
  conflict rules. It has no separate border of its own.
- **[V1]** **Province** is an optional level between town and kingdom: a governmental body grouping towns. A town
  always links to its kingdom and may also link to a province; validation checks the province is in the same
  kingdom. Small kingdoms need no provinces. A province's territory = the combined area of its towns.
- **[Later]** Provinces with regional lords who can act like small kingdoms and conflict with their king or queen;
  province-held land becomes a new holder kind. Holder rank decides who wins an overlap.

## 3. Overlap and the conflict entity

- **[V1]** When two territories of equal rank overlap (or crown land overlaps across alliances), the overlap belongs
  to neither: it becomes a **contested zone**, and the system creates a **TerritoryConflict** entity recording the
  holders and the area.
- **[V1]** Conflicts are not resolved automatically. Admins see them and resolve them by redrawing the lines manually
  or awarding the area to one holder.
- **[Later]** Conflicts become gameplay in the town and civ simulation UI. The outcome depends on the relationship
  (alliance, friendly, same kingdom or clan), relative power and local grasp (§5): the holder with the stronger grasp
  in the contested cells has the better claim.

## 4. Structures, binding and loyalty

- **[V1]** A structure belongs to a town through an explicit link in the database, not through its position. The
  territory check runs at creation time as a **warning-style validation rule**: it warns an admin but does not block.
- **[V1]** If territory later shrinks or becomes contested, the structure keeps its owner. It is flagged, and listed
  on the related conflict entity if there is one.
- **[V1]** Structures carry a **loyalty** field, separate from ownership. In V1 it is stored only, and admins
  resolve.
- **[Later]** A structure in land whose territory holder differs from the town it is loyal to can switch sides or
  revolt over time.

## 5. Grasp, expansion points and public safety

- **[Later]** Power produces **expansion points** that a town spends on either **range** (pushes the border outward)
  or **grasp** (strengthens control within the existing territory). Spreading thin versus digging in is a strategic
  choice.
- Grasp is a strength that fades with distance from the town's districts. Points on range move the border; points
  on grasp slow the fade.
- **Public safety** follows grasp: bandit, raider and ambush chances rise where grasp is weak, so a low-power or
  overextended town sees more trouble at its edges.
- Inspiration: Anno (service buildings cover a radius), Europa Universalis IV (control falls off with distance;
  forts project a zone of control), Total War (low public order spawns rebels, garrisons restore it), Mount & Blade:
  Bannerlord (settlement security, bandits gather where it is low, patrols raise it).

## 6. The safety field (cell grid)

- The map is divided into cells (one per chunk, sharing the territory cache). Each cell holds a grasp and safety
  value per holder, built by summing **layers**:
  1. **Base grasp**, fading with distance from districts (capital bonus applies).
  2. **Structure bubbles**: military structures (garrisons, gatehouses, outposts) project a local bubble of grasp and
     safety, so a remote quarry or road can be secured. They also add a small amount to the town's overall power.
  3. **Patrol trails**: cells guards walk through get a boost that decays slowly. Frequently walked routes stay
     strong; rarely walked ones fade. This covers both the live bubble around a patrol and the regional effect of
     where guards are stationed and patrol often.
- The grid is recalculated periodically (every few minutes, setting), not every tick.
- Consumers (bandit spawns, ambush chance, conflict claims, revolts, later territory effects) only read cell values.
  They never know which sources contributed.

## 7. Source registry

- Sources feed the grid through a **registry**, the same pattern as the navigator's registry for player access
  rules.
- **Pull providers** for steady sources (base grasp, structure bubbles, patrol trails): each registers a provider,
  and the grid pulls from every registered provider on each recalculation.
- **Pushed modifiers** for events (a raid, a bandit camp cleared, a festival): pushed with a strength, an area and an
  expiry, and removed automatically when they expire.
- New sources (roads, watchtowers, a popular lord, recent raids) are added by registering a provider or pushing a
  modifier. The grid and its consumers do not change.

## 8. World modification and region priority

- **[V1]** No one but admins modifies the world: no building or breaking in territory for strangers or town members.
  The world-wide default already blocks this, so territory protects nothing itself.
- **[V1]** The only exception is player harvesting at production structures, governed by those structures' own
  regions and rules.
- **[V1]** WorldGuard priority ladder for the regions that remain, low to high: districts, then structures.
  (Territory and crown land would sit below districts if ever exported to WorldGuard.)
- **[Later]** Territory effects reading cell values: hunger and health effects, mob spawning and mob killing effects,
  and possibly wilderness harvesting with regrowing blocks (e.g. logs), as in V1.

## 9. V1 scope summary

- Computed territory per holder (town or kingdom), chunk cache with split border chunks, entry and exit checks on
  chunk crossing, BlueMap markers from the cache.
- Admin-set power; range from base + power × factor; capital bonus.
- Crown land outranks towns; optional provinces with same-kingdom validation.
- Overlap becomes a contested zone + TerritoryConflict entity; admin resolution only.
- Structure-to-town link; warning-style territory check at creation; loyalty field stored only.
- Grid layers, registry, expansion points, patrol trails, bandits, revolts, territory effects and WorldGuard export
  are **[Later]** or **[Parked]**, but V1 data shapes (holder, power value, loyalty field, conflict entity, chunk
  cache) should not block them.

## 10. Still open

- How the computed territory replaces production DESIGN §3.4's region rules T1-T7 (which become territory lookups,
  which stay WorldGuard checks on districts and structures), and the matching changes to IMPLEMENTATION_PLAN P2.
- Whether crown land needs its own anchor entity (a point or a set of chunks) and how admins define it.
- Range distance metric (to the nearest district region edge or centre) and the capital bonus formula.
