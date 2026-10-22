# Navigation destination engine — which places a player may navigate to

**Status:** Proposed — design for the developer's review. **No code.** Decisions of 2026-10-22 are recorded in §1.
**Last updated:** 2026-10-22 (E9: frozen above the bypass)
**Linear:** not filed yet (the Linear connector was unavailable in the session that wrote this) — see "To file in Linear" at the end.
**Builds on:** [navigation/DESIGN.md](../navigation/DESIGN.md) (`/navigate`, §6), [navigation-compass/DESIGN.md](../navigation-compass/DESIGN.md)
(§11: match scope, which this design generalises), [user-features/DESIGN.md](../user-features/DESIGN.md) §6.1 (owner/staff mode),
KNG-58 / KNG-123 (offline security store, no main-thread API waits).

## 0. In one paragraph

Today `/navigate` has one world catalogue, a second hand-rolled list for siege matches, a third for the compass, and a
pile of hard blocks (loading, frozen, "in a siege lobby", the command filter). This design replaces them with **one
engine that builds, per player, the ordered list of destinations they may navigate to** from *providers* (catalogue,
siege match, configured compass targets, later arena/quests/home) under *policies* (exclusive scopes by priority). A
destination can only be navigated to if it came out of that list: the navigation service accepts only an
engine-issued handle. Hard blocks become policies that return an empty list **with a reason**. The engine reads from an
in-memory model that is **persisted to disk**, so it behaves the same with the web API down, including after a restart.

## 1. Decisions (developer, 2026-10-22)

| # | Decision |
|---|---|
| E1 | **Offline: full, via a persisted snapshot.** The catalogue, compass settings and the data the destinations need are written to disk whenever the API answers and loaded at start-up; the engine has no separate "offline mode". Limited mode only when no snapshot exists yet (§7.4). |
| E2 | **Layering: exclusive scopes by priority.** The highest-priority scope that applies decides the list and replaces lower ones (a match scope replaces the world catalogue; loading/frozen/lobby give an empty list with a reason). |
| E3 | **Type-level enforcement.** `NavigationService.navigate` accepts only an engine-issued handle, never a raw `Destination`; admin tools get an explicit, named bypass. |
| E4 | **Re-validate live sessions.** When the list changes (objective captured, match ended, player frozen, mode changed) the running session's destination is re-checked and ended with the policy's reason if it dropped out. Replaces `EndReason.SIEGE` and the eligibility predicate. |
| E5 | **Staff bypass is a policy**, not a special case: permission node (proposed `knk.navigate.any`). |
| E6 | **Owner mode and staff mode are exempt from these rules and conditions** as well (on top of E5). |
| E7 | **Code-defined policies first**; tuning values come from existing settings. Web-app-editable policies are a later step. |
| E8 | **Design document first, no code.** Implementation is a separate issue and branch (§10). |
| E9 | **Frozen sits above the bypass.** Freeze also applies to owner/staff mode and `knk.navigate.any` holders (only higher ranks can freeze, so the rank order gates it). |

## 2. What exists today (from the code, 2026-10-22)

- **The world catalogue** (`NavigationDestinations`): domain summaries and Locations from the API, refreshed in the
  background every 60 s, **memory only**; streets and named nodes come from the road-network snapshot of the player's
  world. Names resolve through `NamedTargets` (`type:name`, `type:#id`, ambiguity, suggestions, completion).
  `locate(target, mode, world)` turns a target into a `Destination`; for a *domain* it calls the API (town/district/
  structure → location) **at click time** (`DomainLocationResolver`, with the data-access caches as the only fallback).
- **Match scope** (`MatchNavigationScope`, added for KNG-234): one method returning `Optional<List>`; enforced three
  times — in `NavigationService.navigate` (via `Destination.sameAs`), in `NavigateCommand.navigateInMatch`, in
  `completeInMatch`. It bypasses `NamedTargets`, so `type:name` and the spawn/region words do not exist in a match.
- **Compass lists**: a third builder (`NavigationCompassService`: siege entries from `SiegeCompassTargets`, general
  entries resolved against the catalogue, its own cursor).
- **Hard blocks**: `NavigationEligibility` (loading, frozen, siege lobby member outside a running match), the 2-second
  re-check ending sessions with `EndReason.SIEGE`, `lobbyChanged`, the `knk.navigate` check in the command and the
  compass, `SiegeCommandFilter` always allowing `/navigate`.
- **Offline today**: `OfflineSecurityStore` (KNG-58/123) persists identity, **active mode**, freeze and permission
  answers; `RoadNetworkCache` keeps road tiles on disk, so streets/nodes survive a restart. The destination catalogue,
  the domain places (spawn Location, region id) and the compass settings do **not**: after a restart during an outage
  the catalogue is empty, `locate` of a domain fails with "not found", compass settings fall back to defaults. A running
  match keeps working (its config is in memory).
