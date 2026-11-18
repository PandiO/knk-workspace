# Navigation destination engine — smoke test

**Status:** Draft from the design (2026-11-18); § 1 updated by the P1 link (9 of 11 steps automated, tagged), § 2 by
the P2 link (12 of 13 steps automated, tagged); no manual steps run. Later sections are not yet automated (their links tag them).
**Last updated:** 2026-11-18 (§ 2 updated to the P2 code, steps tagged, #103); 2026-11-18 (§ 1 updated to the P1 code, steps tagged, #96); 2026-11-18 (design approved: tiers confirmed, phase 4b is #747); 2026-11-18 (draft from the design refresh, phases 1, 2, 3, 4, 4b and 5)
**Design:** [specs/navigation-destination-engine/DESIGN.md](../specs/navigation-destination-engine/DESIGN.md) · **Issue:**
[PandiO/knk-workspace#25](https://github.com/PandiO/knk-workspace/issues/25)

The engine decides which places a player may navigate to. Phases 1 and 2 change nothing a player sees; phases 3 and 4
are behind `navigation.destination-engine` (default `false`), and with it off navigation must behave exactly as
before. Phase 4b removes the flag. Acceptance ids (A01…) are in DESIGN § 13; sections are sized by the phase's tier
(approved 2026-11-18, DESIGN § 10).

Accounts and data used throughout:

1. **Player:** an ordinary account with `knk.navigate` (default), not staff.
2. **Staff:** an account that can switch owner or staff mode and freeze players (`/knk mode staff`).
3. **Bypass:** an ordinary account given `knk.navigate.any` (not granted by default).
4. **Dev world:** the world with the road network, at least one town with a spawn Location, one district without a
   spawn Location (region only), one named street and one Location target; a second world with a domain of its own.
5. **Siege:** a siege scenario with two teams, at least one capture objective behind a closed gate (#176), and the
   navigation compass enabled for sieges in the web app's compass settings.

## 1. Phase 1: pure engine in knk-core (#96, tier:2)

*Updated by the P1 link (2026-11-18) to what was built: knk-plugin `claude/navigation-destination-engine`, package
`net.knightsandkings.knk.core.navigation.destinations`. 9 of 11 steps automated in CI (tagged); every step can
still be run by hand; manual steps not run. Full manual run about 25 minutes; the untagged steps (10 and 11) about
10 minutes.*

Nothing is wired in this phase: the engine is code and tests only, with no config key and no migration. The manual
check is that nothing changed. The tagged steps are knk-core JUnit tests (`./gradlew :knk-core:test`, part of CI's
build); to run one by hand, read the test named in its tag and check the stated result in its assertions.

### 1.0 Preconditions

1. Deployed: plugin build from `next` with phase 1 merged.
2. Settings: none new.
3. Accounts and data: Player, Staff; the dev world; the siege scenario.

### 1.1 Steps

1. [automated: `InitialScopesTest.theTableIsWalkedInTheDesignsOrder`, `DestinationEngineTest` scope tests] Read the
   scope table in `InitialScopes`. **Expected:** scopes in the order account loading 110, frozen 110, bypass 100, no
   permission 80, siege match 60, siege match with the compass off 55, siege lobby 50, world 10; the first that
   applies decides the whole list and lower scopes are not asked (A01).
2. [automated: `InitialScopesTest` loading and frozen tests, `ReasonTest.theInitialTableHasTheDesignsCodesAndTodaysTexts`]
   Check the loading and frozen scopes for a plain player, in owner mode, in staff mode and with `knk.navigate.any`.
   **Expected:** an empty list with code `loading` and "Your account is still loading - try again in a moment.", or
   code `frozen` and "You can't navigate while frozen.", in every mode (A02, E9).
3. [automated: `InitialScopesTest` bypass tests, `LandmarkLikeProviderTest.theBypassListsLandmarksEvenInAMatch`] Check
   owner mode, staff mode and `knk.navigate.any`, also inside a running match. **Expected:** the bypass scope lists
   every world provider and the match provider (A03, E5, E6).
4. [automated: `InitialScopesTest` no-permission tests] Check a player without `knk.navigate`. **Expected:** an empty
   list with code `no-permission` and "You don't have permission to use /navigate." (A04).
5. [automated: `InitialScopesTest.aMatchWithoutDestinationsListsNothingWithTodaysText`,
   `withTheCompassOffAMatchMemberGetsTheReason`, `aMatchListIsRebuiltOnEveryCallNotCached`] Check a member of a running
   match with the compass on, with the compass off, and with an empty match list. **Expected:** only the match's
   objectives and team spawn in the compass's order; with the compass off (item disabled or off for sieges) an empty
   list with code `siege-compass-off`; an empty match list with code `siege-match-empty`; both with today's text "This
   match has no destinations to navigate to."; the match list is built again on every call, not cached (A05, E15, E18).
6. [automated: `InitialScopesTest.aLobbyMemberWithoutARunningMatchGetsTheSiegeReason`,
   `aHubProviderWithDestinationsReplacesTheLobbyReason`] Check a lobby member without a running match, without and
   with a hub provider. **Expected:** an empty list with code `siege-lobby` and "You can't navigate while you are in a
   siege."; a hub provider with places in the player's world lists them instead (A06, E10).
7. [automated: `DestinationEngineTest` resolving and completion tests, `InitialScopesTest` match resolution tests]
   Resolve `Kardenna`, `town:Kardenna`, `town:#1`, an ambiguous `Market` and a misspelt name, in the world and in a
   match. **Expected:** found, found, found, a choice of `district:Market` and `town:Market`, suggestions; in a match
   the same forms work on objectives (`objective:Keep Gate`) (A07).
8. [automated: `InitialScopesTest.anotherWorldIsHiddenFromCompletionButResolvesToItsMessage`,
   `LandmarkLikeProviderTest.aLandmarkInAnotherWorldIsNotCompletedButResolvesApart`] Complete and resolve a town and a
   landmark in another world. **Expected:** not offered in completion; resolving gives the other-world answer (A08,
   E11).
9. [automated: `ArchitectureGuardTest.onlyTheDestinationEngineConstructsAllowedDestination`,
   `InitialScopesTest` and `DestinationEngineTest` re-validation tests, `LandmarkLikeProviderTest`] Check the handle
   and re-validation, and the landmark-like provider in the World scope. **Expected:** only the engine package
   constructs `AllowedDestination`; a session's destination is found by key after re-ordering and after a rename,
   stays when an objective changes kind, and ends with the scope's reason (or code `no-longer-listed`) when it drops
   out; a landmark (key `landmark:<id>`, type word `landmark`, detail `in <domain>`, a point with an optional arrival
   radius or a region) is listed in the world, hidden in a match, the lobby, loading, frozen and without permission,
   and listed for the bypass (A09, E3, E4, E16, § 3.2).
10. As Player, `/navigate` a town, a street and a Location target, and press Tab after `/navigate ` and after a few
    letters. **Expected:** the same routes, messages and suggestions as before the update. (Manual: checks that
    nothing is wired; needs a server and a player.)
11. As Player in a running siege match, right-click the compass a few times and type `/navigate ` with Tab.
    **Expected:** the same objectives and team spawn as before, in the same order; other places are refused with the
    same message. (Manual: checks that nothing is wired; needs a server, a siege and a player.)

## 2. Phase 2: navigation model and offline snapshot (#103, tier:2)

*Updated by the P2 link (2026-11-18) to what was built: knk-web-api `claude/navigation-destination-engine` (the
domain search's `location`), knk-plugin `claude/navigation-destination-engine` (package
`net.knightsandkings.knk.core.navigation.model`, runtime `net.knightsandkings.knk.paper.navigation.model`). 12 of 13
steps automated in CI (tagged); every step can still be run by hand; manual steps not run. Full manual run about
35 minutes; the untagged step 13 about 5 minutes.*

Nothing a player sees changes in this phase: the plugin builds, refreshes and saves the model, but nothing reads it
before phase 3. The tagged steps are API xUnit tests (`dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`)
and plugin JUnit tests (`./gradlew test`), both part of CI; to run one by hand, read the test named in its tag and
check the stated result in its assertions, or do the manual form written in the step.

### 2.0 Preconditions

1. Deployed: knk-web-api from `next` with phase 2 (the domain search's `location`); plugin build from `next` with
   phase 2. Either can be deployed first: an older API makes the plugin look Locations up one by one (step 11).
2. Settings: `navigation.destinations.stale-after-days: 14` under `navigation:` in `config.yml` (the default; a
   missing key means 14).
3. Accounts and data: Staff; the dev world with a town that has a spawn Location, a district without one, a domain
   whose road access is "Ignored", and a Location target.
4. The snapshot file is `plugins/KnightsAndKings/offline/navigation-model.json` (the plugin's data folder).

### 2.1 Steps

1. [automated: `DomainSearchLocationTests.TheSearchCarriesTheLocationOrNull`,
   `TheRepositoryLoadsEachDomainsLocation`, `TheJsonAlwaysHasTheLocationKeyAndKeepsTheOtherFields`] As Staff with an
   API client, run the domain search (`POST api/Domains/search` with `{"pageNumber":1,"pageSize":50}`).
   **Expected:** each domain carries `location` (id, name, x, y, z, yaw, pitch, world) when it has one and
   `"location": null` when it has none; `id`, `name`, `description`, `wgRegionId`, `worldName`, `parentDomainId`,
   `parentDomain`, `domainType`, `navigationDefault` and `roadAccess` are unchanged. (A10, E12)
2. [automated: `DomainCatalogMapperTest.theLocationAndWorldAreCarriedThrough`,
   `anExplicitNullMeansTheDomainHasNoLocation`, `anOlderApiWithoutTheFieldLeavesTheLocationUnknown`] Check how the
   plugin reads the search. **Expected:** a `location` object becomes the domain's place; `"location": null` means
   "no Location"; a search without the key (an older API) leaves the place unknown for the fallback of step 11. (A10)
3. [automated: `NavigationModelRuntimeTest.theFirstStartWritesTheSnapshotAfterTheBackgroundRefresh`,
   `NavigationModelSnapshotTest.schemaOneHasEverySectionAndAnEmptyLandmarksList`, `theFileHoldsNoPlayerData`] Delete
   the snapshot file if there is one, start the server with the API up and wait a minute. **Expected:** the log has
   "No navigation model snapshot yet" and then "Navigation model loaded: N domain(s), M Location(s)"; the file exists
   with `"schema" : 1`, `asOf`, `domains` (each with its spawn, region, world, `navigationDefault` and `roadAccess`),
   `locations`, `compass` and an empty `landmarks` list, and no player names or UUIDs. (A11, E16, E19)
4. [automated: `NavigationModelSnapshotTest.theWriteIsAtomicAndReplacesTheOldFile`,
   `NavigationModelRefresherTest.theSnapshotIsWrittenOffTheCallingThreadAfterAChange`,
   `anUnchangedModelIsNotWrittenAgainUntilItsFileIsADayBehind`] Watch the file's modification time for a few minutes
   without changing anything in the web app. **Expected:** it is not rewritten every minute (only after a change, or
   once a day to keep its `asOf` current); no `navigation-model.json.tmp` is left in the folder. (A11)
5. [automated: `NavigationModelRefresherTest.afterARestartWithTheApiDownTheSameModelIsServed`,
   `NavigationModelRuntimeTest.theSnapshotIsLoadedAtStartUpBeforeTheApiAnswers`] Stop the web API, restart the game
   server, then as Player `/navigate` the town by name. **Expected:** the log has "Navigation model snapshot loaded
   from …: N domain(s), M Location(s), as of <time>, fresh (<age> old)" and then "Navigation model refresh failed,
   keeping the last model"; `/navigate` still behaves as today (the engine reads the model from phase 3 on, § 3.3
   step 1). (A12, E1)
6. [automated: `NavigationModelSnapshotTest.aCorruptFileIsIgnoredNeverThrown`, `aNewerSchemaIsIgnored`,
   `NavigationModelRefresherTest.aCorruptSnapshotIsIgnoredAndTheNextGoodRefreshWritesANewOne`,
   `NavigationModelRuntimeTest.aBrokenSnapshotDoesNotStopTheStart`] Stop the server, replace the file's content with
   `{ broken`, start again with the API up. **Expected:** a warning "Ignoring the navigation model snapshot …
   (CORRUPT: …); the next good refresh writes a new one", the plugin starts normally, and within a minute the file is
   valid again. The same with `"schema": 2` gives "(NEWER_SCHEMA: schema 2 …)". (A13)
7. [automated: `ModelFreshnessTest.withoutAnyModelTheListIsLimitedWithTheDesignsText`] With no snapshot and the API
   down, the model's freshness is "limited (no snapshot)" with the text "Some places aren't available while the web
   API is down.". **Expected:** as stated; players see it from phase 3 on (§ 3.3 step 2). (A13)
8. [automated: `NavigationModelRefresherTest.aRefreshReplacesTheModelSoRenamesAndDeletionsPropagate`] With the API
   up, rename the town in the web app and delete a test structure, then wait for the next refresh (about a minute).
   **Expected:** the snapshot holds the new name and not the old one, and the deleted structure is gone. (A14)
9. [automated: `ModelFreshnessTest.aModelOlderThanTheLimitGetsTheMayBeOutOfDateNote`,
   `theLimitIsConfigurableButAtLeastADay`, `NavigationModelConfigTest`] Stop the API, set the file's `asOf` to 15
   days ago, restart. **Expected:** the start-up log line says "stale (15 days old)"; the lists get "The list of
   places may be out of date (last updated 15 days ago)." from phase 3 on; `stale-after-days: 30` makes it "fresh";
   0 counts as 1. (A15, E12)
10. [automated: `NavigationModelRuntimeTest.theRoadAccessAnswersAreTheCataloguesAnswers`,
    `NavigationModelTest.onlyAnExplicitIgnoredLiftsTheRuleOffTheRoads`,
    `regionsOfIgnoredDomainsAreAnsweredInAnyCase`] Compare the model's road-access answers with today's catalogue
    for the same API data. **Expected:** the same answer for every domain id and region (the "Ignored" domain and its
    region in any case: yes; others and unknown ones: no). Routes use them from phase 3 on (A21). (E19)
11. [automated: `NavigationModelRefresherTest.withAnOlderApiPlacesAreLookedUpAFewPerTickAndTheSnapshotWaitsForThem`,
    `placesFoundByTheFallbackAreKeptByTheNextRefresh`, `aFailedLookupIsTriedAgainAfterTheNextRefreshAndDoesNotHoldUpTheSnapshot`,
    `withTheNewApiNothingIsLookedUp`, `NavigationModelRuntimeTest.theFallbackLooksUpTownsDistrictsAndStructuresThroughTheResolver`]
    Run the phase 2 plugin against an API without the change. **Expected:** the log says "… N domain place(s) to look
    up one by one (the API's search sends no Locations)"; two places a second are looked up; the snapshot is written
    once they are done; a later refresh keeps them; `/knk cache refresh` looks them up again. Against the new API
    nothing is looked up. (§ 7.2)
12. [automated: `NavigationModelUnreadTest.onlyTheModelPackagesAndTheStartUpWiringUseTheModel`] Check that nothing
    reads the model. **Expected:** only `KnKPlugin` (start and stop) names the model's packages. (A16 groundwork)
13. As Player, `/navigate` a town, a street and a Location target, press Tab after `/navigate `, and right-click the
    navigation compass outside a siege. **Expected:** the same routes, messages, suggestions and compass behaviour as
    before the update. (Manual: checks that nothing is wired; needs a server and a player.)

## 3. Phase 3: switch-over behind the flag (#69, tier:3)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 3.0 Preconditions

1. Deployed: plugin build from `next` with phases 1 to 3; knk-web-api as in § 2.
2. Settings: first `navigation.destination-engine: false`, then `true` (`/knk reload` or a restart, as the link's
   deploy notes say).
3. Accounts and data: Player, Staff, Bypass; the dev world and the second world; the siege scenario.

### 3.1 Flag off

1. With the flag off, repeat § 1.1 steps 2 and 3. **Expected:** exactly today's behaviour. (A16)

### 3.2 Flag on, outside a siege

1. As Player, `/navigate <town>`, `/navigate <town> spawn`, `/navigate <district> region`, `/navigate street:<name>`
   and `/navigate location:<name>`. **Expected:** the same routes as with the flag off; no delay at click time. (A17)
2. As Player, Tab after `/navigate ` and after `town:`. **Expected:** the same suggestions as with the flag off; places
   of the second world are not suggested. (A17, A08)
3. As Player, `/navigate <domain of the second world>`. **Expected:** "… is in another world" as today. (A08)
4. As Player, type a misspelt town name. **Expected:** "unknown destination" and a "did you mean" line as today. (A07)
5. As Player, right-click the compass outside a siege with general targets configured. **Expected:** it cycles the
   configured targets as today; with the general switch off it says "The navigation compass has no destinations
   here." while `/navigate` still works. (A19)
6. As Staff, run `/knk road why <town>`. **Expected:** the explanation as today. (A20)
7. As Player, walk a route that passes a domain whose road access is "Ignored". **Expected:** the route uses its
   roads as before. (A21)

### 3.3 Flag on, API down

1. Stop the web API, restart the game server, then as Player `/navigate <town>` and right-click the compass.
   **Expected:** the town is found and routed from the snapshot; the compass uses the saved settings, not the
   defaults. (A12, A17)
2. Stop the server, delete `navigation-model.json`, start with the API still down, then `/navigate ` with Tab.
   **Expected:** streets and named nodes are offered; towns are not; `/navigate` and the compass say "Some places
   aren't available while the web API is down.". (A13)

### 3.4 Flag on, in a siege match

1. As Player in a running match, Tab after `/navigate `. **Expected:** only the match's objectives, the team spawn and
   `stop`. (A18)
2. As Player, `/navigate objective:<name>` and `/navigate <start of an objective name>`. **Expected:** both start a
   route to that objective. (A18, A07)
3. As Player, `/navigate <town>`. **Expected:** refused; the message names the match's destinations. (A18)
4. As Player of the attacking team, select the objective behind the closed gate with the compass. **Expected:** the
   route leads to the gate, not the capture point (#176). (A18)
5. Switch the compass off for sieges in the web app, wait a minute, then `/navigate ` and right-click the compass.
   **Expected:** `/navigate` says "This match has no destinations to navigate to."; the compass says "The navigation
   compass is switched off during sieges.". (A05, A19)
6. As Bypass in the match, `/navigate <town>`. **Expected:** a route starts (the bypass lists everything). (A03)
7. As Player, select an objective with the compass, stop with shift-click, then shift-click again. **Expected:** the
   compass resumes the same objective while it is still listed. (A19)

## 4. Phase 4: hard blocks as scopes and live re-validation (#62, tier:3)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 4.0 Preconditions

1. Deployed: plugin build from `next` with phases 1 to 4.
2. Settings: `navigation.destination-engine: true`.
3. Accounts and data: Player, Staff, Bypass; the siege scenario.

### 4.1 Steps

1. As Player right after joining (account still loading), `/navigate <town>`. **Expected:** "Your account is still
   loading - try again in a moment.". (A22)
2. As Staff, freeze Player, then as Player `/navigate <town>`. **Expected:** "You can't navigate while frozen.". (A22)
3. As Staff in staff mode, have another staff member of higher rank freeze you, then `/navigate <town>`. **Expected:**
   refused while frozen, as for anyone (E9). (A02, A25)
4. Remove `knk.navigate` from Player, `/navigate <town>`. **Expected:** "You don't have permission to use
   /navigate.". (A22, A04)
5. As Player in a siege lobby before the match, `/navigate <town>` and right-click the compass. **Expected:**
   `/navigate`: "You can't navigate while you are in a siege."; the compass: "The navigation compass works once the
   siege match has started.". (A22, A06)
6. As Player, start a route to a town, then join a siege lobby. **Expected:** the route ends at once with "You can't
   navigate while you are in a siege.". (A23, A24, A26)
7. As Player in a running match, navigate to a capture objective; let the other team capture it so it is no longer
   listed for you. **Expected:** the route ends at once with the scope's reason; if it is still listed as "defend",
   the route keeps going. (A23, A24, A25)
8. As Player, navigate to an objective, then let the match end. **Expected:** the route ends at once with the reason
   of the scope you are in now. (A24)
9. As Staff in staff mode in a match, `/navigate <town>`; then switch staff mode off. **Expected:** the route starts;
   after switching off it ends at once with the match's reason. (A25)
10. As Player navigating to a town, have Staff freeze you. **Expected:** the route ends at once with "You can't
    navigate while frozen.". (A23, A24)

## 5. Phase 4b: removal of the old paths and the flag (#747, tier:2)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 5.0 Preconditions

1. Deployed: plugin build from `next` with phase 4b; the developer has run § 3 and § 4 with the flag on.
2. Settings: `navigation.destination-engine` removed from `config.yml` (the deploy notes say so).
3. Accounts and data: as in § 3.

### 5.1 Steps

1. Start the server without the flag. **Expected:** no warning about an unknown or missing key; navigation uses the
   engine. (A27)
2. Repeat § 3.2 steps 1, 2 and 5, § 3.4 steps 1, 3 and 5, and § 4.1 steps 5 and 6. **Expected:** as written there.
   (A28)

## 6. Phase 5: arena duels provider and scope (#55, tier:2)

*Draft from the design (2026-11-18); written in full when the arena duels work is merged and the phase is scheduled.*

### 6.0 Preconditions

1. Deployed: plugin build from `next` with phase 5 and the arena duels work.
2. Settings: arena duels enabled.
3. Accounts and data: two Players in a duel.

### 6.1 Steps

1. As a Player in a running duel, Tab after `/navigate ` and `/navigate <town>`. **Expected:** only the duel's places
   are offered; the town is refused with the duel's reason. (A29)
2. As a Player queued or in the duel's lobby, `/navigate <town>`. **Expected:** refused with the duel's reason. (A29)
3. After the duel, `/navigate <town>`. **Expected:** a route starts as usual. (A29)
