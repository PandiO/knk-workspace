# Navigation destination engine — which places a player may navigate to

**Status:** **Decided 2026-11-18** (developer). Approved in the design refresh session: § 14.1–14.6 "yes"
(E14–E21 accepted as written). Decisions of 2026-10-22 are recorded in §1; the refresh of 2026-11-18 in § 1.1, § 2.1,
§ 3.2, § 5.1, § 10, § 13, § 14; E1–E13 unchanged.
**Last updated:** 2026-11-18 (P1 link: § 10.2 item 7, what was applied); 2026-11-18 (approved by the developer: status Decided, phase 4b filed as #747, tier labels applied,
§ 14 answered); refreshed 2026-11-18 (§ 2, § 5 and § 10 re-checked against knk-plugin `next` `1f414d08`; landmark
provider hook § 3.2; the October P1 code checked on `next` § 10.2; tiers, flag and links § 10; acceptance items § 13;
points for approval § 14; agent decisions E14–E21 in § 1.1); 2026-10-23 (E9–E13 recorded; KNG-234 merged to main
2026-10-23, so the engine's base is `main`)
**Issue:** [PandiO/knk-workspace#25](https://github.com/PandiO/knk-workspace/issues/25), phases
[#96](https://github.com/PandiO/knk-workspace/issues/96) (P1), [#103](https://github.com/PandiO/knk-workspace/issues/103) (P2),
[#69](https://github.com/PandiO/knk-workspace/issues/69) (P3), [#62](https://github.com/PandiO/knk-workspace/issues/62) (P4),
[#747](https://github.com/PandiO/knk-workspace/issues/747) (4b), [#55](https://github.com/PandiO/knk-workspace/issues/55) (P5). Smoke test:
[guides/navigation-destination-engine-smoke-test.md](../../guides/navigation-destination-engine-smoke-test.md) (draft).
Waiting on it: off-road navigation phase 5.1 landmarks ([#708](https://github.com/PandiO/knk-workspace/issues/708),
off-road decision O27).
**Linear:** [KNG-235](https://linear.app/kngpandi/issue/KNG-235) with phases [KNG-236](https://linear.app/kngpandi/issue/KNG-236) (P1), [KNG-237](https://linear.app/kngpandi/issue/KNG-237) (P2), [KNG-238](https://linear.app/kngpandi/issue/KNG-238) (P3), [KNG-239](https://linear.app/kngpandi/issue/KNG-239) (P4), [KNG-240](https://linear.app/kngpandi/issue/KNG-240) (P5).
**Builds on:** [navigation/DESIGN.md](../navigation/DESIGN.md) (`/navigate`, §6), [navigation-compass/DESIGN.md](../navigation-compass/DESIGN.md)
(§11: match scope, which this design generalises), [user-features/DESIGN.md](../user-features/DESIGN.md) §6.1 (owner/staff mode),
KNG-58 / KNG-123 (offline security store, no main-thread API waits), [navigation-offroad/DESIGN.md](../navigation-offroad/DESIGN.md)
§ 6 (landmarks plug in as a `LandmarkProvider`, O27).

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
| E10 | **Lobby/hub/after-match: empty with a reason by default** (today's behaviour). The hub scope may offer a small list when a hub provider has destinations that can actually be navigated to; today the hub world has **no road network**, so nothing is offered. No hub provider is built now; the scope keeps the extension point (§4.1). |
| E11 | **Other-world places** are hidden from tab completion but still resolve to today's "X is in another world" message. |
| E12 | **Defaults:** the bypass node is `knk.navigate.any` (not granted by default); a snapshot older than 14 days adds a "may be out of date" note (`navigation.destinations.stale-after-days`); **the domain search API is extended** with each domain's Location (§7.2). |
| E13 | **Implementation starts after the developer's review of this document**, on a new branch with its own Linear issue. |

### 1.1 Agent decisions of the refresh (2026-11-18, accepted by the developer the same day)

Taken by the design refresh session as reversible defaults; each lists its alternatives. None changes E1–E13. The
developer accepted all of them with the design on 2026-11-18 (§ 14.1–14.6: yes).

| # | Date | Who | Decision | Alternatives considered |
|---|---|---|---|---|
| E14 | 2026-11-18 | agent | **Reuse the October P1 code.** The P1 link takes knk-plugin `claude/navigation-destination-engine` (`ea368a8b`), merges `next` into it (one conflict, § 10.2), applies the refresh deltas of § 10.2 and finishes it. | (a) Restart from `next`: throws away about 1 900 lines and 60 tests that still compile and pass on `next`. (b) Cherry-pick onto a new branch: the same result as the merge, but loses the history and goes against "merge, never rebase". |
| E15 | 2026-11-18 | agent | **A scope's reason is a code plus a default text.** `Empty(code, text)`; each client may present its own wording for a code, so the compass keeps "The navigation compass works once the siege match has started." in the lobby while `/navigate` keeps "You can't navigate while you are in a siege." (§ 2.1 item 3). | (a) One text for every client: changes the compass's wording, which nobody decided. (b) Clients keep their own pre-checks: duplicates the rules the engine replaces. |
| E16 | 2026-11-18 | agent | **The engine is ready for landmarks from P1/P2** (§ 3.2): P1 gives `Place.Point` an optional arrival radius and documents the key form `landmark:<id>`; P2 reserves an empty `landmarks` section in the model and in snapshot schema 1. Off-road phase 5.1 (#708) builds `LandmarkProvider` and fills the section; no engine file changes there. | (a) #708 adds the place shape and a schema 2: another chain edits engine files and bumps the snapshot. (b) A landmark scope of its own: wrong, landmarks follow the World scope and are hidden by exclusive scopes (off-road § 6.1.3). |
| E17 | 2026-11-18 | agent | **P3 and P4 run behind `navigation.destination-engine` (default `false`).** Off, the plugin uses today's paths unchanged; on, the command, completion, compass and service use the engine. The old paths and the flag are removed in a new phase 4b after the developer's live test of P3 and P4 in `next` (§ 10). | (a) No flag, delete the old paths in P3 as § 10 first said: a `tier:3` switch-over of every navigation entry point unguarded in `next`, against global "Branches" rule 6. (b) Keep both paths for good: the rules stay duplicated and E3 never holds. |
| E18 | 2026-11-18 | agent | **Only model-backed lists are cached** by `(scope, world, modelVersion)`. Match lists are rebuilt per call: they hold a handful of entries and depend on the board and on gate states (#176, § 2.1 item 5). | (a) A board/gate version counter in the siege code to cache them: siege code changes for no measurable gain. |
| E19 | 2026-11-18 | agent | **Road-access answers move with the catalogue.** `roadAccessIgnored`, `roadsIgnoreRegion` and `onRoadAccessChanged` (today on `NavigationDestinations`, read by `NavigationAccess` and the road tags) are served from the model from P2 on (same data, same answers, now also after a restart with the API down); `NavigationDestinations` is deleted in phase 4b. | (a) Keep a slim `NavigationDestinations` for road access: the domain list would be fetched twice. |
| E20 | 2026-11-18 | agent | **Tiers** (§ 10): P1 `tier:2`, P2 `tier:2`, P3 `tier:3`, P4 `tier:3`, 4b `tier:2`, P5 `tier:2`. | (a) P1 `tier:3` as "new foundations": nothing is wired in P1, so a full manual check has nothing to check. (b) P2 `tier:3`: the API change is additive (no migration) and nothing reads the model before P3. |
| E21 | 2026-11-18 | agent | **#96's label:** `status:in-review` is wrong (nothing was merged or offered for test); the issue is backlog with no status label until the P1 link starts it (`status:in-progress`). | (a) Keep `status:in-review`: the digest would list it as waiting for a test that cannot run. |

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

### 2.1 Re-check against knk-plugin `next` (2026-11-18)

Checked against knk-plugin `next` `1f414d08` (2026-11-18). The list above was written on the compass branch on
2026-10-22; the October P1 branch's base `c7806b87` (2026-10-23 11:43) predates the compass merge (`2662dca4`, 14:36 the
same day), so none of the compass classes are in it. What still holds and what changed, dated corrections in the
style of off-road DESIGN § 3.5:

1. **Holds:** the catalogue (`paper/navigation/NavigationDestinations`, unchanged since `c7806b87`) is memory only,
   refreshed every 60 s and never awaited; `locate` of a domain calls `DomainLocationResolver` at click time; names
   resolve through `core/util/NamedTargets`. `CompassSettingsStore` is memory only too (60 s refresh, defaults until the
   first good read and after a restart with the API down). No navigation snapshot exists; `OfflineSecurityStore`
   holds identity, mode, freeze and permission answers only.
2. **Holds:** the match scope is enforced three times: `NavigationService.navigate` (via `Destination.sameAs`),
   `NavigateCommand.navigateInMatch` and `NavigateCommand.completeInMatch`. `NavigationCompassService` implements
   `MatchNavigationScope` and `SiegeMatchObserver` and builds its own lists (`Entry`, `siegeEntries`, `generalEntries`,
   the `Last` cursor). `NavigationEligibility` is wired with `siegeMembersOutsideMatch` (KnKPlugin): loading, frozen,
   and "lobby member without a running match". The 40-tick re-check ends sessions with `EndReason.SIEGE`;
   `lobbyChanged` ends them too, except while the lobby's phase is `IN_PROGRESS`. `SiegeCommandFilter` always allows
   `/navigate` and `/nav`.
3. **Correction (messages differ per client):** the same rule has different words in the command and the compass. In
   a lobby `/navigate` says "You can't navigate while you are in a siege." and the compass "The navigation compass
   works once the siege match has started."; with the compass off for sieges `/navigate` says "This match has no
   destinations to navigate to." and the compass "The navigation compass is switched off during sieges.". Outside a
   siege the compass's general list may be switched off ("The navigation compass has no destinations here.") while
   `/navigate` still works. Hence E15: reasons carry a code, clients keep their wording; and the compass's general
   switch is a compass setting, not a scope.
4. **Correction (§ 4.1, scope 55):** its text "Navigation is switched off in this siege." does not exist in the code;
   today's text is "This match has no destinations to navigate to." (`CompassMessages.noMatchDestinations`). The
   scope applies when the compass **item** is disabled or the compass is off for sieges
   (`destinationsOf`: `!item().enabled() || !siegeEnabled()`). A match member without a team gets an empty match list
   with the same text. § 4.1 is corrected; the October P1 code carries the wrong text (§ 10.2).
5. **New since 2026-10-22: gate approaches** (#176, `SiegeGateApproaches`): for an objective to capture behind a closed
   gate of the player's own alliance, the compass leads to the gate, not the capture point. A siege candidate's place
   therefore depends on live gate state: it is built when the list is built (as today), its key stays `objective:<id>`,
   and match lists are not cached (E18).
6. **Not in § 2 before: the catalogue also serves the route layer.** `NavigationDestinations.roadAccessIgnored`,
   `roadsIgnoreRegion` and `onRoadAccessChanged` (rev. 7 Part C, KNG-92) feed `NavigationAccess`'s road rule and the
   road tags (KnKPlugin). The catalogue cannot simply be deleted in P3; the answers move to the model (E19).
7. **Compass resume:** a shift-click `RESUME` re-navigates to the `Destination` stored in `Last`. Under the engine the
   compass stores the candidate key and resolves it again through the list (a resumed destination may have left it).
8. **`NavigationService` grew about 630 lines** since `c7806b87`, none of it about which destinations exist: off-road
   L1 walk counters (#703), L3 shaping on the walk thread and L4 cursor and winding back (#710, #711, both behind
   `navigation.guidance-v2`), the plaza-line preview (#712), NPC hooks (`planRoadFor`, `plazaCrossingsOf`,
   `accessRules`, `addRuleChangeListener`; #360 `PlayerAccessSubject`). They touch `navigate`'s body and the session
   tick, which P3 and P4 change: a merge-conflict risk, handled by "at most one link on navigation code at a time"
   (charter). NPC navigation has its own service and is outside this engine; the handle governs player navigation only.
9. **New since 2026-10-22: realtime domain changes** reach NPC navigation (`NavigationDomainChanges`, #533/#593;
   `DomainCacheRewarm`, #506/#724). The model refresh of P2 may listen to the same `EntityChanged` events for towns,
   districts and structures to refresh sooner than 60 s (optional, P2's choice).
10. **Permission answers offline:** `OfflineSecurityStore.forgetPermissionAnswers` (#179) drops a user's remembered
    answers after a realtime permission change; during an outage an unknown answer for `knk.navigate.any` counts as
    not granted, so the bypass falls back to the normal scopes (safe default).
11. **Callers of `navigate(Player, Destination)`** on `next`: `NavigateCommand` (two), `NavigationCompassService` (two:
    `go` and `RESUME`). `/knk road why` uses `explain`, which stays the unrestricted diagnostic path (§ 6).

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
  resolved through the catalogue). Accepted from outside the engine: `LandmarkProvider` (off-road #708, § 3.2).
  Planned: arena duels (KNG-197), home, party member, quest.
- **`Scope`** (the policy) — `id`, `priority`, `applies(ctx)`, and what it yields: either `providers + filters +
  ordering`, or `Empty(reason)`; plus `exclusive` (always, per E2: the highest-priority applicable scope wins). A
  scope may also set the **display name** of its list ("this match", "the world").
- **Reason** (E15) — why a list is empty: a stable `code` (`loading`, `frozen`, `no-permission`, `siege-compass-off`,
  `siege-lobby`) and a default text (today's `/navigate` wording). A client may show its own wording for a code (the
  compass does).
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

### 3.2 Landmark provider (off-road O27, added 2026-11-18)

Landmarks (off-road DESIGN § 6) plug into the engine as a provider from the start; they are never added to the old
`NavigationDestinations` catalogue. What the engine guarantees, and which phase carries it:

1. **A provider of the World scope** (P1). `InitialScopes.create` takes the World scope's providers as a list; the
   landmark provider is one more entry, registered by the plugin when `navigation.landmarks` is on. The Bypass scope
   lists all world providers, so owner/staff mode and `knk.navigate.any` see landmarks too (E5, E6).
2. **Candidate** (P1 documents it, #708 builds it): key `landmark:<id>` (the landmark's id, stable across renames),
   label = the landmark's name, type word `landmark`, id for `landmark:#<id>`, detail `in <domain>` when linked to a
   domain (null otherwise), source `landmarks`. Landmarks with `NavigationEnabled = false` are not offered.
3. **Place** (P1, E16): a point with an optional arrival radius (`ExtentKind.Radius`), or a region
   (`ExtentKind.Region`, the existing `Place.Region`); `None` is a plain point arrived at within `arrive-distance`.
4. **Other worlds (E11)** (P1): the candidate's place carries the landmark's world; the engine lists it apart, so it
   is hidden from tab completion but resolves to the "X is in another world" message.
5. **Exclusive scopes hide them (E2)** (P1): a running siege match (scopes 60/55), the lobby (50), loading, frozen and
   no permission list nothing from the World scope.
6. **Offline (E1)** (P2): the model and snapshot schema 1 carry a `landmarks` section, empty until #708 fills it from
   `api/landmarks`; the landmark provider reads the model, never the API at click time.
7. **Reachable from `/navigate`, completion and the compass** (P3): only through the engine, so with
   `navigation.destination-engine` off no landmark is offered anywhere (off-road § 6.5.3: never through two paths).

The off-road chain's landmark link (L8, #708) therefore waits for P1, P2 and P3 merged into `next`.

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
| 55 | Siege match, compass off | member of a running match, compass item disabled or compass off for sieges (§ 2.1 item 4, corrected 2026-11-18) | `Empty("This match has no destinations to navigate to.")` (today's text; the compass says "The navigation compass is switched off during sieges.", E15) |
| 50 | Siege lobby/hub/after-match | member of a siege lobby, no running match | `Empty("You can't navigate while you are in a siege.")` (the compass: "…works once the siege match has started.", E15); **if a hub provider has navigable destinations** (E10) a small hub list instead — none today (no road network in the hub world) |
| 10 | World (default) | always | `CatalogueProvider` for the player's world, plus `LandmarkProvider` when `navigation.landmarks` is on (§ 3.2) |

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
| `NavigationDestinations.roadAccessIgnored/roadsIgnoreRegion/onRoadAccessChanged` (road rule of `NavigationAccess`, road tags) | served from the model (E19, P2), same answers; the class is deleted in phase 4b |
| `MatchNavigationScope`, `NavigateCommand.navigateInMatch`, `completeInMatch`, `Destination.sameAs` | removed in phase 4b; the siege scope + engine (P3, behind the flag) |
| `NavigationCompassService` list building (`Entry`, `siegeEntries`, `siegeDestinations`, `generalEntries`, `destinationsOf`) | compass = a client: asks the engine for the list, keeps the cursor (`Last`, now a candidate key), the item rule, the granting (`memberReadiedAtHub`), the click cooldown and its own wording per reason code (E15) |
| `SiegeCompassTargets` + `SiegeGateApproaches` (#176) | `SiegeMatchProvider`: the same order, the gate approach applied when the list is built (E18) |
| `NavigationEligibility`, `lobbyChanged` ending sessions, `EndReason.SIEGE` | scopes (§4.1) + `revalidate` (§8) |
| `SiegeCommandFilter` always allowing `/navigate` | stays (the command is safe in a match because the engine limits it) |
| `CompassSettingsStore` (memory only) | read from the model, persisted in the snapshot (P2) |

### 5.1 Corrections of 2026-11-18

1. Rows added for the road-access answers (§ 2.1 item 6), the gate approaches (§ 2.1 item 5) and the compass
   settings store; the compass row names `siegeDestinations`, `destinationsOf` and the `Last` cursor (§ 2.1 items 2, 7).
2. "Removed" now happens in phase 4b, after the developer's live test with the flag on (E17); until then P3 and P4 add
   the engine path next to today's code.

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
  the place is resolved by `DomainLocationResolver` (N lookups). **Decided (E12):** the API's domain search DTO
  (`DomainListDto`) is extended with the domain's Location, so one paged search fills the snapshot (no N+1); until the API change
  is live, a paced background resolver fills in places (a few per second) and the snapshot is saved when complete.
- **Locations** — id, name, coordinates, world (the `/navigate location:` targets).
- **Compass settings** — the item rule, switches and general targets (small).
- **Road-access answers** — per domain the `roadAccess` flag and region id that the route layer reads today from
  `NavigationDestinations` (E19, added 2026-11-18).
- **Landmarks** — an empty section in schema 1, filled by off-road phase 5.1 (#708): id, name, world, point, extent,
  domain id and name, `NavigationEnabled` (E16, § 3.2, added 2026-11-18).
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
in `config.yml`), and the bypass node. Added 2026-11-18 (E17): `navigation.destination-engine` (default `false`) switches
the command, completion, compass and service to the engine in P3/P4; removed in phase 4b. Both keys need deploy notes
in the links that add them. Adding a minigame = one `Provider` + one `Scope` + registering them; no change
to the command, the compass or the service. Web-app-editable policies (e.g. per-lobby extra destinations) can be added
later by letting a `Scope` read admin-defined rows.

## 10. Plan (phases, tiers, flag; refreshed 2026-11-18)

Behaviour is unchanged until P3, and from P3 on only with `navigation.destination-engine: true` (E17). Each phase merges
into `next` on its own. One knk-plugin link touching navigation code at a time (§ 2.1 item 8; charter
[DESTINATION_ENGINE_CHAIN.md](../../ai-agents/handoffs/DESTINATION_ENGINE_CHAIN.md)). Tiers as approved 2026-11-18
(E20) and set as labels on the sub-issues.

| Phase | Content | Acceptance (§ 13) | Repos | Tier | Flag | Sub-issue | Depends on |
|---|---|---|---|---|---|---|---|
| 1 | Pure engine in `knk-core`: `Candidate`, `Provider`, `Scope`, `NavigationContext`, `DestinationList`, `AllowedDestination`, generalised `NamedTargets`, scope table, `revalidate`. Reuses the October code (E14) with the deltas of § 10.2 | A01–A09 | knk-plugin | tier:2 | none (nothing is wired) | [#96](https://github.com/PandiO/knk-workspace/issues/96) | none |
| 2 | Model + snapshot: `NavigationModel` (domain places, Locations, compass settings, road-access answers E19, empty `landmarks` section E16), snapshot reader/writer, background refresh, bulk domain places (API DTO extension § 10.3 + paced fallback), `degraded`, staleness note | A10–A15 | knk-web-api, knk-plugin | tier:2 | none (nothing reads the model before P3; the snapshot file is written) | [#103](https://github.com/PandiO/knk-workspace/issues/103) | P1 for the engine types; the model itself can start in parallel |
| 3 | Adapters and switch-over behind the flag: `NavigateCommand`, tab completion, compass and `NavigationService` on the handle; `CatalogueProvider`, `SiegeMatchProvider`, `CompassTargetsProvider`; architecture test on the new entry; road access from the model | A16–A21 | knk-plugin | tier:3 | `navigation.destination-engine` (off) | [#69](https://github.com/PandiO/knk-workspace/issues/69) | P1, P2 |
| 4 | Hard blocks into scopes; live re-validation (`EndReason.DESTINATION_NOT_ALLOWED`, immediate triggers), all behind the flag | A22–A26 | knk-plugin | tier:3 | `navigation.destination-engine` (off) | [#62](https://github.com/PandiO/knk-workspace/issues/62) | P3 |
| 4b | Removal: delete `MatchNavigationScope`, `navigateInMatch`, `completeInMatch`, `Destination.sameAs`, the compass list building, `NavigationEligibility`, `EndReason.SIEGE`, `NavigationDestinations`; the handle becomes the only `navigate` entry (E3); the flag is removed | A27–A28 | knk-plugin | tier:2 | removes the flag | [#747](https://github.com/PandiO/knk-workspace/issues/747) | P4, and the developer's live test of P3 and P4 in `next` with the flag on |
| 5 | Arena duels provider+scope (when that branch lands; timing not confirmed by the developer); optional hub list (E10) | A29 | knk-plugin | tier:2 | none (on the engine) | [#55](https://github.com/PandiO/knk-workspace/issues/55) | 4b and the arena duels work (KNG-197) |

Order: P1, then P2, then P3, P4, 4b; P5 when arena duels lands. The off-road landmark link (#708) may start once P1,
P2 and P3 are merged into `next` (§ 3.2); it never runs at the same time as P3, P4 or 4b (they share navigation code).
Estimated: phases 1–2 are the bulk (a pure core plus the snapshot); 3–4 are mostly wiring; 4b is deletion.

### 10.1 Corrections of 2026-11-18

1. Sub-issues, tiers, flag and acceptance ids added; Linear ids stay in the header's history only.
2. P3's "delete the duplicate paths" moved to the new phase 4b, and P3/P4 run behind `navigation.destination-engine`
   (E17), so `next` keeps today's behaviour until the developer has tested the engine live.
3. P2 also carries the compass settings (§ 2.1 item 1), the road-access answers (E19) and the empty `landmarks`
   section (E16).
4. P5 depends on 4b (its scope plugs into the engine once the engine is the only path).

### 10.2 The October P1 code (checked 2026-11-18)

knk-plugin branch `claude/navigation-destination-engine`, head `ea368a8b` (2026-10-23), base `c7806b87`, 366 commits
behind `next` `1f414d08`; 15 new files, 1 932 lines, additions only (8 classes in
`core/navigation/destinations`, 6 test classes and a fixture, and the handle rule in `ArchitectureGuardTest`).

1. **Merge check** (throwaway worktree, nothing pushed): `git merge origin/next` has one conflict, in
   `ArchitectureGuardTest`: `next` added `sharedShapingPackageDoesNotUseNpcPackages` (off-road #704) where the branch
   added `onlyTheDestinationEngineConstructsAllowedDestination`; both tests are kept, nothing else conflicts.
2. **Build and tests** on the merge: `./gradlew :knk-core:test` (Gradle on JDK 21, JDK 25 toolchain) passed: 3 195
   knk-core tests, 0 failures, 0 skipped; 60 of them are the engine's tests and the architecture guard. knk-paper is
   untouched by the branch.
3. **Matches the design:** the scope table with priorities 110/110/100/80/60/55/50/10 and freeze above the bypass
   (E9); exclusive scopes (E2); a hub extension point (`Listed.reasonWhenEmpty`, E10); the bypass by mode or node (E5,
   E6, `knk.navigate.any`); the handle with a package-private constructor guarded across all modules (E3); other-world
   candidates listed apart (E11); `NamedTargets` over `Candidate`; revalidation by key (E4); providers that throw are
   skipped (§ 7.4).
4. **Deltas the P1 link applies:**
    1. `Scope.Empty` carries a reason code and a default text (E15); `InitialScopes` defines the codes.
    2. `COMPASS_OFF_REASON` becomes today's "This match has no destinations to navigate to." (§ 2.1 item 4), and the
       siege match context gets "compass item disabled" next to "compass off for sieges" (or one `compassEnabled`
       built from both by the adapter in P3; the link chooses and says so).
    3. `Place.Point` gains an optional arrival radius; the `landmark:<id>` key form is documented with a test of a
       landmark-like provider in the World scope: listed, hidden in a match, listed for the bypass, other world
       resolved apart (§ 3.2, E16).
    4. The list cache of § 11 is only for model-backed scopes (E18), if the link adds a cache at all.
5. **Verdict:** reuse (E14). The P1 link merges `next` into the branch, resolves the conflict as in item 1, applies
   item 4 and opens the pull request into `next`.
6. **#96's label:** remove `status:in-review` (nothing was merged); the P1 link sets `status:in-progress` (E21).
7. **Applied by the P1 link (#96, 2026-11-18)**, for the adapters of P3 and P4: `Reason(code, text)` in the engine
   package; `InitialScopes` codes `loading`, `frozen`, `no-permission`, `siege-compass-off` (scope 55),
   `siege-match-empty` (scope 60 with nothing listed: a member without a team, a board without objectives; today's
   same text) and `siege-lobby`; the engine's own `no-longer-listed` when a running session's key dropped out of a list.
   The siege context keeps one `compassEnabled`, which the P3 adapter builds as `item().enabled() && siegeEnabled()`.
   `Place.Point` has a nullable `arrivalRadius` (positive, finite). No list cache in P1 (E18).

### 10.3 E12: what the domain search returns today (knk-web-api `next` `8ec54e1`, checked 2026-11-18)

1. `POST api/Domains/search` (`DomainsController.Search`, `PagedQueryDto`, default page size 10) returns
   `PagedResultDto<DomainListDto>`. Writes and the search need `knk.admin.world` or the game server's key (closed-alpha
   WP1.3); the plugin has the key.
2. `DomainListDto` has `id`, `name`, `description`, `wgRegionId`, `worldName` (KNG-111), `parentDomainId`,
   `parentDomain`, `domainType`, `navigationDefault` (KNG-73), `roadAccess` (KNG-92). **No Location.**
3. `Domain` (TPT base of Town, District, Structure, gate structures) has `LocationId` and `Location`, so all types
   share one join; `DomainRepository.SearchAsync` loads no navigation property today.
4. **P2 adds:** a nullable `location` on `DomainListDto` (`LocationDto`: id, name, x, y, z, yaw, pitch, world) mapped in
   `DomainMappingProfile`, and `.Include(d => d.Location)` in `SearchAsync`. Additive, no migration, older clients
   ignore the field; tests for a domain with and without a Location. The plugin pages through the search with a large
   page size (`SearchAsync` takes the page size as given; the link checks the service layer and sets a cap if needed).

## 11. Risks and details to settle in implementation

- **Key stability:** candidate keys must survive renames (use ids, not names); matches use ids already.
- **Tab-completion cost:** completion runs per keystroke; model-backed lists are cached per `(scope, world,
  modelVersion)` and are immutable, so completion is a filter over an array. Match lists are small and rebuilt per
  call (E18).
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

### 12.1 Platform-specific parts

1. Pure, Bukkit-free (`knk-core`, `core/navigation/destinations`): the engine, scopes, providers' candidate building,
   the model and the snapshot format, the reasons.
2. `knk-paper` adapters: building `NavigationContext` from the player (world, mode, freeze, permissions, siege
   membership), the snapshot file under `plugins/KnK/offline/`, `NavigateCommand`, the compass, `NavigationService`'s
   handle entry, and turning a `Place` into a routable `Destination`.

## 13. Acceptance checklist (added 2026-11-18)

Each item is checked by a test or a smoke step (guide: [navigation-destination-engine-smoke-test.md](../../guides/navigation-destination-engine-smoke-test.md)).

1. A01: the first applicable scope by priority decides the whole list; lower scopes are not consulted (E2).
2. A02: loading and frozen yield an empty list with today's text, also in owner/staff mode and with `knk.navigate.any` (E9).
3. A03: owner mode, staff mode and `knk.navigate.any` list every world provider and the match provider (E5, E6).
4. A04: without `knk.navigate` the list is empty with "You don't have permission to use /navigate.".
5. A05: a running match lists only the match's objectives and team spawn in the compass's order; with the compass item or its siege switch off the list is empty with "This match has no destinations to navigate to." (§ 2.1 item 4).
6. A06: a lobby member without a running match gets an empty list with "You can't navigate while you are in a siege."; a hub provider with destinations would list them (E10).
7. A07: `type:name`, `type:#id`, ambiguity choices and suggestions work in every scope, in a match too.
8. A08: a place in another world is not completed but resolves to "X is in another world" (E11).
9. A09: only the engine package constructs `AllowedDestination` (architecture test, E3); revalidation finds a candidate by key after re-ordering and refuses with the scope's reason (E4); a landmark-like provider in the World scope is listed, hidden in a match, listed for the bypass (§ 3.2).
10. A10: the domain search returns each domain's Location (null when it has none); existing fields unchanged (E12).
11. A11: the model is saved to `plugins/KnK/offline/navigation-model.json` after a successful refresh that changed it, atomically, off the main thread; it holds no player data.
12. A12: after a restart with the API down the same domains, Locations and compass settings are available as before the restart (E1).
13. A13: a corrupt or newer-schema snapshot is ignored with a log line, never fatal; with no snapshot and the API down the list is limited with "Some places aren't available while the web API is down." (§ 7.4).
14. A14: a refresh replaces the model: a renamed or deleted domain is renamed or gone after it.
15. A15: a snapshot older than `navigation.destinations.stale-after-days` (14) adds the "may be out of date" note (E12).
16. A16: with `navigation.destination-engine: false` `/navigate`, completion and the compass behave exactly as before P3.
17. A17: with the flag on, `/navigate <town>`, `/navigate street:…`, `spawn`/`region` words and tab completion behave as today outside a match, and `locate` makes no API call at click time.
18. A18: with the flag on, in a running match `/navigate`, completion and the compass offer only the match's destinations, now with `type:name` too (§ 3.1), and the gate approach of #176 still applies.
19. A19: with the flag on, the compass cycles the engine's list, keeps its own wording per reason code (E15), and a resume re-resolves the stored key.
20. A20: with the flag on, `NavigationService` starts a session only from a handle; `/knk road why` still works through `explain`.
21. A21: road-access answers come from the model and match today's (E19), also after a restart with the API down.
22. A22: with the flag on, loading, frozen, permission and lobby refusals come from the scopes with unchanged texts.
23. A23: a running session whose destination leaves the list ends with the scope's reason (`DESTINATION_NOT_ALLOWED`).
24. A24: immediate re-checks on objective captured, match ended, lobby changed, round released, mode change, freeze change and model refresh.
25. A25: an objective that changes kind but stays listed does not end the session; switching owner/staff mode on or off lifts or applies the bypass at once; freeze ends a staff session (E9).
26. A26: with the flag on `EndReason.SIEGE` is never used.
27. A27: after 4b the removed classes and the flag are gone, the handle is the only `navigate` entry, and the architecture test guards it.
28. A28: after 4b every A16–A26 behaviour holds without a flag.
29. A29: an arena duel restricts navigation through its own provider and scope without changes to the command, the compass or the service.

## 14. Points for approval (2026-11-18) — all approved

The design had no open questions after E13; the refresh added these, each with the default the documents use.
**Answered 2026-11-18 by the developer: "14.1–14.6: yes, approved".** Open questions left: none.

1. Approve the design as refreshed (status becomes **Decided**). Recommendation: approve.
2. Reuse the October P1 code (E14) rather than restart. Recommendation: reuse.
3. Run P3 and P4 behind `navigation.destination-engine` (off) and file phase 4b (removal) as a new sub-issue of #25
   (E17). Recommendation: yes. Alternative: no flag, delete in P3 (as § 10 said before).
4. Tiers (E20): P1 #96 `tier:2`, P2 #103 `tier:2`, P3 #69 `tier:3`, P4 #62 `tier:3`, 4b `tier:2`, P5 #55 `tier:2`.
   Recommendation: as proposed.
5. Reason codes with per-client wording (E15), landmark readiness in P1/P2 (E16), match lists uncached (E18), road
   access from the model (E19). Recommendation: accept.
6. Remove `status:in-review` from #96 (E21). Recommendation: yes.

Done on approval: status Decided; phase 4b filed as #747 (`tier:2`); labels #96 `tier:2` (status label removed),
#103 `tier:2`, #69 `tier:3`, #62 `tier:3`, #55 `tier:2`.

## Linear

Filed 2026-10-22: KNG-235 (the engine) and one child per phase of §10: KNG-236 (P1), KNG-237 (P2), KNG-238 (P3), KNG-239 (P4), KNG-240 (P5). Start prompt for P1 alone: `docs/ai-agents/handoffs/2026-10-22-destination-engine-p1-start.md`; coordinator prompt that delegates all phases: `docs/ai-agents/handoffs/2026-10-22-destination-engine-coordinator.md`.