- Gate/domain **route access** (gates, entry rules) is a different layer (`AccessPolicy`) and stays as it is: it decides
  *how* a route runs, not *which destinations exist*.

## 3. Concepts

All pure Java in `knk-core` (`net.knightsandkings.knk.core.navigation.destinations`), Bukkit-free; Bukkit adapters in
`knk-paper`.

- **`NavigationContext`** — immutable snapshot of one player at evaluation time: UUID, world, `ActiveMode`, flags
  (`loading`, `frozen`), permission answers asked for (`knk.navigate`, `knk.navigate.any`), minigame facts (e.g. "in a
  running siege match, team T, scenario S"), and a `modelVersion`. Built on the main thread from offline-aware sources
  (§7.5). Cheap to build; never blocks.
- **`Candidate`** — one navigable thing: stable `key` (`domain:Town:12`, `objective:7`, `spawn:3`, `street:5`,
  `node:88`, `location:41`), `label`, `typeWord` + aliases (so `town:Kardenna`, `objective:Keep Gate` work), `detail`
  (e.g. "defend, under attack, 62% held"), `priority` (ordering inside the list), `source` (provider id), and a
  **synchronous** `place`: the data needed to build a `Destination` (point / region / street / node, with the modes a
  domain offers). No API call at click time.
- **`Provider`** — `candidates(ctx)` → list. Initial providers: `CatalogueProvider` (domains, locations, streets,
  nodes), `SiegeMatchProvider` (today's `SiegeCompassTargets`), `CompassTargetsProvider` (the configured lines,
  resolved through the catalogue). Planned: arena duels (KNG-197), home, party member, quest.
- **`Scope`** (the policy) — `id`, `priority`, `applies(ctx)`, and what it yields: either `providers + filters +
  ordering`, or `Empty(reason)`; plus `exclusive` (always, per E2: the highest-priority applicable scope wins). A
  scope may also set the **display name** of its list ("this match", "the world").
- **`DestinationList`** — the engine's answer: `scopeId`, ordered `candidates`, optional `reason` when empty, `degraded`
  flag + text (§7.4), `modelVersion`.
- **`AllowedDestination`** (handle) — what `navigate` accepts: player UUID, scope id, candidate key, the resolved
  `Destination`, `modelVersion`. Constructible only inside the engine package (§6).

### 3.1 Engine API

```
DestinationList  listFor(NavigationContext ctx)
Resolution       resolve(NavigationContext ctx, String typed, Mode mode)   // found / ambiguous / suggestions — inside the list only
List<String>     complete(NavigationContext ctx, List<String> words)       // inside the list only
Revalidation     revalidate(NavigationContext ctx, AllowedDestination h)   // still allowed? else: reason
```

`NamedTargets` is generalised over `Candidate` (it already takes extractor functions), so `type:name`, ids, ambiguity
choices, suggestions and completion behave the same in every scope — in a match as in the world.

## 4. Evaluation

1. Build the context. 2. Walk the scopes by descending priority; the first whose `applies(ctx)` is true decides.
3. Ask its providers for candidates, apply its filters, order them (scope ordering, then candidate `priority`, then
label). 4. Return the list. Pure and deterministic for a given context + model version, so it is trivially testable and
can be cached per `(scope, world, modelVersion)` for tab completion.

### 4.1 Initial scope table (highest priority first)

| Priority | Scope | Applies when | Yields |
|---|---|---|---|
| 110 | Account loading | account still loading (the mode is not known yet, so nothing can be exempt) | `Empty("Your account is still loading - try again in a moment.")` |
| 110 | **Frozen** | player frozen — **applies to owner/staff mode too** (E9) | `Empty("You can't navigate while frozen.")` |
| 100 | **Bypass** | `ActiveMode` is `OWNER` or `STAFF` (E6), or the player has `knk.navigate.any` (E5) | the full catalogue (all providers' union for the world), no further policy checked |
| 80 | No permission | lacks `knk.navigate` | `Empty("You don't have permission to use /navigate.")` |
| 60 | Siege match | member of a *running* siege match, compass enabled for sieges | `SiegeMatchProvider` (objectives by relevance, then the team spawn) |
| 55 | Siege match, compass off | member of a running match, compass off for sieges | `Empty("Navigation is switched off in this siege.")` |
| 50 | Siege lobby/hub/after-match | member of a siege lobby, no running match | `Empty("You can't navigate while you are in a siege.")` today; room to offer a hub list later (tunable) |
| 10 | World (default) | always | `CatalogueProvider` for the player's world |

Notes: the existing messages stay as the scope's reason, so players see the same texts. "Cycle list" of the compass
is the *same* list with the compass's own presentation (cursor, chat line); outside a siege the compass's configured
targets are a **filter/ordering of the World scope** (`CompassTargetsProvider`) rather than a second catalogue.
Freeze sits **above** the bypass (E9, developer, 2026-10-22): a freeze can only be placed by someone of higher rank, so it is
the one rule that also holds for owner/staff mode and `knk.navigate.any`.

### 4.2 What stays a hard block (not a destination question)

Feature disabled (`navigation.enabled`), no road network loaded for the world, the route layer (gate/domain access,
"no way out", walk limits). These keep their current messages. Everything else listed in §2 moves into scopes.

## 5. Replacing today's code

| Today | Becomes |
|---|---|
| `NavigationDestinations.resolve/complete/isComplete/locate` | `CatalogueProvider` + engine `resolve/complete`; `locate` loses its API call (§7) |
| `MatchNavigationScope`, `NavigateCommand.navigateInMatch`, `completeInMatch`, `Destination.sameAs` | removed; the siege scope + engine |
| `NavigationCompassService` list building (`Entry`, `siegeEntries`, `generalEntries`) | compass = a client: asks the engine for the list, keeps the cursor, the item rule, the granting |
| `NavigationEligibility`, `lobbyChanged` ending sessions, `EndReason.SIEGE` | scopes (§4.1) + `revalidate` (§8) |
| `SiegeCommandFilter` always allowing `/navigate` | stays (the command is safe in a match because the engine limits it) |

## 6. Enforcement: the handle

`NavigationService.navigate(Player, AllowedDestination)` is the only public entry. `AllowedDestination` has a
package-private constructor in the engine package; an architecture test in `ArchitectureGuardTest` fails the build if
anything else constructs it. Admin and diagnostic paths (`/knk road why`, `explain`) call a clearly named
`navigate…Unrestricted` / `explain` API that does not go through the list. The handle carries the `modelVersion` and
scope id, which `revalidate` uses (§8). Result: no menu, command or future feature can navigate somewhere the list
does not contain, without writing code that reads as a bypass.

## 7. Offline (E1)

### 7.1 Principle

There is **no offline branch** in the engine. It always reads one in-memory **model**, which is (a) loaded from a
snapshot file at start-up, (b) replaced atomically whenever the API refresh succeeds, and (c) re-saved after that.
An outage only means the model is not refreshed. This also removes the async API call from `locate` (click-time),
making compass/command resolution synchronous and consistent with KNG-123 (no main-thread waits on the API).

### 7.2 What the snapshot holds (`plugins/KnK/offline/navigation-model.json`, schema-versioned, atomic write like `OfflineSecurityStore`)

- **Domain places** — per domain: id, name, type, navigation default, road-access flag, WorldGuard region id, world,
  and the resolved spawn Location (x, y, z, yaw, pitch, world). Today's domain search does not carry the Location, so
  the place is resolved by `DomainLocationResolver` (N lookups). **Recommendation:** extend the API's domain search DTO
  (`DomainListDto`) with the domain's Location, so one paged search fills the snapshot (no N+1); until the API change
  is live, a paced background resolver fills in places (a few per second) and the snapshot is saved when complete.
- **Locations** — id, name, coordinates, world (the `/navigate location:` targets).
- **Compass settings** — the item rule, switches and general targets (small).
- Not stored: street/node data (already on disk in the road tile cache and loaded at start), siege objectives (derived
  from the running match, in memory), anything personal. The snapshot has no player data, so no erasure duty.

Size: hundreds of domains × ~200 B ≈ tens of KB; written off the main thread, only when the content changed.

### 7.3 Freshness

The snapshot carries `asOf`. A successful refresh **replaces** the model (so renames and deletions propagate). No hard
expiry for destinations (they are not security data); `/knk road` status shows the age, and a model older than a
configurable limit (default 14 days) puts a "may be out of date" note on the list's `degraded` text. A corrupt or
newer-schema file is ignored (logged), never fatal.

### 7.4 Degraded and limited modes

- **Full (snapshot present):** identical lists, `degraded=false` except the optional staleness note.
- **Limited (no snapshot ever written, API down):** the sources that never need the API — streets and named nodes
  (road cache), a running match, general targets that resolve from those — and `degraded=true` with the text "Some
  places aren't available while the web API is down." on `/navigate`, tab completion and the compass.
- **Per-source failure:** a provider that throws is logged and skipped; the rest of the list is still served.

### 7.5 Context inputs offline

Active mode, freeze and permission answers already come from the offline-aware services backed by
`OfflineSecurityStore` (KNG-58/123); the context builder uses those, not the API. Loading state is local. Siege
membership and the running match are in memory. Nothing in the context requires the API.

### 7.6 Out of scope here

Starting a *new* siege match needs the API (its runtime config) — a siege concern, unchanged. The route layer's
offline behaviour (domain lookups without main-thread waits) is KNG-123, unchanged.

## 8. Live re-validation (E4)

A running session stores its `AllowedDestination`. The existing 40-tick re-check calls `engine.revalidate(ctx, handle)`:
the engine re-lists for the player and looks the candidate **key** up in the current list (keys are stable across
re-ordering). Not found, or the player now falls into an `Empty` scope → the session ends with the scope's reason as
its message (a new `EndReason.DESTINATION_NOT_ALLOWED`; the reason text is the scope's). Immediate triggers (instead of
waiting for the tick): siege observer events (`objectiveCaptured`, `matchEnded`, `lobbyChanged`, `roundReleased`), mode
changes, freeze changes, model refresh. A candidate that changed *kind* but is still listed (an objective flips from
"capture" to "defend") does not end the session. An owner/staff-mode toggle lifts or applies the Bypass scope at once.

## 9. Tuning and configuration (E7)

Scopes are code. Their parameters come from existing settings: compass settings (`siegeEnabled`, `generalEnabled`,
`generalTargets`, item rule), siege configuration, the staleness limit (new `navigation.destinations.stale-after-days`
in `config.yml`), and the bypass node. Adding a minigame = one `Provider` + one `Scope` + registering them; no change
to the command, the compass or the service. Web-app-editable policies (e.g. per-lobby extra destinations) can be added
later by letting a `Scope` read admin-defined rows.

## 10. Plan (separate issue and branch, behaviour unchanged until phase 3)

| Phase | Content | Done when |
|---|---|---|
| 1 | Pure engine in `knk-core`: `Candidate`, `Provider`, `Scope`, `NavigationContext`, `DestinationList`, `AllowedDestination`, generalised `NamedTargets`, scope table, `revalidate` | unit tests for every scope, ordering, resolution in a match, owner/staff/permission bypass, empty-with-reason |
| 2 | Model + snapshot: `NavigationModel`, snapshot reader/writer, background refresh, bulk domain places (API DTO extension + paced fallback), `degraded` | tests: restart with API down serves the same list; corrupt/newer snapshot ignored; refresh replaces deleted entries |
| 3 | Adapters and switch-over: `NavigateCommand`, compass, `NavigationService` on the handle; delete the duplicate paths (§5); architecture test | `/navigate`, tab completion and compass behave as today outside a match and as KNG-234 §11 in a match |
| 4 | Hard blocks into scopes; live re-validation; remove `NavigationEligibility`/`EndReason.SIEGE` | frozen/loading/lobby messages unchanged; sessions end with the scope's reason |
| 5 | Arena duels provider+scope (when that branch lands); optional hub list | arena match restricts navigation without touching the engine |

Estimated: phases 1–2 are the bulk (a pure core plus the snapshot); 3–4 are mostly deletion and wiring.

## 11. Risks and details to settle in implementation

- **Key stability:** candidate keys must survive renames (use ids, not names); matches use ids already.
- **Tab-completion cost:** completion runs per keystroke; lists are cached per `(scope, world, modelVersion)` and are
  immutable, so completion is a filter over an array.
- **Thread model:** the model is an immutable object swapped through a `volatile`; context building and listing run on
  the main thread; refresh and snapshot writes run off it.
- **Domain places that move:** the snapshot can hold a place that was just edited; the next refresh corrects it, and
  region-based goals are unaffected by a moved spawn.
- **Worlds:** places carry their world; the World scope filters by the player's world as today (other-world places are
  listed with a note or hidden — keep today's "not in this world" message by hiding them from completion but resolving
  them to the existing message).

## 12. Test plan

Core: every scope's `applies`/yield, priority conflicts, ordering, resolution/ambiguity/suggestions per scope, bypass
(mode, node), empty-with-reason, revalidation by key, handle can only be minted by the engine (architecture test).
Snapshot: round-trip, atomic write, corrupt/newer file ignored, refresh replaces, restart without API. Adapters: the
command, completion and compass against a fake engine. **Live** (needs a server): API down at start-up (stop the API,
restart the server, `/navigate` a town and a street, run the compass in a match); owner/staff mode in a match; frozen →
list emptied and a running session ends with the reason; objective captured → compass updates and a session to a
now-dropped destination ends.

## To file in Linear

Open one issue "Navigation destination engine (providers, exclusive scopes, handle, offline snapshot)" as a feature,
related to KNG-27 / KNG-123 / KNG-234, linking this document; child issues per phase in §10. Filing was not possible in
the session that wrote this (Linear connector offline).
