# Domain AllowEntry/AllowExit bypassed by holding W — root cause and fix

**Status:** fixed and unit-tested on branch, not merged; live re-test pending (see "Verification")
**Last updated:** 2026-10-06 (later the same day: rider and `DomainAccessEvaluator` statements corrected; the follow-up analysis is [`2026-10-06-domain-access-enforcement-options.md`](2026-10-06-domain-access-enforcement-options.md), KNG-56)
**Linear:** [KNG-55](https://linear.app/kngpandi/issue/KNG-55)
**Branch:** knk-plugin `claude/worldguard-entry-deny-bypass-sj1j7g` at `9ab1f5d` (one commit on `main` `74607a9`); knk-workspace same branch (this report, tracker row, cross-link in `architecture/managed-worldguard-regions.md` §5)

## Report

On 2026-10-06 the developer saw a player in the **Noble** permission group get into a district whose **AllowEntry** is false. The player walked up to the WorldGuard region from outside. The first step over the border was blocked. While they kept holding **W**, the next steps went through and they were inside.

They also asked for **AllowExit** (the "may leave" flag) to be checked.

## Root cause

Domain entry and exit rules are enforced by knk-plugin, not by WorldGuard flags. `WorldGuardRegionListener` passes every `PlayerMoveEvent`/`PlayerTeleportEvent` to `WorldGuardRegionTracker.handleMove`. If the returned decision denies the move (and the player has no `knk.region.bypass`), the listener cancels the event.

`handleMove` (on `main` `74607a9`) worked like this:

1. `oldRegions` came from the tracker's own per-player set `regionsByPlayer`, and `newRegions` from the region ids at `to`.
2. `OnRegionEnterEvent`/`OnRegionLeaveEvent` fired straight away.
3. `regionsByPlayer.put(playerId, newRegions)` ran, and only then did
4. `transitionService.handleRegionTransition(...)` decide.

So the tracked set was already "inside" when the decision came back denied. Cancelling the event kept the player outside, but the tracker now believed the player was in the district. On the next move event (W still held), `oldRegions` (tracked: inside) equalled `newRegions` (inside). The tracker saw "no region change", returned `null`, and the listener allowed the move. Exactly one step was blocked and every step after it went through, which matches the report.

**AllowExit had the same defect**, mirrored. The first step out was cancelled, the tracked set was already "outside", and the second step out was allowed.

**The Noble group is not the cause.** A player with the bypass (`knk.region.bypass`) is never stopped, not even on the first step. Any player without it could reproduce this.

### Other holes in the same enforcement path

Reading the path for the fix turned up more ways past a denial. All are fixed on the branch:

| # | Hole | Effect |
|---|---|---|
| 1 | **Cold cache.** A crossing into a region whose domain isn't cached yet is allowed while the API is asked. Afterwards the move was re-validated only if the player's region set still exactly equalled the destination's. | Walking one region further (for example into a nested structure or plot region) before the lookup came back cancelled enforcement silently. |
| 2 | **Second player during a lookup.** A crossing whose region was already being fetched by another player's move was allowed with no re-validation scheduled. | Anyone crossing behind the first player stayed in. |
| 3 | **In-flight bookkeeping.** For a lookup of several regions, `inFlightLookups.put(lookupKey, …)` stored a combined key (`"a,b"`) that was never removed. A later lookup of the same set returned early: no fetch, no re-validation. A single-region lookup that finished before the `put` ran could also leave its id marked "in flight" forever. | After one API hiccup, a border involving those regions could be waved through for good. |
| 4 | **WorldGuard regions that no domain uses** were never cached. `RegionDomainResolver.resolveRegionsFromApi` also swallows API errors, so the failed-lookup cooldown never applied. | Every crossing that touched such a region took the "allowed while loading" path, never the immediate check. |
| 5 | **Riding.** The plugin had no `VehicleMoveEvent` handler, and a rider's movement is driven by the vehicle (`VehicleMoveEvent`). Whether Paper also fires a `PlayerMoveEvent` for a passenger is unverified: WorldGuard handles `RIDE` from both events, see [`2026-10-06-domain-access-enforcement-options.md`](2026-10-06-domain-access-enforcement-options.md) §1. | A rider crossed any AllowEntry/AllowExit border unchecked. The tracked set then went stale, so after dismounting the player could be denied every step *inside* the district. |
| 6 | **Corrective teleports were judged themselves.** The join-time "denied, go to spawn" teleport and the re-validation teleport went through `handleMove`. | A teleport out of a domain with AllowExit = false was cancelled by the very rule it was enforcing. |

## Fix (knk-plugin)

`knk-paper/.../paper/regions/WorldGuardRegionTracker.java`:

- **Judge from where the player is.** `oldRegions` is now the set of region ids at `from`, the player's real position. The tracked set is no longer used for this. A move the tracker never saw (a ride, or a move another plugin cancelled after the tracker allowed it) therefore can't make it judge the wrong border.
- **Record only what happened.** The tracked set and the enter/leave events go through one helper, `commitRegions`. It runs only when the move is allowed, bypassed, or still waiting on the cache. A denied move leaves the tracked set alone, so the next step over the border is judged, and denied, again.
- **Re-validation after a cold lookup** runs once all the lookups the move depends on have finished, including ones started by other players' moves. Then:
  - if the player is still in the move's destination, the full transition runs (as before);
  - if they are back at the start, nothing happens;
  - if they walked on, the side-effect-free `previewAccess` judges the move from its start to where they are now.

  A refused player is put back where the move started (`from`) instead of at world spawn. World spawn is still the fallback if that location is unavailable.
- **Lookups:** one future per region id, removed in `finally`. Ids the lookup leaves without a domain (a non-domain region, or an API failure) go on the existing 30 s failed-lookup cooldown, so the next crossings are judged straight from the cache.
- **`enforcementTeleport(player, target)`:** a teleport made to undo a refused move is not judged itself, and the tracked set follows the player to where they land.
- A package-private constructor takes the region lookup, the main-thread executor and the event dispatcher, so the tracker can be unit-tested without WorldGuard or Bukkit statics.

`knk-paper/.../paper/listeners/WorldGuardRegionListener.java`:

- **`onVehicleMove`** judges every player riding the vehicle. A vehicle move can't be cancelled, so a refused rider is taken off. The rider is put back at the vehicle's `from`, and so is the vehicle once it is empty. `onPlayerMove` skips riders: their moves belong to `onVehicleMove`.
- The join-time "go to spawn" now uses `enforcementTeleport`.

The AllowEntry/AllowExit rules themselves (`SimpleRegionTransitionService.checkEntryDenials`/`checkExitDenials` on `main`; extracted into `DomainAccessEvaluator` only on the unmerged road-navigation branch) were correct and are unchanged.

### Behaviour changes to review (reversible defaults)

1. **Pushed back, not sent to spawn.** A player refused after a cold-cache lookup is put back where they stepped over the border, instead of at world spawn. This puts them in the same place an immediate cancellation would. The old spawn teleport would also land a player who walked on in an unrelated place.
2. **Enter/leave events fire after the decision**, not before, and never for a denied move. `RegionTaskEventListener`/`WgRegionIdTaskHandler` (the only consumer) only cares that a player is really in the region. Domain discovery reads WorldGuard directly (`DomainDiscoveryListener`).
3. **A non-domain WorldGuard region is looked up at most every 30 s** (the existing cooldown) instead of on every crossing. A domain created for a region that is on cooldown is picked up within 30 s.

### Known limits (unchanged, documented)

- **Fail-open on missing data.** A domain the API can't deliver (outage) is treated as unrestricted until it is cached, as before. Fail-closed would freeze players at every unknown border during an outage.
- **No side effects for bypassed entry.** When a bypassing player enters a refusing domain, `handleRegionTransition` returns the denial before it runs gate control or district gate loading. This is pre-existing and out of scope.
- **Not trunk yet.** The road-navigation branches (`claude/road-navigation`, `claude/navigation-walkable-path`) change the same file: `getRegionNamesAt` delegates to `RegionIds`, and there is an extra `regionIds()` accessor. Merging the two causes a small, mechanical conflict around `getRegionNamesAt` and the constructor. Keep this branch's region-lookup seam and point it at `RegionIds.at`.

## Tests

New `knk-paper/src/test/java/.../paper/regions/WorldGuardRegionTrackerTest.java`, using the real `RegionDomainResolver` and `SimpleRegionTransitionService`, mocked `Player`/`World`/`Vehicle`:

- holding forward into an AllowEntry=false district: denied on every one of 5 steps, no enter event;
- holding forward out of an AllowExit=false district: denied on every step;
- an allowed entry is recorded once, with one enter event;
- a bypassing player is let through and tracked;
- a move the tracker never saw is judged from `from`, and the tracked set catches up;
- cold cache: the player walks on into a nested region during the lookup and is still put back;
- a second player crossing while the lookup is in flight is re-validated too (one API lookup for both);
- a non-domain region at the border: the first crossing is re-validated, and the next one is denied on the spot (cooldown, no second lookup);
- the enforcement teleport out of an AllowExit=false district is not judged;
- listener: every step of a held W cancels its `PlayerMoveEvent`;
- listener: a rider entering an AllowEntry=false district is taken off, and rider and vehicle are put back; an allowed ride is recorded.

## Verification

- **Build/tests (2026-10-06, knk-plugin `9ab1f5d`):** `./gradlew test -x deployToDevServer` is green: knk-core 1201, knk-api-client 150 (2 skipped), knk-paper 1041 (14 skipped), 0 failures. That includes the 12 new `WorldGuardRegionTrackerTest` cases.
- **The tests catch the bug.** With the old order temporarily restored (commit regions before deciding, judge from the tracked set), 5 of the 12 fail: both held-forward cases, the listener's held-W case, the ride case and the unseen-move case. The restore was then reverted.
- **Not verified here:** anything in game. Riders are judged only on `VehicleMoveEvent` (`onPlayerMove` skips them), which is safe whether or not Paper also fires `PlayerMoveEvent` for passengers. Riding an entity that is not a Bukkit `Vehicle` is not covered. Needs the live check below.
- **Live (developer):** with a non-bypass account on the dev server:
  1. hold W into an AllowEntry=false district: every step is blocked;
  2. hold W out of an AllowExit=false district: every step is blocked;
  3. ride a horse and a boat into both: the rider is dismounted and put back;
  4. restart the server (cold cache), walk into the district and keep walking: you are put back to the border, not to spawn;
  5. check that a `knk.region.bypass` holder still walks through, and that entry/exit messages still appear.
