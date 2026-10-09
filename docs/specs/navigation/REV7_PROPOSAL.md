# Road Navigation — Rev. 7 proposal: a routing view, entrances, and which access rules apply to roads

**Status:** Proposed (2026-10-09), awaiting the developer's decisions (§7). Nothing implemented.
**Last updated:** 2026-10-09
**Builds on:** [DESIGN.md](DESIGN.md) §5.6 step 6 and §6.7 (live tags, start/goal sides),
[LAST_MILE_PATHFINDING.md](LAST_MILE_PATHFINDING.md) (walk paths), the live test of 2026-10-07 to 10-09
([smoke-test guide](../../guides/road-navigation-smoke-test.md), findings N3, N4, N6, N10, N14).
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27), [KNG-51](https://linear.app/kngpandi/issue/KNG-51);
related [KNG-73](https://linear.app/kngpandi/issue/KNG-73) (default destination per type),
[KNG-75](https://linear.app/kngpandi/issue/KNG-75) (walk legs at both ends), [KNG-36](https://linear.app/kngpandi/issue/KNG-36)
(NPC pathfinding). A Linear issue for this proposal is still to be made.

This proposal has three parts:
- **Part A:** a routing view that cuts edges where access changes.
- **Part B:** entrance points for structures.
- **Part C:** a per-type setting for which access rules apply to roads.

Part A fixes a structural weakness. Parts B and C prepare for houses, shops, taverns and production structures.

## 1. Why

### 1.1 The navigator reasons about whole edges

An edge is the stretch of road between two nodes, often 30-60 blocks long. Gates and domain regions are **tags on an
edge** (`GateDoorIds`, `RegionIds`), without a position. Every access verdict (`GateAvailability`,
`DomainAvailability`, `AccessPolicy.check`) is therefore for the whole edge. The live test hit this four times, and
each time it was patched by working out the position again afterwards:

| Finding | Symptom | Patch (knk-plugin `main`) |
|---|---|---|
| N6 | Standing on the road of a closed gate gave an instant "arrived"; the way back was not found | `RouteRequest.StartSides`: each half of the start edge is re-tagged from the world and checked on its own |
| N10 | A gate closing behind the player blocked the route | the re-check checks only the part of a step still ahead (`PolicyFactory.partOpen`) |
| N10 (run 7) | The part check got the whole edge's cached verdict | `AccessPolicy.checkPart` bypasses the per-id cache |
| N14 | A destination on the open side of a closed gate was unreachable | `RouteRequest.GoalSides`, the mirror of the start sides |

Two consequences of the same weakness are **still open**:
- **"Guiding you to the gate" stops at the node *before* the gate's edge, not at the gate**
  (`BlockedExplainer`, Phase 2d decision). On edge 10139 (the South Gate road) the bridge-side node is about 34 blocks
  from the door.
- **A road that clips a no-entry region anywhere is unusable along its whole length**, including the stretches
  outside the region.

Every future feature that touches edges would need the same reconstruction:
- tolls at a gate;
- siege gate rules;
- conditional entry (title, balance, clan; vision §2.2);
- NPC movement (KNG-36).

### 1.2 New destinations along roads

Houses, shops, taverns and production structures are coming. Each is a destination along a street, has a WorldGuard
region, and should be navigable to its **front door** (or very close to it). Two questions follow:
1. Does every such region cut the street into pieces? (§2.3: no.)
2. What does a private house's "no entry" mean for the public street in front of it? (§4: nothing.)

## 2. Part A — a routing view cut where access changes

### 2.1 The idea

Navigation routes on a **routing view** of the network rather than on the stored edges. In the view, every edge is
cut at the positions where an *access-relevant* tag starts or stops:
- **a gate door crossing:** the door becomes its own short piece of a few blocks, between two new nodes;
- **the border of an access-relevant region** (§4): the stretch inside the region becomes its own piece.

Each piece keeps its stored edge's id as `parentEdgeId`, plus its along-range on that edge. Its own synthetic id is
outside the stored id range. It also inherits the stored edge's profile, street, flags and cost, scaled to its length.

The stored graph does not change: no builder version bump, no proposals on curated tiles, no API or database change.
The view is built from the world at runtime, which keeps it current when a district or a gate is added (findings
N3/N4).

### 2.2 Where it is built

It is built in `LiveEdgeTags` (knk-paper `roads/`, findings N3/N4), which already samples every edge for regions
(every 2 blocks) and gate-door cells (every half block). It runs when a world's network changes and every minute, within
a lookup budget per tick. Today it collects *sets* of tags per edge. It would record *where* along the edge each tag
starts and stops, then cut there:
- **`core/roads/build/EdgeTagging`:** returns tag intervals (`[alongFrom, alongTo] → regionId | doorId`) instead of
  sets.
- **New `core/roads/route/RoutingView`:** builds the cut snapshot from a stored snapshot and the intervals. Between
  two pieces sits a new node with kind `Split` (not a destination, no name). The snapshot builder already copies
  nodes, edges, profiles and streets (`RoadNetworkSnapshot.retag`).
- **Navigation reads the view.** `NavigationService` already receives its snapshots through `LiveEdgeTags::snapshot`.
  The admin side (`/knk road …`, overlay, builder) keeps the stored snapshot.

### 2.3 Size

Cuts happen only at access-relevant changes (§4): gate doors, and borders of towns, districts and walled
structures with an access rule. On Cinix today that is 4 gates and a few district borders, so tens of extra nodes.
On a full server it would be hundreds. The router is designed for ~15 000 nodes (DESIGN §6.2), so this is
negligible. Houses, shops and taverns add **no cuts** (§3, §4).

If a large map ever needs far more cuts, the same intervals can stay on the edge ("blocked between along 12 and 15")
and be cut only when a route touches the edge, at search time. Start with plain cuts: they are simpler, and the router
stays whole-edge.

### 2.4 What it fixes and what it removes

**Fixes, by construction:**
- start, destination and re-check on a gated edge;
- the gate behind the player;
- "Guiding you to the gate" ends at the door (the piece before the gate's piece ends there);
- a road clipping a district is blocked only inside the district.

**Removes:** the patches from §1.1. These are `RouteRequest.StartSides`, `RouteRequest.GoalSides`,
`PolicyFactory.startSides/goalSides/partOpen`, `AccessPolicy.checkPart` and the part logic in
`NavigationService.recheck`. On the view they are always true, so they can go in a second step, once the view is
live-tested.

**Stays:** walk paths, partial paths, the road fallback (N13) and the closest-point guidance (N14). They are
independent of edge granularity.

### 2.5 Mapping back

Route steps then reference pieces:
- `/knk road why`, `NavigationRerouteEvent` details and log lines show the stored `parentEdgeId` (with the along-range
  where useful).
- The overlay keeps drawing stored edges.
- `onGateChanged` finds the affected sessions by the door's piece, which is exact.

### 2.6 Risks

- **Synthetic ids:** they must never collide with stored ids. Use a negative range, or offset beyond the API's max
  id, and assert it in tests.
- **Swapping views mid-session:** a minute-later pass may cut differently, for example after a new district. Active
  sessions already re-route on `onNetworkChanged`, and the session keeps its snapshot until then.
- **Sampling accuracy:** cuts fall at sample positions (½ block for doors, 2 blocks for regions). Good enough for
  guidance; keep the 2-block region step, or refine near borders.

## 3. Part B — entrances: navigating to the front door

**A destination along a road needs no cut.** The router already treats the start and the destinations as temporary
nodes that split their edges, for one route (DESIGN §6.2). That is how a Location or a domain's spawn works today.
After the road, the walk path (KNG-51) covers the last metres.

What is missing is **data: where the front door is.**
- **API:** an optional `EntranceLocationId` on domains, or on structures only (§7, D2), next to `LocationId` (the
  spawn). The web app gets a field on the domain form; in game, `/knk domain entrance set` at the door.
- **Navigation:** a third destination mode next to `spawn` and `region`, `entrance`:
  - The router snaps the entrance to the road in front of it.
  - The walk path leads from there to the door. A player without access gets "No conventional path" for the last
    metres, not a blocked street (§4).
  - Without an entrance, it falls back to the spawn, then the region.
- **Default mode:** `entrance` would be the natural default for houses, shops, taverns and production structures.
  KNG-73 makes the default configurable per type, with per-domain overrides, so it only needs the new mode.

**Cost per destination: nothing in the network.** A thousand houses add a thousand catalogue entries (tab completion,
`NavigationDestinations`), but no nodes or edges. Each costs one temporary node, and only when someone navigates
there.

## 4. Part C — which access rules apply to roads

Today any domain region tagged on an edge takes part in routing. With houses and shops along streets, a private house
(entry denied) whose region overlaps the street or the pavement would close that stretch of public street for everyone.
With Part A it would close only the overlapping metres, but that is still the street.

**Proposal:** a per-domain-type setting, **"its access rule applies to road routing"**:

| Type | Applies to roads | Why |
|---|---|---|
| Town, District | yes | borders cross roads; "no entry" means the road stops at the border |
| GateStructure | yes | the gate is the road |
| Structure (walled, e.g. a keep) | yes, default | its region usually contains its own paths |
| House, Shop, Tavern, ProductionStructure | **no**, default | the street in front is public; the rule applies at the door, through the walk path |

The rule still applies everywhere it does today: at the border (WorldGuard, KNG-56), for teleports, and for walk
paths (`WorldGuardWalkAccess`). Only the *road router* ignores the domain for types where it is off. In Part A, these
regions also cause no cuts. A per-domain override (like KNG-73's) handles exceptions, such as a fortified mansion
whose region does span a private road.

**Where it lives:** next to KNG-73's per-type navigation settings (API `DomainNavigationDefault`, web-app
`DomainNavigationDefaultsCard`, being built in a separate cloud session on `claude/kng-73-road-navigation-n92vlm`).
It would be one more column, and one more field in the domain DTO the plugin reads. `DomainAvailability` and
`LiveEdgeTags` skip regions whose domain has it off.

## 5. Order and effort

1. **Part C first**, before houses and shops exist. It is small (one setting, one filter in `DomainAvailability` and
   in the cut logic) and fits into KNG-73's settings. Default values per the table above.
2. **Part A** on the standing branch:
   - `EdgeTagging` intervals, `RoutingView`, `LiveEdgeTags` building the view;
   - router and explainer tests on cut networks; mapping back (§2.5);
   - live re-test of A7, A8, C3-C5 and the gate/region cases of the 2026-10-07/09 run;
   - then remove the patches (§2.4) in a separate commit.
   This is a medium change in knk-core plus `LiveEdgeTags`. No API or web-app change.
3. **Part B** when the first house/shop/tavern types exist: `EntranceLocationId` (API, migration with the developer's
   go-ahead), the web-app field, `/knk domain entrance set`, the `entrance` mode, and KNG-73's default per type.

## 6. Tests

**Core:**
- cuts at gate doors and region borders: number, positions, inherited tags;
- routes on the view:
  - start or destination on either side of a closed gate;
  - a road clipping a denied district;
  - the partial route ending at the door;
- synthetic id range;
- mapping back to `parentEdgeId`.

**Paper:**
- `LiveEdgeTags` builds the view from a fake probe (intervals) and swaps it;
- `NavigationService` on the view: the N6/N10/N14 tests stay and must pass unchanged, then without the patches;
- `onGateChanged` by piece.

**Part C:** a house region over the street does not block it for the router, and the walk path still refuses the
door.

**Part B:** the `entrance` mode with and without an entrance; the fallback order.

## 7. Decisions for the developer

- **D1 — Part A at all, or keep the patches?** Recommended: Part A, then remove the patches.
- **D2 — entrances on all domains, or on structures only?** Recommended: structures (and their future subtypes);
  towns and districts keep spawn/region.
- **D3 — Part C defaults:** the table in §4. Should a plain Structure (keep, tower) default to "applies"?
- **D4 — where Part C's setting lives:** with KNG-73's per-type settings (recommended) or as a separate table.
- **D5 — region sampling step for cuts:** 2 blocks (as the live tags), or refine to 1 block near a border.
